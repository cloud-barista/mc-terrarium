# Multi-Cloud Terrarium

Multi-Cloud Terrarium (mc-terrarium) aims to provide an environment (i.e., infrastructure terrarium) and features to enrich multi-cloud infrastructure.

The infrastructure terrarium consists of:

- <ins>information of cloud resources/services</ins>, which is created and managed by Cloud-Barista,
- <ins>TF configuration files</ins>, which specify resources/services to be add, and
- <ins>OpenTofu</ins>, which create and manage resources on cloud platforms.
- and so on.

mc-terrarium currently provides features for multi-cloud network, such as site-to-site VPN. This will gradually evolve to enable you to build the multi-cloud infrastructure you need.

## Prerequisites

### Install OpenTofu

- See [Installing OpenTofu](https://opentofu.org/docs/intro/install/)
- Refer to [the custom installer for Ubuntu 22.04](https://github.com/cloud-barista/mc-terrarium/blob/main/scripts/install-tofu.sh)

### Get source code

In this readme, the default root directory is `~/mc-terrarium`.

```bash
git clone https://github.com/cloud-barista/mc-terrarium.git ~/mc-terrarium
```

### Install swag

If you got an error because of missing swag, install swag:

```bash
go install github.com/swaggo/swag/cmd/swag@latest
```

### Prepare credentials

Prepare credentials by looking at the README and templates in the `/secrets` directory.

Note - There may be an issue regarding Credential settings. Contributions are welcome.

## Up and run MC-Terrarium

- Supported Docker Compose based execution.
- Required a Docker network, `terrarium_network`

> [!NOTE]
> services in other docker composes can access the `mc-terrarium` service, like `http://mc-terrarium:8055/terrarium`.  
> _Condition: Set up `terrarium_network` in external docker compose_

You can do this by running the following command:

```bash
make compose-up
```

The command to build and run the source code is as follows:

```bash
make compose
```

### Access Swagger UI

You can find the default username and password to access to API dashboard when the API server runs.

URL: http://localhost:8055/terrarium/swagger/index.html

Note - You can find API documentation on Swagger UI.

---

## Appendix

**The example of API call sequence**

1. POST /tr/{trId}/vpn/gcp-azure/env
2. POST /tr/{trId}/vpn/gcp-azure/infracode
3. POST /tr/{trId}/vpn/gcp-azure/plan
4. POST /tr/{trId}/vpn/gcp-azure (Time-consuming API, return a request ID and be processed asynchronously)
5. GET /tr/{trId}/vpn/gcp-azure/request/{requestId}/status (Check the above API status)
6. GET /tr/{trId}/vpn/gcp-azure (Get resource info with detail (refined, raw))
7. DELETE /tr/{trId}/vpn/gcp-azure (Time-consuming API, return a request ID and be processed asynchronously)
8. DELETE /tr/{trId}/vpn/gcp-azure/env
