# Studio ownership boundaries

- The user owns every Studio instance named `UserOwned` and all its descendants. Never edit, delete, move, rename, reparent, or map these instances into forward Rojo sync without the user's explicit request for that specific change.
- `studio-snapshots/` contains user-authored Studio snapshots. Read for context only; never modify existing snapshots or map them into a live-sync project. A user-requested import may create a NEW snapshot.
- Keep `$ignoreUnknownInstances: true` on the DataModel and all mapped service/container ancestors. Do not map whole services to filesystem directories.
- Current forward-sync allowlist is exactly ServerScriptService/WarrrServer and StarterPlayer/StarterPlayerScripts/WarrrClient. Expansion requires explaining and agreeing on ownership with the user first.
- Game code must not search for and mutate UserOwned descendants or clear/destroy their ancestors. Runtime cleanup must target objects created and owned by that runtime only. Read-only references do not authorize edits.
- Studio is the source of truth for UserOwned. Do not replace the user's edited place with a generated rbxlx; generated places omit Studio-only content. Save/publish the Studio place to preserve user content.
- Run tools/Check-Ownership.ps1 before serving/building after project mapping changes. This guard is a project workflow check, not an OS or Roblox security boundary.
