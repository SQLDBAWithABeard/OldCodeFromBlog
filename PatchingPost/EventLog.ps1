
#############################################################################################
#
# NAME: EventLog.ps1
# AUTHOR: Rob Sewell http://newsqldbawiththebeard.wordpress.com @fade2blackuk
# DATE:10/05/2013
#
# COMMENTS: This script will create 3 Windows Azure SQL Servers and open up RDP connections
# ready for use. There is also the scripts to remove the Windows Azure Objects to save on
# usage costs
# ------------------------------------------------------------------------

#  to only show Errors add -      where {$_.entryType -match "Error"}


#Enter Server Name and set as variable
            $Server= Read-Host "Please Enter the Server"
#Enter log type to read and set as variable - Application, system, security
            $log= Read-Host "Please Enter the Event Log"
#Enter number of Events to display and set as variable
            $latest= Read-Host "How many events to display?"

            Get-EventLog  -computername $server -log $log -newest $latest | Out-GridView