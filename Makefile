# Autoload Last Save
# Builds the loose-folder mod with the AMUMSS Linux port.
#
# What it does: sets the game's own BootDirectlyIntoLastSave option, so
# boot goes straight into the most recently played save instead of
# stopping at the Main Menu. No game binaries live in this repo: the one
# patched value is rendered into the script from src/patches.tsv.
#
# Usage:
#   make release      clean rebuild + verify + pack dist/ zip (default)
#   make verify       sanity-check the built outputs
#   make clean        remove build/ and dist/
#   make assets       regenerate the Nexus page images (needs Pillow)
#
# Override the AMUMSS install location if needed:
#   make AMUMSS_HOME=/path/to/AMUMSS release
#
# Game-update playbook (see README.md):
#   1. fetch latest MBINCompiler into AMUMSS_HOME
#   2. re-derive the base in src/patches.tsv (see README.md)
#   3. bump VERSION below (the mod version, published on Nexus)
#   4. make release, import + deploy + test in game

AMUMSS_HOME ?= $(HOME)/AMUMSS
AMUMSS_LINUX ?= $(HOME)/Git/AMUMSS/linux

# The mod version, published as the version of the Nexus release. An
# unreleased build stays at 0.0.0; the first public release bumps this in the
# same commit that publishes it. The version is deliberately not part of the
# mod name: the artifact is named after the mod alone (see ROOTZIP), because
# a mod manager names the installed mod after the archive file name and shows
# the version in a column of its own.
VERSION      := 0.0.0

MOD_SET      := Autoload Last Save

SRC_TEMPLATE := src/autoload.lua.in
SRC_TABLE    := src/patches.tsv

BUILD := build
DIST  := dist
STAMP := $(BUILD)/.built

RENDERED := $(BUILD)/autoload.lua
EXPECTED := $(BUILD)/autoload.expected.tsv

.PHONY: all release render build verify clean rootzip assets

all: release

# Single canonical artifact: the mod folder zipped as-is (Amethyst default
# import, or drop the folder into GAMEDATA/MODS). A
# single-configuration mod ships a plain zip and nothing else.
ROOTZIP := $(DIST)/$(MOD_SET).zip

release: clean render build verify rootzip
	@echo "release: $(ROOTZIP) (version $(VERSION))"

# The patched value in src/patches.tsv drives the rendered script, so a
# value can never ship without its patch.
render: $(SRC_TEMPLATE) $(SRC_TABLE) src/render_mod.py
	@mkdir -p "$(BUILD)"
	@python3 src/render_mod.py --table "$(SRC_TABLE)" --template "$(SRC_TEMPLATE)" \
		--out-script "$(RENDERED)" --out-expected "$(EXPECTED)"

build: render
	@test -d "$(AMUMSS_HOME)/MODBUILDER" || (echo "ERROR: no AMUMSS install at $(AMUMSS_HOME)" >&2; exit 1)
	@test -x "$(AMUMSS_HOME)/MODBUILDER/MBINCompiler-linux" || (echo "ERROR: run $(AMUMSS_LINUX)/scripts/fetch_mbincompiler.sh with AMUMSS_HOME=$(AMUMSS_HOME) first" >&2; exit 1)
	@rm -rf "$(AMUMSS_HOME)/MODBUILDER/MOD" && mkdir -p "$(AMUMSS_HOME)/MODBUILDER/MOD"
	@if [ -d "$(AMUMSS_HOME)/ModScript" ]; then mv "$(AMUMSS_HOME)/ModScript" "$(AMUMSS_HOME)/ModScript.makebak"; trap 'rm -rf "$(AMUMSS_HOME)/ModScript"; mv "$(AMUMSS_HOME)/ModScript.makebak" "$(AMUMSS_HOME)/ModScript";' EXIT; fi
	@mkdir -p "$(AMUMSS_HOME)/ModScript"
	@cp "$(RENDERED)" "$(AMUMSS_HOME)/ModScript/mod.lua"
	@rm -rf "$(AMUMSS_HOME)/CreatedMODS/$(MOD_SET)"
	@AMUMSS_HOME="$(AMUMSS_HOME)" "$(AMUMSS_LINUX)/buildmod.sh" --run-pipeline
	@rm -rf "$(AMUMSS_HOME)/ModScript"
	@if [ -d "$(AMUMSS_HOME)/ModScript.makebak" ]; then mv "$(AMUMSS_HOME)/ModScript.makebak" "$(AMUMSS_HOME)/ModScript"; fi
	@trap - EXIT
	@rm -rf "$(BUILD)/$(MOD_SET)" && mkdir -p "$(BUILD)/$(MOD_SET)"
	@cp -a "$(AMUMSS_HOME)/CreatedMODS/$(MOD_SET)/." "$(BUILD)/$(MOD_SET)/"
	@cp "$(RENDERED)" "$(BUILD)/$(MOD_SET)/mod.lua"
	@touch "$(STAMP)"
	@echo "built: $(BUILD)/$(MOD_SET)"

# verify_build.py checks the built EXML carries the rendered value and the
# mod folder holds nothing else.
verify: build
	@python3 src/verify_build.py --build "$(BUILD)" --mod-set "$(MOD_SET)"

# Single install archive: the bare mod folder maps to GAMEDATA/MODS/.
rootzip: verify
	@rm -rf "$(BUILD)/rootzip" && mkdir -p "$(BUILD)/rootzip"
	@cp -a "$(BUILD)/$(MOD_SET)" "$(BUILD)/rootzip/"
	@rm -f "$(BUILD)/rootzip/$(MOD_SET)/AMUMSS_v"*.txt
	@mkdir -p "$(DIST)" && rm -f "$(ROOTZIP)" && cd "$(BUILD)/rootzip" && zip -qr "$(shell pwd)/$(ROOTZIP)" "$(MOD_SET)"
	@echo "packed: $(ROOTZIP) (version $(VERSION))"
	@unzip -l "$(ROOTZIP)" | tail -4

# Nexus page header from the source screenshot in assets/src. The generated
# images are build artifacts and are not tracked; the screenshot and the
# typeface are.
assets: assets/src/gallery-autoload-last-save.jpg assets/generate.py
	python3 assets/generate.py

clean:
	rm -rf "$(BUILD)" "$(DIST)"
