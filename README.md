# Overview
Storage performance benchmarking of vsan clusters using diskspd and powershell.

# Input files
benchmarking_manifest.psd1  : VCSA IP, cluster name, template name, etc. are defined in this file. <br />
profile_manifest.psd1       : all storage test profiles are defined in this file. <br />

# Prerequisites
A Windows VM template should be available in the vCenter (with just C drive and diskspd.exe application should be available in C:\).<br />
VMtools should be installed. <br />
VMware.PowerCLI module should be installed. <br />
Tested on PowerShell version: 5.1.14393.2515 and PowerCLI version: 11.0.0.10380590 <br />

# How to use?
Provide all necessary details in the above mentioned two input files. <br />
Invoke deploy_test_vms.ps1 (provide VCSA creds and administrator password of the Windows template VM). <br />
Once the stress-test-VMs are deployed, you can invoke start_stress_test.ps1 (provide VCSA creds and administrator password of the Windows template VM). <br />

# Output logs
Output logs from diskspd application from each stress-test-vm for each storage test profile will be saved under C:\temp on the local machine from where the script is running. <br />
