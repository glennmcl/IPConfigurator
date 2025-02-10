# Load Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Configuration file path
$configPath = Join-Path $PSScriptRoot "ip_configurations.json"

# Function to load saved configurations
function Load-Configurations {
    if (Test-Path $configPath) {
        return Get-Content $configPath | ConvertFrom-Json
    }
    return @()
}

# Function to save configurations
function Save-Configuration {
    param (
        $configs,
        $newConfig
    )
    
    # Convert configs to array if it isn't already
    if ($null -eq $configs) {
        $configs = @()
    }
    elseif ($configs -isnot [Array]) {
        $configs = @($configs)
    }
    
    # Remove existing config with same name if it exists
    $configs = @($configs | Where-Object { $_.Name -ne $newConfig.Name })
    
    # Add new config
    $configs = $configs + @($newConfig)
    
    # Save to file
    $configs | ConvertTo-Json | Set-Content $configPath
    return $configs

}

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'IP Configurator'
$form.Size = New-Object System.Drawing.Size(400,400)
$form.StartPosition = 'CenterScreen'

# Saved Configurations Dropdown
$labelSavedConfigs = New-Object System.Windows.Forms.Label
$labelSavedConfigs.Location = New-Object System.Drawing.Point(10,20)
$labelSavedConfigs.Size = New-Object System.Drawing.Size(100,20)
$labelSavedConfigs.Text = 'Saved Configs:'
$form.Controls.Add($labelSavedConfigs)

$comboSavedConfigs = New-Object System.Windows.Forms.ComboBox
$comboSavedConfigs.Location = New-Object System.Drawing.Point(120,20)
$comboSavedConfigs.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($comboSavedConfigs)

# Load saved configurations
$savedConfigs = Load-Configurations
foreach ($config in $savedConfigs) {
    $comboSavedConfigs.Items.Add($config.Name)
}

# Configuration Name
$labelConfigName = New-Object System.Windows.Forms.Label
$labelConfigName.Location = New-Object System.Drawing.Point(10,60)
$labelConfigName.Size = New-Object System.Drawing.Size(100,20)
$labelConfigName.Text = 'Config Name:'
$form.Controls.Add($labelConfigName)

$textBoxConfigName = New-Object System.Windows.Forms.TextBox
$textBoxConfigName.Location = New-Object System.Drawing.Point(120,60)
$textBoxConfigName.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($textBoxConfigName)

# IP Address
$labelIP = New-Object System.Windows.Forms.Label
$labelIP.Location = New-Object System.Drawing.Point(10,100)
$labelIP.Size = New-Object System.Drawing.Size(100,20)
$labelIP.Text = 'IP Address:'
$form.Controls.Add($labelIP)

$textBoxIP = New-Object System.Windows.Forms.TextBox
$textBoxIP.Location = New-Object System.Drawing.Point(120,100)
$textBoxIP.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($textBoxIP)

# Subnet Mask
$labelSubnet = New-Object System.Windows.Forms.Label
$labelSubnet.Location = New-Object System.Drawing.Point(10,140)
$labelSubnet.Size = New-Object System.Drawing.Size(100,20)
$labelSubnet.Text = 'Subnet Mask:'
$form.Controls.Add($labelSubnet)

$textBoxSubnet = New-Object System.Windows.Forms.TextBox
$textBoxSubnet.Location = New-Object System.Drawing.Point(120,140)
$textBoxSubnet.Size = New-Object System.Drawing.Size(200,20)
$textBoxSubnet.Text = '255.255.255.0'
$form.Controls.Add($textBoxSubnet)

# Gateway
$labelGateway = New-Object System.Windows.Forms.Label
$labelGateway.Location = New-Object System.Drawing.Point(10,180)
$labelGateway.Size = New-Object System.Drawing.Size(100,20)
$labelGateway.Text = 'Gateway:'
$form.Controls.Add($labelGateway)

$textBoxGateway = New-Object System.Windows.Forms.TextBox
$textBoxGateway.Location = New-Object System.Drawing.Point(120,180)
$textBoxGateway.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($textBoxGateway)

# Network Adapter Dropdown
$labelAdapter = New-Object System.Windows.Forms.Label
$labelAdapter.Location = New-Object System.Drawing.Point(10,220)
$labelAdapter.Size = New-Object System.Drawing.Size(100,20)
$labelAdapter.Text = 'Adapter:'
$form.Controls.Add($labelAdapter)

$comboAdapter = New-Object System.Windows.Forms.ComboBox
$comboAdapter.Location = New-Object System.Drawing.Point(120,220)
$comboAdapter.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($comboAdapter)

# Populate adapter list
Get-NetAdapter | ForEach-Object {
    $comboAdapter.Items.Add($_.Name)
}
if ($comboAdapter.Items.Count -gt 0) {
    $comboAdapter.SelectedIndex = 0
}

# Save Configuration Button
$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Location = New-Object System.Drawing.Point(120,260)
$saveButton.Size = New-Object System.Drawing.Size(200,23)
$saveButton.Text = 'Save Current Configuration'
$form.Controls.Add($saveButton)

# Load Configuration Handler
$comboSavedConfigs.Add_SelectedIndexChanged({
    $selectedConfig = $savedConfigs | Where-Object { $_.Name -eq $comboSavedConfigs.SelectedItem }
    if ($selectedConfig) {
        $textBoxConfigName.Text = $selectedConfig.Name
        $textBoxIP.Text = $selectedConfig.IPAddress
        $textBoxSubnet.Text = $selectedConfig.SubnetMask
        $textBoxGateway.Text = $selectedConfig.Gateway
        if ($comboAdapter.Items.Contains($selectedConfig.AdapterName)) {
            $comboAdapter.SelectedItem = $selectedConfig.AdapterName
        }
    }
})

# Save Configuration Handler
$saveButton.Add_Click({
    if ([string]::IsNullOrWhiteSpace($textBoxConfigName.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a configuration name", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    $newConfig = @{
        Name = $textBoxConfigName.Text
        IPAddress = $textBoxIP.Text
        SubnetMask = $textBoxSubnet.Text
        Gateway = $textBoxGateway.Text
        AdapterName = $comboAdapter.SelectedItem
    }

    $savedConfigs = Save-Configuration $savedConfigs $newConfig

    # Refresh the saved configurations dropdown
    $comboSavedConfigs.Items.Clear()
    foreach ($config in $savedConfigs) {
        $comboSavedConfigs.Items.Add($config.Name)
    }

    [System.Windows.Forms.MessageBox]::Show("Configuration saved successfully!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})

# OK Button
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(120,300)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'Apply'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

# Cancel Button
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(220,300)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

# Show the form
$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        [System.Windows.Forms.MessageBox]::Show("This script must be run as Administrator", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        exit 1
    }

    try {
        # Get the network adapter
        $adapter = Get-NetAdapter | Where-Object { $_.Name -eq $comboAdapter.SelectedItem } | Select-Object -First 1
        
        if ($null -eq $adapter) {
            [System.Windows.Forms.MessageBox]::Show("Network adapter not found", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            exit 1
        }
        
        # Convert subnet mask to prefix length
        $maskBytes = $textBoxSubnet.Text.Split('.')
        $maskBits = 0
        foreach ($byte in $maskBytes) {
            $bits = [Convert]::ToString($byte, 2)
            $maskBits += ($bits.ToCharArray() | Where-Object {$_ -eq '1'} | Measure-Object).Count
        }
        
        # Remove existing IP addresses
        Remove-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        
        # Remove existing gateway
        Remove-NetRoute -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        
        # Set new IP address configuration
        New-NetIPAddress -InterfaceIndex $adapter.ifIndex `
                        -AddressFamily IPv4 `
                        -IPAddress $textBoxIP.Text `
                        -PrefixLength $maskBits `
                        -DefaultGateway $textBoxGateway.Text

        [System.Windows.Forms.MessageBox]::Show(
            "Successfully changed IP configuration:`n`n" +
            "IP Address: $($textBoxIP.Text)`n" +
            "Subnet Mask: $($textBoxSubnet.Text)`n" +
            "Gateway: $($textBoxGateway.Text)`n" +
            "Adapter: $($adapter.Name)",
            "Success",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        exit 1
    }
}
