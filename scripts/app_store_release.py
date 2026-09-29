#!/usr/bin/env python3
"""Separate Mac App Store release path for Stem Separator.

This script never changes the Developer ID release pipeline. Commands with a
network side effect are explicit: `validate`, `upload`, and `status`.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import stat
import subprocess
import sys


ROOT = Path(__file__).resolve().parent.parent
DIRECT_CONFIG = json.loads((ROOT / "Packaging/release-config.json").read_text())
SCHEME = os.environ.get("APP_STORE_SCHEME", "StemSeparatorAppStore")
RELEASE_ROOT = ROOT / "build/AppStoreRelease"


class ReleaseError(RuntimeError):
    pass


def project_version() -> tuple[str, str]:
    source = (ROOT / "project.yml").read_text()
    values = {}
    for key in ("MARKETING_VERSION", "CURRENT_PROJECT_VERSION"):
        match = re.search(rf"(?m)^\s*{key}:\s*[\"']?([^\s\"']+)", source)
        if not match:
            raise ReleaseError(f"{key} is missing from project.yml")
        values[key] = match.group(1)
    return values["MARKETING_VERSION"], values["CURRENT_PROJECT_VERSION"]


def paths() -> tuple[Path, Path, Path]:
    version, build = project_version()
    root = RELEASE_ROOT / f"{version}-{build}"
    return root, root / "StemSeparator.xcarchive", root / "export"


def run(*args: str | Path, capture: bool = False, env: dict[str, str] | None = None) -> str:
    argv = [str(value) for value in args]
    result = subprocess.run(argv, cwd=ROOT, env=env, text=True, check=False,
                            stdout=subprocess.PIPE if capture else None,
                            stderr=subprocess.PIPE if capture else None)
    if result.returncode:
        detail = (result.stderr or result.stdout or "").strip() if capture else ""
        raise ReleaseError(f"Command failed ({result.returncode}): {argv[0]} {argv[1] if len(argv) > 1 else ''}\n{detail}")
    return result.stdout if capture else ""


def require_tool(name: str) -> None:
    if not shutil.which(name):
        raise ReleaseError(f"Required tool is unavailable: {name}")


def require_store_scheme() -> None:
    source = (ROOT / "project.yml").read_text()
    if not re.search(rf"(?m)^  {re.escape(SCHEME)}:\s*$", source):
        raise ReleaseError(f"Store scheme {SCHEME!r} is not declared in project.yml")


def key_flags() -> list[str]:
    """Return Xcode authentication flags only for a complete local credential."""
    key_id = os.environ.get("ASC_KEY_ID", "")
    issuer = os.environ.get("ASC_ISSUER_ID", "")
    key_path = os.environ.get("ASC_P8_PATH", "")
    provided = (bool(key_id), bool(issuer), bool(key_path))
    if not any(provided):
        return []
    if not all(provided):
        raise ReleaseError("Set ASC_KEY_ID, ASC_ISSUER_ID, and ASC_P8_PATH together")
    p8 = Path(key_path).expanduser().resolve()
    if not p8.is_file() or p8.suffix != ".p8":
        raise ReleaseError("ASC_P8_PATH must name an existing local .p8 file")
    if p8.is_relative_to(ROOT):
        raise ReleaseError("The App Store Connect private key must be outside this repository")
    if p8.stat().st_mode & (stat.S_IRWXG | stat.S_IRWXO):
        raise ReleaseError("Restrict App Store Connect private key permissions to owner only (chmod 600)")
    return ["-authenticationKeyPath", str(p8), "-authenticationKeyID", key_id,
            "-authenticationKeyIssuerID", issuer]


def altool_flags() -> list[str]:
    xcode_flags = key_flags()
    if not xcode_flags:
        raise ReleaseError("ASC_KEY_ID, ASC_ISSUER_ID, and ASC_P8_PATH are required for this command")
    return ["--api-key", xcode_flags[3], "--api-issuer", xcode_flags[5],
            "--p8-file-path", xcode_flags[1]]


def preflight() -> None:
    require_tool("xcodebuild")
    require_tool("codesign")
    require_tool("xcrun")
    require_tool("productbuild")
    require_store_scheme()
    runtime = ROOT / "build/StemRuntime/dist/StemWorker.app"
    if not runtime.is_dir():
        raise ReleaseError(f"Bundled worker missing: {runtime}; run scripts/build_stem_runtime.sh")
    store_libomp = ROOT / "build/AppStoreRuntime/libomp.dylib"
    if not store_libomp.is_file():
        raise ReleaseError(f"Sandbox-compatible OpenMP runtime missing: {store_libomp}; run scripts/build_store_libomp.sh")
    print(f"Store source ready: {SCHEME}, {DIRECT_CONFIG['bundleID']}, {project_version()[0]} ({project_version()[1]})")
    print("Signing availability and provisioning are proven only by archive/export.")


def archive() -> None:
    preflight()
    root, archive_path, _ = paths()
    if archive_path.exists():
        raise ReleaseError(f"Refusing to replace an existing Store archive: {archive_path}")
    root.mkdir(parents=True, exist_ok=True)
    xcodegen = ROOT / "build/BuildTools/xcodegen/bin/xcodegen"
    if not xcodegen.is_file():
        require_tool("xcodegen")
        xcodegen = Path(shutil.which("xcodegen"))
    run(xcodegen, "generate")
    command = ["xcodebuild", "archive", "-project", DIRECT_CONFIG["project"],
               "-scheme", SCHEME, "-configuration", "Release",
               "-destination", "generic/platform=macOS", "-archivePath", archive_path,
               "-derivedDataPath", root / "DerivedData", "CODE_SIGNING_ALLOWED=NO", "-quiet"]
    run(*command)
    verify_archive()


def signed_entitlements(path: Path) -> dict:
    # codesign writes diagnostic lines to stderr and the plist to stdout.
    # `-` prints a human-readable [Dict] tree in current codesign; `:-` emits
    # the XML plist needed for an exact entitlement assertion.
    raw = run("codesign", "-d", "--entitlements", ":-", path, capture=True)
    try:
        return plistlib.loads(raw.encode())
    except (ValueError, plistlib.InvalidFileException) as error:
        raise ReleaseError(f"Cannot read signed entitlements from {path}: {error}") from error


def verify_archive() -> None:
    _, archive_path, _ = paths()
    app = archive_path / "Products/Applications" / DIRECT_CONFIG["appName"]
    helper = app / "Contents/Helpers/StemWorker.app"
    if not app.is_dir() or not helper.is_dir():
        raise ReleaseError("Store archive must contain the main app and bundled StemWorker.app")
    info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    if info.get("CFBundleIdentifier") != DIRECT_CONFIG["bundleID"]:
        raise ReleaseError("Store archive bundle identifier differs from release configuration")
    version, build = project_version()
    if (info.get("CFBundleShortVersionString"), info.get("CFBundleVersion")) != (version, build):
        raise ReleaseError("Store archive version/build does not match project.yml")
    if (app / "Contents/Frameworks/Sparkle.framework").exists():
        raise ReleaseError("Sparkle is present in the App Store archive")
    print(f"Verified unsigned Store archive structure: {archive_path}")


def signing_identity(env_name: str, label: str, *, code: bool) -> str:
    identity = os.environ.get(env_name, "").strip()
    if not identity:
        raise ReleaseError(f"Set {env_name} to the local {label} signing identity")
    argv = ["security", "find-identity", "-v"]
    if code:
        argv += ["-p", "codesigning"]
    identities = run(*argv, capture=True)
    if identity not in identities:
        raise ReleaseError(f"{label} signing identity is unavailable in the keychain")
    return identity


def mach_o(path: Path) -> bool:
    magic = {b"\xcf\xfa\xed\xfe", b"\xfe\xed\xfa\xcf", b"\xce\xfa\xed\xfe",
             b"\xfe\xed\xfa\xce", b"\xca\xfe\xba\xbe", b"\xbe\xba\xfe\xca",
             b"\xca\xfe\xba\xbf", b"\xbf\xba\xfe\xca"}
    with path.open("rb") as stream:
        return stream.read(4) in magic


def sign_app(*, local: bool) -> None:
    verify_archive()
    root, archive_path, _ = paths()
    app = root / ("signed-local" if local else "signed") / DIRECT_CONFIG["appName"]
    if app.exists():
        raise ReleaseError(f"Refusing to replace an existing signed Store app: {app}")
    identity = "-" if local else signing_identity("MAS_APP_SIGN_IDENTITY", "Apple Distribution", code=True)
    profile = None
    if not local:
        profile_path = os.environ.get("MAS_PROVISION_PROFILE", "")
        if not profile_path:
            raise ReleaseError("Set MAS_PROVISION_PROFILE to the local Mac App Store provisioning profile")
        profile = Path(profile_path).expanduser().resolve()
        if not profile.is_file() or profile.is_relative_to(ROOT):
            raise ReleaseError("Provisioning profile must be an existing local file outside this repository")
        profile_data = plistlib.loads(run("security", "cms", "-D", "-i", profile, capture=True).encode())
        if DIRECT_CONFIG["teamID"] not in profile_data.get("TeamIdentifier", []):
            raise ReleaseError("Mac App Store provisioning profile belongs to a different team")
        profile_app_id = profile_data.get("Entitlements", {}).get("com.apple.application-identifier")
        expected_app_id = f"{DIRECT_CONFIG['teamID']}.{DIRECT_CONFIG['bundleID']}"
        if profile_app_id != expected_app_id:
            raise ReleaseError(f"Provisioning profile is not for {DIRECT_CONFIG['bundleID']}")
        expiration = profile_data.get("ExpirationDate")
        if isinstance(expiration, datetime) and expiration.replace(tzinfo=timezone.utc) <= datetime.now(timezone.utc):
            raise ReleaseError("Mac App Store provisioning profile has expired")
    app_entitlements = ROOT / "Packaging/AppStore/StemSeparator.entitlements"
    helper_entitlements = ROOT / "Packaging/AppStore/StemWorker.entitlements"
    if not app_entitlements.is_file() or not helper_entitlements.is_file():
        raise ReleaseError("Store app and worker entitlement plists are required under Packaging/AppStore")
    app.parent.mkdir(parents=True, exist_ok=True)
    run("ditto", archive_path / "Products/Applications" / DIRECT_CONFIG["appName"], app)
    if profile:
        shutil.copyfile(profile, app / "Contents/embedded.provisionprofile")
    helper = app / "Contents/Helpers/StemWorker.app"
    for path in app.rglob("*"):
        if path.is_symlink():
            if not path.exists() or not path.resolve().is_relative_to(app):
                raise ReleaseError(f"Unsafe symlink in Store app: {path}")
    # Sign individual code first; each enclosing bundle seals only final bytes.
    signing_flags = [] if local else ["--timestamp", "--options", "runtime"]
    for leaf in sorted((p for p in app.rglob("*") if p.is_file() and not p.is_symlink() and mach_o(p)),
                       key=lambda p: len(p.parts), reverse=True):
        run("codesign", "--force", *signing_flags, "--sign", identity, leaf)
    bundles = [p for p in app.rglob("*") if p.is_dir() and not p.is_symlink()
               and p != helper and p.suffix in (".framework", ".app", ".xpc")]
    for bundle in sorted(bundles, key=lambda p: len(p.parts), reverse=True):
        run("codesign", "--force", *signing_flags, "--sign", identity, bundle)
    run("codesign", "--force", *signing_flags, "--sign", identity,
        "--entitlements", helper_entitlements, helper)
    run("codesign", "--force", *signing_flags, "--sign", identity,
        "--entitlements", app_entitlements, app)
    verify_signatures(app, require_team=not local)


def sign() -> None:
    sign_app(local=False)


def sign_local() -> None:
    sign_app(local=True)


def verify_signatures(app: Path, *, require_team: bool) -> None:
    helper = app / "Contents/Helpers/StemWorker.app"
    if not helper.is_dir():
        raise ReleaseError("Signed Store app/helper is missing; run sign first")
    for item in (app, helper):
        run("codesign", "--verify", "--deep", "--strict", item)
    for leaf in (p for p in app.rglob("*") if p.is_file() and not p.is_symlink() and mach_o(p)):
        run("codesign", "--verify", "--strict", leaf)
    app_entitlements = signed_entitlements(app)
    helper_entitlements = signed_entitlements(helper)
    if app_entitlements.get("com.apple.security.app-sandbox") is not True:
        raise ReleaseError("Main Store app signature lacks App Sandbox")
    if helper_entitlements.get("com.apple.security.app-sandbox") is not True:
        raise ReleaseError("StemWorker signature lacks App Sandbox")
    if helper_entitlements.get("com.apple.security.inherit") is not True:
        raise ReleaseError("StemWorker signature lacks sandbox inheritance")
    if require_team:
        for item in (app, helper):
            details = subprocess.run(["codesign", "-dv", str(item)], capture_output=True, text=True)
            if f"TeamIdentifier={DIRECT_CONFIG['teamID']}" not in details.stderr:
                raise ReleaseError(f"Wrong signing team in {item}")
    print(f"Verified sandboxed Store app and worker: {app}")


def verify_signed() -> None:
    root, _, _ = paths()
    verify_signatures(root / "signed" / DIRECT_CONFIG["appName"], require_team=True)


def verify_local() -> None:
    root, _, _ = paths()
    verify_signatures(root / "signed-local" / DIRECT_CONFIG["appName"], require_team=False)


def export() -> None:
    verify_signed()
    root, _, export_path = paths()
    if export_path.exists():
        raise ReleaseError(f"Refusing to replace an existing Store export: {export_path}")
    identity = signing_identity("MAS_INSTALLER_SIGN_IDENTITY", "Mac Installer Distribution", code=False)
    export_path.mkdir(parents=True)
    version, build = project_version()
    package_path = export_path / f"Stem-Separator-App-Store-{version}-{build}.pkg"
    run("productbuild", "--sign", identity, "--component",
        root / "signed" / DIRECT_CONFIG["appName"], "/Applications", package_path)
    run("pkgutil", "--check-signature", package_path)
    print(f"Exported signed Store installer package: {package_path}")


def package() -> Path:
    _, _, export_path = paths()
    packages = sorted(export_path.glob("*.pkg")) if export_path.is_dir() else []
    if len(packages) != 1:
        raise ReleaseError("Expected one exported Store .pkg; run export first")
    return packages[0]


def validate() -> None:
    pkg = package()
    run("xcrun", "altool", "--validate-app", "-f", pkg, "-t", "macos",
        *altool_flags())
    print(f"Apple validation accepted: {pkg}")


def upload() -> None:
    pkg = package()
    # Deliberately separate from validation: the operator can inspect the exact
    # package and Apple validation result before initiating delivery.
    run("xcrun", "altool", "--upload-app", "-f", pkg, "-t", "macos",
        *altool_flags())
    print("Upload delivered; Apple processing and build association remain to be checked.")


def status() -> None:
    apple_id = os.environ.get("ASC_APPLE_ID", "")
    if not apple_id.isdigit():
        raise ReleaseError("Set ASC_APPLE_ID to the numeric App Store Connect app ID")
    version, build = project_version()
    run("xcrun", "altool", "--build-status", "--apple-id", apple_id,
        "--bundle-version", build, "--bundle-short-version-string", version,
        "--platform", "macos", "--output-format", "json", *altool_flags())


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("preflight", "archive", "verify-archive",
                                            "sign-local", "verify-local", "sign", "verify-signed", "export", "validate",
                                            "upload", "status"))
    command = parser.parse_args().command
    try:
        globals()[command.replace("-", "_")]()
    except ReleaseError as error:
        parser.exit(1, f"App Store release: {error}\n")


if __name__ == "__main__":
    main()
