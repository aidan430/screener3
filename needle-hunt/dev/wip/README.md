# Work in progress (stopped 11 Nov, to continue)

Three jobs were stopped part-way. Nothing here is in the game yet; `src/` is as last shipped.

- `first_person/first_person_wip.patch`: the new first-person view (hands, fingers, grip, motion,
  animations, first-person lock) and its preview renderer (`dev/preview/viewmodel*`,
  `shoot_viewmodel.js`). First pass: passes the tests and the script check, numbers not tuned, not
  reviewed. Apply from the repo root with `git apply needle-hunt/dev/wip/first_person/first_person_wip.patch`.
  `first_person/cand_*`: two part-tuned styles (fencer, dagger); a third (dart) was not started.
  Known problems in the first pass: the hand is too big and flat, the fingers don't wrap the
  needle, the sleeve fills the screen at the end of the stab.
- `realistic_maps_spec.md`: the build plan for the realistic look of Hayfield Farm (not yet
  critiqued). `maps_agent_results.md`: the engine research and the three designs behind it.
- `combat_movement_spec.md`: the build plan for combat and movement (crouch and slide, impact,
  easier hits, more moves). It was still being written when stopped: check its end before
  building from it. `combat_agent_results.md`: the research and the three designs.

The preview renderer needs `three.min.js` (r128) beside `viewmodel.html` and the `lupa` Python
package; neither is committed.
