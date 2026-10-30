# Autoload Last Save

Boots directly into your most recently played save instead of stopping
at the Main Menu. Built natively on Linux with the
[AMUMSS Linux port](https://github.com/SavageCore/AMUMSS/tree/feat/linux-support).

## What it does

No Man's Sky normally stops at the Main Menu after the title screens.
This mod sets the game's own `BootDirectlyIntoLastSave` option, so you
go straight into your most recent save.

To get back to the Main Menu (a different save, multiplayer): disable
the mod and launch once.

## Install

Install `dist/Autoload Last Save.zip` as a normal mod into `GAMEDATA/MODS`
([Amethyst](https://github.com/ChrisDKN/Amethyst-Mod-Manager)) or copy the
`Autoload Last Save` folder into `GAMEDATA/MODS`.

One value in one file: safe to add or remove at any time.

## Compatibility

One EXML value in `GLOBALS/GCDEBUGOPTIONS.GLOBAL.MBIN`, so it works alongside
mods that change other lines of that file. A mod that sets this same
option conflicts outright: the last one loaded wins. The included
`mod.lua` lets you merge with AMUMSS.

Built for Forsaken.

## Build (on Linux)

Requires a full AMUMSS install at `~/AMUMSS` (override with
`AMUMSS_HOME=...`) with `MBINCompiler-linux` fetched
(`linux/scripts/fetch_mbincompiler.sh` in the AMUMSS repo).

```sh
make release      # clean rebuild + verify + pack dist/ zip (default)
make verify       # sanity-check the built outputs
make rootzip      # pack the install archive (no rebuild)
make assets       # regenerate the Nexus page images (needs Pillow)
make clean        # remove build/ and dist/
```

### `make verify` is the load-bearing step

It checks the built global carries the rendered value and the mod
folder holds nothing else - including that no previous build's file
survives a script that changed nothing.

## Game updates / versioning

The mod version is `VERSION` in the `Makefile`. When No Man's Sky
updates, re-derive the base in `src/patches.tsv`: decompile the vanilla
`GLOBALS/GCDEBUGOPTIONS.GLOBAL.MBIN` with MBINCompiler and read the shipped
`BootDirectlyIntoLastSave` value, then rebuild and test in game.
