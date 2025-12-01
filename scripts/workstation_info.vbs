' ==============================================================================
' SCRIPT : Workstation Information Popup                                v1.0.0
' FILE   : workstation_info.vbs
' ==============================================================================
' PURPOSE:
'   Displays a popup message box showing system information to the end user.
'   Designed to be triggered from the RMM tray icon for user self-service.
'
' COLLECTS:
'   - Operating System name and version
'   - Computer name and current user
'   - Serial number
'   - CPU name and core count
'   - Total RAM
'   - Network adapter info (name, IP, MAC)
'
' PREREQUISITES:
'   - Windows 10/11
'   - No special privileges required
'
' CHANGELOG:
'   2024-12-01 v1.0.0  Initial release - migrated from SuperOps
' ==============================================================================

Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")

' Get Operating System Information
Set colOS = objWMIService.ExecQuery("SELECT * FROM Win32_OperatingSystem")
For Each objOS in colOS
    os_name = objOS.Caption
    os_version = objOS.Version
Next

' Get Computer Information
Set colComputer = objWMIService.ExecQuery("SELECT * FROM Win32_ComputerSystem")
For Each objComputer in colComputer
    computer_name = objComputer.Name
    current_user = CreateObject("WScript.Network").UserName
Next

' Get CPU Information
Set colCPU = objWMIService.ExecQuery("SELECT * FROM Win32_Processor")
For Each objCPU in colCPU
    cpu_name = objCPU.Name
    cpu_cores = objCPU.NumberOfCores
Next

' Get Memory Information
Set colMemory = objWMIService.ExecQuery("SELECT * FROM Win32_PhysicalMemory")
total_ram = 0
For Each objMemory in colMemory
    total_ram = total_ram + objMemory.Capacity
Next
total_ram = FormatNumber(total_ram / 1024^3, 2)

' Get Network Adapter Information
Set colNetworkAdapters = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled=True")
network_adapters = ""
For Each objNetworkAdapter in colNetworkAdapters
    network_adapters = network_adapters & "Adapter: " & objNetworkAdapter.Description & vbCrLf
    network_adapters = network_adapters & "IP: " & objNetworkAdapter.IPAddress(0) & vbCrLf
    network_adapters = network_adapters & "MAC: " & objNetworkAdapter.MACAddress & vbCrLf & vbCrLf
Next

' Get Serial Number
Set colBIOS = objWMIService.ExecQuery("SELECT * FROM Win32_BIOS")
For Each objBIOS in colBIOS
    serial_number = objBIOS.SerialNumber
Next

' Display the workstation information in a message box
MsgBox "=== Workstation Information ===" & vbCrLf & vbCrLf & _
    "=== Operating System ===" & vbCrLf & _
    "Name: " & os_name & vbCrLf & _
    "Version: " & os_version & vbCrLf & vbCrLf & _
    "=== Computer ===" & vbCrLf & _
    "Name: " & computer_name & vbCrLf & _
    "User: " & current_user & vbCrLf & _
    "Serial: " & serial_number & vbCrLf & vbCrLf & _
    "=== Hardware ===" & vbCrLf & _
    "CPU: " & cpu_name & vbCrLf & _
    "Cores: " & cpu_cores & vbCrLf & _
    "RAM: " & total_ram & " GB" & vbCrLf & vbCrLf & _
    "=== Network ===" & vbCrLf & _
    network_adapters, _
    vbInformation + vbOKOnly, "Workstation Information"
