#!/usr/bin/env python3
"""
MC-Terrarium CSP Credential Registration

Decrypts ~/.cloud-barista/credentials.yaml.enc and registers
CSP credentials into OpenBao KV v2 secret engine.

Designed for compatibility with cb-tumblebug's credential format,
enabling unified Cloud-Barista credential management.

Usage:
  uv run register-credentials.py                                    # Full init (interactive)
  uv run register-credentials.py -y                                 # Non-interactive
  uv run register-credentials.py --credentials-only                 # Credential import only
  uv run register-credentials.py --openbao-only                     # OpenBao init/unseal only
  uv run register-credentials.py --key-file ~/.cloud-barista/.tmp_enc_key
"""

import argparse

# import json
import os
import subprocess
import sys
import time

import requests
import yaml
from colorama import Fore, Style
from colorama import init as colorama_init

# Initialize colorama
colorama_init(autoreset=True)

# ── Argument parsing ──────────────────────────────────────────────

parser = argparse.ArgumentParser(
    description="Initialize MC-Terrarium: OpenBao setup and CSP credential import.",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog="""
Examples:
  %(prog)s                                # Full initialization (interactive)
  %(prog)s -y                             # Non-interactive (auto-confirm)
  %(prog)s --credentials-only             # Import credentials only
  %(prog)s --openbao-only                 # OpenBao init/unseal only
  %(prog)s --key-file /path/to/keyfile    # Use key file for decryption
    """,
)
parser.add_argument(
    "-y",
    "--yes",
    action="store_true",
    help="Automatically proceed without confirmation prompts",
)
parser.add_argument(
    "--credentials",
    "--credentials-only",
    action="store_true",
    dest="credentials_only",
    help="Register CSP credentials only (skip OpenBao init/unseal)",
)
parser.add_argument(
    "--openbao",
    "--openbao-only",
    action="store_true",
    dest="openbao_only",
    help="OpenBao init/unseal only (skip credential registration)",
)
parser.add_argument(
    "--key-file",
    type=str,
    default=None,
    help="Path to decryption key file (default: ~/.cloud-barista/.tmp_enc_key, then prompt)",
)
args = parser.parse_args()

# Determine operations
run_all = not (args.credentials_only or args.openbao_only)
run_openbao = run_all or args.openbao_only
run_credentials = run_all or args.credentials_only

# ── Configuration ─────────────────────────────────────────────────

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)

VAULT_ADDR = os.getenv("VAULT_ADDR", "http://localhost:8200")
VAULT_TOKEN = os.getenv("VAULT_TOKEN", "")

# KV v2 path configuration
# Mount: "secret" (default KV v2 mount — OpenTofu/Terraform standard)
# Prefix: "csp" (logical namespace for CSP credentials)
# CLI usage:  bao kv get secret/csp/aws
# HCL usage:  vault_kv_secret_v2 { mount = "secret", name = "csp/aws" }
# API path:   /v1/secret/data/csp/{provider}  ("data" is KV v2 API convention)
KV_MOUNT = "secret"
SECRET_PREFIX = "csp"

CRED_PATH = os.path.join(os.path.expanduser("~"), ".cloud-barista")
ENC_FILE = os.path.join(CRED_PATH, "credentials.yaml.enc")
KEY_FILE = os.path.join(CRED_PATH, ".tmp_enc_key")

# CSP key mapping: cb-tumblebug YAML keys → Terrarium/OpenTofu env var keys
KEY_MAP = {
    "aws": {
        "ClientId": "AWS_ACCESS_KEY_ID",
        "ClientSecret": "AWS_SECRET_ACCESS_KEY",
    },
    "azure": {
        "ClientId": "ARM_CLIENT_ID",
        "ClientSecret": "ARM_CLIENT_SECRET",
        "TenantId": "ARM_TENANT_ID",
        "SubscriptionId": "ARM_SUBSCRIPTION_ID",
    },
    "gcp": {
        "ProjectID": "project_id",
        "ClientEmail": "client_email",
        "PrivateKey": "private_key",
        "private_key_id": "private_key_id",
        "client_id": "client_id",
    },
    "alibaba": {
        "ClientId": "ALIBABA_CLOUD_ACCESS_KEY_ID",
        "ClientSecret": "ALIBABA_CLOUD_ACCESS_KEY_SECRET",
    },
    "ibm": {
        "ApiKey": "IC_API_KEY",
    },
    "ncp": {
        "ClientId": "NCLOUD_ACCESS_KEY",
        "ClientSecret": "NCLOUD_SECRET_KEY",
    },
    "tencent": {
        "ClientId": "TENCENTCLOUD_SECRET_ID",
        "ClientSecret": "TENCENTCLOUD_SECRET_KEY",
    },
    "openstack": {
        "IdentityEndpoint": "OS_AUTH_URL",
        "Username": "OS_USERNAME",
        "Password": "OS_PASSWORD",
        "DomainName": "OS_DOMAIN_NAME",
        "ProjectID": "OS_PROJECT_NAME",
    },
}


# ── Helper functions ──────────────────────────────────────────────


def load_env_file(path):
    """Load VAULT_TOKEN from .env file."""
    global VAULT_TOKEN
    if os.path.isfile(path):
        with open(path) as f:
            for line in f:
                line = line.strip()
                if line.startswith("VAULT_TOKEN="):
                    VAULT_TOKEN = line.split("=", 1)[1].strip()
                    os.environ["VAULT_TOKEN"] = VAULT_TOKEN


def check_openbao_status():
    """Check OpenBao seal status. Returns (initialized, sealed) or exits on error."""
    try:
        resp = requests.get(f"{VAULT_ADDR}/v1/sys/seal-status", timeout=5)
        resp.raise_for_status()
        data = resp.json()
        return data["initialized"], data["sealed"]
    except requests.RequestException:
        print(Fore.RED + f"Cannot reach OpenBao at {VAULT_ADDR}.")
        print(Fore.YELLOW + "Start it first:")
        print("  docker compose up -d openbao")
        sys.exit(1)


def run_script(script_name):
    """Run a shell script from the init/ directory."""
    script_path = os.path.join(SCRIPT_DIR, script_name)
    result = subprocess.run([script_path], cwd=PROJECT_DIR)
    if result.returncode != 0:
        print(Fore.RED + f"{script_name} failed with exit code {result.returncode}")
        sys.exit(result.returncode)


def decrypt_credentials(enc_file_path, key):
    """Decrypt credentials.yaml.enc using openssl."""
    try:
        result = subprocess.run(
            ["openssl", "enc", "-aes-256-cbc", "-d", "-pbkdf2", "-in", enc_file_path, "-pass", f"pass:{key}"],
            capture_output=True,
            check=True,
        )
        return result.stdout.decode("utf-8"), None
    except subprocess.CalledProcessError as e:
        return None, f"Decryption error: {e.stderr.decode('utf-8').strip()}"


def get_decrypted_content():
    """Decrypt credentials file using key file or interactive password.

    Resolution order (same as cb-tumblebug):
      1. --key-file <path>  (explicit CLI argument)
      2. ~/.cloud-barista/.tmp_enc_key  (convention)
      3. Interactive password prompt (up to 3 attempts)
    """
    # 1. Try explicit --key-file argument
    if args.key_file and os.path.isfile(args.key_file):
        with open(args.key_file) as kf:
            key = kf.read().strip()
        print(Fore.YELLOW + f"Using key from {args.key_file}")
        content, error = decrypt_credentials(ENC_FILE, key)
        if error is None:
            return content, True  # (content, used_key_file)
        print(Fore.RED + error)

    # 2. Try default .tmp_enc_key (cb-tumblebug convention)
    if os.path.isfile(KEY_FILE):
        with open(KEY_FILE) as kf:
            key = kf.read().strip()
        print(Fore.YELLOW + f"Using key from {KEY_FILE}")
        content, error = decrypt_credentials(ENC_FILE, key)
        if error is None:
            return content, True  # (content, used_key_file)
        print(Fore.RED + error)

    # 3. Prompt for password (up to 3 attempts)
    from getpass import getpass

    for attempt in range(1, 4):
        password = getpass(f"Enter the password for credentials.yaml.enc (attempt {attempt}/3): ")
        content, error = decrypt_credentials(ENC_FILE, password)
        if error is None:
            return content, False  # (content, used_key_file=False)
        print(Fore.RED + error)

    print(Fore.RED + "Failed to decrypt after 3 attempts. Exiting.")
    sys.exit(1)


def register_credential(provider, credentials):
    """Register a single CSP credential to OpenBao."""
    # Check if provider has any non-empty values
    has_value = any(v for v in credentials.values() if v)
    if not has_value:
        return provider, "skip", "No credential values"

    # Build secret data with Terrarium-compatible keys
    secret_data = {}
    key_map = KEY_MAP.get(provider, {})
    mapped_keys = []

    for yaml_key, value in credentials.items():
        if not value:
            continue
        terrarium_key = key_map.get(yaml_key)
        if terrarium_key:
            secret_data[terrarium_key] = value
            mapped_keys.append(terrarium_key)

    if not mapped_keys:
        # No mapping found — store raw keys as-is
        for yaml_key, value in credentials.items():
            if value:
                secret_data[yaml_key] = value
        mapped_keys = list(secret_data.keys())

    # Register to OpenBao via KV v2 API
    # KV v2 write path: /v1/{mount}/data/{prefix}/{name}
    url = f"{VAULT_ADDR}/v1/{KV_MOUNT}/data/{SECRET_PREFIX}/{provider}"
    headers = {
        "X-Vault-Token": VAULT_TOKEN,
        "Content-Type": "application/json",
    }
    try:
        resp = requests.post(url, json={"data": secret_data}, headers=headers, timeout=10)
        resp.raise_for_status()
        version = resp.json().get("data", {}).get("version", "?")
        return provider, "ok", f"v{version}  keys=[{', '.join(mapped_keys)}]"
    except requests.RequestException as e:
        return provider, "fail", str(e)


# ── Main ──────────────────────────────────────────────────────────


def main():
    global VAULT_TOKEN

    print(Style.BRIGHT + Fore.CYAN)
    print("=" * 60)
    print("  MC-Terrarium CSP Credential Registration")
    print("=" * 60)
    print(Style.RESET_ALL)

    # Show configuration
    print(Fore.YELLOW + "Configuration")
    print(f" - {Fore.CYAN}VAULT_ADDR:{Fore.RESET} {VAULT_ADDR}")
    print(f" - {Fore.CYAN}CRED_FILE:{Fore.RESET} {ENC_FILE}")
    print(f" - {Fore.CYAN}KEY_FILE:{Fore.RESET} {KEY_FILE}")
    print()

    # Show operations
    print(Fore.YELLOW + "Operations to be performed:")
    step = 1
    if run_openbao:
        print(f"  {Fore.CYAN}{step}. Initialize / Unseal OpenBao")
        step += 1
    if run_credentials:
        print(f"  {Fore.CYAN}{step}. Register CSP credentials → OpenBao")
    print()

    # Determine if password input will be required (tumblebug pattern)
    # If password is needed, it serves as confirmation (skip "proceed?" prompt)
    password_required = run_credentials and os.path.isfile(ENC_FILE) and not args.key_file and not os.path.isfile(KEY_FILE)

    # Decrypt credentials BEFORE confirm prompt (tumblebug pattern)
    # Password input itself serves as user confirmation
    decrypted_content = None
    if run_credentials and os.path.isfile(ENC_FILE):
        if password_required:
            print(Fore.CYAN + "Enter the credential password to proceed...")
        print(Fore.CYAN + "Decrypting credentials...")
        decrypted_content, used_key_file = get_decrypted_content()
        print(Fore.GREEN + "Decryption successful!")
        print()

        # If key file was used (no password prompt), ask for confirmation
        if used_key_file and not args.yes:
            confirm = input(Fore.CYAN + "Proceed? (y/n): " + Style.RESET_ALL).lower()
            if confirm not in ("y", "yes"):
                print(Fore.GREEN + "Cancelled.")
                sys.exit(0)
            print()
    elif not args.yes:
        # No credentials to import - ask for confirmation
        confirm = input(Fore.CYAN + "Proceed? (y/n): " + Style.RESET_ALL).lower()
        if confirm not in ("y", "yes"):
            print(Fore.GREEN + "Cancelled.")
            sys.exit(0)
        print()

    start_time = time.time()

    # ── Step 1: OpenBao init / unseal ─────────────────────────────
    if run_openbao:
        print(Style.BRIGHT + "── OpenBao Initialization ──" + Style.RESET_ALL)
        initialized, sealed = check_openbao_status()

        if not initialized:
            print(Fore.CYAN + "OpenBao not yet initialized. Running init-openbao.sh...")
            run_script("init-openbao.sh")
        elif sealed:
            print(Fore.CYAN + "OpenBao is sealed. Running unseal-openbao.sh...")
            run_script("unseal-openbao.sh")
        else:
            print(Fore.GREEN + "OpenBao is already initialized and unsealed.")
        print()

        # Reload .env to pick up VAULT_TOKEN
        load_env_file(os.path.join(PROJECT_DIR, ".env"))

    # ── Step 2: Register CSP credentials ────────────────────────────
    if run_credentials:
        print(Style.BRIGHT + "── CSP Credential Registration ──" + Style.RESET_ALL)

        # Ensure VAULT_TOKEN is available
        if not VAULT_TOKEN:
            load_env_file(os.path.join(PROJECT_DIR, ".env"))
        if not VAULT_TOKEN:
            print(Fore.RED + "VAULT_TOKEN not set. Run init-openbao.sh first.")
            sys.exit(1)

        # Check OpenBao is ready
        initialized, sealed = check_openbao_status()
        if not initialized:
            print(Fore.RED + "OpenBao is not initialized. Run ./init/init-openbao.sh first.")
            sys.exit(1)
        if sealed:
            print(Fore.RED + "OpenBao is sealed. Run ./init/unseal-openbao.sh first.")
            sys.exit(1)

        # Check encrypted file and decrypted content
        if not os.path.isfile(ENC_FILE):
            print(Fore.YELLOW + f"Skipping: {ENC_FILE} not found.")
            print(Fore.YELLOW + "Generate it using cb-tumblebug/init/encCredential.sh")
        elif decrypted_content is None:
            print(Fore.RED + "Decrypted content is empty. Skipping credential import.")
        else:
            # Parse YAML
            try:
                data = yaml.safe_load(decrypted_content)
                cred_data = data["credentialholder"]["admin"]
            except Exception as e:
                print(Fore.RED + f"Error parsing credentials YAML: {e}")
                sys.exit(1)

            # Register each CSP
            print(Fore.CYAN + "Registering credentials to OpenBao...")
            print()

            success_count = 0
            skip_count = 0
            fail_count = 0

            for provider, credentials in cred_data.items():
                provider_name, status, message = register_credential(provider, credentials)
                if status == "ok":
                    print(f"  {Fore.GREEN}OK  {Style.RESET_ALL} {provider_name:12s}  {message}")
                    success_count += 1
                elif status == "skip":
                    print(f"  {Fore.YELLOW}SKIP{Style.RESET_ALL} {provider_name:12s}  ({message})")
                    skip_count += 1
                else:
                    print(f"  {Fore.RED}FAIL{Style.RESET_ALL} {provider_name:12s}  {message}")
                    fail_count += 1

            print()
            print(
                f"Results: {Fore.GREEN}{success_count} registered{Style.RESET_ALL}, "
                f"{Fore.YELLOW}{skip_count} skipped{Style.RESET_ALL}, "
                f"{Fore.RED}{fail_count} failed{Style.RESET_ALL}"
            )

            if fail_count > 0:
                print(Fore.RED + "\nSome credentials failed to register.")

        print()

    # Summary
    elapsed = int(time.time() - start_time)
    print(Style.BRIGHT + Fore.GREEN)
    print("=" * 60)
    print(f"  Initialization complete! ({elapsed}s)")
    print("=" * 60)
    print(Style.RESET_ALL)

    # Usage hint
    if run_credentials:
        print("To verify a credential:")
        print("  source .env")
        print(f'  curl -s -H "X-Vault-Token: $VAULT_TOKEN" {VAULT_ADDR}/v1/{KV_MOUNT}/data/{SECRET_PREFIX}/aws | jq .data.data')
        print(f"  bao kv get {KV_MOUNT}/{SECRET_PREFIX}/aws")
        print()


if __name__ == "__main__":
    main()
