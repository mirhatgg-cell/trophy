# Object hierarchy, control and integration

Open `Mountainverse.rbxlx` as a place, not as a model inserted into an unrelated running place. Everything below except uploaded music IDs is serialized by `tools/build_place.py`.

```text
Workspace
├── WorldMap
│   ├── ValleyLandforms               collision bedrock + central escarpment
│   ├── Lobby [Persistent]
│   │   ├── Meridian Tower / Lift     cabin, upper/lower calls, rails, motor
│   │   ├── Navigation Hall           framed west hall
│   │   ├── TrialGate1 … TrialGate50   physical travel prompts
│   │   ├── Museum Exchange           east visitor directories
│   │   ├── Curator Market / ShopCounter
│   │   ├── Assembly Bay 1 … 4 / Queue1 … Queue4
│   │   ├── AdminConsole              owner / Studio inspection access
│   │   └── Service corridor
│   ├── Mountain01_tetris … Mountain50_finale
│   ├── Horizon01 … Horizon50         persistent, noncolliding distance proxies
│   └── PublicArchive                 empty museum for edit-mode inspection
└── MountainverseRuntime              created by server
    ├── Matches / Match_N_Round_N     underground private interior + active mechanisms
    └── Museum_USERID [Atomic]        cloned full museum + Figures
ReplicatedStorage
├── TrophyEvent                      shared, rate-limited RemoteEvent
├── Catalog                          all fifty contracts + progression
├── TrophyIcons                      fifty miniature architectural trophy builders
├── Trials                           setup, step, control, attack, qualification, cleanup
├── Elimination                      contact-derived procedural rig poses
└── Infrastructure                   callable lift movement and rider transport
ServerStorage
└── MuseumTemplate [Atomic]          anchored primary part at local origin
ServerScriptService
└── TrophyServer                     world bindings, profiles, match coordinator
StarterPlayer / StarterPlayerScripts
└── TrophyClient                     HUD, menu toggle, controls, sound, proxy visibility
Lighting                             afternoon daylight + local work lamps
```

## Startup and persistence

DataStore acquisition is protected independently of per-player load. A failed acquisition, including an unpublished place, creates a usable temporary profile; it does not stop world bindings. If acquisition succeeds but a player load fails, that profile is temporary and cannot overwrite the previous persistent record. Profile synchronization retries from the client; after a bounded wait, the HUD displays a useful server failure message. `Workspace.MountainverseServerReady` is set only at the end of initialization.

`Mountainverse_v1` stores nonnegative currency/wins/runs, per-ID trophy wins and mutation, owned/equipped cosmetics, achievements and titles. It does not include Roblox secrets. Saves run every 60s, on leave and in a bounded close callback. Session ownership locks and cross-server conflict handling are not implemented; use a separate test experience before production.

## Match state transitions

```text
assembly → validate capacity → prepare characters → build interior
→ store spawn destinations → 3s preparation → running
→ resolve contact animations → qualify winners → award → return
→ 4s interval → next trial (five rounds) → finish
```

Private interiors are aligned beneath their mountain coordinates, starting at Y=-300; reusable 220-Stud depth slots isolate simultaneous groups instead of leaving unrelated floating arenas above the valley. The workspace fall limit is -10000, below the supported instance range.

A character callback during preparation returns the player to their stored trial spawn instead of displacing them back to the lobby. A respawn during running marks that player eliminated. Cancelling an inspection run does not increment completed runs. A completed team balance/escape rewards all surviving qualified teammates. Ordinary ties use a random choice among equal eligible top scorers.

## Input / server boundaries

- Travel, market, queues, museum visits, machinery buttons and lift calls are real ProximityPrompts; the server independently checks distance before invoking callbacks.
- `join`, `leave`, `configure`, `start` never grant a client ownership of another party. Friends/invitation modes are checked server-side.
- `control` requires the actual curator, a running trial and proximity to that trial’s physical console. Next-shape selection changes the next piece, never an already locked block.
- `attack` requires the duel, an active player, facing and distance, and a 0.7s recovery. The Tool is removed at cleanup.
- `buy` checks item identity, ownership and currency once. Equipping never grants unowned items.
- `admin` checks Studio status, owner UserId or the explicit whitelist on the server. `PublicTestAdmin=false` remains the shipped default.
- Remote calls are throttled per action; physical stations have their own recovery. This is not a claim of a complete adversarial anti-cheat system.

## Collision and animation boundaries

Moving hazards are anchored, server-positioned bodies. Active damage volumes use each body’s local frame, making orientation and character position relevant. Falling and moving mechanisms warn before their active interval. The compression system plays contact-oriented motor poses, keeps the camera responsive, then records elimination. Rigs do not disappear instantly or flatten into replacement objects. A full Studio pass must verify motor names, rig scaling, collision network behavior and the final pose on both R6 and R15.

## Rebuild and inspection

After any source or geometry edit:

```sh
python3 tools/build_place.py
python3 tools/document_project.py
python3 tools/check.py --luau /path/to/luau --compiler /path/to/luau-compile
```

The checker compares the embedded source text with the actual source files, validates unique XML references and parses all seven scripts. Its API-double lifecycle runs include unpublished-place startup, real row removal, lift calls/rider displacement, preparation callback regression, server access control and all fifty trial branches. **It cannot establish rendering, audio asset authorization, live service readiness or real Roblox physics.**
