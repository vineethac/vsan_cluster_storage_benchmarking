# Overview
Storage performance benchmarking of vsan clusters using diskspd and powershell.

# Input files
benchmarking_manifest.psd1  : VCSA IP, cluster name, template name, etc. are defined in this file. <br />

profile_manifest.psd1       : all storage test profiles are defined in this file. <br />

# Prerequisites
A Windows VM template should be available in the vCenter (with just C drive and diskspd.exe application should be available in C:\).<br />

![image](https://user-images.githubusercontent.com/30316226/54984601-30fc9a00-4fd5-11e9-886e-deac7f947d39.png)

As you can see above, I have a template named "template_vm_2019". This is just a Windows 2019 VM with only C drive (thin provisioned) and diskspd.exe is already copied and present in C:\ drive. <br /> 

VMtools should be pre-installed on the above Windows template VM. <br />
VMware.PowerCLI module should be installed on the local machine from where the scripts are running. <br />
Tested on PowerShell version: 5.1.14393.2515 and PowerCLI version: 11.0.0.10380590. <br />

# How to use?
Provide all necessary details in the above mentioned two input files. <br />

Invoke deploy_test_vms.ps1 (provide VCSA creds and administrator password of the Windows template VM). <br />

Once the stress-test-VMs are deployed, you can invoke start_stress_test.ps1 (provide VCSA creds and administrator password of the Windows template VM). This script will start the stroage stress test based on the profiles defined in profile_manifest.psd1 file one after another automatically and the corresponding log files will be saved to local machine as explained below. <br />

# Output logs
Logs of diskspd application from each stress-test-vm for each storage test profile will be saved in seperate folders under C:\temp on the local machine from where the script is running. <br />

![image](https://user-images.githubusercontent.com/30316226/54985328-9ef59100-4fd6-11e9-8338-da88aa2f5fe7.png)

Log file provides detailed information about read/ write IOPS, throughput, read/ write latency, etc.
