# 와르르! — 첫 손맛 프로토타입

## Rojo로 작업하기

### 사용자 전용 영역

각 서비스의 `UserOwned` 폴더는 Studio에서 사용자가 관리하며 forward Rojo 설정에 포함하지 않습니다. `tools/Create-UserOwned.studio.luau`를 Studio 편집 모드의 Command Bar에서 한 번 실행하면 폴더들을 만듭니다. 기존 내용은 변경하지 않습니다. 생성 후 Studio 장소를 저장하세요. 이는 동기화 제외이며 다른 플러그인/스크립트를 차단하는 보안 권한은 아닙니다.

기존 `WarrrServer`, `WarrrClient`는 외부 코드 영역입니다. `UserOwned`로 옮기지 마세요. 서비스 바로 아래에 있어야 작동하는 오브젝트도 있으므로 모든 항목을 무조건 Folder 안으로 옮기지는 마세요. 특히 StarterPack의 Tool 지급, GUI/LocalScript 실행은 실제 플레이로 확인해야 합니다.

Studio 작업을 로컬에 가져오려면 먼저 Stop 후 전체 장소를 별도 `.rbxl` 또는 `.rbxlx`로 저장하고, RSgames 터미널에서 `./tools/Import-StudioSnapshot.ps1 -InputPlace '저장한 장소의 전체 경로.rbxl'`을 실행합니다. 새 `studio-snapshots` 폴더에 원본 백업과 Rojo syncback 결과를 보관하며, live-sync 코드에는 반영하지 않습니다. 가져오기는 명시적으로 실행할 때만 수행하며 실시간 양방향 동기화는 아닙니다. 사본을 다시 Studio로 보내는 서버는 실행하지 마세요.

사용자 작업을 보존하려면 Studio에서 작업한 장소를 저장/게시하세요. 아래 `build.ps1`로 만든 장소에는 Studio에서 추가한 내용이 없으므로 사용자 장소를 대체하지 마세요.

VS Code에서 상위 `RSgames` 폴더를 엽니다. 루트의 `default.project.json`이 서버 코드와 클라이언트 코드를 각각 `ServerScriptService/WarrrServer`, `StarterPlayer/StarterPlayerScripts/WarrrClient`로 연결합니다. Rojo가 관리하지 않는 기존 오브젝트는 유지합니다.

VS Code의 `Rojo: Open Menu`에서 프로젝트 서버를 시작한 다음, Studio에서 이 프로토타입을 열고 Rojo 플러그인으로 `localhost:34872`에 연결합니다. 연결 시 변경 목록을 확인합니다. Rojo UI는 연결된 프로젝트 구조를 확인하는 보조 확장입니다.

코드 저장 → Studio 동기화 → Stop 후 Play로 다시 테스트합니다. 동기화는 실행 중 코드의 안전한 재시작이나 Roblox 게시를 대신하지 않습니다. 게시가 필요한 시점에 Studio에서 별도로 게시합니다. Rojo 연결 중에는 아래 장소 파일 재생성 작업을 매번 할 필요가 없습니다.

## 파일로 직접 열기

`Warrr.rbxlx`를 Roblox Studio에서 열고 **Play / F5**를 누르세요. 코드 붙여넣기나 플러그인 설치는 필요 없습니다. 편집 화면에는 맵이 없으며 실행하면 생성됩니다.

- WASD 이동, Space 점프. 모바일은 Roblox 기본 이동/점프 버튼.
- 밟은 발판은 1.65초 뒤 붕괴합니다.
- 마지막 0.65초 동안 빨갛게 깜빡입니다. 이때 점프하면 충격이 충전됩니다.
- 충전 후 착지는 주변 8칸 중 이미 금이 간 발판을 즉시 무너뜨립니다. 착지한 발판은 정상 경고 시간을 줍니다.
- 8초부터 다른 발판도 무너지기 시작합니다. 혼자는 60초 생존, 여럿은 최후 생존자가 목표입니다.
- 탈락 후 라운드 종료 시 자동 재시작. 진행 중 입장자는 다음 라운드에 참가합니다.

먼저 확인할 것: 빨간 경고를 보고 점프할 시간이 충분한지, 충전과 강한 착지가 분명한지, 이동이 답답하지 않은지.

상점/저장/유료 상품은 없는 손맛 실험입니다. Studio 실플레이 검증 전이며, 포함된 기본 효과음은 Studio 환경에서 재생 여부를 확인해야 합니다.

소스 수정 후 PowerShell에서 `./build.ps1`을 실행하면 장소 파일을 다시 생성합니다. 핵심 조정값은 서버 코드의 LIFE(붕괴 시간), WalkSpeed(이동), JumpPower(점프), remaining <= 0.65(충전 판정)입니다.
