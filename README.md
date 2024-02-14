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

Prepare AWS credential and run `aws configure`

See [Set and view configuration settings using commands](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html#cli-configure-files-methods)

##### GCP

Store your GCP credential `.tofu/secrets/credential-gcp.json`

See [Service account credentials](https://developers.google.com/workspace/guides/create-credentials#service-account)

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
