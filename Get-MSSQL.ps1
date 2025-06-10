Import-Module SQLPS -WarningAction SilentlyContinue
$ErrorActionPreference= 'silentlycontinue'
###
# Read the ini file, if provided
###
function Get-IniFile {  
    param(  
        [parameter(Mandatory = $true)] [string] $filePath  
    )  
    
    $anonymous = "NoSection"
  
    $ini = @{}  
    switch -regex -file $filePath  
    {  
        "^\[(.+)\]$" # Section  
        {  
            $section = $matches[1]  
            $ini[$section] = @{}  
            $CommentCount = 0  
        }  

        "^(;.*)$" # Comment  
        {  
            if (!($section))  
            {  
                $section = $anonymous  
                $ini[$section] = @{}  
            }  
            $value = $matches[1]  
            $CommentCount = $CommentCount + 1  
            $name = "Comment" + $CommentCount  
            $ini[$section][$name] = $value  
        }   

        "(.+?)\s*=\s*(.*)" # Key  
        {  
            if (!($section))  
            {  
                $section = $anonymous  
                $ini[$section] = @{}  
            }  
            $name,$value = $matches[1..2]  
            $ini[$section][$name] = $value  
        }  
    }  

    return $ini  
} 
##
# Read user config
##
function Get-UserConfig {
    param(
        [parameter(Mandatory = $false)] [string] $instance
    )
    $ini = ""
    $mkconf=Get-Item -Path $ENV:MK_CONFDIR
    if($instance.Length -gt 0)
    {
        $conf="$($mkconf.FullName)mssql_$instance.ini"
        if(Get-Item -Path "$conf")
        {
            $ini = Get-IniFile -filePath "$conf"
        }
    }
    else
    {
        $conf="$($mkconf.FullName)mssql.ini"
        if(Get-Item -Path "$conf")
        {
            $ini = Get-IniFile -filePath "$conf"
        }
    }
    return $ini
}
##
# Invoking SQL Queries based on the delivered (or not delivered) configuration
##
function Invoke-SqlcmdWithConfig{
    param(
        $instance,
        $sql
    )
    $iniGlobal=Get-UserConfig
    cd $instance.PSPath
    $ini = Get-UserConfig -instance $instance.PSChildName
    if($ini -like "")
    {
        $ini=$iniGlobal
    }
    $data=""
    if($ini -like "")
    {
        $data = Invoke-Sqlcmd -Query "$sql" -WarningAction SilentlyContinue
    }
    else
    {
        $data = Invoke-Sqlcmd -Query "$sql" -Username $ini.auth.name -Password $ini.auth.password -WarningAction SilentlyContinue
    }
    return $data
}
##
# Creates an empty structure for the cmk output
##

function Get-Basestruct{
    $basestruct=@{}
    $basestruct["instance"]=@{}
    $basestruct["instance"]["name"]="<<<mssql_instance:sep(124)>>>"
    $basestruct["databases"]=@{}
    $basestruct["databases"]["name"]="<<<mssql_databases:sep(124)>>>"
    $basestruct["counters"]=@{}
    $basestruct["counters"]["name"]="<<<mssql_counters:sep(124)>>>"
    $basestruct["tablespaces"]=@{}
    $basestruct["tablespaces"]["name"]="<<<mssql_tablespaces>>>"
    $basestruct["blocked_sessions"]=@{}
    $basestruct["blocked_sessions"]["name"]="<<<mssql_blocked_sessions:sep(124)>>>"
    $basestruct["backup"]=@{}
    $basestruct["backup"]["name"]="<<<mssql_backup:sep(124)>>>"
    $basestruct["transactionlogs"]=@{}
    $basestruct["transactionlogs"]["name"]="<<<mssql_transactionlogs:sep(124)>>>"
    $basestruct["datafiles"]=@{}
    $basestruct["datafiles"]["name"]="<<<mssql_datafiles:sep(124)>>>"
    $basestruct["clusters"]=@{}
    $basestruct["clusters"]["name"]="<<<mssql_cluster:sep(124)>>>"
    $basestruct["connections"]=@{}
    $basestruct["connections"]["name"]="<<<mssql_connections>>>"
    return  $basestruct
}
###
# Read the configuration string for the SQL server
###
function Get-ConfString{
    param(
        $instance
    )
    
    $conf=Invoke-SqlcmdWithConfig -instance $instance -sql "SELECT SERVERPROPERTY('edition') AS edition, SERVERPROPERTY('ProductVersion') as version"

    return "$($conf.version.Trim())|$($conf.edition.trim())|$($instance.ClusterName)"

}
###
# Get the SQL server service state 
###
function Get-StateString{
    param(
        $instanceName
    )
    if($instanceName -ne "MSSQLSERVER")
    {
       $instanceName = "MSSQL`$$instanceName"
    }
    $service=Get-Service $instanceName
    if($service.Status -eq "Running")
    {
        $state=1
        $errormsg=""
    }
    else
    {
        $state=0
        $errormsg="Service $instanceName is in state $($service.Status)"
    }
    return "$state|$errormsg"
}
###
# Get the SQL Servers UTC time
###
function Get-UTCString{
    param(
        $instance
    )
    $data=Invoke-SqlcmdWithConfig -instance $instance -sql "SELECT GETUTCDATE() as utc_date"
    return "None|$($data.utc_date.ToUniversalTime().ToString("M/d/yyyy hh:mm:ss tt"))"
}
##
# Returns the Counter name
##
function Get-CounterString{
    param(
        $counterRow
    )
    return "$($counterRow.counter_name)"
}
##
# Adds a counter to the structure
##
function Add-Counter{
    param(
        $dbstruct,
        $counterdata
    )
    $objectName=$counterdata.object_name.trim().Replace(" ", "_").Replace("$", "_")
    if(-not $dbstruct["counters"].ContainsKey("$objectName"))
    {
        $dbstruct["counters"]["$objectName"]=@{}
    }
    $counterName=$counterdata.counter_name.trim().Replace(" ", "_").Replace("$", "_").ToLower()
    if(-not $dbstruct["counters"]["$objectName"].ContainsKey("$counterName"))
    {
        $dbstruct["counters"]["$objectName"]["$counterName"]=@{}
    }
    $instanceName=$counterData.instance_name.trim().Replace(" ", "_").Replace("$", "_")
    if($instanceName -eq "") { $instanceName = "None" }
    $dbstruct["counters"]["$objectName"]["$counterName"]["$instanceName"]=$counterdata.cntr_value.toString().trim()
        
}
##
# Adds the blocked sessions to the structure
##
function Add-BlockedSession{
    param(
        $dbstruct,
        $blockedData
    )
    $session_id=$counterdata.session_id.toString().trim().Replace(" ", "_").Replace("$", "_")
    if(-not $dbstruct["blocked_sessions"].ContainsKey("$session_id"))
    {
        $dbstruct["blocked_sessions"]["$session_id"]=@{}
    }
    $wait_duration_ms=$counterdata.wait_duration_ms.toString().trim().Replace(" ", "_").Replace("$", "_")
    if(-not $dbstruct["blocked_sessions"]["$session_id"].ContainsKey("$wait_duration_ms"))
    {
        $dbstruct["session_id"]["$session_id"][$wait_duration_ms]=@{}
    }   
    $blocking_session_id=$counterdata.blocking_session_id.toString().trim().Replace(" ", "_").Replace("$", "_")
    if(-not $dbstruct["blocked_sessions"]["$session_id"][$wait_duration_ms].ContainsKey("$blocking_session_id"))
    {
        $dbstruct["blocked_sessions"]["$session_id"][$wait_duration_ms]["$wait_type"]["$blocking_session_id"]=$null
    }        
}
###
# Add the database sizes to the structure
# !!! The original script does not output any informations on not accessible (e.g. restoring) databases !!!
###
function Add-DatabaseSize{
    param(
        $dbstruct,
        $instance,
        $instanceName,
        $dbname
    )
    $data=Invoke-SqlcmdWithConfig -instance $instance -sql "USE [$dbname]; EXEC sp_spaceused"# @oneresultset = 1"
    if($data -notlike "")
    {
        $field="MSSQL_$instanceName $($dbname.Replace(" ", "_")) $($data[0].database_size.trim()) $($data[0].'unallocated space'.trim()) $($data[1].reserved.trim()) $($data[1].data.trim()) $($data[1].index_size.trim()) $($data[1].unused.trim())"
        $dbstruct["tablespaces"]["$field"]=$null
    }
}
##
# Writes the structure to a CMK readable format
##
function Write-DBStruct {
    param(
        $dbstruct
    )
    foreach($key in $dbstruct.Keys)
    {
        "$($dbstruct.$key.name)"


        foreach($subkey in ($dbstruct.$key.Keys | Where-Object {$_ -notlike 'name'}))
        {
            if($dbstruct.$key.$subkey -ne $null)
            {
                Get-ValuesRecurse -sub $dbstruct.$key.$subkey -base "$subkey"
            }
            else
            {
                "$subkey"
            }
        }
    }
}
###
# Help function to print a hastable recursively 
###
function Get-ValuesRecurse {
    param(
        $sub,
        $base
        )
    if($sub.GetType().Name -eq "Hashtable")
    {
        if($sub.Keys.Count -gt 0)
        {
            foreach($key in $sub.Keys)
            {
                if($sub.$key -eq $null)
                {
                    "$base|$key"
                }
                else
                {
                    Get-ValuesRecurse -sub $sub.$key -base "$base|$key"
                }
            }
        }
        else
        {
            if($sub.Value -eq $null)
            {
                "$base"
            }
            else
            {
                "$base|$sub"
            }
        }
    }
    else
    {
        "$base|$sub"
    }
    
    
}
##
# Get the database backup informations
##
function Add-BackupInformation{
    param(
        $dbstruct,
        $instance,
        $instanceName,
        $dbname
    )
    $sql=@"
    USE [master];
    DECLARE @HADRStatus sql_variant; DECLARE @SQLCommand nvarchar(max);
    SET @HADRStatus = (SELECT SERVERPROPERTY ('IsHadrEnabled'));
    IF (@HADRStatus IS NULL or @HADRStatus <> 1)
	    BEGIN
		    SET @SQLCommand = 'SELECT CONVERT(VARCHAR, DATEADD(s, DATEDIFF(s, ''19700101'', MAX(backup_finish_date)), ''19700101''), 120) AS last_backup_date, type, machine_name, ''True'' as is_primary_replica, ''1'' as is_local, '''' as replica_id FROM msdb.dbo.backupset WHERE database_name = ''DBNAMETEMPL'' AND  machine_name = SERVERPROPERTY(''Machinename'') GROUP BY type, machine_name '
	    END
    ELSE
	    BEGIN
		    SET @SQLCommand = 'SELECT CONVERT(VARCHAR, DATEADD(s, DATEDIFF(s, ''19700101'', MAX(b.backup_finish_date)), ''19700101''), 120) AS last_backup_date, b.type, b.machine_name, isnull(rep.is_primary_replica,0) as is_primary_replica, rep.is_local, isnull(convert(varchar(40), rep.replica_id), '''') AS replica_id FROM msdb.dbo.backupset b LEFT OUTER JOIN sys.databases db ON b.database_name = db.name LEFT OUTER JOIN sys.dm_hadr_database_replica_states rep ON db.database_id = rep.database_id WHERE database_name = ''DBNAMETEMPL'' AND (rep.is_local is null or rep.is_local = 1) AND (rep.is_primary_replica is null or rep.is_primary_replica = ''True'') and machine_name = SERVERPROPERTY(''Machinename'') GROUP BY type, rep.replica_id, rep.is_primary_replica, rep.is_local, b.database_name, b.machine_name, rep.synchronization_state, rep.synchronization_health'
	    END
    EXEC (@SQLCommand)
"@.Replace("DBNAMETEMPL", "$dbname")
    $backups=Invoke-SqlcmdWithConfig -instance $instance -sql $sql
    foreach($backup in $backups)
    {
        if($backup.last_backup_date.toString() -ne "" -and ($backup.replica_id.toString().trim() -eq "" -or $backup.is_primary_replica.toString().Trim() -eq "True" ))
        {
            if(-not $dbstruct["backup"].ContainsKey("MSSQL_$instanceName"))
            {
                $dbstruct["backup"]["MSSQL_$instanceName"]=@{}
            }
            if(-not $dbstruct["backup"]["MSSQL_$instanceName"].ContainsKey("$($dbname.Replace(" ", "_"))"))
            {
                $dbstruct["backup"]["MSSQL_$instanceName"]["$($dbname.Replace(" ", "_"))"]=@{}
            }
            $dbstruct["backup"]["MSSQL_$instanceName"]["$($dbname.Replace(" ", "_"))"]["$($backup.last_backup_date.trim().replace(" ", "|"))|$($backup.type.trim())"]=$null
        }
    }
}
##
# Get the database datafiles
##
function Add-DataFiles{
    param(
        $type,
        $dbstruct,
        $instance,
        $instanceName,
        $dbname
    )
    if($type -like "datafiles")
	{
		$dbtype="ROWS"
	}
	else
	{
		$dbtype="LOG"
	}
    $sql=@"
USE [DBNAMETEMPL];
SELECT name, physical_name,
 cast(max_size/128 as bigint) as MaxSize,
 cast(size/128 as bigint) as AllocatedSize,
 cast(FILEPROPERTY (name, 'spaceused')/128 as bigint) as UsedSize,
 case when max_size = '-1' then '1' else '0' end as Unlimited
FROM sys.database_files WHERE type_desc = 'TYPETEMPL'
"@.Replace("DBNAMETEMPL", $dbname.Trim()).Replace("TYPETEMPL", $dbtype)
    $files=Invoke-SqlcmdWithConfig -instance $instance -sql $sql
    foreach($file in $files)
    {
        if(-not $dbstruct["$type"].ContainsKey("$instanceName"))
        {
            $dbstruct["$type"]["$instanceName"]=@{}
        }
        if(-not $dbstruct["$type"]["$instanceName"].ContainsKey("$($dbname.Replace(" ", "_"))"))
        {
            $dbstruct["$type"]["$instanceName"]["$($dbname.Replace(" ", "_"))"]=@{}
        }
        $field="$($file.name.trim().replace(" ", "_"))|$($file.physical_name.trim().replace(" ", "_"))|$($file.MaxSize)|$($file.AllocatedSize)|$($file.UsedSize)|$($file.Unlimited)"
        $dbstruct["$type"]["$instanceName"]["$($dbname.Replace(" ", "_"))"][$field]=$null
    }
}
##
# Add accessible databases
##
function Add-DataBase{
    param(
        $dbstruct,
        $instance,
        $instanceName,
        $database
    )
    $sql=@"
SELECT
DATABASEPROPERTYEX(name, 'Status') AS Status,
DATABASEPROPERTYEX(name, 'Recovery') AS RecoveryModel, 
DATABASEPROPERTYEX(name, 'IsAutoClose') AS AutoClose,
DATABASEPROPERTYEX(name, 'IsAutoShrink') AS AutoShrink
FROM master.dbo.sysdatabases WHERE name = 'DBNAMETEMPL'
"@.Replace("DBNAMETEMPL", $database.Name)
    $databaseData=Invoke-SqlcmdWithConfig -instance $instance -sql $sql
    if(-not $dbstruct["databases"].ContainsKey("$instanceName"))
    {
        $dbstruct["databases"]["$instanceName"]=@{}
    }
    $dbstruct["databases"]["$instanceName"]["$($database.Name.Trim().Replace(" ", "_"))"]="$($databaseData.Status)|$($databaseData.RecoveryModel)|$($databaseData.AutoClose)|$($databaseData.AutoShrink)"
}
##
# Add active DB connections
##
function Add-DBConnections{
    param(
        $dbstruct,
        $instance,
        $instanceName,
        $database
    )
    $sql=@"
SELECT name AS DBName, ISNULL((SELECT COUNT(dbid) AS NumberOfConnections FROM
sys.sysprocesses WHERE dbid > 0 AND name = DB_NAME(dbid) GROUP BY dbid ),0) AS NumberOfConnections
FROM sys.databases WHERE name = 'DBNAMETEMPL'
"@.Replace("DBNAMETEMPL", $database.Name)
    $databaseCons=Invoke-SqlcmdWithConfig -instance $instance -sql $sql
    $dbstruct["connections"]["$($instanceName) $($database.Name.Replace(" ", "_")) $($databaseCons.NumberOfConnections)"]=$null
}

##
# Main function
##

$path = Get-Location
$dbstruct=Get-Basestruct

foreach($machine in Get-ChildItem -Path SQLSERVER:\SQL\)
{
    foreach($instance in Get-ChildItem -Path $machine.PSPath)
    {
        $instanceName=$instance.ServiceName
        $dbstruct["instance"]["MSSQL_$instanceName"]=@{}
        $dbstruct["instance"]["MSSQL_$instanceName"]["config"]=Get-ConfString -instance $instance
        $dbstruct["instance"]["MSSQL_$instanceName"]["state"]=Get-StateString -instanceName $instanceName
        $dbstruct["counters"]["None"]=@{}
        $dbstruct["counters"]["None"]["utc_time"]=Get-UTCString -instance $instance
        foreach($counter in Invoke-SqlcmdWithConfig -instance $instance -sql "SELECT counter_name, object_name, instance_name, cntr_value FROM sys.dm_os_performance_counters WHERE object_name NOT LIKE '%Deprecated%'")
        {
            Add-Counter -dbstruct $dbstruct -counterdata $counter    
        }
        foreach($session in Invoke-SqlcmdWithConfig -instance $instance -sql "SELECT session_id, wait_duration_ms, wait_type, blocking_session_id FROM sys.dm_os_waiting_tasks WHERE blocking_session_id <> 0")
        {
            Add-BlockedSession -dbstruct $dbstruct -blockedData $session  
        }
        foreach($database in $instance.Databases)
        {
            Add-DatabaseSize -dbstruct $dbstruct -instance $instance -instanceName $instanceName -dbname $database.Name
            Add-BackupInformation -dbstruct $dbstruct -instance $instance -instanceName $instanceName -dbname $database.Name
            Add-DataFiles -type "datafiles" -dbstruct $dbstruct -instance $instance -instanceName $instanceName -dbname $database.Name
            Add-DataFiles -type "transactionlogs" -dbstruct $dbstruct -instance $instance -instanceName $instanceName -dbname $database.Name
            Add-DataBase -dbstruct $dbstruct -database $database -instance $instance -instanceName $instanceName
            Add-DBConnections -dbstruct $dbstruct -database $database -instance $instance -instanceName $instanceName
        }
    }
}
Write-DBStruct -dbstruct $dbstruct

cd $path
