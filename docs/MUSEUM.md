# Museum R4: measured geometry and scope

The museum is the current entry point; previous trial scripts are retained as source only. `Museum.rbxl` contains the complete static place. Its XML-equivalent is `Museum.Full.rbxlx.gz`. The small XML alternatives contain the collision-complete structure and four entrance samples, then assemble all remaining authored detail during Play.

## Space and continuous surfaces

The core is 480×384 Studs on each of three floors (levels 0, 28, 56). Core footprint: 184,320 Studs²; three main floors: 552,960 Studs². Separate side stair enclosures and the 580×120 forecourt extend beyond that footprint. These are not confused with internal floor area.

Each floor has a continuous collidable slab, a visible backing, and 81,920 individual stone mosaic tesserae. Ceiling surfaces have the same tile count. Masonry, arches, capitals, rails, lamps and service frames bring the architectural count to 547,000. Mosaic grout is backed by solid stone and a continuous collision plane.

Side stairs are outside the full floor plates. Each side has two 56-tread flights: 0.5 rise, 1.25 run, 16 width. Treads have filled support volumes; consecutive treads overlap in projection. Landings overlap the main floors. Both sides have actual collidable glass guards and handrails.

Two enclosed elevators have 0/28/56 stops. Landing gates span the shaft interior. The carriage is 20.8 Studs wide, eliminating a character-sized side gap. Landing and carriage overlap in depth; equal surface elevations avoid a step into a void. Gates close before movement and the internal carriage gate remains closed in transit. Three separate keys and prompts select levels.

## Sculpture geometry

The 50 trial icons are converted from the actual icon source to shared skeleton specifications. Surface subdivisions create at least 1,200 relief cells per design; the independent binary report finds 1,202–2,037 actual body Parts. Hidden physics padding does not supply this minimum. The body, geometric animation layer and descriptive values are separate folders/objects.

Four entrance examples show wet mud, gilding, a translucent pale-cyan ghost and a blue galactic body. Twenty more exhibits demonstrate distinct material ranks. Their animation meshes are authored separately: clay coil, stone fragments, a copper drive wheel, bronze leaves, silver highlights, gem growth, ice/snow, plasma arcs, a constellation, comet trail, planets, a rift, an hourglass and a crown.

Mud folds deform anisotropically, droplets fall and taper, and puddle ripples expand. Ghost ribbons rotate in the opposite direction while body opacity phases. Galactic orbital frames use distinct inclinations; its stars shimmer. Gold has separate relief/filigree and moving metallic coins. These mechanisms do not use colored particle substitutions.

## Representation and workload

Detailed surfaces are anchored, noncollidable, nontouching and nonquerying; the 1,046 collision-bearing objects form the architectural envelope, stairs, gates and plinths. Decorative chunks stream atomically at a 16×16-tessera granularity. Each trophy also streams atomically. The structural model is persistent so floor collision is not waiting for ornamental streaming.

Client animation selects up to four nearby visible exhibits. It never broadcasts per-frame transforms for hundreds of thousands of Parts from the server. Pausing animations freezes those layers for inspection.

Counts are for the full server/editor scene. A streaming client intentionally receives a local subset. Real memory and frame-rate measurements must be made in Studio on target hardware; none are fabricated here.

## Audit

`docs/museum-readback-report.json` is produced by decoding `Museum.rbxl`, not by trusting a requested target. It contains the actual architectural count, counts for all trophy bodies, collision geometry and embedded script hashes.

The audit compiles each script separately, checks all body budgets, verifies three uninterrupted floors, checks routes to 74 exhibit approaches with character clearance, inspects both staircase connections, verifies platform/gate dimensions and executes the actual runtime sculpture builder in a deterministic Luau API-double harness. This does not replace the Roblox engine or certify every network/physics behavior.

The image in `docs/previews/museum-gallery.png` is an external Blender visualization of the authored geometry. It is not represented as a Roblox Studio screenshot or an engine-performance measurement.
