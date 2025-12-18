# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Production-ready PowerShell and shell scripts for RMM platforms (SuperOps, Datto, NinjaRMM).

## Repository Structure

- `scripts/` - Production scripts (`.ps1` and `.sh`)
- `tools/` - Migration helpers (local use only, gitignored)
- `docs/` - Documentation and style guidelines
- `wiki/` - GitHub wiki content

## Script Style Requirements

**All scripts must follow Limehawk Style A methodology.**

Read the complete guidelines before creating or modifying scripts: `docs/limehawk_script_generation_guidelines.txt`

Key points:
- Use snake_case filenames (`speedtest_to_superops.ps1`)
- Hardcode all inputs (no `param()` blocks)
- Include Limehawk ASCII art header and README block
- Exit 0 on success, exit 1 on failure

## Version Bumping (MANDATORY)

When modifying ANY existing script, you **MUST** update:
1. **VERSION** - Increment appropriately (major.minor.patch)
   - Major: Breaking changes or significant rewrites
   - Minor: New features or functionality
   - Patch: Bug fixes or minor tweaks
2. **CHANGELOG** - Add entry at top: `YYYY-MM-DD vX.Y.Z Description of changes`
3. **README sections** - Update any affected sections (PURPOSE, BEHAVIOR, REQUIRED INPUTS, etc.)

## Migration Context

Scripts are being migrated from SuperOps. See `MIGRATION_PLAN.md` for status. The `tools/` directory contains migration helpers for local use only.
