#
# Function used to interact with the UAG API
#
function Invoke-ApiRequest {
    param (
        [Parameter(Mandatory=$true)]
        [string]$uag_host,

        [Parameter(Mandatory=$true)]
        [string]$adminUsername,

        [Parameter(Mandatory=$true)]
        [string]$adminPassword,

        [Parameter(Mandatory=$true)]
        [string]$apiUrl,

        [Parameter(Mandatory=$true)]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE')]
        [string]$httpMethod,

        [Parameter(Mandatory=$false)]
        [string]$Body
    )

    $API_Settings = @{
        Headers     = @{ "Authorization" = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($adminUsername):$($adminPassword)"))}
        Method      = $httpMethod
        ContentType = "application/json"
        Body        = $Body
    }

    $API_Endpoint = "https://" + $uag_host + ":9443" + $apiUrl

    try {
        write-host $headers
        $response = Invoke-RestMethod -Uri $API_Endpoint -Method $API_Settings.Method -Headers $API_Settings.Headers -ContentType $API_Settings.ContentType -Body $API_Settings.Body -SkipCertificateCheck
        return $response
    }
    catch {
        Write-Error "Failed to invoke API request: $_"
        return $null
    }
}

# Find the old certificate with the friendly name 'vdm' and rename it to 'vdm old'
function Update-CertFriendlyName {
    # Define the friendly names
    $oldFriendlyName = 'vdm'
    $newFriendlyName = 'CONNECTION SERVER DOMAIN'  ### -- Update

    # Get today's date
    $today = (get-date).Date

   
   # Get the new cert created today
   # $newCert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.NotBefore.Date -eq $today -and $_.FriendlyName -like $newFriendlyName }

    $global:newCert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.FriendlyName -like $newFriendlyName -and $_.NotBefore.Date -eq (Get-Date).Date }

    if ($global:newCert -ne $null) {
        # Get the old cert(s) with the friendly name 'vdm'
        $oldCerts = Get-ChildItem -Path Cert:\LocalMachine\My |
                    Where-Object { $_.FriendlyName -eq $oldFriendlyName }

        # Change the friendly name of the old certs from 'vdm' to 'vdm old'
        foreach ($oldCert in $oldCerts) {
            $oldCert.FriendlyName = 'vdm old'
        }

        # Change the friendly name of the new cert to 'vdm'
        $global:newCert.FriendlyName = $oldFriendlyName


    } 
    
    else {
        
            throw "No cert found -- Ending"
    }
}

#Run Rename 
Update-CertFriendlyName

#
# //PARAM CONSTANTS
#

[string]$uag_host = "UAG DOMAIN"  ### -- Update
[string]$adminUsername = "UAG USER"  ### -- Update
$adminPassword = "UAG PASSWORD"  ### -- Update

#Get JSON Req and replace with new thumprint 

$JSON = Invoke-ApiRequest -uag_host $uag_host -adminUsername $adminUsername -adminPassword $Creds -apiUrl "/rest/v1/config/edgeservice/VIEW" -httpMethod "GET"
$JSON #| ConvertFrom-Json
$JSON.proxyDestinationUrlThumbprints = $newCert.Thumbprint
$JSON = $JSON | ConvertTo-Json  -Depth 20
Write-Host $JSON

#PUT new JSON to API with new Thumbprint 
Invoke-ApiRequest -uag_host $uag_host -adminUsername $adminUsername -adminPassword $Creds -apiUrl "/rest/v1/config/edgeservice/view" -httpMethod "PUT" -Body $JSON
 
#Restart VMWare Horizon Services
$vmservices = "VGAuthService", "wsdct", "VMBlastSG", "wsbroker", "wsnm", "wsmsgbus", "PCOIPSG", "wstunnel", "wstomcat", "vm3dservice", "ADAM_VMwareVDMDS" # replace with the names of the services you want to restart

foreach ($service in $vmservices) {
        Write-host "Restarting $service"
        Restart-Service -Name $service -Verbose -Force
    }

