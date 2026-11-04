# PROBA — revision requested 2026-11-04

This document preserves the user's review and work state across quota interruptions. Continue implementation without requesting the same approval again. User screenshots showed a bench intruding into the street, a fountain on the road, reversed drawers/chair, a generic large shop and oversized appraisal UI.

## Accepted direction

- English persistent brand: **PROBA · Appraisal & Antiques**. Name is a design choice, not a claim of trademark availability.
- Generated visual reference: [direction board](references/proba-direction-board.png). The board is an aspirational concept, not evidence of implemented game visuals.
- Preserve useful existing economy, reputation, approximation, peer appraisals, save isolation, small environmental details and admin laboratory.

## Ordered implementation checklist

- [x] Put fountain in a separate pedestrian courtyard, benches fully on pavement; keep manholes and practical details.
- [x] Reverse appraisal drawers toward operator and face the operator chair toward customer. A real Seat starts work; E at the desk remains for visiting players' appraisal requests only.
- [x] Queue customers inside, with clearance around the door, displays and operator aisle.
- [x] Replace starter shop proportions with a recognisable converted ISO container: long narrow module(s), corner castings, cargo doors/locking bars, credible cut-outs, original corrugated shell. Research source access must be explicit; do not pretend to have browsed blocked Roblox/web pages.
- [ ] Guided first-session tutorial: sit, identify needed expert, inspect, verdict, buy, display, visit another specialist. Persist milestones and provide skip/replay.
- [x] Free specialty switching, retained XP; meaningful practice advances corresponding expertise. Equipment and optional training remain separate from unlocking an already learned profession.
- [ ] Profession pictogram and required specialty beside each NPC emotion/speech bubble. Generate five actual icon assets (household/jeweler/historian/archaeologist/mechanic), retain text fallback until real asset IDs are configured.
- [x] Read ALL friendship pages. Random shuffled cycles; no immediate or near-immediate repeats where sufficient distinct friends exist. Fetch descriptions on demand, not hundreds on arrival; handle errors and active visitors.
- [x] Varied NPC first-person stories per instance; keep one story stable throughout the case and persist it when buying. Stories, offers and complaints appear in the NPC speech bubble; keep them readable during inspection.
- [ ] Compact immersive appraisal UI (world visible), separate controls for loupe sweep, weighing/calibration, UV sweep, material sampling and mechanical diagnostic alignment. Server validates duration, case, challenge steps; no rewards based solely on client-reported score.
- [ ] Visible physical condition: dirt, chips, altered glaze, false hallmark, repair seams; cleaning/testing changes the visible local inspection state. Preserve genuine-with-restoration and convincing counterfeits.
- [ ] Better cup/coin shapes and custom materials; generated PNGs in assets with import manifest. No fabricated Roblox asset IDs. External texture uploads require a supported authenticated Roblox upload route; record any remaining upload step.
- [ ] Physical collection on shelves/counters: choose/display/carry/sell an owned UID via prompts. UI may index collection, but owned objects must actually appear in shop. Avoid moving colliders or crowding route.
- [ ] Purchasable decor: signs, banners, ads, paintings, chairs, lamps, scales and prestige animated versions; authored safe placement sockets; virtual currency and optional premium cosmetic entitlements. Real Robux product IDs and receipts must be configured and verified; never fake a successful Robux charge.
- [ ] Uniqueness percentage independent of mutation. Working interpretation pending user correction: normal 0%; first +0.1 percentage point is 1/1000, further steps exponentially rarer. Document actual odds and provide deterministic admin preview.
- [ ] Seven distinct mutations with effects/geometry/motion, not recoloured identical emitters. Silver (1/1000, brushed metal/specular sweep); Gold (hammered gold/filigree); Ghost (translucency/phased silhouette); Verdant (growing vines/moss); Glacial (faceted frost/cold breath); Ember (charcoal/glowing cracks/cinders); Astral (parallax starfield/orbiting geometry). Suggested later odds: 1/10000, 1/50000, 1/100000, 1/250000, 1/1000000, 1/10000000. Keep rarity persistent and server-rolled.
- [ ] Spatial glass-door slide/stop sounds and fitting tool/transaction feedback; retain mute/volume control. Use real accessible assets or a clear import manifest.
- [ ] TAB becomes small top-right roster, independent of the large management window. Separate title/name effects from banner/frame cosmetics; include plain and animated variants.
- [ ] Rebuild .rbxlx, compile Luau, exercise authoritative transactions, validate seating, queues, displays, rarity persistence and safe decor geometry. Keep engine-playtest status truthful: Studio not available here.

## Checkpoint

Starting published commit: `77324d2`. First checked revision implements the seven checked items above, a small independent top-right roster, generated reference/icon/porcelain PNGs and text profession badges. Starter footprint is now 56×22×14.5 Studs (two joined high-cube modules), with original end cargo hardware. Automated checks pass, including 4098 visit/story assertions and authoritative seated-work and free-switch checks. PNGs are saved but not uploaded to Roblox; no asset ID has been invented. Current main appraisal UI and timed research still need replacement; mutation/decor/physical collection/tutorial work remains open. Studio engine playtest is not available. Continue from the unchecked items.
