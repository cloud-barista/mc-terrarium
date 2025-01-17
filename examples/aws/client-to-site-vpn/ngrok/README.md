# Ngrok Docker Setup

This directory contains a Docker-based setup for running Ngrok, which creates secure tunnels to localhost for easy sharing and testing of web services.

> [!WARNING]
> It’s important to check with the security team about whether ngrok is allowed before using it. (I tried to strengthen security... and got a friendly reminder from the security team! :sweat_smile:)

## Prerequisites

- Docker and Docker Compose installed
- Ngrok account and authtoken (Sign up at [ngrok.com](https://ngrok.com))
- (Optional) Static Domain from Ngrok

## Quick Start

Get the bootstapper script

```shell
mkdir ~/ngrok
cd ~/ngrok
wget https://raw.githubusercontent.com/cloud-barista/mc-terrarium/refs/heads/main/examples/aws/client-to-site-vpn/ngrok/bootstrapper.sh
chmod +x bootstrapper.sh
```

Run the script with YOUR_AUTHTOKEN and TARGET_PORT

```shell
sudo ./bootstrapper.sh --ngrok-authtoken=your_authtoken --target-port=your_target_port
```

Note - the environment variables in `.env`:

- `NGROK_AUTHTOKEN` (Required): Your ngrok authentication token
- `NGROK_STATIC_DOMAIN` (Optional): Your static domain (if available)
- `TARGET_PORT` (Optional): Local port to expose (default: 80)

### Manual Setup

1. Set up environment variables in `.env`
2. Start the service:

```shell
docker compose up -d
```

## Features

- Automatic tunnel creation
- Support for static domains (Premium feature)
  - 1 static domain is provided for free if for development purposes
- Configurable target port
- Docker-based deployment
- Bootstrap script for easy setup

## Monitoring

- Access the ngrok web interface at `http://localhost:4040`
  > **Note:** Ensure that the ngrok web interface is not exposed to the public for security reasons.
- View tunnel status and request/response inspection

## Troubleshooting

1. If the tunnel doesn't start:

   - Check if your authtoken is valid
   - Ensure the target port is accessible
   - Verify Docker is running

2. If you can't access the web interface:
   - Confirm the ngrok container is running
   - Check Docker logs: `docker compose logs`

## More Information

For more information, visit the [ngrok website](https://ngrok.com/).
