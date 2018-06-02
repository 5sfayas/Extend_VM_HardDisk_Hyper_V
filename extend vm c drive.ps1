$path = Read-Host "provide path or list of VM file EG: C:vm.txt"
Write-Host "enter the vm user password (valid user name and password for login VMs)"
$UserVM = zss\fayasak
$PasswordVM= Read-Host -Prompt " Guest Password for VM `n"
$Crendential= New-Object System.Management.Automation.PSCredential ($UserVM, $PasswordVM)


if ($path -eq "NO")
{
    Write-Host "finding the list of VM and past to a path"
    Get-Vm | Where ($_.State -eq 'Running')|Select-Object -Property name | Export -CSV "C:vm.csv"
}

[int]$add=Read-host "Please give how much (extra) disk capacity you need in GB :"

else
{
    $VMs = Get-Content $path
   Foreach ($VM in $VMs)
    {
		#Get the VM total disk size
      $total=Get-VM -VMName $VM | Select-Object VMId | Get-VHD | select @{label='Size(GB)';expression={$_.filesize/1gb -as [int]}}
      #$total=get-vm -VMName $Vm | select -expand HardDrives | select -first 1 |select @{label='Size(GB)';expression={$_.filesize/1gb -as [int]}}
     
	 #ideas is total size after adding does not go beyond 100GB
      $y = $total+$add
      $vhdxpath=Get-VM | Select-Object VMId | Get-VHD | select path
        if ($y -le 100)
        {
            #get-vm -VMName $VM | select -expand HardDrives | select -first 1 | resize-vhd -SizeBytes $add –passthru -whatif
            #What if: Performing operation "Resize-VHD" on Target "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\Win7-2.vhd".
            Resize-VHD -Path $vhdxpath -SizeBytes $add

            #remote login to vm to expand disk size
            
            $pss=New-PSSession -VMName $VM -Credential $Crendential
            
            Invoke-Command -Session $pss -VMName $VM -ScriptBlock {'Update-Disk -Number 0;$m=(Get-PartitionSupportedSize -DriveLetter c).sizeMax;Resize-Partition -DriveLetter c -Size $m' } 
            Remove-PSSession $s
        }
    
    }

}
