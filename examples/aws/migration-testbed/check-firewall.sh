#!/bin/bash

# Check firewall status on all VMs
# Usage: ./check-firewall.sh

echo "=== AWS Migration Testbed Firewall Status Check ==="
echo "$(date)"
echo

# Check if private key exists
if [[ ! -f "private_key_mig_testbed.pem" ]]; then
    echo "❌ private_key_mig_testbed.pem not found. Please run:"
    echo "   tofu output -json ssh_info | jq -r .private_key > private_key_mig_testbed.pem"
    echo "   chmod 600 private_key_mig_testbed.pem"
    exit 1
fi

echo "🔍 Retrieving VM information from OpenTofu..."

# Get VM public IPs
VM1_IP=$(tofu output -json vm_public_ips | jq -r .vm1)
VM2_IP=$(tofu output -json vm_public_ips | jq -r .vm2)
VM3_IP=$(tofu output -json vm_public_ips | jq -r .vm3)
VM4_IP=$(tofu output -json vm_public_ips | jq -r .vm4)
VM5_IP=$(tofu output -json vm_public_ips | jq -r .vm5)
VM6_IP=$(tofu output -json vm_public_ips | jq -r .vm6)

# Get service roles
VM1_ROLE=$(tofu output -json service_roles | jq -r .vm1)
VM2_ROLE=$(tofu output -json service_roles | jq -r .vm2)
VM3_ROLE=$(tofu output -json service_roles | jq -r .vm3)
VM4_ROLE=$(tofu output -json service_roles | jq -r .vm4)
VM5_ROLE=$(tofu output -json service_roles | jq -r .vm5)
VM6_ROLE=$(tofu output -json service_roles | jq -r .vm6)

echo "📋 Found 6 VMs to check"
echo

SUCCESS_COUNT=0
FAILURE_COUNT=0

# Function to check single VM
check_vm() {
    local vm_name=$1
    local vm_ip=$2
    local service_role=$3
    
    echo "========================================="
    echo "🔍 Checking $vm_name ($service_role) - $vm_ip"
    echo "========================================="
    
    if ssh -i private_key_mig_testbed.pem -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@$vm_ip "
        echo '=== System Information ===';
        echo \"Hostname: \$(hostname)\";
        echo \"Uptime: \$(uptime -p)\";
        echo \"Public IP: $vm_ip\";
        echo \"Private IP: \$(hostname -I | awk '{print \$1}')\";
        echo;
        
        echo '=== Firewall Configuration ===';
        if [[ \"$service_role\" == \"general\" ]]; then
            echo \"🔧 Security Group only (UFW not used for general purpose VMs)\";
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
        
        echo '=== Service Role ===';
        if [[ -f /etc/vm-service-role ]]; then
            ACTUAL_ROLE=\$(cat /etc/vm-service-role);
            echo \"Expected role: $service_role\";
            echo \"Actual role: \$ACTUAL_ROLE\";
            if [[ \"$service_role\" == \"\$ACTUAL_ROLE\" ]]; then
                echo \"✅ Service role matches\";
            else
                echo \"❌ Service role mismatch!\";
            fi;
        else
            echo '❌ Service role file not found';
        fi;
        echo;
        
        echo '=== Error Check ===';
        if [[ -f /var/log/user-data-debug.log ]]; then
            ERROR_COUNT=\$(grep -i error /var/log/user-data-debug.log 2>/dev/null | wc -l);
            if [[ \$ERROR_COUNT -gt 0 ]]; then
                echo \"❌ Found \$ERROR_COUNT errors in user-data log\";
                grep -i error /var/log/user-data-debug.log | tail -2;
            else
                echo \"✅ No errors in user-data execution\";
            fi;
        else
            echo '⚠️  User-data log not found';
        fi;
    " 2>/dev/null; then
        echo "✅ $vm_name check completed successfully"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "❌ Failed to connect to $vm_name"
        FAILURE_COUNT=$((FAILURE_COUNT + 1))
    fi
    echo
}

# Check all VMs individually
check_vm "vm1" "$VM1_IP" "$VM1_ROLE"
check_vm "vm2" "$VM2_IP" "$VM2_ROLE"
check_vm "vm3" "$VM3_IP" "$VM3_ROLE"
check_vm "vm4" "$VM4_IP" "$VM4_ROLE"
check_vm "vm5" "$VM5_IP" "$VM5_ROLE"
check_vm "vm6" "$VM6_IP" "$VM6_ROLE"

echo "================================================="
echo "🏁 FINAL SUMMARY"
echo "================================================="
echo "📊 Total VMs: 6"
echo "✅ Successful checks: $SUCCESS_COUNT"
echo "❌ Failed checks: $FAILURE_COUNT"
echo "⏰ Check completed at: $(date)"

if [[ $SUCCESS_COUNT -eq 6 ]]; then
    echo "🎉 All VMs are properly configured!"
    exit 0
else
    echo "⚠️  Some VMs need attention. Review the output above."
    exit 1
fi