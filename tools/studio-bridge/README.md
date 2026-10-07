# Studio → local reference snapshots

This bridge reads the 11 `UserOwned` roots only. It never sets Studio properties, runs incoming code, or sends local changes to Studio. It is separate from Rojo's forward sync. The receiver listens on loopback port 34873 and requires the random token embedded in the local plugin. Do not publish or share the generated plugin or local pairing config.

Build: `node tools/studio-bridge/build.mjs`

Install once: In Studio open the Plugins Folder, copy `dist/WarrrStudioBridge.rbxmx` there, and restart Studio. This is a local Studio plugin; do not insert it into the game. If Studio asks, allow this plugin to communicate with `127.0.0.1:34873`.

Start receiver: VS Code → Terminal → Run Task → `Studio: Start snapshot receiver`. If Node is not on PATH, run `receiver.mjs` using your Node executable's full path. Keep the terminal open.

Use: Stop Play → edit your UserOwned content → click `내 작업 업데이트` in the `Warrr Studio Bridge` toolbar. Check Studio Output for success or failure. Each click creates a NEW directory in `studio-snapshots` containing `snapshot.json` and `tree.txt`; old snapshots are not overwritten. No AI request is needed for a snapshot.

Captured: instance tree, class/name, attributes, tags, selected common properties, readable script editor source. Complex property types may be represented as display text; Instance references are informational paths, not stable IDs. Missing folders and unreadable scripts are reported as warnings. Limit: 20,000 instances, depth 100, JSON size 10 MB.

This is NOT a complete backup or a restorable Rojo model. Terrain voxels, CSG data, asset binaries and properties outside the allowlist are not captured. Continue saving your Studio place. Rojo cannot display these snapshots as live mapped objects; Codex can read them for context.

Local tests: `node --test tools/studio-bridge/receiver.test.mjs`. Studio UI/HTTP permissions require one real click to verify after installation.
