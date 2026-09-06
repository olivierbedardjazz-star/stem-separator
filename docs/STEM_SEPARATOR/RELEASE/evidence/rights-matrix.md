# Runtime rights review — in progress

Recorded September 6, 2026. No public distribution clearance is claimed.

## Model gate

Current checkpoint: `955717e8-8726e21a.th`; exact hash in runtime/provenance.json. The [upstream author statement](https://github.com/facebookresearch/demucs/issues/327#issuecomment-1134828611) explicitly separates weights from MIT code. The archived repository and maintained fork do not establish an explicit grant for this checkpoint in the reviewed materials. A newer upstream Hugging Face listing for hdemucs_mmi was also inspected; its current raw model card has no licence field and no LICENSE file was available. Search-result licence labels are not accepted as authoritative clearance.

Public model-bearing release is blocked pending permission evidence or a separately validated alternative. The owner has been asked whether a different four-stem backend may be evaluated if needed. No maintainer has been contacted.

## Installed-distribution inventory

This table records collected metadata only. Actual PyInstaller payload reconciliation, native-library obligations and source asset publication review remain pending.

| Component | Version | Collected licence files | Review |
| --- | --- | --- | --- |
| altgraph | 0.17.5 | 1 | Pending payload/terms reconciliation |
| antlr4-python3-runtime | 4.9.3 | 0 | Pending payload/terms reconciliation |
| cloudpickle | 3.1.2 | 1 | Pending payload/terms reconciliation |
| demucs | 4.0.1 | 1 | Pending payload/terms reconciliation |
| dora_search | 0.1.12 | 1 | Pending payload/terms reconciliation |
| einops | 0.8.2 | 1 | Pending payload/terms reconciliation |
| filelock | 3.32.5 | 1 | Pending payload/terms reconciliation |
| fsspec | 2026.7.0 | 1 | Pending payload/terms reconciliation |
| Jinja2 | 3.1.6 | 1 | Pending payload/terms reconciliation |
| julius | 0.2.8 | 1 | Pending payload/terms reconciliation |
| lameenc | 1.8.4 | 1 | Pending payload/terms reconciliation |
| macholib | 1.16.4 | 1 | Pending payload/terms reconciliation |
| MarkupSafe | 3.0.3 | 1 | Pending payload/terms reconciliation |
| mpmath | 1.3.0 | 1 | Pending payload/terms reconciliation |
| networkx | 3.6.1 | 1 | Pending payload/terms reconciliation |
| numpy | 1.26.4 | 4 | Pending payload/terms reconciliation |
| omegaconf | 2.3.1 | 1 | Pending payload/terms reconciliation |
| openunmix | 1.3.0 | 1 | Pending payload/terms reconciliation |
| packaging | 26.3 | 3 | Pending payload/terms reconciliation |
| pip | 24.0 | 1 | Pending payload/terms reconciliation |
| pyinstaller | 6.16.0 | 1 | Pending payload/terms reconciliation |
| pyinstaller-hooks-contrib | 2026.7 | 1 | Pending payload/terms reconciliation |
| PyYAML | 6.0.3 | 1 | Pending payload/terms reconciliation |
| retrying | 1.4.2 | 2 | Pending payload/terms reconciliation |
| setuptools | 82.0.0 | 17 | Pending payload/terms reconciliation |
| submitit | 1.5.4 | 1 | Pending payload/terms reconciliation |
| sympy | 1.13.1 | 2 | Pending payload/terms reconciliation |
| torch | 2.5.1 | 2 | Pending payload/terms reconciliation |
| torchaudio | 2.5.1 | 1 | Pending payload/terms reconciliation |
| tqdm | 4.70.0 | 0 | Pending payload/terms reconciliation |
| treetable | 0.2.6 | 1 | Pending payload/terms reconciliation |
| typing_extensions | 4.16.0 | 1 | Pending payload/terms reconciliation |

Python, Sparkle, the model, fonts, logo/icon/banner assets and template-owned source require their separate records; pip metadata is not the full shipped inventory.

## Completed source-scan tooling

`scripts/audit_public_source.py` audits an explicit relative path list and reports only path/category for suspected credentials. Three unit tests passed for secret redaction, allowed public-key metadata, forbidden artifacts/traversal/symlinks. This is a tool check, not a completed staged-tree review.

## New exact-checkpoint evidence found during continued execution

The author-hosted [HTDemucs repository](https://huggingface.co/adefossez/HTDemucs) identifies checkpoint `955717e8`, the four-stem model used by this app. Its latest revision `cbc8a9b1a87023b7fd74e7b3412e6321c0eab003`, authored by adefossez on 2026-08-31, is titled [Remove license from model card](https://huggingface.co/adefossez/HTDemucs/commit/cbc8a9b1a87023b7fd74e7b3412e6321c0eab003). The diff removes `license: mit`. The current raw README has no model licence declaration and the repository has no LICENSE file. The preceding July 11 revision did carry that metadata label; whether that earlier label establishes an enduring grant for a particular acquired artifact is not resolved by this engineering review. Do not erase that history or assert a legal conclusion about retroactive revocation.

The maintainer also replied to [issue 508, specifically about htdemucs v4](https://github.com/facebookresearch/demucs/issues/508), that weights were provided for research use. Four stems versus six stems does not resolve this distinction. No public distribution permission for the currently bundled `.th` artifact was established. No change of backend or first-run download workaround has been made.
