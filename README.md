# Jovian Wake — Callisto Playground

A small first-person Godot 4 experiment: stand on Callisto, see Jupiter, walk to a six-wheel rover, drive across a rocky ice field, and get back out.

![Callisto landing site and rover, rendered in Godot](docs/playground.png)

This is a separate project from the working TypeScript cruise deckbuilder in `../jovian-wake`. It tests movement, scale, and rover feel; it does not commit Jovian Wake to a survival/crafting game or a particular long-term design.

## Play on Windows

Double-click **`Play.cmd`**. It launches the current exported game, or finds a local Godot installation and runs the source. This workspace's existing Spiritbound/Range Club Godot installation is also detected.

You can run **`builds/windows/CallistoPlayground-v0.2.exe`** directly without the editor. Keep its adjacent `.pck` file with it. The generated build is ignored by Git. The earlier executable remains available so an ongoing playtest is not interrupted; `Play.cmd` prefers v0.2. Close the old window and relaunch to use updated controls and sky.

To edit the prototype, import `project.godot` in **Godot 4.7.2 Standard** and press **F5**. The Compatibility renderer requires OpenGL 3.3; no plugins or downloaded assets are needed.

## Gamepad controls

Use a standard Xbox-style gamepad. Hot-plugging works through Godot's controller support; use any stick or button to switch the HUD prompts.

| Action | On foot | In the rover |
| --- | --- | --- |
| Left stick | Walk | Steer; forward/back also drives |
| Right stick | Look | Look around the cockpit |
| A | Jump | — |
| X | Enter nearby rover | Exit and park rover |
| LB | Move faster while held | — |
| RT / LT | LT: hold visor zoom | Forward / reverse, with analog throttle |
| B | — | Brake |
| Y | Reset the landing site | Reset the landing site |
| Menu / Start | Pause / resume | Pause / resume |

The sticks have deadzones and the look stick uses a gentle response curve for fine aiming. The game starts directly in first person; the whole loop works without a mouse. Focus loss pauses movement; Menu resumes. Pause is a small overlay, not a menu system.

## Keyboard and mouse

WASD moves or drives; mouse looks. Space jumps on foot and brakes in the rover. E enters/exits. Shift moves faster on foot. Hold the right mouse button for visor zoom. R resets. Esc pauses or resumes; clicking the window also resumes after mouse release.

## What's in the playground

- A fixed 240 m terrain mesh with shallow craters, rocky obstacles, ice-colored facets, distant rim silhouettes, a small landing module, and survey markers.
- Black sky with Jupiter, the Sun, Io, Europa, and Ganymede. Radii and observer distances determine their apparent sizes. Jupiter is approximately 4.35° across; the small solar disk has a little optical glare so it is findable. Their static arrangement is a chosen circular-orbit approximation, not an ephemeris for a real date.
- Astronaut gravity of **1.24 m/s²**. A modest 1.65 m/s jump gives roughly 1.1 m of rise and 2.7 seconds of flight on flat ground. Jumping preserves horizontal momentum: no midair steering or braking. Ground contact restores control. You can still look around during flight.
- An arcade rover with six visual wheels, a cockpit view, analog throttle, steering, brakes, ground collision, and visual chassis tilt. Top speed is 11 m/s; reverse is capped at 4.5 m/s. Its collider stays upright; there is no simulated suspension or wheel traction.
- Exits check several sides and refuse blocked or unsafe steps. Boundary colliders keep both bodies on the finite map; reset provides immediate recovery.

The terrain is an authored mathematical playground, not a reconstruction of Callisto. Ambient fill light, movement control, and rover contact are artistic/playability choices, not a physical simulation. The scene depicts a location on the Jupiter-facing side: [NASA's Callisto overview](https://science.nasa.gov/jupiter/jupiter-moons/callisto/facts/) describes its tidally locked rotation. The mesh and materials are generated locally with built-in Godot resources.

## Verify and export

```powershell
.\tools\godot.ps1 check
.\tools\godot.ps1 test
.\tools\godot.ps1 windows
.\tools\godot.ps1 capture
```

Set `CALLISTO_GODOT` or pass `-GodotPath 'C:\path\to\godot.exe'` to choose another compatible engine. Windows export needs matching Godot export templates. Captures require a graphical renderer and write ignored PNGs to `artifacts/`.

Automated checks run the actual 3D collision world and simulated keyboard/gamepad events. They cover landing, walking/stopping, jump/gravity and conserved horizontal momentum, rover range and seating, trigger driving/reverse, steering/braking, stick drift/look, visor zoom, pause/reset, blocked exits, terrain boundaries, crater collision, fall recovery, and astronomical apparent sizes. They do not establish physical controller compatibility or perceived handling comfort. Those require manual playtesting.

On October 13, 2026, all **54 checks** passed in both source and exported Windows-pack runs. Godot import/export and a Windows executable startup check completed without script/runtime errors. Actual rendered views were inspected on foot, approaching the rover, in the cockpit, after exit, and through the visor at Jupiter, the Sun, and Ganymede. The original exported game's native window was inspected. Physical gamepad feel remains a manual playtest item.

## Code map

| File | Responsibility |
| --- | --- |
| `game/playground.gd` | World setup, interaction, safe exit, reset, pause, input routing |
| `game/terrain.gd` | Immutable height field, low-poly mesh, matching ground collider |
| `game/astronaut.gd` | First-person camera, walking, jumping, low gravity |
| `game/rover.gd` | Primitive rover model and arcade movement |
| `game/controls.gd` | Keyboard and Xbox-style input mappings |
| `game/hud.gd` | Minimal controls, interaction prompts, pause overlay |
| `game/sky.gd` | Physical angular sizes, static Sun/moon arrangement, sky meshes |
| `game/jupiter.gdshader` | Procedural cloud bands |
| `game/sun_glare.gdshader` | Small optical glare around the solar disk |
| `tests/` | Physics/input checks and rendered view captures |

Movement uses Godot's [CharacterBody3D](https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html); gamepad mappings use its [controller input support](https://docs.godotengine.org/en/stable/tutorials/inputs/controllers_gamepads_joysticks.html).

## First playtest

1. Look up at Jupiter, walk around, and try a jump. Does the movement feel floaty without being tedious?
2. Approach the rover and use X / E. Drive over the shallow crater slopes, steer, reverse, and brake.
3. Look around from the cockpit. Exit, walk away, and reenter. Try Y / R and Menu / Esc.
4. Check a physical controller's sticks, triggers, buttons, hot-plugging, and comfortable look speed.

No inventory, crafting, survival meters, progression, AI services, voxel framework, or networking is included.
