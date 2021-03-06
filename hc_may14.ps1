

 

#$path = 'C:\Users\in0079d6\Desktop\Technicolor_script'

$name=read-host "whats your name "
write-host "Hi " $name "Iam automated HEALTH CHECKER .I WILL FIND AND FIX ANAMOLIES BASED ON YOUR RESPONSE IN YES AND NO.CHECK FOR YELLOW LINES" -ForegroundColor Gray

$head = @'

<style>

body { background-color:#dddddd;

       font-family:Tahoma;

       font-size:12pt; }

td, th { border:1px solid black;

         border-collapse:collapse; }

th { color:white;

     background-color:black; }

table, tr, td, th { padding: 2px; margin: 0px }

table { margin-left:50px; }

</style>

'@

$clusters = Import-Csv -path  "C:\users\in0079d6\Desktop\Technicolor_script\EU_tc_CLUSTER.csv"

$fragments = @()
$esxi_names_EU = @()

foreach ($line in $clusters) {

   $cluster = Get-Cluster -name $line.clustername

   $vms = Get-VM -location $cluster

   $esx = Get-VMHost -Location $cluster

 



   $esxi_names_EU += $esx.name
   #$ssh_running_remote = Get-VMHostService -VMHost $esx | Where-Object { $_.key -eq "TSM-SSH" }
   #$fragments += $ssh_running_remote|ConvertTo-Html -Property name -Fragment -PreContent '<h2>remote_ssh</h2>'|out-string

   $fragments += Get-Cluster -name $cluster |

  Select name |

   ConvertTo-Html -Property name -Fragment -PreContent '<h2>clustername </h2>' |

   Out-String


<#      $Report=@()
foreach ($e in $esx){
    foreach($triggered in $e.TriggeredAlarmState){
        If ($triggered.OverallStatus -like "red" ){
            $lineitem={} | Select Name, AlarmInfo
            $alarmDef = Get-View -Id $triggered.Alarm
            $lineitem.Name = $e.Name
            $lineitem.AlarmInfo = $alarmDef.Info.Name
            $Report+=$lineitem
        } 
    }
}


$fragments += $Report |

 

   ConvertTo-Html -PreContent '<h2>alarm_report </h2>' |

   Out-String
   #>



   foreach ($e in $esx)

{

   foreach ($triggered in $e.ExtensionData.TriggeredAlarmState)

   {

   If ($triggered.OverallStatus -like "red" ){
   Write-Host "check alarm on " $e.Name -ForegroundColor Yellow

   

   $lineitem = { } | Select Name, AlarmInfo

   $alarmDef = Get-View -Id $triggered.Alarm

   $lineitem.Name = $e.Name

   $lineitem.AlarmInfo = $alarmDef.Info.Name

   $Report += $lineitem

   }

   }

}




$fragments += $Report |

ConvertTo-Html -PreContent '<h2>alarm_report </h2>' |

Out-String








   $ds_all = Get-Datastore -RelatedObject $cluster

   $syslog_server = "10.x.x.x"

   $fragments += Get-Datastore -RelatedObject $cluster |

   Where-Object {($_.FreeSpaceGB) / ($_.CapacityGB) -le 0.15} |

  Select Name |

   ConvertTo-Html -Property Name -Fragment -PreContent '<h2>DATASTORE WITH LESS THAN 15 PERCENT SPACE </h2>' |

   Out-String

   $fragments += $vms | Get-Snapshot |

  Select Name, @{N = 'VM'; E = {$_.VM.Name}}, Created |

   ConvertTo-Html -Property Name, VM, Created -Fragment -PreContent '<h2>SNAPSHOT_INFO</h2>' |

   Out-String

   $poweredoff_vms = $vms | Where-Object {$_.PowerState -eq "poweredoff"}

   #Write-Host "there are" $poweredoff_vms.count " powered off vms in" $cluster.name -ForegroundColor Yellow

$waste_storage=($poweredoff_vms|Measure-Object -Property provisionedspacegb -Sum).sum
$waste_storage_round=[math]::Round($waste_storage)
Write-Host "there are" $poweredoff_vms.count " powered off vms in" $cluster.name " wastage of  "$waste_storage_round "GB" -ForegroundColor Yellow








   $fragments += $vms | Where-Object {$_.PowerState -eq "poweredoff"}|

  select name|

   ConvertTo-Html -Property Name -Fragment -PreContent '<h2>POWEREDOFF_VMS</h2>' |

   Out-String

   $fragments += $esx |

  select name, @{N = 'vmkernel'; E = {$_ | Get-VMHostNetworkAdapter -VMKernel | Where-Object {$_.vmotionenabled -eq "true"}}}|

   ConvertTo-Html -Property name, vmkernel -Fragment -PreContent '<h2>VMKERNEL_PORT_VMOTION</h2>' |

   Out-String


   $fragments += $esx | 
   
   select name, @{N = 'memoryusagepercent'; E = {
                                                  $per_mem=$_.memoryusageGB/$_.memorytotalGB*100
                                                  $per_mem_round=[math]::Round($per_mem)
                                                   $per_mem_round                              }}|

   ConvertTo-Html -Property name,memoryusagepercent  -Fragment -PreContent '<h2>MEMORY_USAGE_PERCENT</h2>' |

   Out-String


   foreach ($e in $esx)
   {

   $per_mem=$e.memoryusageGB/$e.memorytotalGB*100
   $per_mem_round=[math]::Round($per_mem)
                                                   
if($per_mem_round -ge "90"){
write-host "check  MEMORY usage on host" $e.name -ForegroundColor Yellow





   }}
   


    $fragments += $esx | 
   
   select name, @{N = 'cpuusagepercent'; E = {
                                                  $per_cpu=$_.Cpuusagemhz/$_.CpuTotalMhz*100
                                                  $per_cpu_round=[math]::Round($per_cpu)
                                                  $per_cpu_round                              }}|

   ConvertTo-Html -Property name,cpuusagepercent  -Fragment -PreContent '<h2>CPU_USAGE_PERCENT</h2>' |

   Out-String


   
   
   <#%{

   $vm_host=get-vmhost $_
   $per_mem=$vm_host.MemoryUsageGB/$vm_host.MemoryTotalGB*100
   $per_cpu=$vm_host.Cpuusagemhz/$vm_host.CpuTotalMhz*100

   $per_mem_round=[math]::Round($per_mem)
   $per_cpu_round=[math]::Round($per_cpu)

   $vm_host|select name,@{N='memoryusagepercent';E={$per_mem_round}},@{N='cpuusagepercent';E={$per_cpu_round}}|ConvertTo-Html -Property memusgaepercent,cpuusagepercent -Fragment -PreContent '<h2>memory and cpu usage percent</h2>' |

   Out-String



   }#>

  




   <#$fragments += $esx |

  select name, @{N = 'remote_ssh'; E = { (Get-VMHostService -VMHost $_|?{$_.key -eq "tsm-ssh"}).Running}}|

   ConvertTo-Html -Property name,remote_ssh -Fragment -PreContent '<h2>REMOTESSH_RUNNING</h2>' |

   Out-String#>


      foreach ($e in $esx)
   {
   $ssh_service=(Get-VMHostService -VMHost $e|?{$_.key -eq "tsm-ssh"})
   $ssh_running_status=(Get-VMHostService -VMHost $e|?{$_.key -eq "tsm-ssh"}).Running
                                                   
#if($ssh_running_status -eq "true"){
if($ssh_running_status){
write-host "i found remote_ssh is enabled on  " $e.name -ForegroundColor Yellow
$response=read-host "would you like to turn it off?"
if($response -eq "yes"){
write-host "based on your response turning off ssh on"$e.Name -ForegroundColor Green

Stop-VMHostService -HostService $ssh_service -Confirm:$false

}




   }}

   $fragments += $esx |

  select name, @{N = 'remote_ssh'; E = { (Get-VMHostService -VMHost $_|?{$_.key -eq "tsm-ssh"}).Running}}|

   ConvertTo-Html -Property name,remote_ssh -Fragment -PreContent '<h2>REMOTESSH_RUNNING</h2>' |

   Out-String




   $fragments += $esx |

  select name, @{N = 'syslogserver'; E = {Get-VMHostSysLogServer -VMHost $_}}|

   ConvertTo-Html -Property name, syslogserver -Fragment -PreContent '<h2>SYSLOGSERVER<h2>' |

   Out-String

  

   $fragments += $vms | Where-Object {$_.Guest.GuestFamily -eq 'windowsGuest' -and $_.ExtensionData.guest.toolsversionstatus -eq 'guesttoolsneedupgrade'}|

  select name|

   ConvertTo-Html -Property Name -Fragment -PreContent '<h2>WINDOWS_VM_TOOLS_NEED_UPGRADE</h2>' |

   Out-String

   <#$fragments += $esx | Get-VMHostService|? {$_.key -eq 'ntpd'}|

  select vmhost, key, running|

   ConvertTo-Html -Property vmhost, key, running -Fragment -precontent '<h2>NTP<h2>'|

   Out-String#>

 


   foreach ($e in $esx)

   {

   $ntp = (Get-VMHostService -VMHost $e | ? { $_.key -eq "ntpd" })

   $ntp_running_status = (Get-VMHostService -VMHost $e | ? { $_.key -eq "ntpd" }).Running

   if (-not $ntp_running_status)

   {

   Write-Host "I found ntp is disabled on  " $e.name -ForegroundColor Yellow

   $response = Read-Host "Would you like to enbale ntp?"

   if ($response -eq "yes")

   {

   Write-Host "based on your response enabling ntp on "$e.Name -ForegroundColor Green

   Start-VMHostService -HostService $ntp -Confirm:$false

   }

   }

   }

   $fragments += $esx | Get-VMHostService|? {$_.key -eq 'ntpd'}|

  select vmhost, key, running|

   ConvertTo-Html -Property vmhost, key, running -Fragment -precontent '<h2>NTP<h2>'|

   Out-String




   $fragments += $esx |

  select name, build, version, model,connectionstate|

   ConvertTo-Html -Property name, build, version, model,connectionstate -Fragment -PreContent '<h2>VERSION$CONNECTION<h2>'|

   Out-String

   $fragments += $cluster|

  select drsenabled, haenabled, HAAdmissionControlEnabled|

   ConvertTo-Html -Property drsenabled, haenabled, HAAdmissionControlEnabled -Fragment -PreContent '<h2>CLUSTERPROPERTIES<h2>'|

   Out-String

   $fragments += Get-DatastoreCluster -Location(Get-Datacenter -Cluster $cluster)|

  select name|ConvertTo-Html -Property name -Fragment -PreContent '<h2>DATASTORECLUSTER<h2>'|

   Out-String

}

ConvertTo-HTML -head $head -PostContent $fragments |

   Out-String | Out-File -FilePath $path
    
  


