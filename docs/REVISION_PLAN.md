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
- [x] Guided first-session tutorial: identify expert, sit, inspect, verdict, buy, carry from collection, visit another specialist. Eight persisted milestones with skip/replay and target highlighting.
- [x] Free specialty switching, retained XP; meaningful practice advances corresponding expertise. Equipment and optional training remain separate from unlocking an already learned profession.
- [x] Profession symbol and required specialty beside each NPC emotion/speech bubble. Five actual icons generated in an atlas; text/symbol fallback remains active until genuine image IDs are configured.
- [x] Read ALL friendship pages. Random shuffled cycles; no immediate or near-immediate repeats where sufficient distinct friends exist. Fetch descriptions on demand, not hundreds on arrival; handle errors and active visitors.
- [x] Varied NPC first-person stories per instance; keep one story stable throughout the case and persist it when buying. Stories, offers and complaints appear in the NPC speech bubble; keep them readable during inspection.
- [x] Compact appraisal UI up to 340×550 px, leaving the world visible. Five active tasks: loupe marks, tare/weight calibration, UV zones, prism alignment, diagnostic wheels. Server validates duration, case and steps; no reward from waiting or a client-reported score. Mouse/touch rotation includes vertical tilt.
- [x] Visible dirt, chipped cup edges, altered surface tone and repair seams. Saved surface clues and UV repair reports agree; originals can have repairs and replicas can look convincing. Restoration reduces value by 8%. Cleaning/restoration as a separate paid activity is not part of this revision.
- [x] Cup walls have overlapping segments; coins have struck profile, reeding and beaded border. Procedural surface patterns work now. Four generated material PNGs and five profession icons are saved with a precise import manifest; real image upload remains external below.
- [x] Forty physical collection slots per building. Owned instances appear with their condition and rarity; F carries an owned nearby item. Only changed models rebuild, and held items return to the shelf when unequipped. Sale and ownership remain server-authoritative.
- [x] Twenty-six decor/card/frame variants, nine categories, six authored mounting sockets, free re-equipping of owned items and moving prestige mechanisms. Coin purchases and entitlement persistence implemented. Native premium prompt/receipt path implemented but disabled with Product ID=0; real billing remains external below.
- [x] Uniqueness independent of mutation: normal 0%; first +0.1 percentage point 1/1000, each further consecutive step 1000 times rarer. Odds documented and F8 preview deterministic.
- [x] Seven different mutation mechanisms: Silver specular sheen; Gold metal/filigree/glint; Ghost translucent phased silhouette; Verdant vines/leaves; Glacial facets/cold breath; Ember charcoal/cracks/cinders; Astral dark glass/orbiting stars. Exact odds: 1/1000, 1/10000, 1/50000, 1/100000, 1/250000, 1/1000000, 1/10000000. Server-rolled and saved.
- [x] Spatial door slide/stop, instrument and transaction feedback, local mute group. Six original WAVs generated with import manifest; Roblox built-in fallback is active pending upload.
- [x] Independent 310 px top-right TAB. Title/name effects, card backgrounds and frames are equipped separately; plain and animated choices included.
- [x] Fresh rbxlx build, all source compiled, authoritative economy/session/receipt flows exercised, source freshness/API schema/geometry validated. These are automated checks, not a Studio playtest.

## Checkpoint

Initial complete prototype: `77324d2`; first revision checkpoint: `dc37f49`. Current revision 0.2 contains all checked implementation above, embedded in `build/PROBA.rbxlx`. The build retains 100 items, 91 geometry families, three buildings and six plots. Offline architecture/interior previews have been regenerated from current geometry; they omit Roblox HUD and SurfaceGui rendering and must never be described as Studio screenshots.

Latest automated checks: 3911 economy assertions; 4098 visit/story assertions; 53 instrument assertions; 16 rarity assertions; 6 tutorial assertions; 43 authoritative server-flow assertions, plus XML/API/geometry validation. The two deliberate storage-outage warnings are expected test scenarios.

## External steps still unverified

- [ ] Upload generated PNG/WAV files under the experience owner and assign genuine Config IDs; see [assets instructions](../assets/README.md). No authenticated Roblox upload tool is attached. Procedural art, text badges and built-in sound remain functional without upload.
- [ ] Create/configure actual Developer Products and test native receipts in a published test experience if premium billing is wanted. Product IDs are intentionally 0 until then.
- [ ] Run [Studio engine checklist](STUDIO_CHECKLIST.md), including R6/R15, mobile layout, avatar API, physical seating/replication, all decor sockets and cloud persistence. Studio is not installed here; passing mock and geometry checks does not establish these engine results.

The generated direction board remains a target reference. The present construction uses detailed assembled geometry and authored surface patterns; it is not a claim that all concept-art texture fidelity has already been reproduced in-engine.
