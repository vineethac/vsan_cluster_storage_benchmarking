# Module Name  : Deploy Test VMs
# Script Name  : deploy_test_vms.ps1
# Author       : Vineeth A.C.
# Version      : 0.1
# Last Modified: 24/03/2019 (ddMMyyyy)

Begin {
    #Ignore invalid certificate
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Verbose

    #Importing manifest file
    $config_data = Import-PowerShellDataFile -Path .\benchmarking_manifest.psd1 -ErrorAction Stop
    
    try {
        #Connect to VCSA
        Write-Verbose -Message "Connecting to vCenter $($config_data.vCenter). Provide vCenter creds!" -Verbose
        Connect-VIServer -Server $config_data.vcenter -ErrorAction Stop
    }
    catch {
        Write-Error "Incorrect vCenter creds!" -ErrorAction Stop
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
Process {
    $vms = get-vm stress-test-vm*
    
    Write-Warning -Message "About to shutdown the following stress-test-vms:`n $($vms.Name)"
    $vms | Shutdown-VMGuest -Confirm

    foreach ($vm in $vms) { do { $stat = (Get-vm $vm).PowerState; write-host "$vm $stat"; Start-Sleep 2 } until ($stat -eq 'PoweredOff') }
    
    Write-Warning -Message "About to permanently delete the following stress-test-vms:`n $($vms.Name)"
    $vms | Remove-VM -DeletePermanently -Confirm
}
End{
    #Disconnect session
    Disconnect-VIServer $config_data.vCenter -Confirm:$false
}