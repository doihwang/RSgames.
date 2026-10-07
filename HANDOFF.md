# RSgames handoff

## User workflow
- Communicate in Korean. Teach one concrete step at a time; user is new to VS Code/Rojo setup.
- Goal: quickly build a polished Roblox game through prompts with minimal manual tool use and efficient token usage.
- User chose to continue in the Codex VS Code extension with this same RSgames folder.
- Read AGENTS.md first. UserOwned content is user-controlled; do not change it or forward-sync it.

## Game
- Prototype: 와르르! survival arena. Stepped-on tiles collapse after 1.65 seconds. Jump during the final 0.65 seconds to charge the next landing, which collapses neighboring cracked tiles.
- Solo 60-second survival and multiplayer last survivor; automatic rounds. Monetization planned around cosmetics, but not implemented.
- Sources: prototype/Server.server.luau and prototype/Client.client.luau.
- Removed runtime write to restricted Workspace.FallenPartsDestroyHeight after a Studio error. Do not reintroduce it.
- Gameplay has not been fully playtested. Do not claim it is verified.

## Rojo and Studio
- Rojo 7.7.1 installed through Aftman. VS Code extensions evaera.vscode-rojo and muoshuu.rojo-ui installed.
- default.project.json forward-syncs only ServerScriptService/WarrrServer and StarterPlayer/StarterPlayerScripts/WarrrClient. Preserve unknown instances.
- User confirmed Studio connection and creation of UserOwned folders in 11 containers.
- User wanted cloud saving and received initial Publish/Team Create instructions; actual cloud publishing and autosave state have NOT been independently verified. Place ID is unknown.
- Preserve the user's Studio place. Generated prototype/Warrr.rbxlx excludes Studio-only content and must not replace it.

## One-button Studio export
- Local plugin tools/studio-bridge/dist/WarrrStudioBridge.rbxmx was built. User installed it and confirmed that the 내 작업 업데이트 button appears in Studio.
- Plugin only reads UserOwned trees and sends selected properties, attributes, tags and script source to a loopback receiver on port 34873.
- Receiver: tools/studio-bridge/receiver.mjs. Start via VS Code task Studio: Start snapshot receiver. Check for an existing receiver before starting another.
- Pairing secret lives in .studio-bridge-local.json and generated plugin. Never print, publish, or share it.
- New reference snapshots go into studio-snapshots/<unique-id>/snapshot.json and tree.txt. Existing snapshots are immutable by project policy. NOT a complete/restorable model backup, and NOT Rojo two-way sync.
- Receiver tests passed; ownership guard and plugin XML checks passed. Actual Studio button-to-receiver transfer remains UNVERIFIED. This is the next small functional check after VS Code setup.
- Ask user to Stop Play, click the button, allow localhost plugin HTTP permission if prompted, then inspect local snapshots and Studio Output. Do not assume success until verified.
- Standalone file-based backup import is tools/Import-StudioSnapshot.ps1; this is optional, not the user's preferred everyday workflow.

## Useful checks
- ./tools/Check-Ownership.ps1
- node --test tools/studio-bridge/receiver.test.mjs
- Do not run AI agents simultaneously modifying the same files in the desktop app and VS Code.
