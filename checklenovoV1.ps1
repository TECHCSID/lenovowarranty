Function Get-LenovoWarranty {
 
<#
.SYNOPSIS
    This will check the warranty status of a Lenovo laptop
    For updated help and examples refer to -Online version.
  
.DESCRIPTION
    This will check the warranty status of a Lenovo laptop
    For updated help and examples refer to -Online version.
  
.NOTES  
    Name: Get-LenovoWarranty
    Author: The Sysadmin Channel
    Version: 1.0
    DateCreated: 2018-Apr-21
    DateUpdated: 2018-Apr-21
  
.LINK
    https://thesysadminchannel.com/get-lenovo-warranty-expiration-status-with-powershell/ -
    For updated help and examples refer to -Online version.
  
#>
 
    [CmdletBinding()]
 
    Param (
        [Parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
         
        [String[]]  $ComputerName = $env:COMPUTERNAME,
 
        [Parameter()]
        [switch]    $IncudeBatteryExpiration
        ) 
 
    BEGIN {
        $Object = @()
        $Today = Get-Date -Format 'yyyy-MM-dd'
    }
 
    PROCESS {
        Foreach ($Computer in $ComputerName) {
            Try {
                $Bios = Get-WmiObject Win32_Bios -ComputerName $Computer -ErrorAction Stop
                $SerialNumber = $Bios.SerialNumber
                $Manufacturer = $Bios.Manufacturer
 
                    If ($Manufacturer -eq "LENOVO") {
                            $ApiObject = Invoke-RestMethod -Uri "http://supportapi.lenovo.com/V2.5/Warranty?Serial=$SerialNumber"
                        } else {
                            Write-Error "BIOS manufacturer is not Lenovo; unable to proceed." -ErrorAction Stop
                    }
 
                    If ($IncudeBatteryExpiration) {
                            $Notebook = $ApiObject.Warranty | Where-Object {($_.ID -like "1EZ*") -or ($_.ID -eq "36Y") -or ($_.ID -eq "3EZ")}
                        } else {
                            $Notebook = $ApiObject.Warranty | Where-Object {($_.ID -eq "36Y") -or ($_.ID -eq "3EZ")}    
                    }
                 
                    foreach ($ID in $Notebook) {
 
                        $EndDate   = $ID.End.Split('T')[0]
                        $StartDate = $ID.Start.Split('T')[0]
 
                        if ($EndDate -gt $Today) {
                                $DaysRemaining = New-TimeSpan -Start $Today -End $EndDate | select -ExpandProperty Days
                                $DaysRemaining = $DaysRemaining - 1
 
                                $Properties = @{
                                                ComputerName  = $Computer
                                                Type          = $ID.Type
                                                ID            = $ID.ID
                                                StartDate     = $StartDate
                                                EndDate       = $EndDate
                                                DaysRemaining = $DaysRemaining
                                                Status        = 'Active'
                                                }
 
                            } else {
                                $Properties = @{
                                                ComputerName  = $Computer
                                                Type          = $ID.Type
                                                ID            = $ID.ID
                                                StartDate     = $StartDate
                                                EndDate       = $EndDate
                                                DaysRemaining = 0
                                                Status        = 'Expired'
                                                }
 
                        }
                     
                        $Object += New-Object -TypeName PSObject -Property $Properties | Select ComputerName, Type, ID, StartDate, EndDate, DaysRemaining, Status
                    }
                }
 
            catch {
                $ErrorMessage = $Computer + " Error: " + $_.Exception.Message
 
            } finally {
 
                Write-Output $Object
                $Object = $null
 
                    if ($ErrorMessage) {
                        #Write-Output $ErrorMessage
                        $ErrorMessage = $null
                    }
            }
        }
 
    }
 
    END {}
 
}
