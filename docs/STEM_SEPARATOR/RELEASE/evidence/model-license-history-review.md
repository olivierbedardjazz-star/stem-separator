# HTDemucs historical licence review

Reviewed 2026-09-06. Research findings, not a legal opinion or a completed distribution clearance. No model, application code, or publication state changed.

## Findings

Demucs code has an [MIT licence](https://github.com/facebookresearch/demucs/blob/main/LICENSE). MIT permits commercial distribution subject to its notice condition. Code licensing alone does not resolve the trained weights.

The author's [2022 statement](https://github.com/facebookresearch/demucs/issues/327#issuecomment-1134828611) separates weights from the code licence and limits their stated purpose to scientific work. A [2023 answer specifically concerning htdemucs v4](https://github.com/facebookresearch/demucs/issues/508#issuecomment-1663033356) says the weights are provided for research. Both comments were rechecked through the GitHub API.

There is significant contrary evidence: on July 11, 2026, adefossez uploaded HTDemucs weights to Hugging Face with `license: mit` in the model card. The [historical raw card](https://huggingface.co/adefossez/HTDemucs/raw/bf35a81b663819a8255c8fefee17f9d812b786b5/README.md) explicitly describes pretrained weights and signature 955717e8. This is an author-hosted declaration, not merely a third-party mirror label. [Hugging Face documentation](https://huggingface.co/docs/hub/repositories-licenses) expressly permits specifying licences through card metadata; the absence of a separate LICENSE file alone does not invalidate this evidence.

On August 2 a user [asked whether the MIT label was intentional](https://huggingface.co/adefossez/HTDemucs/discussions/1), identifying the conflicting earlier statements. No maintainer response appeared in the discussion API at review time. On August 31, the author [removed the MIT metadata](https://huggingface.co/adefossez/HTDemucs/commit/cbc8a9b1a87023b7fd74e7b3412e6321c0eab003). The commit does not explain the legal effect or whether the original label was a mistake. Neither mistake nor valid relicensing is established by this sequence alone.

## Earlier copies and continued redistribution

A valid open-source grant is ordinarily understood to preserve compliant recipients' rights despite a later upstream licence change. MIT includes distribution and sublicensing permissions, so the principle is not limited to privately keeping an old downloaded copy. A properly licensed earlier version can ordinarily continue downstream under its original terms. [MIT text](https://opensource.org/license/MIT); [FSF definition](https://www.gnu.org/philosophy/free-sw.en.html).

Do not turn that general principle into an unconditional legal conclusion: MIT does not expressly use the word irrevocable, applicable law and grant validity matter, and an unauthorized label cannot grant rights its publisher did not hold. [Research on modification and revocation](https://arxiv.org/abs/2407.13064) describes irrevocability as the traditional approach, while proposing a departure; it is not a court ruling on this model.

Consequently, removing the metadata does not prove earlier rights were revoked. The historical label is meaningful evidence supporting a possible continuing MIT grant. Whether that grant was authorized and covers the exact artifact to be shipped remains unresolved. Merely downloading before a particular date, or downloading an old revision now, does not independently settle those questions.

## Exact artifacts

Our runtime/provenance.json records a download from Meta's server of `955717e8-8726e21a.th`, SHA-256 `8726e21a993978c7ba086d3872e7608d7d5bfca646ca4aca459ffda844faa8b4`. It does not document acquisition under the July Hugging Face MIT declaration.

The July Hugging Face tree instead contains `955717e8.safetensors`, 84,025,440 bytes, LFS SHA-256 `d9fa14133cfcc034a6758923bb3a8ca9f8dfd0b582134643bbf83f72c17576dd`. Historical revision: `bf35a81b663819a8255c8fefee17f9d812b786b5`. Both identify the same checkpoint signature, but the serialized artifacts differ. Tensor equivalence has not been checked. A format change alone neither grants nor removes redistribution permission.

## Release implication

Current status remains unresolved, not a determination that all use or distribution is unlawful. The strongest route for retaining this model is written clarification from the rights holder that the July grant was authorized and remains usable, or a qualified legal review accepting that historical grant for the chosen artifact. No inquiry has been sent. Do not claim the historical MIT evidence is meaningless, that permission was definitely revoked, or that an alternative model is already authorized or selected.
