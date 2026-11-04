#!/bin/bash
cd "$(dirname "$0")"

# Check firewall and AI Stack status on all VMs in ai-stack-testbed
# Usage: ./check-firewall.sh

echo "=== AWS AI Stack Migration Testbed Status Check ==="
echo "$(date)"
echo

PEM_FILE="private_key_ai_stack_testbed.pem"
if [[ ! -f "$PEM_FILE" ]]; then
    echo "❌ $PEM_FILE not found. Please run:"
    echo "   tofu output -json ssh_info | jq -r .private_key > $PEM_FILE"
    echo "   chmod 600 $PEM_FILE"
    exit 1
fi

echo "🔍 Retrieving VM information from OpenTofu..."

PUBLIC_IPS_JSON=$(tofu output -json vm_public_ips)
ROLES_JSON=$(tofu output -json service_roles)
VM_KEYS=$(echo "$PUBLIC_IPS_JSON" | jq -r 'keys[]')
TOTAL_VMS=$(echo "$VM_KEYS" | wc -l)

echo "📋 Found $TOTAL_VMS VMs to check"
echo

SUCCESS_COUNT=0
FAILURE_COUNT=0

check_vm() {
    local vm_name=$1
    local vm_ip=$2
    local service_role=$3

    echo "============================================================"
    echo "🔍 Checking $vm_name ($service_role) - $vm_ip"
    echo "============================================================"

    if ssh -i "$PEM_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@"$vm_ip" "
        echo '=== System Information ===';
        echo \"Hostname: \$(hostname)\";
        echo \"Uptime: \$(uptime -p)\";
        echo \"Public IP: $vm_ip\";
        echo \"Private IP: \$(hostname -I | awk '{print \$1}')\";
        echo;

        echo '=== Firewall Configuration ===';
        if [[ \"$service_role\" == \"general\" ]] || [[ \"$service_role\" == \"cloud-migrator\" ]]; then
            echo \"🔧 Security Group only (UFW not used for Cloud-Migrator/general VMs)\";
            echo \"✅ Firewall managed by AWS Security Group\";
        else
            if sudo ufw status 2>/dev/null | head -20; then
                echo;
                UFW_STATUS=\$(sudo ufw status | grep 'Status:' | awk '{print \$2}');
                if [[ \"\$UFW_STATUS\" == \"active\" ]]; then
                    echo \"✅ UFW is active\";
                else
                    echo \"❌ UFW is not active\";
                fi;
            else
                echo '❌ UFW not configured';
            fi;
        fi;
        echo;

        if [[ \"$service_role\" == \"ai-webui\" ]]; then
            echo '=== AIMX AI Service Stack Status ===';
            echo \"Init Stage: \$(cat /var/log/ai-stack-status.log 2>/dev/null || echo 'PENDING')\";
            nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>/dev/null || echo '⚠️  nvidia-smi not ready yet';
            sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true;
            echo;
        fi;
    " 2>/dev/null; then
        echo "✅ $vm_name check completed successfully"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "❌ Failed to connect to $vm_name ($vm_ip)"
        FAILURE_COUNT=$((FAILURE_COUNT + 1))
    fi
    echo
}

for vm_key in $VM_KEYS; do
    vm_ip=$(echo "$PUBLIC_IPS_JSON" | jq -r --arg k "$vm_key" '.[$k]')
    vm_role=$(echo "$ROLES_JSON" | jq -r --arg k "$vm_key" '.[$k]')
    check_vm "$vm_key" "$vm_ip" "$vm_role"
done

echo "============================================================"
echo "🏁 FINAL SUMMARY"
echo "============================================================"
echo "📊 Total VMs: $TOTAL_VMS"
echo "✅ Successful checks: $SUCCESS_COUNT"
echo "❌ Failed checks: $FAILURE_COUNT"
echo "⏰ Check completed at: $(date)"
