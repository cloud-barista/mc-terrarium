## Multi-Cloud Terrarium

Multi-Cloud Terrarium (mc-terrarium) aims to provide an environment (i.e., infrastructure terrarium) and features to enrich multi-cloud infrastructure.

The infrastructure terrarium consists of:

- <ins>information of cloud resources/services</ins>, which is created and managed by Cloud-Barista,
- <ins>TF configuration files</ins>, which specify resources/services to be add, and
- <ins>OpenTofu</ins>, which create and manage resources on cloud platforms.
- and so on.

mc-terrarium currently provides features for multi-cloud network, such as site-to-site VPN. This will gradually evolve to enable you to build the multi-cloud infrastructure you need.

### Prerequisites

#### Install OpenTofu

See [Installing OpenTofu](https://opentofu.org/docs/intro/install/)

##### Install by the installer

```bash
# Download the installer script:
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
# Alternatively: wget --secure-protocol=TLSv1_2 --https-only https://get.opentofu.org/install-opentofu.sh -O install-opentofu.sh

# Give it execution permissions:
chmod +x install-opentofu.sh

# Please inspect the downloaded script

# Run the installer:
./install-opentofu.sh --install-method deb

# Remove the installer:
rm -f install-opentofu.sh
```

#### Get source code

In this readme, `~/mc-terrarium` is used as the default directory.

```bash
git clone https://github.com/cloud-barista/mc-terrarium.git ~/mc-terrarium
```

#### Install swag

If you got an error because of missing swag, install swag:

```bash
go install github.com/swaggo/swag/cmd/swag@latest
```

#### Setup credentials

Note - There may be an issue regarding Credential settings. Contributions are welcome.

##### AWS

1. Install AWS CLI (It should be checked.)

2. Prepare your AWS credential

See [Set and view configuration settings using commands](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html#cli-configure-files-methods)

<details>
  <summary>Click to see sample</summary>

    ```
    [default]
    AWS_ACCESS_KEY_ID=A2KXXXXXXXXXXX4XXXSD
    AWS_SECRET_ACCESS_KEY=AB2YjR92sdflkj4D34XXXXXXXXXXXXXXXXXXXXXX
    ```

</details>

3. Store your AWS credential `~/.aws/credentials`

##### MS Azure

1. Install MS Azure CLI (It should be checked.)

See [How to install the Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

2. Prepare your MS Azure credential (i.e., a service principal)

See [Create a service principal for use with Microsoft Purview](https://learn.microsoft.com/en-us/purview/create-service-principal-azure)
See [Create an Azure service principal with Azure CLI](https://learn.microsoft.com/en-us/cli/azure/azure-cli-sp-tutorial-1?tabs=bash)

3. Store MS Azure credential `secrets/credential-azure.env`

<details>
  <summary>Click to see sample</summary>

    ```
    ARM_CLIENT_ID=asd9f234-1fs2-xxxx-xxxx-xxxxxxxxxxxx
    ARM_CLIENT_SECRET=a23i11G~nxxxxXxxXXxx-xxxXXXX3XxxxXXXXxxx
    ARM_TENANT_ID=asdf231d-8s7s-11xx-x111-111111xxx111
    ARM_SUBSCRIPTION_ID=e14fhg99-11xx-1111-11x1-111xx11x1x11
    ```

</details>

4. Run

```bash
source secrets/credential-azure.env
az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
```

##### GCP

1. Prepare your GCP credential

See [Service account credentials](https://developers.google.com/workspace/guides/create-credentials#service-account)

2. Store your GCP credential `secrets/credential-gcp.json`

<details>
  <summary>Click to see sample</summary>

    ```json
    {
        "type": "service_account",
        "project_id": "YOUR_PROJECT_ID",
        "private_key_id": "xx0x0x0x0x0xx0xxxxx0xx0xx0x0x0xx0x0xxxx0",
        "private_key": "-----BEGIN PRIVATE KEY-----\YOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEYYOURPRIVATEKEY==\n-----END PRIVATE KEY-----\n",
        "client_email": "YOUR_SERVICE_ACCOUNT@YOUR_PROJECT_ID.iam.gserviceaccount.com",
        "client_id": "000000000000000000000",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/YOUR_SERVICE_ACCOUNT%40YOUR_PROJECT_ID.iam.gserviceaccount.com"
    }
    ```

</details>

### Getting started

#### Source code based installation and exeuction

##### Build

```bash
cd ~/mc-terrarium
make
```

##### Run API server binary

```bash
cd ~/mc-terrarium
make run
```

#### Container based execution

Check a tag of mc-terrarium container image in cloudbaristaorg/mc-terrarium

##### Run mc-terrarium container

Note - Credentials for AWS, Azure, and GCP must be prepared and injected when running a container.

Note - Modify `source="${PWD}"/secrets/` to the appropriate path.

Note - About credential injection:

- Set AWS credenttal as environment variable: `--env-file "${PWD}"/secrets/credentials`
- Set Azure credential as environment variable: `--env-file "${PWD}"/secrets/credentials`
- Mount GCP credential file: `--mount type=bind,source="${PWD}"/secrets/,target=/app/secrets/`

```bash

docker run \
--env-file "${PWD}"/secrets/credentials \
--env-file "${PWD}"/secrets/credential-azure.env \
--mount type=bind,source="${PWD}"/secrets/,target=/app/secrets/ \
-p 8888:8888 \
--name mc-terrarium \
cloudbaristaorg/mc-terrarium:latest
```

#### Access Swagger UI

You can find the default username and password to access to API dashboard when the API server runs.

URL: http://localhost:8888/terrarium/swagger/index.html

Note - You can find API documentation on Swagger UI.

---

### Appendix

**The example of API call sequence**

1. POST /tr/{trId}/vpn/gcp-azure/env
2. POST /tr/{trId}/vpn/gcp-azure/infracode
3. POST /tr/{trId}/vpn/gcp-azure/plan
4. POST /tr/{trId}/vpn/gcp-azure (Time-consuming API, return a request ID and be processed asynchronously)
5. GET /tr/{trId}/vpn/gcp-azure/request/{requestId}/status (Check the above API status)
6. GET /tr/{trId}/vpn/gcp-azure (Get resource info with detail (refined, raw))
7. DELETE /tr/{trId}/vpn/gcp-azure (Time-consuming API, return a request ID and be processed asynchronously)
8. DELETE /tr/{trId}/vpn/gcp-azure/env
