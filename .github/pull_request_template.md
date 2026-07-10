## Summary

Describe the user-visible or agent-visible change.

## Validation

- [ ] `node scripts/check-repository.mjs`
- [ ] `node tests/run-all.mjs`
- [ ] Shell syntax checks
- [ ] Clean SDK build, when build/runtime code changed
- [ ] Real-device validation, when display/input/power/network behavior changed

## Data safety

- [ ] No API Key, Cookie, token, password, private key or QR UID
- [ ] No shelf, title, cover, EPUB, progress, comment, annotation or user log
- [ ] No SDK, font, archive, build output or third-party checkout
- [ ] Upgrade does not delete `/home/root/.local/share/rm-weread/`

## Device impact

State whether this changes Xochitl, XOVI/AppLoad, root filesystem files, sleep/wake or user data.
