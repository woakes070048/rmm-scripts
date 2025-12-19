# Security Policy

## Reporting Vulnerabilities

If you discover a security vulnerability in this repository, please report it privately via [GitHub Security Advisories](https://github.com/limehawk/rmm-scripts/security/advisories/new) rather than opening a public issue.

## Credential Handling

These scripts are designed for RMM deployment. **Never hardcode credentials directly into scripts.**

### Best Practices

1. **Use RMM platform variables** - Most RMM platforms support secure variable injection (e.g., `$siteToken`, `$env:API_KEY`)
2. **Environment variables** - Scripts fall back to environment variables when RMM injection isn't available
3. **Review before deploying** - Always audit scripts before running in production

### Scripts Requiring Sensitive Inputs

| Script | Sensitive Input | Recommended Method |
|--------|-----------------|-------------------|
| `sentinelone_install_silent.ps1` | Site token | RMM secure variable |
| `huntress_install_macos.sh` | Account/Org keys | Environment variables |
| `dokploy_deploy_running_apps.sh` | API token | Environment variable |
| `splashtop_business_agent_install.ps1` | Deploy code | RMM secure variable |

## What We Don't Store

This repository intentionally excludes:
- API keys, tokens, or passwords
- Customer data or internal URLs
- Private configuration files
- Environment-specific settings

## Code Safety

All scripts in this repository:
- Avoid dangerous patterns like `Invoke-Expression` with remote content
- Include `$ErrorActionPreference = 'Stop'` for fail-fast behavior
- Document security considerations in their README headers
- Use exit codes for proper RMM status reporting
