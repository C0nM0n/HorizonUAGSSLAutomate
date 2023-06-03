# PowerShell Scripts for VMware Horizon View Certificate Management and UAG API Interaction

These PowerShell scripts are designed to automate the process of managing certificates in a VMware Horizon View environment and interacting with the Unified Access Gateway (UAG) API.

The scripts encompass several core functionalities:

## 1. Interacting with the UAG API

The Invoke-ApiRequest function interacts with the UAG API. It makes HTTP requests (GET, POST, PUT, DELETE) to the specified API URL and handles the corresponding response. It uses Basic Authentication to pass the admin credentials in the header.

## 2. Certificate Management

The scripts offer robust management of certificates, enabling you to identify an old certificate, rename it, and replace it with a new one. The Update-CertFriendlyName function is used for renaming certificates in the local certificate store.

## 3. OpenSSL Installation

The scripts automatically check if OpenSSL is installed in the system. If not, they install Chocolatey (if it's not already present) and use it to install OpenSSL.

## 4. Certificate Retrieval, Export, and Conversion

The scripts retrieve a new certificate from the local certificate store, export it to a PFX file, and then use OpenSSL to convert this PFX certificate to PEM format (splitting into a separate certificate and key PEM files).

## 5. Updating UAG with New Certificate Information

The scripts build a JSON object with the newly created certificate and private key and make a PUT request to the UAG API to upload the new SSL certificate.

## 6. Restarting VMware Horizon View Services

The scripts perform a restart of the VMware Horizon View services after updating the certificate.

## 7. Cleanup

Finally, the scripts clean up any temporary files and folders created during the process.

## Notes:

- Placeholder values in the scripts (`'UAG DOMAIN'`, `'UAG USER'`, `'UAG PASSWORD'`, `'DOMAIN FRIENDLY NAME'`, `'CERT PASSWORD'`, `'UAG URL'`, `'UAG USERNAME'`, and `'UAG PASSWORD'`) need to be replaced with your actual values before running the script.
- Ensure the account running the script has the necessary permissions to interact with the UAG API and manage the certificates.
- The scripts assume the UAG API is accessible via HTTPS on port 9443. If this is not the case for your setup, adjust the scripts accordingly.
- In production environments, handle credentials securely.

By automating these critical tasks, the scripts improve efficiency and reduce the likelihood of errors in managing certificates and interacting with the UAG API in a VMware Horizon View environment.