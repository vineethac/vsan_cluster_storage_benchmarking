# Module Name  : Start Stress Test
# Script Name  : start_stress_test.ps1
# Author       : Vineeth A.C.
# Version      : 0.1
# Last Modified: 24/03/2019 (ddMMyyyy)

Begin {
    #Ignore invalid certificate
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Verbose

    #Importing manifest file
    $config_data = Import-PowerShellDataFile -Path .\benchmarking_manifest.psd1 -ErrorAction Stop
    $profile_data = Import-PowerShellDataFile -Path .\profile_manifest.psd1 -ErrorAction Stop
    
    try {
        #Connect to VCSA
        Write-Verbose -Message "Connecting to vCenter $($config_data.vCenter). Provide vCenter creds!" -Verbose
        Connect-VIServer -Server $config_data.vCenter -ErrorAction Stop
    }
    catch {
        Write-Error "Incorrect vCenter creds!" -ErrorAction Stop
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }

    #Cluster details
    $cluster_name = Get-Cluster -Name $config_data.cluster_name
    $hosts_in_cluster = $cluster_name | Get-VMHost
      
    #List of ESXi hostnames
    $esxi_list = $hosts_in_cluster.Name

    #DRS check
    if ("$($cluster_name.DrsEnabled)" -eq 'True') {
        #Disconnect session
        Disconnect-VIServer $config_data.vCenter -Confirm:$false
        Write-Error -Message "Disable DRS and re-run the script!" -ErrorAction Stop
    }
    
    #Collecting stress-test-vm guest OS creds
    try {
        Write-Verbose -Message "Collecting stress-test-vm guest OS Creds" -Verbose
        $guest_os_creds = Get-Credential -Message "Enter stress-test-vm guest OS Creds" -UserName administrator
    }
    catch {
        Write-Error -Message "[EndRegion] Failed collecting gateway creds. Exiting!" -Verbose -ErrorAction Stop
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
        
}

Process {
    #Get all profile data keys
    $all_keys = $profile_data.GetEnumerator() | ForEach-Object {$_.Key} | Sort-Object

    #Parent folder for logs for each script run
    $parent_folder = (Get-Date).tostring("dd-MM-yyyy-hh-mm-ss")

    #For reach profile defined in manifest2 do following
    for ($i=0; $i -lt $profile_data.Keys.Count; $i++) {
        
        #Verify status of VM tools for all VMs
        Write-Verbose -Message "Verify status of VM tools on all stress-test-vms" -Verbose
        $vms = get-vm stress-test-vm*
        foreach ($vm in $vms) { do { $stat = (Get-vm $vm).ExtensionData.Guest.ToolsStatus; write-host "$vm $stat"; Start-Sleep 2 } until ($stat -eq 'toolsOk') }
        
        #Invoke diskspd on each stress-test-vm
        get-vm -Name stress-test-vm* | ForEach-Object {Invoke-VMScript -VM $_ -ScriptText  "C:\diskspd.exe -b$($profile_data.$($all_keys[$i]).block_size) -d$($profile_data.$($all_keys[$i]).duration_in_sec) -t$($profile_data.$($all_keys[$i]).threads) -o$($profile_data.$($all_keys[$i]).OIO) -h -$($profile_data.$($all_keys[$i]).access_pattern) -w$($profile_data.$($all_keys[$i]).write_percent) -L -Z500M -c$($profile_data.$($all_keys[$i]).workload_file_size) E:\io_stress.dat > C:\$_.txt" -ScriptType Powershell -ToolsWaitSecs 60 -GuestCredential $guest_os_creds -RunAsync -Verbose -confirm:$false}
        
        #Test run time
        $test_duration = $profile_data.$($all_keys[$i]).duration_in_sec

        #Waiting till test duration
        Write-Verbose "$($all_keys[$i]): Storage stress test in progress. Test duration: $($profile_data.$($all_keys[$i]).duration_in_sec) seconds. Please wait!" -Verbose

        Start-Sleep $test_duration -Verbose

        Write-Verbose -Message "$($all_keys[$i]): Storage stress test completed"
        Start-Sleep 60 -Verbose
        
        #Copy diskspd logs from stress-test-vms to local machine
        Write-Verbose "Copying diskspd logs to local machine" -Verbose
        $foldername = (Get-Date).tostring("dd-MM-yyyy-hh-mm-ss")+"-"+$all_keys[$i]
        get-vm -Name stress-test-vm* | ForEach-Object {Copy-VMGuestFile -Source c:\$_.txt -Destination c:\temp\$parent_folder\$foldername\ -VM $_ -GuestToLocal -GuestCredential $guest_os_creds -Force -ToolsWaitSecs 120} -Verbose
        
        Start-Sleep 60 -Verbose
        Write-Verbose "Restarting all stress-test-vms"
        Get-VM -Name stress-test-vm* -Verbose | Restart-VMGuest -Verbose
        Start-Sleep 60 -Verbose
    }
}

End {
    Disconnect-VIServer $config_data.vCenter -Confirm:$false
}
