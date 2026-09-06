# Bundled runtime source and modification information

Some NumPy native numerical libraries and tqdm have source-availability obligations. The matching release includes **Corresponding-Sources.tar.gz**, alongside the installer, available at:

https://github.com/olivierbedardjazz-star/stem-separator/releases/latest/download/Corresponding-Sources.tar.gz

Version-specific release pages retain their own source archive. The archive contains GCC 11.3.0 source, the macOS gfortran recipe and ARM patches, and tqdm 4.70.0 source. Download hashes and provenance are recorded in Packaging/corresponding-sources.lock.json in the source repository.

NumPy 1.26.4's wheel-building scripts identify OpenBLAS v0.3.23-293-gc2f4bdbb and gfortran gcc-11.3.0-2. The associated gfortran distribution uses conda-forge GCC 11.3.0. The preserved recipe includes the GCC source hash, ARM patches and build/install scripts. Sources:

- https://github.com/numpy/numpy/blob/v1.26.4/tools/openblas_support.py
- https://github.com/numpy/numpy/blob/v1.26.4/tools/wheels/gfortran_utils.sh
- https://github.com/isuruf/gcc/releases/tag/gcc-11.3.0-2
- https://github.com/conda-forge/gfortran_impl_osx-64-feedstock/tree/481738c977ef7b651105c9715ad2255c613500df

The helper dynamically loads NumPy's OpenBLAS, libgfortran, libgcc and libquadmath libraries. Upstream source is unmodified by this app; PyInstaller relocates binary load paths and the distribution process applies code signatures. See the complete NumPy licence, GCC Runtime Library Exception and LGPL text in RuntimeLicenses. OpenBLAS has BSD terms; libgfortran/libgcc have GPL terms with the GCC runtime exception; libquadmath has LGPL-2.1-or-later terms. tqdm has MPL/MIT notices.

You may modify LGPL-covered libraries and replace/relink them for your own use, and reverse engineer the combined work to debug such modifications, to the extent permitted or required by their licences. Those rights take precedence over any conflicting app terms. Replacing an executable library invalidates the original code signature and notarization ticket: do not present modified copies as signed by the original publisher.

For a development rebuild, use the public build scripts and the pinned artifact/source records. The frozen helper lives at Contents/Helpers/StemWorker.app. NumPy libraries reside under Contents/Frameworks/numpy/__dot__dylibs inside that helper. Rebuild or replace the compatible arm64 libraries, preserve their relative load paths, re-sign the helper's native code and containers using your own identity (or ad hoc for local development), regenerate the helper manifest with scripts/create_runtime_manifest.py, then sign the outer app last. scripts/sign_stem_runtime.sh documents nested signing order; production identity verification in that script must be adapted for a local developer signature. Modified builds do not retain the publisher's update/signature guarantees.

Build-only tools listed in the aggregate inventory need not be loaded by the app. In particular, the final Mach-O inventory is the authority for native payload presence; the app does not ship the lameenc extension or an ffmpeg/SoX runtime. Full collected notices are preserved even where a dependency is used only on the builder.
