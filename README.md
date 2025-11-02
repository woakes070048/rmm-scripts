```
██╗     ██╗███╗   ███╗███████╗██╗  ██╗ █████╗ ██╗    ██╗██╗  ██╗
██║     ██║████╗ ████║██╔════╝██║  ██║██╔══██╗██║    ██║██║ ██╔╝
██║     ██║██╔████╔██║█████╗  ███████║███████║██║ █╗ ██║█████╔╝ 
██║     ██║██║╚██╔╝██║██╔══╝  ██╔══██║██╔══██║██║███╗██║██╔═██╗ 
███████╗██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║╚███╔███╔╝██║  ██╗
╚══════╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝
```
# RMM Scripts

A collection of production-ready PowerShell scripts optimized for Remote Monitoring and Management (RMM) platforms including SuperOps, Datto, and NinjaRMM.

## About

This repository contains PowerShell automation scripts designed specifically for RMM environments. All scripts follow the **Limehawk Style A** methodology, ensuring consistency, reliability, and production-readiness across the entire collection.

## Limehawk Style A Guidelines

All scripts in this repository adhere to the **Style A** standard for PowerShell RMM scripting. This methodology ensures:

- **Hardcoded inputs** - No param blocks or command-line arguments; all configuration is defined within the script
- **Comprehensive documentation** - Every script includes a detailed README/CHANGELOG block with purpose, behavior, prerequisites, and examples
- **Structured console output** - Clear, parseable output with labeled sections and key-value formatting
- **Robust error handling** - Uses `$ErrorActionPreference = 'Stop'` with contextual error messages
- **Production-ready code** - No secrets in logs, proper validation, and consistent exit codes

For complete guidelines on creating Style A scripts, see: [`limehawk_script_generation_guidelines.txt`](docs/limehawk_script_generation_guidelines.txt)

## Scripts

For detailed documentation on all available scripts, please visit the **[Wiki](https://github.com/limehawk/rmm-scripts/wiki)**.

### Script Categories

- **System Administration** - Disk analysis, BitLocker management, hardware reporting, system maintenance
- **Installation & Updates** - MSI deployment, winget installation
- **Device Management** - Device renaming, reboot scheduling, admin account management
- **Monitoring & Reporting** - Speed testing, product key extraction, workstation information
- **RMM Agent Management** - Agent installation and removal

Browse the [complete script index](https://github.com/limehawk/rmm-scripts/wiki) with detailed documentation for each script including prerequisites, configuration, usage examples, and more.

## Usage

### Running Scripts in RMM Platforms

1. **Review the script** - Each script contains a README block at the top with:
   - Purpose and behavior description
   - Required inputs (hardcoded values to modify)
   - Prerequisites and permissions needed
   - Example output

2. **Configure hardcoded inputs** - Edit the variables section after `Set-StrictMode` to match your environment:
   ```powershell
   # Example - modify these values as needed
   $apiKey = 'your-api-key-here'
   $targetPath = 'C:\Your\Path'
   $timeout = 300
   ```

3. **Deploy to RMM** - Upload the script to your RMM platform (SuperOps, Datto, NinjaRMM, etc.)

4. **Execute and monitor** - Run the script and review console output for status
   - Exit code 0 = Success
   - Exit code 1 = Failure
   - Check `[ ERROR OCCURRED ]` sections for troubleshooting

### Local Testing

```powershell
# Run in PowerShell with appropriate permissions
.\scripts\script_name.ps1
```

## Creating New Scripts

To create new scripts following the Limehawk Style A methodology:

1. **Review the guidelines** - Read [`limehawk_script_generation_guidelines.txt`](limehawk_script_generation_guidelines.txt)

2. **Follow the 4-phase approach**:
   - **Understand** - Define the automation task and requirements
   - **Architect** - Design operational phases and error handling
   - **Structure** - Create README block and console sections
   - **Generate** - Write production-ready code

3. **Use the quality checklist**:
   - README has all required sections (80 = rulers, 62 - dividers)
   - Filename uses snake_case convention
   - All inputs are hardcoded
   - Input validation is present
   - Console sections match operations
   - Error handling provides context
   - No secrets in output

## Contributing

Contributions are welcome! When submitting scripts:

1. **Follow Style A guidelines** - All scripts must comply with the Limehawk methodology
2. **Include comprehensive README** - Document purpose, inputs, behavior, and examples
3. **Test thoroughly** - Ensure scripts work in target RMM environments
4. **Use descriptive commit messages** - Explain what the script does and why
5. **No secrets** - Never commit API keys, passwords, or sensitive credentials

## File Naming Convention

All scripts use snake_case naming:
- ✅ `speedtest_to_superops.ps1`
- ✅ `windows_update_check.ps1`
- ✅ `chrome_installer.ps1`
- ❌ `SpeedTest-To-SuperOps.ps1`
- ❌ `WindowsUpdateCheck.ps1`

## License

This repository is provided as-is for use in RMM environments. Review and test all scripts before production deployment.

## Support

For issues or questions:
- Review the script's README block for troubleshooting guidance
- Check the Style A guidelines for scripting standards
- Open an issue for bug reports or feature requests
