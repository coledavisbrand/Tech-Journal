function 480Banner()
{
    $banner = @"
    ____  _____ ____ _  _    ___   ___        _   _ _____ ___ _     ____                  
    / ___|| ____/ ___| || |  ( _ ) / _ \      | | | |_   _|_ _| |   / ___|                 
    \___ \|  _|| |   | || |_ / _ \| | | |_____| | | | | |  | || |   \___ \                 
     ___) | |__| |___|__   _| (_) | |_| |_____| |_| | | |  | || |___ ___) |                
    |____/|_____\____|  |_|  \___/ \___/       \___/  |_| |___|_____|____/                 
           _ _   _           _                            __      _ _     _         _      
      __ _(_) |_| |__  _   _| |__   ___ ___  _ __ ___    / /__ __| | |__ (_)_______| | ___ 
     / _` | | __| '_ \| | | | '_ \ / __/ _ \| '_ ` _ \  / / __/ _` | '_ \| |_  /_  / |/ _ \
    | (_| | | |_| | | | |_| | |_) | (_| (_) | | | | | |/ / (_| (_| | |_) | |/ / / /| |  __/
     \__, |_|\__|_| |_|\__,_|_.__(_)___\___/|_| |_| |_/_/ \___\__,_|_.__/|_/___/___|_|\___|
     |___/                                                                                 
"@
Write-Host $banner
}
function 480Connect([string] $server)
{
    # Check if already connected to a vCenter server
    $con = $global:DefaultVIServer
    if ($con){
        $msg = "Already connected to {0}`n" -f $con
        Write-Host $msg -ForegroundColor Green
    } else {
        # Connect to the specified vCenter server
        $con = Connect-VIServer -Server $server
    }
    Write-Host "`n----------------------------------------"
}
function 480Config([string]$configPath) 
{
    $conf = $null
    # Pull the config path, and send a message if there is no config file found
    if(Test-Path $configPath)
    {
        # Convert from json to variables
        $conf = Get-Content -Raw -Path $configPath | ConvertFrom-Json
        $msg = "`nUsing Configuration at {0}" -f $configPath
        Write-Host $msg -ForegroundColor Green
    }
    else
    {
        # Return a yellow alert message if no config file is found
        Write-Host -ForegroundColor Yellow "No configuration file found at $configPath"
    }
    return $conf
}
function 480pickVM()
{
    # Prompt the user to select a VM
    Write-Host "Select a VM:"
    $selectedVM = $null
    try {
        $vms = Get-VM -Location $conf.vmFolder
        $index = 1
        foreach($vm in $vms)
        {
            Write-Host [$index] $vm.name
            $index++
        }
        $pickIndex = Read-Host "Which VM [X] would you like to select?"
        
        # Check if the input is a valid number
        if (-not [int]::TryParse($pickIndex, [ref]$null) -or $pickIndex -lt 1 -or $pickIndex -gt $vms.Count) {
            Write-Host "Invalid input. Please enter a valid number.`n" -ForegroundColor Yellow
            # Prompt the user to try again if they gave an invalid input
            $pickIndex = Read-Host "Which VM [X] would you like to select?"
        }
        
        # Return the selected VM
        $selectedVM = $vms[$pickIndex - 1]
        $chosenVM = $selectedVM.name
        Write-Host "`nYou have chosen" -NoNewline
        Write-Host " $chosenVM" -ForegroundColor Green
        Write-Host "`----------------------------------------"
        return $selectedVM
    }
    catch {
        # Return red error message if the folder is invalid
        Write-Host "Invalid folder: $conf.vmFolder" -ForegroundColor Red
    }
}
function 480pickDS()
{
    # Ask the user to pick a datastore
    $datastores = Get-Datastore | Where-Object { $_.Name -ne $conf.datastore }

    # Display available datastores to the user
    Write-Host "Choose from these available datastores:"
    for ($i = 0; $i -lt $datastores.Count; $i++) {
        $index = $i + 1
        Write-Host "[$index] $($datastores[$i].Name)"
    }

    # Prompt the user to pick a datastore index
    $datastoreIndex = Read-Host "Which datastore [X] would you like to select? (default: $($conf.datastore))"

    # Set the selected datastore based on user input
    if ([string]::IsNullOrEmpty($datastoreIndex)) {
        $datastore = $conf.datastore
    } else {
        $datastore = $datastores[$datastoreIndex - 1].Name

    # Check if the input is a valid number
    if (-not [int]::TryParse($datastoreIndex, [ref]$null) -or $datastoreIndex -lt 1 -or $datastoreIndex -gt $datastore.Count) {
        Write-Host "Invalid input. Please enter a valid number.`n" -ForegroundColor Yellow
        
        # Prompt the user to try again if they gave an invalid input
        $datastoreIndex = Read-Host "Which datastore [X] would you like to select? (default: $($conf.datastore))"
    }
    }

    # Return the chosen datastore
    Write-Host "`nYou have chosen" -NoNewline
    Write-Host " $datastore" -ForegroundColor Green
    Write-Host "----------------------------------------"
    return $datastore
}

function 480pickSnapshot()
{   
    # Display available snapshots for the selected VM
    Write-Host "Displaying available snapshots for $($selectedVM.Name):"
    $snapshots = $selectedVM | Get-Snapshot | Select-Object -ExpandProperty Name

    # Iterate through the snapshots and display them to the user
    foreach ($snapshot in $snapshots) {
        $index = $snapshots.IndexOf($snapshot) + 1
        Write-Host "[$index] $snapshot"
    }

    # Prompt the user to select a snapshot
    $snapshotIndex = Read-Host "Which snapshot [X] would you like to select? (default: $($conf.defaultSnapshot))"

    # Set the selected snapshot based on user input
    if ([string]::IsNullOrEmpty($snapshotIndex)) {
        $snapshotName = $conf.defaultSnapshot
    } else {
        # Check if the input is a valid number
        if (-not [int]::TryParse($snapshotIndex, [ref]$null) -or $snapshotIndex -lt 1 -or $snapshotIndex -gt $snapshots.Count) {
            Write-Host "Invalid input. Please enter a valid number.`n" -ForegroundColor Yellow

            # Prompt the user to try again if they gave an invalid input
            $snapshotIndex = Read-Host "Which snapshot [X] would you like to select? (default: $($conf.defaultSnapshot))"
            
            if ([string]::IsNullOrEmpty($snapshotIndex)) {
                $snapshotName = $conf.defaultSnapshot
            } else {
                $snapshotName = $snapshots[$snapshotIndex - 1]
            }
        } else {
            $snapshotName = $snapshots[$snapshotIndex - 1]
        }
    }

    # Return the chosen snapshot
    Write-Host "`nYou have chosen" -NoNewline
    Write-Host " $snapshotName" -ForegroundColor Green
    Write-Host "----------------------------------------"
    return $snapshotName
}

function 480pickHost()
{
    # Prompt the user if they want to change the host
    Write-Host "Default host: $($conf.esxiHost)"

    $validInput = $false
    while (-not $validInput) {
        $changeHost = Read-Host "Do you want to change the host? (y/N)"

        # Check if the user wants to change the host
        if ($changeHost -eq "y") {
            # Prompt the user for the IP of the host they want to select
            $hostName = Read-Host "Enter the IP of the host you would like to select"
            $esxiHost = $hostName
            $validInput = $true
        } elseif ($changeHost -eq "n" -or [string]::IsNullOrEmpty($changeHost)) {
            # Use the default host specified in the configuration
            $esxiHost = $conf.esxiHost
            $validInput = $true
        } else {
            Write-Host "Invalid input. Please enter 'y' to change the host or 'n' to use the default host.`n" -ForegroundColor Yellow
        }
    }

    # Return the chosen host
    Write-Host "`nYou have chosen" -NoNewline
    Write-Host " $esxiHost" -ForegroundColor Green
    Write-Host "----------------------------------------"
    return $esxiHost
}

function 480fullClone([string] $vm, $snap, $esxihost, $ds)
{
    # Prompt the user if they want to create a new full clone
    $createFullClone = Read-Host "Do you want to create a new full clone? (Y/n)"

    if ([string]::IsNullOrEmpty($createFullClone) -or $createFullClone -eq "Y") {
        # Prompt the user for the new full clone name
        $vmName = Read-Host "Enter the name of the new full clone VM"
        
        # Build the temporary VM
        $linkedVM = New-VM -LinkedClone -Name "$vmName.temp" -VM $selectedVM -ReferenceSnapshot $selectedSnap -VMHost $selectedHost -Datastore $selectedDS

        # Build the new permanent VM
        $newVM = New-VM -Name $vmName -VM $linkedVM -VMHost $selectedHost -Datastore $selectedDS

        # Take a new snapshot
        $newSnap = "Base"
        New-Snapshot -VM $newVM  -Name $newSnap

        # Delete original temporary VM
        $linkedVM | Remove-VM

        # Print success report
        Write-Host "`nNew VM named $newVM has successfully been created" -ForegroundColor Green
        Write-Host "New snapshot named $newSnap has successfully been created" -ForegroundColor Green

    } elseif ($createFullClone -eq "n" -or $createFullClone -eq "N") {
        Write-Host "Exiting without creating a new full clone." -ForegroundColor Yellow
        
    } else {
        Write-Host "Invalid input. Exiting without creating a new full clone." -ForegroundColor Yellow
    }
}

function 480newNet()
{
    # Prompt the user if they want to create a new network
    $promptNewNetwork = Read-Host "Would you like to create a new network? (Y/n)"

    if ([string]::IsNullOrEmpty($promptNewNetwork) -or $promptNewNetwork -eq "Y") {
        # Create a new network (virtual switch and portgroup
        $newNetwork = Read-Host "Enter the name of the new network"
        New-VirtualSwitch -Name $newNetwork -VMHost "192.168.7.16"
        New-VirtualPortGroup -VirtualSwitch $newNetwork -Name $newNetwork

        # Print success report
        Write-Host "`nNew network named $newNetwork has successfully been created, review details above" -ForegroundColor Green

    } elseif ($promptNewNetwork -eq "n" -or $promptNewNetwork -eq "N") {
        # Print exit message and exit the script
        Write-Host "Exiting..." -ForegroundColor Yellow
        Exit

    } else {
        Write-Host "Invalid input. Please enter 'Y' to create a new network or 'N' to skip." -ForegroundColor Yellow
        480newNet  # Call the 480newNet function to allow the user to try again
    }
}

function 480getIP()
{
# Thanks users "mcity" and "LucD" on the forum linked below for helping with this function
# https://communities.vmware.com/t5/VMware-PowerCLI-Discussions/Get-List-of-IP-addresses-for-each-VM/td-p/2238590

    # Prompt the user if they want to see networking details
    $promptDetails = Read-Host "Would you like to see networking details of a certain machine? (Y/n)"

    if ([string]::IsNullOrEmpty($promptDetails) -or $promptDetails -eq "Y") {
        # Prompt the user to select a VM
        $getName = Read-Host "Enter a VM name to see details (ENTER for all)"

            # If $getName is empty or null, retrieve networking details for all VMs
            if([string]::IsNullOrEmpty($getName)) {
                $outputDetails = foreach($vm in Get-VM){
                    $obj = [ordered]@{
                        Name = $vm.Name
                        "MAC Address" = (Get-NetworkAdapter -VM $vm | Select-Object -ExpandProperty MacAddress -First 1)
                        "IP Address" = $vm.Guest.IPAddress[0]
                    }              
                    New-Object PSObject -Property $obj                           
                }
                $outputDetails
            }

            else {
                #Return the networking details of the selected VM
                Get-VM -Name $getName | Select-Object Name, @{N="MAC Address";E={@(Get-NetworkAdapter -VM $getName | Select-Object -ExpandProperty MacAddress -First 1)}}, @{N="IP Address";E={@($_.guest.IPAddress[0])}}
            }

        } elseif ($promptDetails -eq "n" -or $promptDetails -eq "N") {
            Write-Host "Exiting..." -ForegroundColor Yellow
            Exit

        } else {
            Write-Host "Invalid input. Please enter 'Y' to see details or 'N' to skip." -ForegroundColor Yellow
            480getIP  # Call the 480newNet function to allow the user to try again
        }
}

function 480startStop()
{
    # Prompt the user if they want to start or stop a VM
    Write-Host "`nThis is the current powerstate of the VMs"
    Get-VM

    $promptStartStop = Read-Host "`nWould you like to start or stop a VM? (Y/n)"

    if ([string]::IsNullOrEmpty($promptStartStop) -or $promptStartStop -eq "Y") {
        # Prompt the user to select a VM
        $vmName = Read-Host "Enter the name of the VM you would like to start or stop"

        # Prompt the user to select an action
        $action = Read-Host "Would you like to start or stop the VM? (start/stop)"

        # Start or stop the selected VM based on user input
        if ($action -eq "start") {
            Start-VM -VM $vmName
            Write-Host "`n$vmName has been started" -ForegroundColor Green

        } elseif ($action -eq "stop") {
            Stop-VM -VM $vmName
            Write-Host "`n$vmName has been stopped" -ForegroundColor Green

        } else {
            Write-Host "Invalid input. Please enter 'start' or 'stop'." -ForegroundColor Yellow
            480startStop  # Call the 480startStop function to allow the user to try again
        }

    } elseif ($promptStartStop -eq "n" -or $promptStartStop -eq "N") {
        Write-Host "Exiting..." -ForegroundColor Yellow
        Exit

    } else {
        Write-Host "Invalid input. Please enter 'Y' to start or stop a VM or 'N' to skip." -ForegroundColor Yellow
        480startStop  # Call the 480startStop function to allow the user to try again
    }
}

function 480setNetwork()
{
    # Prompt the user if they want to change the network of a VM
    $promptChangeNetwork = Read-Host "Would you like to change the network of a VM? (Y/n)"

    if ([string]::IsNullOrEmpty($promptChangeNetwork) -or $promptChangeNetwork -eq "Y") {
        # Prompt the user to select a VM
        $vmName = Read-Host "Enter the name of the VM you would like to change the network for"
        Write-Host "`nThe current network adapter(s) for $vmName"
        Get-NetworkAdapter -VM $vmName
        $networkAdapters = Get-NetworkAdapter -VM $vmName

        # Prompt the user to select a network adapter
        $adapterIndex = Read-Host "`nEnter the index of the network adapter you would like to change (1 to $($networkAdapters.Count))"

        if ($adapterIndex -ge 1 -and $adapterIndex -le $networkAdapters.Count) {
            $selectedAdapter = $networkAdapters[$adapterIndex - 1]

            # Prompt the user to select a network
            $networkName = Read-Host "`nEnter the name of the network you would like to change to"

            # Change the network of the selected network adapter
            $selectedAdapter | Set-NetworkAdapter -NetworkName $networkName
            Write-Host "`n$vmName network adapter $($adapterIndex) has been set to $networkName" -ForegroundColor Green
        } else {
            Write-Host "Invalid input. Please enter a valid index." -ForegroundColor Yellow
        }

    } elseif ($promptChangeNetwork -eq "n" -or $promptChangeNetwork -eq "N") {
        Write-Host "Exiting..." -ForegroundColor Yellow
        Exit

    } else {
        Write-Host "Invalid input. Please enter 'Y' to change the network or 'N' to skip." -ForegroundColor Yellow
        480setNetwork  # Call the 480setNetwork function to allow the user to try again
    }
}

function 480setWinIP()
{
    # Prompt the user for username and password
    $username = Read-Host "Enter your username"
    $password = Read-Host "Enter your password" -AsSecureString

    # Prompt the user to select a VM
    $vmName = Read-Host "Enter the name of the VM you would like to set the IP for"

    # Prompt the user to enter the IP address, netmask, gateway, and name server
    $ipAddress = Read-Host "Enter the IP address"
    $netmask = Read-Host "Enter the netmask"
    $gateway = Read-Host "Enter the gateway"
    $nameServer = Read-Host "Enter the name server"
    $adapter = Read-Host "Enter the adapter name"
     
    # Create a script block with the code to set the IP address, netmask, and gateway
    $scriptText = @'
    netsh interface ip set address #adapter static #ipAddress #netmask #gateway
    netsh interface ipv4 add dnsserver #adapter #nameServer index=1
    netsh interface ipv4 add dnsserver #adapter #gateway index=2
'@

    # Invoke the script block on the VM using Invoke-VMScript
    $scriptText = $scriptText.Replace('#adapter',$adapter).Replace('#ipAddress',$ipAddress).Replace('#netmask',$netmask).Replace('#gateway',$gateway).Replace('#nameServer',$nameServer)
    Invoke-VMScript -VM $vmName -ScriptText $scriptText -GuestUser $username -GuestPassword $password -ScriptType PowerShell
}
