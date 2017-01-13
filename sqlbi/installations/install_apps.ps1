﻿#
# Copyright (c) 2014-2017, Colaberry Inc.  All rights reserved.
# Copyrights licensed under the New BSD License.
# See the accompanying LICENSE file for terms.
#

#
# Before running the script, set the execution policy
# Set-ExecutionPolicy RemoteSigned
#

#Helper Functions
function Create-Folder {
    Param ([string]$path)
    if ((Test-Path $path) -eq $false) 
    {
        Write-Host "$path doesn't exist. Creating now.."
        New-Item -ItemType "directory" -Path $path
    }
}

function Download-File{
    Param ([string]$src, [string] $dst)

    (New-Object System.Net.WebClient).DownloadFile($src,$dst)
    #Invoke-WebRequest $src -OutFile $dst
}

function WaitForFile($File) {
  while(!(Test-Path $File)) {    
    Start-Sleep -s 10;   
  }  
} 


#Setup Folders

$setupFolder = "c:\colaberry"
Create-Folder "$setupFolder"

Create-Folder "$setupFolder\training"
$setupFolder = "$setupFolder\training"

Create-Folder "$setupFolder\sqlbi"
Create-Folder "$setupFolder\sqlbi\datasets"
Create-Folder "$setupFolder\sqlbi\installations"
$setupFolder = "$setupFolder\sqlbi\installations"

$os_type = (Get-WmiObject -Class Win32_ComputerSystem).SystemType -match ‘(x64)’

# SQL Server Installation 
if((Test-Path "$setupFolder\SQLServer2016-SSEI-Dev.exe") -eq $false)
{
    Write-Host "Downloading SQL Server installation file.."
    if ($os_type -eq "True"){
        Download-File "http://download.microsoft.com/download/4/4/F/44F2C687-BD92-4331-9D4F-882A5AB0D301/SQLServer2016-SSEI-Dev.exe" "$setupFolder\SQLServer2016-SSEI-Dev.exe"
    }else {
        Write-Host "32 Bit system is not supported"
    }    
}

# Prepare Configuration file
Write-Host "Preparing configuration file.."
if((Test-Path "$setupFolder\ConfigurationFile.ini") -eq $false)
{
    Write-Host "Downloading SQL Server installation file.."
    if ($os_type -eq "True"){
        Download-File "https://raw.githubusercontent.com/Colaberry/training/master/sqlbi/installations/ConfigurationFile.ini" "$setupFolder\ConfigurationFile.ini"
    }else {
        Write-Host "32 Bit system is not supported"
    }    
}

(Get-Content $setupFolder\ConfigurationFile.ini).replace('USERNAMETBR', $env:computername\$env:username) | Set-Content $setupFolder\ConfigurationFile.ini

Write-Host "Installing SQL Server.."
Start-Process -FilePath "$setupFolder\SQLServer2016-SSEI-Dev.exe" -ArgumentList '/ConfigurationFile="$setupFolder\ConfigurationFile.ini"', '/MediaPath="$setupFolder"', '/IAcceptSqlServerLicenseTerms', '/ENU'  -Wait

# SSMS Installation 
if((Test-Path "$setupFolder\SSMS-Setup-ENU.exe") -eq $false)
{
    Write-Host "Downloading SSMS installation file.."
    if ($os_type -eq "True"){
        Download-File "https://download.microsoft.com/download/3/1/D/31D734E0-BFE8-4C33-A9DE-2392808ADEE6/SSMS-Setup-ENU.exe" "$setupFolder\SSMS-Setup-ENU.exe"
    }else {
        Write-Host "32 Bit system is not supported"
    }    
}
Write-Host "Installing SSMS.."
Start-Process -FilePath "$setupFolder\SSMS-Setup-ENU.exe" -ArgumentList '/install','/passive' -Wait


# SSDT Installation 
if((Test-Path "$setupFolder\SSDTSetup.exe") -eq $false)
{
    Write-Host "Downloading SSDT installation file.."
    if ($os_type -eq "True"){
        Download-File "https://download.microsoft.com/download/9/C/7/9C749FF7-7AD2-409A-BF75-69238295A668/Dev14/EN/SSDTSetup.exe" "$setupFolder\SSDTSetup.exe"
    }else {
        Write-Host "32 Bit system is not supported"
    }    
}

Write-Host "Installing SSDT.."
Start-Process -FilePath "$setupFolder\SSDTSetup.exe" -ArgumentList '/INSTALLALL=1', '/passive', '/promptrestart' -Wait

# Download Adventureworks
# AdventureWorks2012_Data.mdf
# https://msftdbprodsamples.codeplex.com/downloads/get/165399
if((Test-Path "$setupFolder\AdventureWorks2012_Data.mdf") -eq $false)
{
    Write-Host "Downloading SSDT installation file.."
    if ($os_type -eq "True"){
        Download-File "https://msftdbprodsamples.codeplex.com/downloads/get/165399" "$setupFolder\AdventureWorks2012_Data.mdf"
    }else {
        Write-Host "32 Bit system is not supported"
    }    
}

Add-PSSnapin SqlServerCmdletSnapin* -ErrorAction SilentlyContinue   
Import-Module SQLPS -WarningAction SilentlyContinue  

$AttachCmd = @"  
USE [master]  CREATE DATABASE [CB2016SQLSERVER] ON (FILENAME ='$setupFolder\AdventureWorks2012_Data.mdf') for ATTACH  
"@  
Invoke-Sqlcmd $attachCmd -QueryTimeout 3600 -ServerInstance CB2016SQLSERVER  
If($?)  
{  
	Write-Host 'Attached database sucessfully!'  
}  
else  
{  
	Write-Host 'Attaching Failed!'  
}


 