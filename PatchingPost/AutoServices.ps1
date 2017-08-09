﻿#############################################################################################
#
# NAME: Autoservices.ps1
# AUTHOR: Rob Sewell http://newsqldbawiththebeard.wordpress.com @fade2blackuk
# DATE:15/05/2013
#
# COMMENTS: # Script to show the services running that are set to Automatic startup - 
# good for checking after reboot
# ------------------------------------------------------------------------

$Server = Read-Host "Which Server?"

Get-WmiObject Win32_Service -ComputerName $Server  |  
Where-Object { $_.StartMode -like 'Auto' }| 
Select-Object __SERVER, Name, StartMode, State | Format-Table -auto
Write-Host "SQL Services"
Get-WmiObject Win32_Service -ComputerName $Server  |  
Where-Object { $_.DisplayName -like '*SQL*' }| 
Select-Object __SERVER, Name, StartMode, State | Format-Table -auto