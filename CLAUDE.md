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

## Migration Context

Scripts are being migrated from SuperOps. See `MIGRATION_PLAN.md` for status. The `tools/` directory contains migration helpers for local use only.
