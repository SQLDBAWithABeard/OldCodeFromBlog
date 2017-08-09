﻿#############################################################################################
#
# NAME: StopSQLServices.ps1
# AUTHOR: Rob Sewell http://newsqldbawiththebeard.wordpress.com @fade2blackuk
# DATE:15/05/2013
#
# COMMENTS: This script will stop all SQL Services on a server
# ------------------------------------------------------------------------

$Server= Read-Host "Please Enter the Server - This WILL stop all SQL services"

Write-Host "###########  Services on $Server BEFORE  ##############" -ForegroundColor Green -BackgroundColor DarkYellow
get-service -ComputerName $server|Where-Object { $_.Name -like '*SQL*' }
Write-Host "###########  Services on $Server BEFORE  ##############" -ForegroundColor Green -BackgroundColor DarkYellow
$Services = Get-Service -ComputerName $server|Where-Object { $_.Name -like '*SQL*' -and $_.Status -eq 'Running' -and $_.Name -ne 'SQLSERverAGENT'}

foreach($Service in $Services)
{
if($service.Status -eq 'Running')
{
$ServiceName = $Service.displayname
(get-service -ComputerName $Server  -Name $ServiceName).Stop()
 while((Get-Service -ComputerName $server -Name $ServiceName).status -ne'Stopped')
 {<#do nothing#>}
 }
 }
Write-Host "###########  Services on $Server After  ##############" -ForegroundColor Green -BackgroundColor DarkYellow
get-service -ComputerName $server|Where-Object { $_.Name -like '*SQL*' }
Write-Host "###########  Services on $Server After  ##############" -ForegroundColor Green -BackgroundColor DarkYellow
 
