# Repository Guidelines

## Project Structure & Module Organization

Cosmogen is a PICO-8 game. All source files live in the repository root. `main.p8` is the cartridge: it includes the Lua modules and stores sprites, map data, sprite flags, sound effects, and music.

- `main.lua` defines `_init`, `_update60`, and `_draw`.
- `cable.lua` handles cable paths, crossings, and movement.
- `astronaut.lua`, `critters.lua`, and `arrows.lua` implement game entities.
- `map.lua` transforms map tiles into terrain and entities; `screen.lua` handles camera transitions.
- `position.lua`, `utils.lua`, `palette.lua`, and `debug.lua` provide shared helpers.

Add new modules to the `#include` list in `main.p8`. Preserve initialization dependencies in `main.lua`.

## Build, Test, and Development Commands

Testing the file requires an installed PICO-8 runtime. 
For now, assume the user will test any changes and provide feedback.

## Coding Style & Naming Conventions

There is a massive design constraint for PICO-8 which means the total number of characters and tokens across all `.lua` files are severely limited.
Therefore, its important to write code in such a way that it is not verbose.
Prefer simple changes and simple implementations for prototyping.
Prefer simpler mechanics that only require a small amount of code over complex mechanics that require a lot of code.

Use PICO-8 Lua, including existing dialect features such as `+=`, `!=`, and built-in functions like `all` and `add`. Standard Lua tooling may reject this syntax.

Prefer four-space indentation; preserve surrounding style in existing helpers. 
Use lowercase snake_case for functions and variables, and established prefixes such as `init_`, `update_`, and `draw_`. Keep temporary values local and make shared game state intentional.

## Testing Guidelines

No automated test framework or coverage target is configured. 

## Commit & Pull Request Guidelines

Never commit or make any pull requests. The user will decide when to commit and do so manually.
