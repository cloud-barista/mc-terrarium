# Multi-Cloud Terrarium

<p align="center">
  <img src="https://github.com/user-attachments/assets/3ab8720f-221d-45a6-8d7a-73222c98edb1" width="50%" height="50%" >
</p>

<p align="center">
  <strong>🚀 Powered by OpenTofu</strong><br>
  <strong>🤝 A Collaboration Between Cloud-Barista & OpenTofu</strong>
</p>

**Multi-Cloud Terrarium (mc-terrarium)** is an open-source project designed to provide an environment—an **infrastructure terrarium**—that enhances multi-cloud infrastructure management.

## 🌟 Features & Components

The infrastructure terrarium consists of:

- **Multi-Cloud Infrastructure Metadata**: Managed by Cloud-Barista to provide a unified view of multi-cloud environments.
- **Infrastructure Enrichment with OpenTofu**: Extends Cloud-Barista’s capabilities by provisioning additional resources and services beyond its native support.
- **Infrastructure Code (.tf)**: Defines and structures infrastructure components and enrichments.
- **Other Evolving Components**: Continuously enhancing multi-cloud infrastructure capabilities.

## 🌍 Multi-Cloud Networking & Beyond

Currently, mc-terrarium provides **multi-cloud networking** features, such as **site-to-site VPN** setup. It will continue to evolve, enabling you to seamlessly build and manage the multi-cloud infrastructure you need.

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
