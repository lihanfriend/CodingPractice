# Required:
# Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force[CmdletBinding()]

Param(
    [string] $VMName = "win2019",
    [string] $VirtualMachineRG = "lihan",
    [Parameter(Mandatory=$true)]
    [ValidateSet('Start','Stop',IgnoreCase = $true)]
    [string] $OpCode = "",
    [string] $AzSubID = "__xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    [string] $AzClientID = "__xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    [string] $AzClientKey = "__abcdefghijklmnopqrstuvwxyz0123456789=",
    [string] $AzTenantID = "__xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
)

Function Test-AccessToAzureSubscription($azTenantID, $azClientID, $azClientKey)
{
    Write-Host "Authenticating Azure PowerShell session using Service Principal ..."
    Write-Host "    Tenant ID          : $azTenantID"
    Write-Host "    ClientID           : $azClientID"
    Write-Host "    Client Key         : $($azClientKey[0])*********************************$($azClientKey[-1])"
    $passkey = ConvertTo-SecureString $azClientKey -AsPlainText -Force
    $mycred = New-Object System.Management.Automation.PSCredential ($azClientID, $passkey)
    $account = Connect-AzAccount -ServicePrincipal -Tenant $azTenantID -Credential $mycred
    if ($null -eq $account) {
        Write-Error "Access is denied."
        return $false
    } else {
        Write-Host "PASS."
        return $true
    }
}

Function Main()
{
    $RunningPath = (Get-Location).Path
    Write-Host "Start Time: $([Datetime]::Now.ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss"))"

    # 0) Azure authentication
    $test = Test-AccessToAzureSubscription $AzTenantID $AzClientID $AzClientKey
    if ($test -eq $false) {
        Exit -1
    }

    Write-Host "Working on Azure subscription:"
    Write-Host "    Subscription ID    : $AzSubID"
    Write-Host "    Resource Group     : $VirtualMachineRG"
    Write-Host "    Virtual Machine    : $VMName"

    # 1) Show the VM to be operated
    $vms = Get-AzVM -ResourceGroupName $VirtualMachineRG
    $totalVMs = $vms.Count
    Write-Host "Found $totalVMs VMs in this resource group:"

    $vmsToBeOperated = @()
    Foreach($vm in $vms) {
        if ($VMName -ne "") {
            if (($vm.Name -Like $VMName) -or ($vm.Name.Contains($VMName))){
                $thisVMFlag = "<----"

                $oneVM = New-Object PSObject
                Add-Member -InputObject $oneVM -MemberType NoteProperty -Name 'VMName' -Value $vm.Name
                $vmsToBeOperated += $oneVM
            } else {
                $thisVMFlag = ""
            }
        }
        
        Write-Host "    $($vm.Name) $thisVMFlag"
    }

    if ($vmsToBeOperated.Count -eq 0) {
        Write-Host "No VM matches the criteria specified."
    } else {
        $randomChar = "{0}" -f $(-join ((97..122) | Get-Random -Count 1 | ForEach-Object {[char]$_}))
        Write-Host "DO YOU CONFIRM TO [$OpCode] ABOVE $($vmsToBeOperated.Count) FLAGGED VM? TYPE '$randomChar' TO CONTINUE ..." -ForegroundColor Cyan
        $keyPress = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($keyPress.Character -ne $randomChar) {
            Write-Host "This operation has been cancelled. No change was made to this resource group." -ForegroundColor Yellow
            exit 0
        }
        Write-Host "The Operation has been started ..."

        foreach($vm in $vmsToBeOperated) {
            $thisVmName = $vm.VMName
            if ($OpCode -eq "Start") {
                Start-AzVM -Name $thisVmName -ResourceGroupName $VirtualMachineRG
            } else {
                Stop-AzVM  -Name $thisVmName -ResourceGroupName $VirtualMachineRG -Force
            }

            # Assume there is only one Nic in this resource group
            $vmNic = Get-AzNetworkInterface -ResourceGroupName $VirtualMachineRG -ErrorAction Ignore
            if ($null -ne $vmNic.IpConfigurations.PublicIpAddress) {
                $publicIPName  = $vmNic.IpConfigurations.PublicIpAddress.Id.Split("/")[-1]
                $publicIP = Get-AzPublicIPAddress -ResourceGroupName $VirtualMachineRG -Name $publicIPName -ErrorAction Ignore
                $vmIPAddress = $publicIP.IpAddress
                Write-Host "Found VM's IP address: $vmIPAddress, from NIC: $($vmNic.Name)"
            } else {
                Write-Host "No public IP address is found for this VM. Exiting ..." -ForegroundColor Red
                Exit -1
            }

            $maxTry =  5 * 60
            $sleepInterval = 1
            $currentTry = 0
            Write-Host "Check the connection to the Azure VM ..."
            while ($currentTry -lt $maxTry) {
                Start-Sleep -Seconds $sleepInterval
                $isOnline = Test-NetConnection -Port 3389 -ComputerName $vmIPAddress -InformationLevel Quiet 

                if ($OpCode -eq "Start") {
                    if ($isOnline -eq $true) {
                        Write-Host "." -ForegroundColor Green
                        Write-Host "CONNECTED." -ForegroundColor Green
                        break
                    } else {
                        Write-Host "." -ForegroundColor Red
                    }
                } else {
                    if ($isOnline -eq $true) {
                        Write-Host "." -ForegroundColor Green
                    } else {
                        Write-Host "." -ForegroundColor Red
                        Write-Host "DISCONNECTED." -ForegroundColor Red
                        break
                    }
                }
            }
        }
    }

    Write-Host "End Time: $([Datetime]::Now.ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss"))"
    Exit 0
}

Main
