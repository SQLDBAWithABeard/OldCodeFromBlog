﻿<#
.Synopsis
   Disk Check and email alert 
.DESCRIPTION
    Author - Rob Sewell https://sqldbawithabeard.com @sqldbawithbeard
    Date - 29/10/2014

   This script will iterate through the list of servers in the filepath at line 29 and check the disk space
   for every disk. You will need to set the Email server variables

   There are three warning levels currently set at 15%,5% and 1%

   If the free disk space for any disk is below a warning level, the script will check for
   the existence of a unique to the disk named text file located in the path of the $location 
   variable, preuming one does not exist, the script will create a text file and then email 

   If the script finds a text file it will not email 

   Once the free space increases above the warning level the script will remove the text file

.EXAMPLE
    The script is designed to run under a scheduled agent job 
    
.NOTES
   The script will log to the file located at $LogFile location which will be deleted

#>
 #Set variables
 $Servers = Get-Content 'PATH\TO\Servers.txt' ## or list of servers or results of query to get servers
 $WarningLevel = '15'
 $ErrorLevel = '5'
 $SevereLevel = '1'
 $Date = Get-Date
 $Location = 'c:\temp\Diskspace\'
 $Logdate = Get-Date -Format yyyyMMdd
 $LogFile = $Location + 'logfile' + $LogDate+ '.txt'
 $smtpServer = ""
 $To = ""
 $From = ""
 $Sender = ""

 # if daily log file does not exist create one
 if(!(Test-Path $LogFile)) 
 {
 New-Item $Logfile -ItemType File
 }

# any logfiles older than 7 days delete
Get-ChildItem -Path $Location *logfile* |Where-Object {$_.LastWriteTime -gt (Get-Date).AddDays(7) }|Remove-Item -Force 


foreach($Server in $Servers)
{
$server
try
{
    # get disk information
    $Disks = Get-WmiObject win32_logicaldisk -ComputerName $Server | Where-Object {$_.drivetype -eq 3} -ErrorAction Stop
}
catch 
{
    $ErrorException = $_.Exception.Message
    $ErrorException
    $logentrydate = (Get-Date).DateTime
    $Log = $logentrydate + ' ' + $Server + ' Disk Check Failed with - ' + $ErrorException 
    Add-Content -Value $Log -Path $Logfile
    
}



foreach($Disk in $Disks)
{
$ServerName = $Disk.__SERVER
$VolumeName = $Disk.VolumeName
$DriveLetter = $Disk.DeviceID.Chars(0)

$TotalSpace=[math]::Round(($Disk.Size/1073741824),2) # change to gb and 2 decimal places
$FreeSpace=[Math]::Round(($Disk.FreeSpace/1073741824),2)# change to gb and 2 decimal places
$UsedSpace = $TotalSpace - $FreeSpace
$PercentFree = [Math]::Round((($FreeSpace/$TotalSpace)*100),2)# change to gb and 2 decimal places

# set variables for unique check file per server and disk
$CheckFile = $Location + $Server + '_' + $DriveLetter + '_Warning.txt' 
$CheckFileError = $Location + $Server + '_' + $DriveLetter + '_Error.txt'
$CheckFileSevere = $Location + $Server + '_' + $DriveLetter + '_Severe.txt'

# Check if percent free below warning level
if ($PercentFree -le $SevereLevel) 
 {

# if text file has been created (ie email should already have been sent) do nothing
if(Test-Path $CheckFileSevere)
{
 $logentrydate = (Get-Date).DateTime
 $Log = $logentrydate + ' ' + $ServerName + ' ' +  $DriveLetter + ' ' +  $VolumeName + ' ' + $PercentFree  +  ' -- ' + $CheckFileSevere + ' File Already Created - No Action Taken'
 Add-Content -Value $Log -Path $Logfile
} 
# if percent free below warning level and text file doesnot exist create text file and email
else 
{

# Create File
New-Item $CheckFileSevere -ItemType File
 $logentrydate = (Get-Date).DateTime
 $Log = $logentrydate + ' ' + $ServerName + ' ' +  $DriveLetter + ' ' +  $VolumeName + ' ' + $PercentFree  + ' ' + $CheckFileSevere + ' -- File Created'
 Add-Content -Value $Log -Path $Logfile
#Create Email Body
$EmailBody = ''
$EmailBody += "<html> <head>  <title> $Date DiskSpace Report</title>"
$EmailBody += "<STYLE TYPE=`"text/css`"> <!-- td { font-family: Tahoma; font-size: 11px; border-top: 1px solid #999999; border-right: 1px solid #999999; border-bottom: 1px solid #999999; border-left: 1px solid #999999; padding-top: 0px; padding-right: 0px; padding-bottom: 0px; padding-left: 0px; } body { margin-left: 5px; margin-top: 5px; margin-right: 0px; margin-bottom: 10px;  table { border: thin solid #000000; } --> </style> </head> <body>" 
$EmailBody += "<table width='100%'><tbody>"

$EmailBody += "<tr>"
$EmailBody += "<td width='100%' colSpan=6><font face='tahoma' color='#003399' size='2'> $Date <BR><BR>Dear ,<BR><BR> This email has been generated as<font face='tahoma' color='#003399' size='2'><strong> $DriveLetter drive labelled $VolumeName on  $ServerName </strong></font> has <font face='tahoma' color='#FF0000' size='2'><strong>free space which has fallen below $SevereLevel% </strong></font><br><BR> Please take the appropriate action <BR><BR> Regards,<BR><BR> The Automatic Disk Monitoring System<BR><BR></font></td>"
$EmailBody += "</tr>"

$EmailBody += "<tr bgcolor='#FF0000'>"
$EmailBody += "<td width='100%' align='center' colSpan=6><font face='tahoma' color='#003399' size='2'><strong> $ServerName </strong></font></td>"
$EmailBody += "</tr>"
$EmailBody += "<tr bgcolor=#CCCCCC>"
$EmailBody += "<td width='15%' align='center'>Drive</td>"
$EmailBody += "<td width='25%' align='center'>Drive Label</td>"
$EmailBody += "<td width='15%' align='center'>Total Capacity(GB)</td>"
$EmailBody += "<td width='15%' align='center'>Used Capacity(GB)</td>"
$EmailBody += "<td width='15%' align='center'>Free Space(GB)</td>"
$EmailBody += "<td width='15%' align='center'>Freespace %</td>"
$EmailBody += "</tr>"

$EmailBody += "<tr>"
$EmailBody += "<td bgcolor='#FF0000' align=center>$DriveLetter</td>"
$EmailBody += "<td bgcolor='#FF0000' align=center>$VolumeName</td>"
$EmailBody += "<td bgcolor='#FF0000' align=center>$TotalSpace</td>"
$EmailBody += "<td bgcolor='#FF0000' align=center>$UsedSpace</td>"
$EmailBody += "<td bgcolor='#FF0000' align=center>$FreeSpace</td>"
$EmailBody += "<td bgcolor='#FF0000' align=center>$PercentFree</td>"
$EmailBody += "</tr>"

#Send Email
$Subject = "URGENT Disk Space Alert 1%"
$Body = $EmailBody
$msg = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.port = '25'
$msg.From = $From
$msg.Sender = $Sender
$msg.To.Add($To)
$msg.Subject = $Subject
$msg.Body = $Body
$msg.IsBodyHtml = $True
$smtp.Send($msg)
 $logentrydate = (Get-Date).DateTime
 $Log = $logentrydate + ' ' + $ServerName + ' ' +  $DriveLetter + ' ' +  $VolumeName + ' ' + $PercentFree  + ' ' +  ' -- Severe Email Sent'
 Add-Content -Value $Log -Path $Logfile
}

 }

# Check if percent free below warning level
elseif ($PercentFree -le $ErrorLevel) 
 {

# if text file has been created (ie email should already have been sent) do nothing
if(Test-Path $CheckFileError)
{
 $logentrydate = (Get-Date).DateTime
 $Log = $logentrydate + ' ' + ' ' + $ServerName + ' ' +  $DriveLetter + ' ' +  $VolumeName + ' --' + $CheckFileError + ' File Already Created - No Action Taken'
 Add-Content -Value $Log -Path $Logfile
} 

# if percent free below warning level and text file doesnot exist create text file and email
else 
{
# Create File
New-Item $CheckFileError -ItemType File
 $logentrydate = (Get-Date).DateTime
 $Log = $logentrydate + ' ' + $ServerName + ' ' +  $DriveLetter + ' ' +  $VolumeName + ' ' + $PercentFree  + ' ' + $CheckFileError + ' -- File Created'
 Add-Content -Value $Log -Path $Logfile

# Create Email Body
$EmailBody = ''
$EmailBody += "<html> <head>  <title> $Date DiskSpace Report</title>"
$EmailBody += "<STYLE TYPE=`"text/css`"> <!-- td { font-family: Tahoma; font-size: 11px; border-top: 1px solid #999999; border-right: 1px solid #999999; border-bottom: 1px solid #999999; border-left: 1px solid #999999; padding-top: 0px; padding-right: 0px; padding-bottom: 0px; padding-left: 0px; } body { margin-left: 5px; margin-top: 5px; margin-right: 0px; margin-bottom: 10px;  table { border: thin solid #000000; } --> </style> </head> <body>" 
$EmailBody += "<table width='100%'><tbody>"

$EmailBody += "<tr>"
$EmailBody += "<td width='100%' colSpan=6><font face='tahoma' color='#003399' size='2'> $Date <BR><BR>Dear ,<BR><BR> This email has been generated as $DriveLetter drive labelled $VolumeName on $ServerName has free space which has fallen below $WarningLevel%<br><BR> Please take the appropriate action <BR><BR> Regards,<BR><BR> The Automatic Disk Monitoring System<BR><BR></font></td>"
$EmailBody += "</tr>"

$EmailBody += "<tr bgcolor='#CCCCCC'>"
$EmailBody += "<td width='100%' align='center' colSpan=6><font face='tahoma' color='#003399' size='2'><strong> $ServerName </strong></font></td>"
$EmailBody += "</tr>"
$EmailBody += "<tr bgcolor=#CCCCCC>"
$EmailBody += "<td width='15%' align='center'>Drive</td>"
$EmailBody += "<td width='25%' align='center'>Drive Label</td>"
$EmailBody += "<td width='15%' align='center'>Total Capacity(GB)</td>"
$EmailBody += "<td width='15%' align='center'>Used Capacity(GB)</td>"
$EmailBody += "<td width='15%' align='center'>Free Space(GB)</td>"
$EmailBody += "<td width='15%' align='center'>Freespace %</td>"
$EmailBody += "</tr>"


$EmailBody += "<tr>"
$EmailBody += "<td align=center>$DriveLetter</td>"
$EmailBody += "<td align=center>$VolumeName</td>"
$EmailBody += "<td align=center>$TotalSpace</td>"
$EmailBody += "<td align=center>$UsedSpace</td>"
$EmailBody += "<td align=center>$FreeSpace</td>"
$EmailBody += "<td bgcolor='#FF0000' align=center>$PercentFree</td>"
$EmailBody += "</tr>"

#Send Email
$Subject = "Disk Space Alert 5%"
$Body = $EmailBody
$msg = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.port = '25'
$msg.From = $From
$msg.Sender = $Sender
$msg.To.Add($To)
$msg.Subject = $Subject
$msg.Body = $Body
$msg.IsBodyHtml = $True
$smtp.Send($msg)
 $logentrydate = (Get-Date).DateTime
 $Log = $logentrydate + ' ' + $ServerName + ' ' +  $DriveLetter + ' ' +  $VolumeName + ' ' + $PercentFree  +  ' -- Error Email Sent'
 Add-Content -Value $Log -Path $Logfile
}



 }
 # Check if percent free below warning level
 elseif ($PercentFree -le $WarningLevel) 
 {

 # if text file has been created (ie email should already have been sent) do nothing
if(Test-Path $CheckFile)
{
 $logentrydate = (Get-Date).DateTime
 $Log = $logentrydate + ' ' + ' ' + $ServerName + ' ' +  $DriveLetter + ' ' +  $VolumeName + ' ' + $PercentFree  +  ' --' + $CheckFile + ' File Already Created - No Action Taken'
 Add-Content -Value $Log -Path $Logfile
}

# if percent free below warning level and text file doesnot exist create text file and email
else 
{
# Create File
New-Item $CheckFile -ItemType File
 $logentrydate = (Get-Date).DateTime
 $Log = $logentrydate + ' ' + $ServerName + ' ' +  $DriveLetter + ' ' +  $VolumeName + ' ' + $PercentFree  +  ' ' + $CheckFile + ' -- File Created'
 Add-Content -Value $Log -Path $Logfile
#Create Email Body
$EmailBody = ''
$EmailBody += "<html> <head>  <title> $Date DiskSpace Report</title>"
$EmailBody += "<STYLE TYPE=`"text/css`"> <!-- td { font-family: Tahoma; font-size: 11px; border-top: 1px solid #999999; border-right: 1px solid #999999; border-bottom: 1px solid #999999; border-left: 1px solid #999999; padding-top: 0px; padding-right: 0px; padding-bottom: 0px; padding-left: 0px; } body { margin-left: 5px; margin-top: 5px; margin-right: 0px; margin-bottom: 10px;  table { border: thin solid #000000; } --> </style> </head> <body>" 
$EmailBody += "<table width='100%'><tbody>"

$EmailBody += "<tr>"
$EmailBody += "<td width='100%' colSpan=6><font face='tahoma' color='#003399' size='2'> $Date <BR><BR>Dear Service Desk,<BR><BR> This email has been generated as  $DriveLetter drive labelled $VolumeName on $ServerName has free space which has fallen below $WarningLevel%<br><BR> Please take the appropriate action <BR><BR> Regards,<BR><BR> The Automatic Disk Monitoring System<BR><BR></font></td>"
$EmailBody += "</tr>"

$EmailBody += "<tr bgcolor='#CCCCCC'>"
$EmailBody += "<td width='100%' align='center' colSpan=6><font face='tahoma' color='#003399' size='2'><strong> $ServerName </strong></font></td>"
$EmailBody += "</tr>"
$EmailBody += "<tr bgcolor=#CCCCCC>"
$EmailBody += "<td width='15%' align='center'>Drive</td>"
$EmailBody += "<td width='25%' align='center'>Drive Label</td>"
$EmailBody += "<td width='15%' align='center'>Total Capacity(GB)</td>"
$EmailBody += "<td width='15%' align='center'>Used Capacity(GB)</td>"
$EmailBody += "<td width='15%' align='center'>Free Space(GB)</td>"
$EmailBody += "<td width='15%' align='center'>Freespace %</td>"
$EmailBody += "</tr>"


$EmailBody += "<tr>"
$EmailBody += "<td align=center>$DriveLetter</td>"
$EmailBody += "<td align=center>$VolumeName</td>"
$EmailBody += "<td align=center>$TotalSpace</td>"
$EmailBody += "<td align=center>$UsedSpace</td>"
$EmailBody += "<td align=center>$FreeSpace</td>"
$EmailBody += "<td bgcolor='#FBB917' align=center>$PercentFree</td>"
$EmailBody += "</tr>"

#Send Email
$Subject = "Disk Space Alert"
$Body = $EmailBody
$msg = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.port = '25'
$msg.From = $From
$msg.Sender = $Sender
$msg.To.Add($To)
$msg.Subject = $Subject
$msg.Body = $Body
$msg.IsBodyHtml = $True
$smtp.Send($msg)
 $logentrydate = (Get-Date).DateTime
 $Log = $logentrydate + ' ' + ' ' + $ServerName + ' ' +  $DriveLetter + ' ' +  $VolumeName +  ' ' + $PercentFree  + ' -- Warning Email Sent'
 Add-Content -Value $Log -Path $Logfile
}



 }
# If Percent free above warning level - remove text files so that next time it drops below an email is sent again
 else 
 {
 if(Test-Path $CheckFileError)
 {
 Remove-Item $CheckFileError -Force
  $logentrydate = (Get-Date).DateTime
 $Log = $logentrydate + ' ' + $ServerName + ' ' +  $DriveLetter + ' ' +  $VolumeName + ' ' + $PercentFree  + ' ' + $CheckFileError + ' -- File Removed'
 Add-Content -Value $Log -Path $Logfile
 }
  if(Test-Path $CheckFile)
 {
 Remove-Item $CheckFile -Force
  $logentrydate = (Get-Date).DateTime
 $Log = $logentrydate + ' ' + $ServerName + ' ' +  $DriveLetter + ' ' +  $VolumeName + ' ' + $PercentFree  + ' ' + $CheckFile + ' --  File Removed'
 Add-Content -Value $Log -Path $Logfile
 }
 if(Test-Path $CheckFileSevere)
 {
 Remove-Item $CheckFileSevere -Force
  $logentrydate = (Get-Date).DateTime
 $Log = $logentrydate + ' ' + $ServerName + ' ' +  $DriveLetter + ' ' +  $VolumeName + ' ' + $PercentFree  + ' ' + $CheckFileSevere + ' -- File Removed'
 Add-Content -Value $Log -Path $Logfile
 }

 $logentrydate = (Get-Date).DateTime
 $Log = $logentrydate + ' ' + $ServerName + ' ' +  $DriveLetter + ' ' +  $VolumeName + ' ' + $PercentFree  + ' -- Checked No Action Taken'
 Add-Content -Value $Log -Path $Logfile
 }

}
}



