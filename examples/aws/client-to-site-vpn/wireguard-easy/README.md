# WireGuard Easy VPN Setup

This guide explains how to set up a WireGuard VPN server using WireGuard Easy, a web-based management interface.

## Prerequisites

- Linux server with Docker and Docker Compose installed
- Open ports 51820 (UDP) and 51821 (TCP) on your firewall
- Public IP address (will be auto-detected if not specified)

## Generate Password Hash

Before running the bootstrapper script, you need to generate a bcrypt hash for your password.

> [!NOTE]
> The default password hash in the script is for 'multicloud123!'.

### Recommended Method: Using wg-password Tool

Reference: see [wg-password](https://github.com/wg-easy/wg-easy/blob/master/How_to_generate_an_bcrypt_hash.md)

The most reliable way to generate a password hash is using the official wg-password tool:

```shell
docker run --rm -it ghcr.io/wg-easy/wg-easy wgpw 'YOUR_PASSWORD'
```

```shell
PASSWORD_HASH='$2a$12$jFMReyiKFUKvLWEirZbsheuIqMJdS.PK0rZNLUklp.o.q4WtSYCy6'
```

**Important Notes:**

- make sure to enclose your password in single quotes when you run docker run command:

```shell
$ echo $2b$12$coPqCsPtcF <-- not correct
b2
$ echo "$2b$12$coPqCsPtcF" <-- not correct
b2
$ echo '$2b$12$coPqCsPtcF' <-- correct
$2b$12$coPqCsPtcF
```

- don't wrap the generated hash password in single quotes when you use docker-compose.yaml. Instead, replace each `$` symbol with two `$$` symbols. For example:

```yaml
- PASSWORD_HASH=$$2y$$10$$hBCoykrB95WSzuV4fafBzOHWKu9sbyVa34GJr8VV5R/pIelfEMYyG
```

### Alternative Methods

If you can't use the wg-password tool, you can use these alternatives.

Using Python:

```bash
python3 -c "import bcrypt; print(bcrypt.hashpw('your_password'.encode(), bcrypt.gensalt()).decode())"
```

After generating your hash, update it in the bootstrapper script or directly in the .env file.

## Quick Start

Get and run the bootstrapper script:

```shell
mkdir ~/wg-easy
cd ~/wg-easy
wget https://raw.githubusercontent.com/cloud-barista/mc-terrarium/refs/heads/main/examples/aws/client-to-site-vpn/wireguard-easy/bootstrapper.sh
chmod +x bootstrapper.sh
sudo ./bootstrapper.sh
```

The script will:

- Auto-detect your public IP (or use provided IP)
- Use the default password hash ('multicloud123!')
- Create .env file with default configurations
- Download docker-compose.yaml if not present
- Start the WireGuard VPN server

### Optional Parameters

You can customize the setup using these parameters:

1. Basic usage with custom IP:

```bash
./bootstrapper.sh --public-ip=YOUR_PUBLIC_IP
```

2. Using custom password hash (replace the default 'multicloud123!'):

```bash
./bootstrapper.sh \
  --public-ip=YOUR_PUBLIC_IP \
  --password-hash='$$2y$$10$$YourCustomPasswordHashHere'
```

3. Full configuration example:

```bash
./bootstrapper.sh \
  --public-ip=YOUR_PUBLICIP_HERE \
  --port=51820 \
  --default-address=10.2.0.x \
  --dns=1.1.1.1 \
  --allowed-ips="10.0.0.0/8, 192.168.0.0/16" \
  --password-hash='$$2y$$10$$YourCustomPasswordHashHere'
```

## Accessing the Web Interface

1. Open your browser and navigate to:

```
http://YOUR_SERVER_IP:51821
```

2. Login with default credentials:

- Password: multicloud123!

## Default Configuration

- VPN Subnet: 10.1.0.x
- WireGuard Port: 51820
- Web UI Port: 51821
- Default DNS: 8.8.8.8
- Allowed IPs: 10.0.0.0/8

## Managing Clients

Through the web interface, you can:

- Add new clients
- Generate QR codes for mobile devices
- Enable/disable existing clients

## Security Notes

> [!IMPORTANT]
>
> - Change the default password ('multicloud123!')
> - Generate a new password hash and update the configuration
> - Keep your .env file secure and backup safely
> - Regularly update the Docker image
> - Consider enabling additional security features in docker-compose.yaml

## Troubleshooting

1. If the service doesn't start:

   - Check if ports 51820 and 51821 are open
   - Verify Docker and Docker Compose installation
   - Check system logs using `docker compose logs`

2. If clients can't connect:

   - Verify the public IP is correct
   - Check client configurations
   - Ensure firewall rules are properly set

3. If you have password-related issues:git
   - Verify that the PASSWORD_HASH in .env has double `$$` symbols
   - Ensure the password hash was generated correctly with single quotes
   - Try regenerating the password hash if login fails

## More Information

For advanced configuration options and detailed documentation, visit the [WireGuard Easy GitHub repository](https://github.com/wg-easy/wg-easy).
