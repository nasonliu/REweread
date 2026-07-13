# Compatibility matrix

REweread 1.0.0-rc.1 is validated only on the following baseline.

| Component | Tested baseline | Status |
| --- | --- | --- |
| Device | reMarkable Paper Pro Move (`chiappa`) | Supported baseline |
| CPU architecture | `aarch64` | Required |
| Display | 954 x 1696 RGB565 color e-paper | Required by current UI |
| Device OS | 5.7.126, image 3.27.3.0 | Tested |
| Official SDK | chiappa 5.7.119 | Build baseline |
| Qt | 6.8.2 from device/SDK | Tested |
| XOVI | v19-23052026 | Tested |
| AppLoad | v0.5.3 | Tested |
| KOReader | v2025.10 | LuaJIT runtime tested |
| weread.koplugin | metadata v0.2.0 | User-installed dependency; redistribution blocked |

Other reMarkable models, resolutions and operating-system versions are unsupported until separately validated. A system update may replace the Xochitl drop-in or break XOVI/AppLoad compatibility; reinstall only after checking the new version.

## 1.0.0-rc.1 device evidence

- Application launch and return to stock Xochitl.
- QR login and existing-session reuse.
- Shelf, detail, body-text reading, settings, images, comments and stylus input.
- Wi-Fi disconnect/reconnect around suspend.
- Power-button deep suspend and wake.
- Magnetic-folio event detection and wake routing.

Clean-device install/uninstall and long-duration battery measurements remain release-candidate work. This is one reason the release is not marked stable.
