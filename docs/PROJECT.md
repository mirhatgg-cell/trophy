# MOUNTAINVERSE — construction and implementation ledger

This document separates measured, generated objects from gameplay implemented in Luau and from requirements still outstanding. It is not a claim of a finished, Studio-tested release. All dimensions are Studs.

## Common construction system

`tools/architecture.py` creates the permanent map directly in XML. `src/Trials.lua` creates private trial interiors when a match starts; these are separate underground instances aligned with the mountain coordinates, not modifications of the public sightseeing structures. Reusable depth slots separate simultaneous teams. `src/Infrastructure.lua` binds real lift carriages and call buttons. Foundations, columns, floors, guideways, service galleries, lighting and signage are Parts with collision; glass has thickness and framing. Fine inscriptions, cable markers and light strips are visual details. Moving hazards are server-driven anchored Parts; contact uses their oriented boxes. This is a kinematic mechanism system, not a general rigid-body engineering simulator.

## Central complex

Foundation: 480 W × 12 H × 360 D, footprint 172,800. Open main plaza: 320×240 = 76,800. Meridian tower: 76×56 deck plates at 0/40/80/120/180/240, four 8-Stud structural piers, helical external stair with 480 treads (0.5 rise), roof lantern. Upper open decks add 21,280 of walkable area; these are not enclosed internal floors. Enclosed/roofed halls: two 62×300 navigation halls, market 120×36, service corridor 280×20, four 42×32 assembly bays; covered functional floor area 52,496, overlapping the ground circulation footprint rather than adding new land.

Circulation design target: 32 simultaneous visitors, to be configured in Roblox experience settings. Even 32 people each using a 4×4 personal envelope occupy 512 square Studs; 40% of the main plaza alone reserves 30,720 for circulation. Arrival to northern assembly is roughly 240 Studs (15s at default walking speed). The lift provides a fast observation route; stairs provide an independent route. West: fifty engraved mountain stops. East: visitor directories for personal archives. South: market and arrival. North: four physical assembly halls.

Lobby lift: four guide rails, cabin 12×1×12, upper/lower landings, hoist housing and cable. Both floors have call prompts. Smoothstep motion travels at an average scale of 14 Studs/s; each heartbeat carries standing characters by the cabin displacement. Stairs remain available if the lift is occupied.

## Personal archives

Each player receives a separate cloned architectural Model, not just a display room. Footprint: 360×320 = 115,200. Open courtyard: 200×160 = 32,000. Ground covered gallery floor: 83,200. Upper gallery after real stairwell openings and landings: 77,988. Total usable covered floor area: **161,188**. Floors at 0 and 32, roof at 65. Fifty plinths, twenty-five on each floor. Two 16-wide stair flights have actual slab openings; a two-stop lift gives an alternate route. Opposed galleries flank the pool; a 12-wide bridge crosses the court. Service walls, ducts, cabinets, perimeter columns, framed glazing and exhibit luminaires are generated.

Each of the fifty exhibits has its own procedural architectural icon, scaled progressively with rank. Exhibits use stored victories, 20 material/color ranks and three mutation effects. Mud has particles and small positional animation. Museum directories in the east hall let visitors enter another player’s archive. A separate empty public archive is authored for edit-mode inspection. Live clones are placed on a 440-Stud pitch. Streaming is enabled (minimum radius 256, target 1024); lobby geometry persists, museums stream atomically, and noncolliding far silhouettes remain visible until full geometry is near. Teleports request their destination region. Museum idle animation runs only near visitors. Loading/replication performance still needs measurement in Studio.

## Trial loop and common technical spaces

Party admission → player-count check → private interior construction → 3s preparation → timed trial → 1.2s animation settlement → victory qualification and rewards → 4s return interval. A run contains five nonrepeating choices compatible with the party size. Admin solo inspection bypasses the minimum-player rule. Each private interior includes a reinforced raft unless the hazard needs an open pit, four load-bearing piers, overhead trusses, a service gallery, cable channel, technical annex, cabinet, ventilation trunk and work lights. Each public mountain has a 24×36 technical annex and a connected stair/service approach.

Death is server-authoritative. Lethal contact starts recognition, defensive posture, resistance and loss-of-balance motor poses; only after roughly one second does health become zero and the score update. Freeze changes limb color; consume faces the jaw; impact and compression lean relative to the contact body. Cameras are never locked. These are shared procedural R6/R15 animations with cause-specific poses; there are **not fifty independently authored animation sets**.

## Mountain contracts and current implementations

### 01 — TETRIS: LAST LINE

- **Runtime arena:** 80 W × 132 clear H × 48 D; floor footprint 3,840. Public structural raft: 120×88 = 10,560; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 199 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Four reinforced pylons, overhead traverser and glazed curator tower. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 4–4; **trial limit:** 100s plus preparation; **base win reward:** 62 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Survivors collect line keys; curator locks seven tetromino shapes and clears ten-cell rows.
- **Defeat cause:** Swept block impact and staged compression. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** 10 columns × 6 Studs; block cell 6×6×24; 20 logical rows. Seven canonical tetrominoes rotate in the X/Y plane. Fall at 2.2 rows/s, fast drop 14 rows/s, difficulty scales speed. Locking stores each cell separately. Full rows are removed and every cell above is lowered by the number of cleared rows. One curator at a physical console; three survivor spawn points. Next-shape selection has seven physical buttons. A curator wins only if no survivor qualifies; otherwise survivors compete by survival and line-key points.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 02 — PAC-MAN: THE HUNGER MAZE

- **Runtime arena:** 108 W × 24 clear H × 108 D; floor footprint 11,664. Public structural raft: 148×148 = 21,904; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 175 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Square masonry labyrinth under a perforated service roof. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 100s plus preparation; **base win reward:** 64 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Collect maze pellets and energizers while a graph-routed creature hunts.
- **Defeat cause:** Creature captures the character in its closing jaw. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** 9×9 connected graph, 12 Stud cell spacing, 1×14 walls. Depth-first spanning-tree construction guarantees connectivity. Replanning every 1.2s uses breadth-first paths across open edges. Hunter detection radius 70; outside detection it patrols graph nodes. Its articulated jaw follows its carriage. Collect at least three pellets and remain alive to qualify.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 03 — DUEL: TWO THRONES

- **Runtime arena:** 96 W × 64 clear H × 72 D; floor footprint 6,912. Public structural raft: 136×112 = 15,232; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 144 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Opposed limestone and basalt keeps joined by three combat bridges. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 2–2; **trial limit:** 75s plus preparation; **base win reward:** 66 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Land server-validated sword strikes; collect the exposed central standard.
- **Defeat cause:** Weapon impact or falling from a bridge. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Opposed floors at X=-38/+38; bridges at Y=0/24/48. Server creates an actual metal sword Tool. Attack reach 9, facing-dot threshold 0.15, damage 34, recovery 0.7s. F / screen strike is an additional input route. Server arm poses animate a swing. Surviving competitors are ranked by damage-related score and the central standard.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 04 — CHESS: KING’S EXECUTION

- **Runtime arena:** 80 W × 40 clear H × 80 D; floor footprint 6,400. Public structural raft: 120×120 = 14,400; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 221 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Eight-by-eight marble board inside a vaulted chess basilica. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 68 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Read legal chess moves and collect standards on empty squares.
- **Defeat cause:** Moving chess piece sweeps the occupied square. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** 8×8 board at 10 Stud square spacing; 32 physical pieces. Rook and bishop moves stop at occupied squares; queen combines both, knight jumps, king moves one square, pawn advances or captures diagonally and promotes. Sides alternate. A destination warning precedes a 1.3s animated move; collision during transit causes elimination. This is a chess-hazard survival trial, not a full checkmate/castling chess client.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 05 — SNAKE: THE COILING PIT

- **Runtime arena:** 100 W × 72 clear H × 100 D; floor footprint 10,000. Public structural raft: 140×140 = 19,600; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 226 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Three terraced rings enclosed by a segmented steel serpent. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 70 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Reach successive signal pads while the head routes around the pit.
- **Defeat cause:** Contact with a moving snake segment. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** 18 articulated segment bodies follow sampled head-position history at 5.5 Stud spacing, not independent animation loops. The head chooses legal neighboring nodes on a 32-node spatial route; four junctions offer alternate chords. Route height varies up to 15 Studs and neighboring samples interpolate continuously. Segments are oriented toward the preceding path sample. Raised refuge signals award points; contact starts a pressure death. Collect at least one signal and remain alive.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 06 — THE BROKEN SPAN

- **Runtime arena:** 32 W × 50 clear H × 120 D; floor footprint 3,840. Public structural raft: 72×160 = 11,520; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 143 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Suspension bridge between two cracked abutments. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 72 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Cross to the far extraction pad as deck connections fail behind you.
- **Defeat cause:** A warned deck panel breaks and the player falls. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** 12 deck sections of 26×2×9.7 plus protected abutments. Section i warns/fades after i×4 seconds and loses support 1.4s later. The raft beneath is removed. Every player who reaches the far seal is recorded independently; crossing is mandatory for victory.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 07 — THE LAST ELEVATOR

- **Runtime arena:** 64 W × 112 clear H × 64 D; floor footprint 4,096. Public structural raft: 104×104 = 10,816; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 183 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Four-rail lift shaft with recessed floor landings. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 74 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Ride the lift and exit at the marked landing before the counterweight sweep.
- **Defeat cause:** Falling into the shaft or meeting a counterweight. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** 30×2×30 carriage rides four guide rails; sinusoidal travel reaches Y=72. Standing characters are carried by the platform delta. Upper seal at Y=78 is required for victory; surrounding spiral landings provide alternate routes. The lobby/museum lift is a separate callable infrastructure system.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 08 — ROTUNDA OF LOST NORTH

- **Runtime arena:** 100 W × 32 clear H × 100 D; floor footprint 10,000. Public structural raft: 140×140 = 19,600; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 164 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Three concentric rotating masonry drums. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 76 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Align radial doors and collect seals in the outer ring.
- **Defeat cause:** Contact with the closing radial gates. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Three drum radii: 14/28/42. Each has ten wall sectors, leaving radial openings. Adjacent rings rotate in opposite directions at 0.14 rad/s. Rotated-box overlap detects pressure damage. The outer seal is required to qualify.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 09 — THE SILENT ORCHESTRA

- **Runtime arena:** 96 W × 36 clear H × 72 D; floor footprint 6,912. Public structural raft: 136×112 = 15,232; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 155 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Acoustic amphitheatre with organ pipes and suspended resonators. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 78 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Stand on the indicated numbered acoustic pad on each beat.
- **Defeat cause:** Being on an unpowered tile when a resonator fires. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** 6×6 numbered pads. Every 3.5s one safe pad is selected; the final 1.3s discharges all other occupied pads. Damage is time-integrated at 90 health/s, rather than a disconnected touch-kill. Organ pipes provide a physical silhouette; audible numbered musical cues require imported score IDs.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 10 — THE GLACIAL ARCHIVE

- **Runtime arena:** 88 W × 42 clear H × 88 D; floor footprint 7,744. Public structural raft: 128×128 = 16,384; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 148 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Translucent ice vault with ribbed rock buttresses. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 80 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Alternate between heat braziers and frozen archive terminals.
- **Defeat cause:** Cold exposure reaches its limit; freezing animation. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Ice partitions and four heat stations. Per-player heat starts at 15s, drains away from warmth, regenerates at 4/s within 12 Studs of a station. Zero heat starts freezing choreography. Ice material is used physically; this implementation does not yet include a separate friction/temperature body simulation.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 11 — CALDERA OF ASH

- **Runtime arena:** 100 W × 52 clear H × 100 D; floor footprint 10,000. Public structural raft: 140×140 = 19,600; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 163 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Basalt caldera with three raised eruption vents. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 82 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Collect obsidian seals as vents erupt in a visible sequence.
- **Defeat cause:** Lava vent impact or contact with the rising rim of lava. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Three visible vent boxes around a 25-Stud radius. One active vent per 5s phase; the first 2s warn, the remaining phase raises its harmful plume to 28 Studs. Contact burns. Obsidian seals are ordinary server-validated collectible objectives.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 12 — DOMINO CATHEDRAL

- **Runtime arena:** 96 W × 48 clear H × 96 D; floor footprint 9,216. Public structural raft: 136×136 = 18,496; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 154 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Two stone galleries flanking a monumental domino procession. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 84 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Navigate between falling domino chains to collect the final seal.
- **Defeat cause:** Swept falling domino face. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** 16 separate 10×24×2 slabs. Slab i begins rotation at i×2s; rotation is computed around its lower hinge over 1.8s. The moving oriented face can crush characters. The final collection seal is placed beyond the chain.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 13 — THE REMEMBERING ROOM

- **Runtime arena:** 80 W × 28 clear H × 80 D; floor footprint 6,400. Public structural raft: 120×120 = 14,400; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 148 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Dark slate memory chamber with an illuminated coffer ceiling. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 86 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Memorize safe cells before the projection turns off.
- **Defeat cause:** Standing on an unsupported cell during the reveal. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** 36 cells. Safe cells are illuminated; after 1.5s illumination is removed, and the final 1.3s of a 6s cycle discharges unsafe occupied cells. At least one safe cell is guaranteed. Memory differs from rhythm by multiple safe cells and a hidden projection phase.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 14 — TOWER OF DUST

- **Runtime arena:** 72 W × 100 clear H × 72 D; floor footprint 5,184. Public structural raft: 112×112 = 12,544; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 208 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Four-storey concrete tower with a visible demolition spine. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 88 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Climb the linked stairs while lower floors are removed in order.
- **Defeat cause:** Collapse of the occupied level. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Connected spiral landings climb to roughly 71 Studs. Main floors at Y=0/22/44/66 are removed in sequence every 16s. Upper seal at Y=75 is required; waiting on the ground cannot win. Structural removal is scripted, not a whole-building unanchored collapse simulation.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 15 — GYROSCOPE COURT

- **Runtime arena:** 100 W × 36 clear H × 100 D; floor footprint 10,000. Public structural raft: 140×140 = 19,600; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 141 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Circular metal court inside a three-axis bearing frame. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 90 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Cross the rotating arms and collect gyroscope keys.
- **Defeat cause:** Arm impact or falling outside the bearing ring. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Two long driven arms rotate at 0.35 rad/s around a visible drive shaft. Arm contact deals time-integrated pressure damage. Jumping avoids the low rotating sweep. Collecting exposed keys improves ranking.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 16 — THE CARTOGRAPHER’S LIE

- **Runtime arena:** 108 W × 28 clear H × 108 D; floor footprint 11,664. Public structural raft: 148×148 = 21,904; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 180 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Orthogonal maze with a raised switch gallery. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 92 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Curator reroutes marked gates; survivors gather three map fragments.
- **Defeat cause:** Gate compression or routed hunter capture. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Uses the connected graph engine but adds eight curator-operated shortcut gates. Opening disables wall collision and adds graph edges; closing restores collision and removes those edges. Base spanning-tree routes remain connected. The hunter replans after a switch and never routes through a closed gate.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 17 — MIDNIGHT ESCAPEMENT

- **Runtime arena:** 100 W × 60 clear H × 100 D; floor footprint 10,000. Public structural raft: 140×140 = 19,600; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 175 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Open clock face held by a giant visible escapement frame. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 94 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Reach the bell refuge when minute and hour hands align.
- **Defeat cause:** Swept minute hand or exposed gear tooth. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Minute arm speed 0.2 rad/s; hour arm speed one twelfth of minute speed. Arm lengths differ. A bell-refuge exit seal is enabled only after 70% of the round. Reaching it and remaining alive is required for victory.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 18 — THE PENDULUM HALL

- **Runtime arena:** 96 W × 72 clear H × 96 D; floor footprint 9,216. Public structural raft: 136×136 = 18,496; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 173 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Six-bay hall with overhead pivots and pendulum suspension rods. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 96 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Cross beneath alternating pendulums and touch the finish seal.
- **Defeat cause:** Pendulum bob impact. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Five independently phased bobs. Pivots at Y=48, suspension length 42; angle sin(0.8t+phase)×0.9. Rod position and rotation are derived from the same pendulum angle. Swept bob contact triggers an impact death.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 19 — THE WEIGHING HOUSE

- **Runtime arena:** 100 W × 40 clear H × 72 D; floor footprint 7,200. Public structural raft: 140×112 = 15,680; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 132 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Twin scale platforms hung from an overhead weighing beam. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 2–4; **trial limit:** 75s plus preparation; **base win reward:** 98 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Balance team occupancy on left and right pans to unlock the seal.
- **Defeat cause:** Overloaded pan descends into the catch pit. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Two pans at X=-24/+24. Team occupancy determines vertical pan offsets, 3 Studs per player imbalance. Equal nonzero load held for eight seconds completes the trial. All qualified surviving teammates receive trophies, not one random teammate.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 20 — THE FOURTH AIRLOCK

- **Runtime arena:** 100 W × 32 clear H × 88 D; floor footprint 8,800. Public structural raft: 140×128 = 17,920; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 127 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Linked pressure chambers and a central pump room. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 4–4; **trial limit:** 100s plus preparation; **base win reward:** 100 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Activate separated valves together, then use the unlocked airlock.
- **Defeat cause:** Pressure closes a chamber before the team opens its relief valve. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Four stations around a 32-Stud radius. Valve activations must overlap within a 12s window and come from min(4, participant count) distinct players. Each station has server proximity and 3s activation recovery. Team completion rewards every qualified survivor.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 21 — THE NARROWING HALL

- **Runtime arena:** 100 W × 32 clear H × 80 D; floor footprint 8,000. Public structural raft: 140×120 = 16,800; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 127 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Hydraulic compression hall with cylinder housings and piston rails. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 102 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Read wall openings and move through them as pistons advance.
- **Defeat cause:** Swept wall compression. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Four rail-driven wall panels oscillate laterally at 0.35 rad/s with phase offsets. Hydraulic drive housings and floor rails mark their paths. Oriented overlap deals compression damage. No damage is emitted outside the moving panels.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 22 — PINBALL: HUMAN SCORE

- **Runtime arena:** 100 W × 40 clear H × 120 D; floor footprint 12,000. Public structural raft: 140×160 = 22,400; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 133 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Inclined industrial pinball table with bumpers and spring launcher. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 104 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Collect scoring switches while avoiding the launched steel ball.
- **Defeat cause:** Ball impact or draining through the lower gate. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** 7-Stud steel sphere with a 2D velocity state. It reflects at table bounds and rebounds radially from five bumpers. Player collision causes staged impact death. This deterministic kinematic table does not use Roblox unanchored ball physics.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 23 — THE SHIFTING HOTEL

- **Runtime arena:** 108 W × 40 clear H × 108 D; floor footprint 11,664. Public structural raft: 148×148 = 21,904; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 146 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Nine freight-mounted rooms in a square transfer frame. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 106 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Find the marked room as room identities change with each transfer.
- **Defeat cause:** Failure to reach the room with the powered floor. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Nine 30-Stud freight-room floors, with three wall partitions each. Rooms move on parallel rails in alternating directions each 7s cycle, carrying standing players and their partitions. The indicated room is safe during discharge; the final safe room is mandatory for qualification.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 24 — INVERTED OBSERVATORY

- **Runtime arena:** 96 W × 64 clear H × 96 D; floor footprint 9,216. Public structural raft: 136×136 = 18,496; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 163 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Opposed floor and ceiling observatory rings with magnetic pylons. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 108 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Use marked jump windows during periodic upward magnetic pulses.
- **Defeat cause:** Missing a landing or entering a charged ceiling grid. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** An explicitly magnetic trial, not a global Workspace.Gravity change. Every 12s, an 8–10s upward pulse adds vertical velocity; players must land on raised platforms and avoid the energized ceiling grid. Global gravity remains 196.2 for other simultaneous matches.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 25 — THE COUNTERWEIGHT CROSSING

- **Runtime arena:** 48 W × 54 clear H × 120 D; floor footprint 5,760. Public structural raft: 88×160 = 14,080; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 151 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Two bascule leaves with axle piers, chains and counterweight wells. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 110 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Cross during bridge alignment; wait on the protected hinge islands.
- **Defeat cause:** Falling between rotating bridge leaves. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Twelve deck sections form two bascule leaves. Height and pitch derive from the same sinusoidal opening angle; passengers are carried by position delta. The far extraction seal is required. Runtime uses anchored leaf motion rather than constraint-driven counterweights.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 26 — THE SENTENCE ENGINE

- **Runtime arena:** 96 W × 56 clear H × 80 D; floor footprint 7,680. Public structural raft: 136×120 = 16,320; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 175 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Three-lane execution machine with vertical guideways and release latches. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 112 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Choose the announced safe lane before the drop sequence.
- **Defeat cause:** Swept descending ram. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Six guided vertical rams in three lanes. A 7s machine cycle provides four seconds open, a one-second downstroke, then retraction; lanes are phase shifted by 0.7s. Actual ram overlap triggers the compression sequence.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 27 — THE IRON WHEEL

- **Runtime arena:** 100 W × 100 clear H × 100 D; floor footprint 10,000. Public structural raft: 140×140 = 19,600; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 198 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Vertical industrial wheel supported by two bearing towers. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 114 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Board moving gondolas and collect the top extraction seal.
- **Defeat cause:** Falling from a gondola or contacting a spoke. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Ten gondolas circulate on a radius-40 vertical wheel, centered at Y=44, speed 0.12 rad/s. Passengers are carried by delta; upper seal at Y=87 is mandatory. Gondolas remain level, as suspended cabins should.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 28 — THE DROWNED ATRIUM

- **Runtime arena:** 100 W × 72 clear H × 100 D; floor footprint 10,000. Public structural raft: 140×140 = 19,600; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 214 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Flooded atrium with upper galleries, pumps and a dry refuge. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 116 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Collect pump fuses and reach a dry gallery before oxygen runs out.
- **Defeat cause:** Oxygen depleted while below the flood surface. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Atrium flood surface oscillates around Y=24 with amplitude 8. Each player has 12s underwater air and regenerates air at twice real time above the surface. Drowning is based on actual character elevation relative to the visible surface.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 29 — THE TIDAL STACK

- **Runtime arena:** 80 W × 100 clear H × 80 D; floor footprint 6,400. Public structural raft: 120×120 = 14,400; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 212 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Spiral stairwell with a water gauge and emergency landing rings. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 118 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Ascend the spiral landings faster than the visible rising water.
- **Defeat cause:** Rising water overtakes the player. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Surface rises at 0.85 Stud/s from Y=-5. Forty-two connected landings provide an ascent route. Air lasts 12s underwater. The final seal at Y=75 must be reached; simply avoiding one wave does not qualify.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 30 — CORRIDORS IN TRANSIT

- **Runtime arena:** 108 W × 36 clear H × 108 D; floor footprint 11,664. Public structural raft: 148×148 = 21,904; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 132 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Sliding corridor modules on orthogonal service rails. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 120 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Follow a connected route while corridor shutters alternate.
- **Defeat cause:** Being caught by a closing corridor shutter. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** The connected 9×9 transit topology has twelve rail-guided shortcut shutters. Every 6s a different shortcut opens; its graph edge is added only after the physical panel clears the passage. Closed panels remove their graph edges and closing contact is lethal. Base tree connections remain intact, so there is always a valid route. There is no hunter in this trial. Three route seals and survival are required.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 31 — THE FURNACE CHOIR

- **Runtime arena:** 100 W × 48 clear H × 88 D; floor footprint 8,800. Public structural raft: 140×128 = 17,920; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 144 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Brick furnace hall with ducts, baffles and extraction chimneys. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 122 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Operate cooling valves and shelter behind baffles during heat pulses.
- **Defeat cause:** Line-of-sight heat exposure from the open furnace. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Mouth at Z=-42 opens on the latter part of a 9s cycle. Heat damage is applied outside baffle shelter and working cooling-station proximity. Cooling valves and exhaust infrastructure are physical objects. The current shelter test is geometric, not acoustic/thermal CFD.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 32 — THE FALSE QUARRY

- **Runtime arena:** 96 W × 56 clear H × 96 D; floor footprint 9,216. Public structural raft: 136×136 = 18,496; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 187 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Suspended stone slabs on visibly frayed suspension cables. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 124 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Read load ratings and move off the slab before its cable releases.
- **Defeat cause:** Falling after a loaded slab loses support. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** 64 isolated slabs. A selected index group becomes unsupported after a four-second visible warning window within an 8s group cycle. Structural raft is removed. Load is also tracked for visible stress coloration.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 33 — THE STAMPING WORKS

- **Runtime arena:** 100 W × 48 clear H × 96 D; floor footprint 9,600. Public structural raft: 140×136 = 19,040; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 166 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Alternating punch presses with guide columns and camshafts. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 126 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Cross the safe press bed in the gaps between opposed strokes.
- **Defeat cause:** A piston reaches the occupied press bed. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Six punch heads on physical guide posts. Seven-second stroke cycles are offset by 1.5s, creating crossing windows between banks. Position and harmful volume share the same moving object.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 34 — RAIN OF THE RUIN

- **Runtime arena:** 100 W × 64 clear H × 100 D; floor footprint 10,000. Public structural raft: 140×140 = 19,600; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 168 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Damaged concrete vault with exposed reinforcing bars. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 128 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Move out of marked falling masonry impact areas.
- **Defeat cause:** Masonry impact and knockdown. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Warnings at random locations, then masonry falls from Y=55 after 1.5s. Speed 45 Stud/s; position-overlap is checked at server tick intervals before debris passes below the floor. Each warning is removed with its own stone.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 35 — THE PLANETARY GEAR

- **Runtime arena:** 100 W × 40 clear H × 100 D; floor footprint 10,000. Public structural raft: 140×140 = 19,600; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 145 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Sun gear with three driven planet wheels and a toothed rim. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 130 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Step through exposed gear sectors to recover drive keys.
- **Defeat cause:** Contact with a rotating tooth. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Twelve short tooth bodies circulate at radius 31, speed 0.6 rad/s, around a fixed sun shaft. Their actual rotated volumes apply pressure damage. The exterior adds a visibly toothed gear crown.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 36 — THE WITNESS GALLERY

- **Runtime arena:** 100 W × 40 clear H × 100 D; floor footprint 10,000. Public structural raft: 140×140 = 19,600; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 142 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Five carved witnesses arranged around a lit archive court. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 132 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Face the statues to stop them, then turn to collect archive seals.
- **Defeat cause:** A moving statue reaches a player who looks away. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Five stone witnesses. Avatar facing direction, not an arbitrary global timer, determines whether any survivor is watching a statue. A watched statue stops; an unwatched statue pursues the nearest survivor at 10 Stud/s. Face with the avatar to stop it.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 37 — THE VANISHING DISTRICT

- **Runtime arena:** 108 W × 44 clear H × 108 D; floor footprint 11,664. Public structural raft: 148×148 = 21,904; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 169 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Nine urban floor blocks linked by framed alley crossings. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 134 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Stay inside the progressively smaller stable central district.
- **Defeat cause:** Outer foundation rows detach and fall. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** 8×8 foundation district. Outer rows and columns detach every 18s by their minimum distance from the edge. The safe district contracts inward, while the visible failed tiles lose collision.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 38 — THE CRANE OPERATOR

- **Runtime arena:** 100 W × 96 clear H × 100 D; floor footprint 10,000. Public structural raft: 140×140 = 19,600; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 179 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Tower crane with slewing ring, jib, trolley and cable-suspended load. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–4; **trial limit:** 75s plus preparation; **base win reward:** 136 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Curator positions a suspended load; survivors secure three cargo seals.
- **Defeat cause:** A lowered load sweeps or crushes an occupied bay. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Curator console targets trolley X and lowers a 14×12×14 cargo load. Hoist cable position and length derive from actual load height under an 80-Stud jib. With no curator, target motion is automated. Overlap with the suspended load triggers crushing.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 39 — THE SAWMILL OF STONE

- **Runtime arena:** 100 W × 40 clear H × 88 D; floor footprint 8,800. Public structural raft: 140×128 = 17,920; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 142 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Stone-cutting hall with protected saw axles and visible belt drives. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 138 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Cross the mapped blade lanes using the recessed safety pockets.
- **Defeat cause:** Swept rotating blade impact. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Five low rotating steel sweep bodies, phase shifted around a driven court. They deal time-integrated combat impact damage, not gore. The exterior supplies individual saw drives and axles; runtime blades are simplified bar cutters.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 40 — THE HOLLOW FOUNDATION

- **Runtime arena:** 100 W × 44 clear H × 100 D; floor footprint 10,000. Public structural raft: 140×140 = 19,600; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 168 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Concrete slab field over an exposed foundation grid. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 140 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Move away from accumulating cracks caused by player load.
- **Defeat cause:** The occupied cracked slab gives way. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Each of 64 slabs integrates the time players stand on it. At 1.5s it shows stress; at 2.5s accumulated load it loses support. Different players contribute to the same slab load. Falling is handled by the connected fall choreography.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 41 — THE TRANSFER DOCK

- **Runtime arena:** 100 W × 48 clear H × 100 D; floor footprint 10,000. Public structural raft: 140×140 = 19,600; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 144 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Sliding freight platforms over a service trench. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 142 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Board the platform that aligns with the numbered exit dock.
- **Defeat cause:** Missing the transfer or being carried into the trench. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Four rail carriages shuttle over a genuinely open trench; both the regular floor and raft are removed. Standing players follow the carriage delta. Protected docks sit at X=-44/+44. Far-dock extraction is required; falling triggers the fall animation and elimination. Rails remain visible beneath each carriage.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 42 — THE GREAT BULKHEAD

- **Runtime arena:** 100 W × 64 clear H × 96 D; floor footprint 9,600. Public structural raft: 140×136 = 19,040; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 175 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Counter-sliding reinforced doors with racks and hydraulic cylinders. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 144 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Gather lock teeth and cross each door while its mechanical gap is open.
- **Defeat cause:** A moving door edge meets the character. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Three 20-Stud-high reinforced interlocks span the corridor at Z=-28/0/28. Collect physical lock teeth in sequence; a valid console grants an 8s opening. Paired leaves move apart at 0.6 opening units/s, exposing their rack drive. Closing leaf contact crushes. Side walls prevent walking around the mechanism. The final extraction seal is required; shared keys let the team advance together.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 43 — INSIDE THE ENGINE

- **Runtime arena:** 100 W × 56 clear H × 120 D; floor footprint 12,000. Public structural raft: 140×160 = 22,400; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 164 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Three-stage machine with intake rollers, press bed and exhaust shutters. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 146 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Traverse intake, compression and exhaust stages in order.
- **Defeat cause:** Contact with the currently active machine stage. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Intake, compression and exhaust are explicit ordered stages. Three rotating intake cylinders pulse on an 8s cycle; the intake gives forward velocity. Three independently phased compression heads guard Z=0. A traversing exhaust shutter becomes harmful during the final part of a 10s phase. Per-player progress changes only on crossing Z=-20 then Z=22; the far seal at Z=55 requires stage three. Each physical moving mechanism supplies its own contact volume.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 44 — THE PILLAR FOREST

- **Runtime arena:** 100 W × 64 clear H × 100 D; floor footprint 10,000. Public structural raft: 140×140 = 19,600; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 191 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Hydraulic lift columns in a square pressure-distribution grid. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 148 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Climb alternating pillars and collect high seals.
- **Defeat cause:** A column retracts before the player reaches the next one. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** 25 hydraulic columns. Independent sine phases raise each from Y=0 to Y=20 and retract it; passengers follow the position delta. Sockets and service distribution are visible. Collect elevated seals and stay on the columns.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 45 — THE RESONANCE WELL

- **Runtime arena:** 100 W × 60 clear H × 100 D; floor footprint 10,000. Public structural raft: 140×140 = 19,600; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 200 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Circular acoustic well with three expanding pressure rings. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 150 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Jump the visible expanding rings and reach the quiet central platform.
- **Defeat cause:** Resonance ring reaches a grounded character. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Pressure rings spawn every 4s, expand at 10 Stud/s, and consist of 24 low glowing segments. Contact with a low ring deals shock damage; jumping clears the wave. Rings are destroyed after radius 60.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 46 — THE MIRROR FOUNDRY

- **Runtime arena:** 100 W × 40 clear H × 100 D; floor footprint 10,000. Public structural raft: 140×140 = 19,600; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 135 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Brass-framed mirror field and a traversing beam emitter. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–6; **trial limit:** 75s plus preparation; **base win reward:** 152 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Use the opaque baffles; reflected beam directions are shown before firing.
- **Defeat cause:** An unobstructed reflected beam crosses the player. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** A true geometric ray solver intersects oriented mirror boxes and opaque baffles. Up to six reflections use d′=d−2(d·n)n and stop at the nearest opaque obstruction or perimeter wall. The actual reflected path is rebuilt every 5s, shown transparently for 1.6s, then becomes harmful. Each visible beam segment uses the computed length and orientation. Mirror frames and baffles therefore affect gameplay, not only appearance.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 47 — THE OXYGEN EXCHANGE

- **Runtime arena:** 100 W × 40 clear H × 88 D; floor footprint 8,800. Public structural raft: 140×128 = 17,920; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 135 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Sealed pipe gallery with four air reservoirs and pressure gauges. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 4–4; **trial limit:** 75s plus preparation; **base win reward:** 154 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Recharge air at alternating reservoirs while collecting filter cartridges.
- **Defeat cause:** Air reserve reaches zero away from a working reservoir. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Four reservoirs rotate availability every 12s. Air reserve starts at 15s and recharges only within 12 Studs of the currently active reservoir; empty air causes suffocation choreography. Distinct from flood: elevation and water are irrelevant.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 48 — THE RELAY BASTION

- **Runtime arena:** 100 W × 44 clear H × 100 D; floor footprint 10,000. Public structural raft: 140×140 = 19,600; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 140 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Four relay towers linked to a central insulated transmitter. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 4–4; **trial limit:** 75s plus preparation; **base win reward:** 156 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Activate numbered relays in the displayed order before the discharge.
- **Defeat cause:** Touching an energized relay or missing the grounded refuge. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Four relays must be activated in displayed cyclic order, eight correct activations total. Correct inputs score 30, wrong inputs damage by 25. Server range and per-station recovery are enforced. Eight correct relays are mandatory for victory.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 49 — THE LAST CONVOY

- **Runtime arena:** 48 W × 48 clear H × 140 D; floor footprint 6,720. Public structural raft: 88×180 = 15,840; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 149 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Rail convoy deck passing beneath loading gantries. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 158 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Move between freight beds to avoid overhead loading profiles.
- **Defeat cause:** Contact with an approaching loading gantry. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Twelve freight beds span a long axis. A laterally oscillating loading gantry advances from Z=65 to -70 at 12 Stud/s and repeats. Contact causes impact death. Every player can record the far extraction seal.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

### 50 — SUMMIT: THE CONVERGENCE

- **Runtime arena:** 120 W × 96 clear H × 120 D; floor footprint 14,400. Public structural raft: 160×160 = 25,600; the geological mass and service approach extend beyond this building footprint.
- **Built permanent components:** 285 Parts; active hazards and interior technical components are additional and exist only during a match.
- **Architectural identity:** Three-tier summit citadel exposing all surviving machine systems. Standard support columns are 7 Studs thick, service gallery is 12 wide; room openings and technical routes are generated rather than represented by particles.
- **Party range:** 1–8; **trial limit:** 75s plus preparation; **base win reward:** 160 coins + one associated trophy, +15 participation, +40 for the whole five-trial run.
- **Design objective:** Complete alternating route, memory and mechanical phases to reach the summit.
- **Defeat cause:** The active phase hazard strikes the character. Actual runtime qualification and limitations are specified below, not assumed from the name.
- **Implemented state machine:** Three actual elevations (0/24/48) connect by two exterior stair flights with unobstructed slabs and landing bridges. First interlock opens after 25s; second after 50s. Middle stage runs a safe-cell memory projection, top stage activates a real rotating sweeper. Extraction at Y=52 is enabled only after 65s. The final seal and survival are mandatory; waiting on the ground cannot win.
- **Entry/exit:** engraved west-hall stop → public mountain arrival pad → assembly selection. Return pad leads to the central plaza. A live trial is entered by the assembled team, with separate return handling on completion.
- **Lighting/audio/animation:** daylight-readable permanent complex; warm work luminaires in private interiors; stone/metal or specialized ice/brick material contrast. Shared score-state routing selects preparation/calm/danger/movement/impact/elimination/final/victory cues. Impact audio is spatial; original soundtrack cues require uploaded IDs (see AUDIO.md). Contact-derived procedural death poses are used, with the cause above.
- **Structural vs visual:** raft/piers/walls/floors/platforms are collision geometry; inscriptions/light strips/particle accents are visual. Drive rails and housings explain movement paths; kinematic motion does not pretend the decorative housing physically powers a real constraint solver.

## Known unfinished requirements — do not hide these

- No actual Roblox Studio rendering, physics, live multiplayer replication, R6/R15 motor playback or live DataStore session test has been run in this cloud. The Luau API-double test is a logic regression test only.
- Every trial now has a named state machine, but the art uses a common construction kit and shared kinematic collision helpers. Bespoke captured animation sets and independently mixed soundscapes for each of fifty locations are not complete. The source-linked notes above distinguish puzzle rules from rigid-body simulation.
- Ten original WAV cues exist, but custom Roblox music cannot play until their asset IDs are uploaded/authorized and placed in Catalog.AudioAssets. No false asset IDs or unlicensed catalog audio are used.
- Profile session locking, rejoin recovery, production anti-exploit review, mobile layouts and measured streaming/LOD budgets remain release work. Terrain is built from collision landform Parts; this is not hand-sculpted voxel Terrain or a photorealistic asset pack.
- Consequently this is a substantially rebuilt playable development project and detailed construction ledger, **not a completed production implementation of every requirement in the brief**.
