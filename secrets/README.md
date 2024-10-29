## CSP secrets

This is a directory for CSP credentials to run and use MC-Terrarium.

> [!IMPORTANT]
> It would be best if you managed CSP credentials securely.

> [!WARNING]
> Take special pay attention to prevent leakage to the outside.

This is a sample to get credentials.

#### AWS

1. Install AWS CLI (It should be checked.)
2. Prepare your AWS credential

See [Set and view configuration settings using commands](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html#cli-configure-files-methods)

<details>
  <summary>Click to see sample</summary>

    ```
    [default]
    AWS_ACCESS_KEY_ID=A2KXXXXXXXXXXX4XXXSD
    AWS_SECRET_ACCESS_KEY=AB2YjXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    ```

</details>

3. Store your AWS credential `secrets/credentials`

4. (For source code build and run) Store your AWS credential `~/.aws/credentials`

#### MS Azure

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

4. (For source code build and run) Run

```bash
source secrets/credential-azure.env
az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
```

#### GCP

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

## Getting started

### Source code based installation and exeuction

#### Build

```bash
cd ~/mc-terrarium
make
```

#### Run API server binary

```bash
cd ~/mc-terrarium
make run
```

### Container based execution

Check a tag of mc-terrarium container image in cloudbaristaorg/mc-terrarium

#### Run mc-terrarium container

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
-p 8055:8055 \
--name mc-terrarium \
cloudbaristaorg/mc-terrarium:latest
```
