## Functions 

#Check for Choco or install 
[string]$packageName = "openssl"

# Check if OpenSSL is already installed
if (Get-Command openssl -ErrorAction SilentlyContinue) {
    Write-Host "OpenSSL is already installed."
}

else {
    # Check if Chocolatey is installed
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        # Install Chocolatey
        Write-Host "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }

    # Install OpenSSL using Chocolatey
    Write-Host "Installing OpenSSL..."
    choco install $packageName -y

    # Check if OpenSSL installation was successful
    if (Get-Command openssl -ErrorAction SilentlyContinue) {
        
        Write-Host "OpenSSL has been successfully installed."
    }
    
    else {
        
        Write-Host "Failed to install OpenSSL."
    }
}

#Get Cert from localstore 
$today = Get-Date
$friendlyName = "DOMAIN FRIENDLY NAME" ### -- Update

$cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.FriendlyName -like $friendlyName -and $_.NotBefore.Date -eq $today.Date }

# Check if a new certificate is found
if ($null -eq $cert) {
    # No new certificate found
    
    Write-Host "No new certificate found."
    Throw
}

$path = 'C:\exports'
if (!(Test-Path -Path $path)) {
    
    New-Item -ItemType Directory -Path $path
}

#Set Cert Path
Set-Location -Path $path

# Now contains the certificate
[string]$PwdStr = "CERT PASSWORD"  ### -- Update
$cert | Export-PfxCertificate -FilePath "c:\exports\export.pfx" -Password (ConvertTo-SecureString -String $PwdStr -Force -AsPlainText)

[string]$pfxPath = "c:\exports\export.pfx"
$password = ConvertTo-SecureString -String $PwdStr -Force -AsPlainText

$pfx = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$pfx.Import($pfxPath, $password, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)

# Now $pfx contains the certificate and private key


####  Convert PFX to Cert & Priv pem

#Export Cert & Key from PFX

#Set OpenSSL Path 

$env:PATH = $env:PATH + ";C:\Program Files\OpenSSL-Win64\bin"

openssl pkcs12 -in $pfxPath -clcerts -nokeys -out certificate.pem -password pass:$PwdStr

openssl pkcs12 -in $pfxPath -nocerts -nodes -out key.pem -password pass:$PwdStr

#Trim Windows output info from Cer & Key Files 
$Priv = (Get-Content -Raw -Path C:\exports\key.pem)
$PrivStart = $Priv.IndexOf('-----BEGIN PRIVATE KEY-----')
$PrivContent = $Priv.Substring($PrivStart)

$Cer = (Get-Content -Raw -Path C:\exports\certificate.pem)
$CerStart = $Cer.IndexOf('-----BEGIN CERTIFICATE-----')
$CerContent = $Cer.Substring($CerStart)

#Reformats JSON cert all onto one line
$formattedCer = $CerContent -replace '\r', '' -replace '\n', '\n'
$formattedKey = $PrivContent -replace '\r', '' -replace '\n', '\n'

 # Api Function 
 $c
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

#Build JSON file from new Cert
$JSON = '{"privateKeyPem":"' + $formattedkey + '","certChainPem":"' + $formattedCer + '"}'

[string]$uag_host = "UAG URL"  ### -- Update
[string]$adminUsername = "UAG USERNAME"  ### -- Update
[string]$adminPassword = "UAG PASSWORD"  ### -- Update


#PUT new JSON to API with new Thumbprint 
Invoke-ApiRequest -uag_host $uag_host -adminUsername $adminUsername -adminPassword $adminPassword -apiUrl "/rest/v1/config/certs/ssl/end_user" -httpMethod "PUT" -Body $JSON

#Remove Exports Folder from the system
Remove-Item -Path C:\exports -Force 


