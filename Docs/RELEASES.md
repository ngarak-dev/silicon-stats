# Releases & CI

## Public repository

Publish this project as a **public GitHub** repo (recommended name: `silicon-stats`), then push `main`.

GitHub Actions needs macOS runners for Xcode — Origin-only remotes do not build DMGs.

## Tag → DMG

Workflow: [`.github/workflows/release-dmg.yml`](../.github/workflows/release-dmg.yml)

```bash
# After the public repo exists and Actions are enabled:
git tag v1.0.0
git push origin v1.0.0
```

That job:

1. Runs on `macos-14`
2. Builds Release via `scripts/build-dmg.sh`
3. Uploads `SiliconStats-1.0.0.dmg` as a workflow artifact
4. Creates/updates a GitHub Release for the tag and attaches the DMG

Manual run: Actions → **Release DMG** → **Run workflow** (optional version input).

## Local DMG (on a Mac)

```bash
./scripts/build-dmg.sh
# → dist/SiliconStats-<version>.dmg
VERSION=1.2.3 ./scripts/build-dmg.sh
```

## Signing / notarization

Default CI builds are **ad-hoc / unsigned for Gatekeeper**. Users may need to right-click → Open on first launch.

For Developer ID + notarization, add Apple signing secrets to the repo and extend `release-dmg.yml` to set `DEVELOPMENT_TEAM` / import the certificate before `build-dmg.sh`. See `ci/ExportOptions.plist` for archive export options.

## PR / push CI

[`.github/workflows/ci.yml`](../.github/workflows/ci.yml) builds and runs unit tests on `macos-14` for pushes/PRs to `main`.
