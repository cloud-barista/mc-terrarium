## Proof of concepts related to multi-cloud networks

We will explore the functions and necessary properties such as creation, diary, update, and deletion of resources/services for configuring a multi-cloud network.


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
rm install-opentofu.sh
```

#### Get source code

In this readme, `~/poc-mc-net-tf` is used as the default directory.
```bash
git clone https://github.com/cloud-barista/poc-mc-net-tf.git ~/poc-mc-net-tf
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
    aws_access_key_id = A2KXXXXXXXXXXX4XXXSD
    aws_secret_access_key = AB2YjR92sdflkj4D34XXXXXXXXXXXXXXXXXXXXXX
    ```

</details>

3. Store your AWS credential `~/.aws/credentials`

##### MS Azure

1. Install MS Azure CLI (It should be checked.)

See [How to install the Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

2. Prepare your MS Azure credential (i.e., a service principal)

See [Create a service principal for use with Microsoft Purview](https://learn.microsoft.com/en-us/purview/create-service-principal-azure)
See [Create an Azure service principal with Azure CLI](https://learn.microsoft.com/en-us/cli/azure/azure-cli-sp-tutorial-1?tabs=bash)

3. Store MS Azure credential `.tofu/secrets/credential-azure.env`

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
source .tofu/secrets/credential-azure.env
az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
```

##### GCP

1. Prepare your GCP credential

See [Service account credentials](https://developers.google.com/workspace/guides/create-credentials#service-account)

2. Store your GCP credential `.tofu/secrets/credential-gcp.json`

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
cd ~/poc-mc-net-tf
make
```

##### Run API server binary
```bash
cd ~/poc-mc-net-tf
make run
```

#### Container based execution

Check a tag of poc-mc-net-tf container image in cloudbaristaorg/poc-mc-net-tf

##### Run poc-mc-net-tf container

Note - AWS and GCP credentials must be prepared and injected when running a container. (see `--mount type=****`)
Note - Modify `source="${PWD}"/.tofu/secrets/` to the appropriate path.

```bash
docker run \
--mount type=bind,source="${PWD}"/.tofu/secrets/,target=/app/.tofu/secrets/ \
--mount type=bind,source="${PWD}"/.tofu/secrets/,target=/.aws/ \
-p 8888:8888 \
--name poc-mc-net-tf \
cloudbaristaorg/poc-mc-net-tf:latest
```

#### Access Swagger UI

You can find the default username and apssword to access to API dashboard when the API server runs.

URL: http://localhost:8888/mc-net/swagger/index.html

Note - You can find API documentation on Swagger UI.
Note - For testing API, you can import Thunder Client collection (`thunder-collection_tofu-apis.json`).
This has been exported Thunder Client on VSCode.

---

### Appendix

**Current APIs**

![image](https://github.com/cloud-barista/poc-mc-net-tf/assets/7975459/2128613a-bb40-410f-8ddd-4c49156e62cd)

**Example order of calls**
1. GET /tofu/version
2. POST /tofu/init (This will take some times.)
3. POST /tofu/config/vpn-tunnels
4. POST /tofu/plan/vpn-tunnels/{namespaceId}
5. POST /tofu/apply/vpn-tunnels/{namespaceId} (This will take at least 3 minutes.)
6. GET /tofu/show/{namespaceId}
7. DELETE /tofu/destroy/vpn-tunnels/{namespaceId} (This will take some times.)
8. DELETE /tofu/cleanup/{namespaceId}
