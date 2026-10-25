# Minibancho pet assets

The 2026-10-26 revision uses frames from the official BANCHO green-screen video for idle, thinking, movement, and jumping. Other animation states retain the earlier artwork.
The binary assets are stored in the personal Google Drive; this repository keeps their locations and restoration information.

## Files

[Revision folder: minibancho-2026-10-26](https://drive.google.com/drive/folders/1bGp_DxzO5GUvo9bCwbcp_305w1Ht-8wZ) requires access to the personal Drive.

| File | Purpose |
| --- | --- |
| [minibancho-spritesheet-v2.png](https://drive.google.com/file/d/1YSAHhNgYYUbLYBg_01rWuvqfNioe1_nN/view) | Final transparent 1536 × 2288 sprite sheet |
| [pet.json](https://drive.google.com/file/d/1AmzwJpnoJJwGK-7FlGRy8PJEbHFBIOfB/view) | Local pet metadata; expects the image filename `spritesheet.png` |
| [minibancho-restore.zip](https://drive.google.com/file/d/1GVGlDEuEsC1dMNPIZSqoUbzHzdWb-TCD/view) | Final image and metadata in a `minibancho/` directory |
| [minibancho-preview.gif](https://drive.google.com/file/d/19YMzrRxHK1v8FRaUyM0VJ9sTSsaTcJ6P/view) | Idle, thinking, movement, and jumping from the final sheet |
| [BANCHO-GB.mp4](https://drive.google.com/file/d/1BwRj3d02r3IHUuoR-e7E4Mt1BznMu-KR/view) | Original green-screen material |
| [source.json](https://drive.google.com/file/d/1WlxRSLtUFYf35K9Cvj6rUtA4ny6CP9pj/view) | Source URLs and original video checksum |
| [SHA256SUMS](https://drive.google.com/file/d/1NR5zpXk7fqv-5jJyp2DG8Eic-YZODdHz/view) | Checksums of the six files above |

The [previous sprite sheet](https://drive.google.com/file/d/11pqOkO-MiWpWE_qFdGbWT_9IDXyxJEI6/view) remains available separately.

Final sprite-sheet SHA-256:

```text
580d6bb004fb92578096a42aa15bbaac5aee4ded4f605bc1afb186e930cbebff
```

## Restore or update

For the local pet, download and extract `minibancho-restore.zip`. Back up any existing `~/.codex/pets/minibancho/` directory, then place the extracted `minibancho/` directory under `~/.codex/pets/`.
The local selection is `custom:minibancho`, as specified in [codex-config.toml](codex-config.toml).

The registered pet named `みにばんちょー` is a separate copy. To update it, use Pets to replace its sprite sheet with the final PNG while preserving the existing pet ID. Changing only the local files does not update that registered copy.
Both copies were updated to this revision, and the registered image was downloaded again and checked for pixel equality with the final sheet.

## Source

- [Official BANCHO GB video](https://www.youtube.com/shorts/P7MURQLzIsY)
- [Creator's material announcement](https://x.com/todoroki_hajime/status/1833174886581412249)

The creator labels the green-screen material as free material in the announcement and the video's description.
