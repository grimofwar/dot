#!/bin/bash

# DKIM Key Generation Script for bad.mn
# This script generates DKIM keys and provides DNS record information

DOMAIN="bad.mn"
SELECTOR="selector1"
KEY_DIR="./dkim-keys"

echo "=============================================="
echo "DKIM Key Generation for $DOMAIN"
echo "=============================================="
echo "Timestamp: $(date)"
echo ""

# Check if opendkim-genkey is available
if ! command -v opendkim-genkey >/dev/null 2>&1; then
    echo "❌ opendkim-genkey not found. Installing OpenDKIM tools..."
    echo ""
    
    # Try to install opendkim-tools
    if command -v apt-get >/dev/null 2>&1; then
        echo "Installing OpenDKIM tools using apt-get..."
        sudo apt-get update && sudo apt-get install -y opendkim opendkim-tools
    elif command -v yum >/dev/null 2>&1; then
        echo "Installing OpenDKIM tools using yum..."
        sudo yum install -y opendkim opendkim-tools
    else
        echo "❌ Cannot automatically install OpenDKIM tools."
        echo "Please install manually:"
        echo "  Ubuntu/Debian: sudo apt-get install opendkim opendkim-tools"
        echo "  RHEL/CentOS:   sudo yum install opendkim opendkim-tools"
        exit 1
    fi
fi

# Create directory for keys
mkdir -p "$KEY_DIR"
cd "$KEY_DIR"

echo "📁 Created directory: $KEY_DIR"
echo ""

# Generate DKIM key pair
echo "🔑 Generating DKIM key pair for $DOMAIN..."
echo "   Selector: $SELECTOR"
echo "   Domain: $DOMAIN"
echo ""

# Generate the keys
opendkim-genkey -t -s "$SELECTOR" -d "$DOMAIN"

if [ $? -eq 0 ]; then
    echo "✅ DKIM keys generated successfully!"
    echo ""
else
    echo "❌ Failed to generate DKIM keys"
    exit 1
fi

# Check if files were created
PRIVATE_KEY_FILE="${SELECTOR}.private"
PUBLIC_KEY_FILE="${SELECTOR}.txt"

if [ -f "$PRIVATE_KEY_FILE" ] && [ -f "$PUBLIC_KEY_FILE" ]; then
    echo "📄 Generated files:"
    echo "   Private key: $KEY_DIR/$PRIVATE_KEY_FILE"
    echo "   Public key:  $KEY_DIR/$PUBLIC_KEY_FILE"
    echo ""
else
    echo "❌ Expected files not found"
    exit 1
fi

# Display file contents and instructions
echo "=============================================="
echo "PRIVATE KEY (Keep this secure!)"
echo "=============================================="
echo "File: $PRIVATE_KEY_FILE"
echo "Location: $KEY_DIR/$PRIVATE_KEY_FILE"
echo ""
echo "⚠️  IMPORTANT: This private key should be:"
echo "   - Kept secure and private"
echo "   - Copied to your mail server"
echo "   - Set with proper permissions (600)"
echo "   - Never shared publicly"
echo ""

echo "=============================================="
echo "DNS RECORD CONFIGURATION"
echo "=============================================="
echo "File: $PUBLIC_KEY_FILE"
echo ""

# Extract and format the public key for DNS
echo "Add this TXT record to your DNS:"
echo ""
echo "Record Type: TXT"
echo "Name/Host: ${SELECTOR}._domainkey"
echo "Value:"

# Format the DNS record properly
if [ -f "$PUBLIC_KEY_FILE" ]; then
    # Extract just the key part, removing extra formatting
    DNS_RECORD=$(cat "$PUBLIC_KEY_FILE" | grep -o '"v=DKIM1[^"]*"')
    echo "$DNS_RECORD"
    echo ""
    
    # Also show the raw content
    echo "Raw DNS record content:"
    cat "$PUBLIC_KEY_FILE"
    echo ""
fi

echo "=============================================="
echo "FREEDNS CONFIGURATION STEPS"
echo "=============================================="
echo ""
echo "To add this DKIM record to FreeDNS:"
echo ""
echo "1. Go to https://freedns.afraid.org"
echo "2. Log into your account"
echo "3. Click 'DNS' in the menu"
echo "4. Find your domain: $DOMAIN"
echo "5. Click 'Add' next to your domain"
echo "6. Fill in the form:"
echo "   - Type: TXT"
echo "   - Subdomain: ${SELECTOR}._domainkey"
echo "   - Domain: $DOMAIN (should be pre-selected)"
echo "   - Destination: [paste the DNS record value from above]"
echo "7. Click 'Save!'"
echo ""

echo "=============================================="
echo "MAIL SERVER CONFIGURATION"
echo "=============================================="
echo ""
echo "Copy the private key to your mail server:"
echo ""
echo "# Create directory for DKIM keys"
echo "sudo mkdir -p /etc/opendkim/keys/$DOMAIN"
echo ""
echo "# Copy private key (replace with your actual path)"
echo "sudo cp $KEY_DIR/$PRIVATE_KEY_FILE /etc/opendkim/keys/$DOMAIN/$SELECTOR.private"
echo ""
echo "# Set proper permissions"
echo "sudo chown opendkim:opendkim /etc/opendkim/keys/$DOMAIN/$SELECTOR.private"
echo "sudo chmod 600 /etc/opendkim/keys/$DOMAIN/$SELECTOR.private"
echo ""

echo "=============================================="
echo "OPENDKIM CONFIGURATION"
echo "=============================================="
echo ""
echo "Add to /etc/opendkim.conf:"
echo ""
echo "Domain          $DOMAIN"
echo "KeyFile         /etc/opendkim/keys/$DOMAIN/$SELECTOR.private"
echo "Selector        $SELECTOR"
echo "Socket          inet:8891@localhost"
echo ""

echo "Or create key table (/etc/opendkim/KeyTable):"
echo "${SELECTOR}._domainkey.$DOMAIN $DOMAIN:$SELECTOR:/etc/opendkim/keys/$DOMAIN/$SELECTOR.private"
echo ""

echo "And signing table (/etc/opendkim/SigningTable):"
echo "*@$DOMAIN ${SELECTOR}._domainkey.$DOMAIN"
echo ""

echo "=============================================="
echo "VERIFICATION COMMANDS"
echo "=============================================="
echo ""
echo "After adding the DNS record, verify with:"
echo ""
echo "# Check DKIM DNS record"
echo "dig TXT ${SELECTOR}._domainkey.$DOMAIN"
echo ""
echo "# Test DKIM signing (after mail server setup)"
echo "echo 'Test email' | mail -s 'DKIM Test' test@gmail.com"
echo ""
echo "# Check DKIM with online tools:"
echo "# - https://mxtoolbox.com/dkim.aspx"
echo "# - https://dmarcian.com/dkim-inspector/"
echo ""

echo "=============================================="
echo "SECURITY NOTES"
echo "=============================================="
echo ""
echo "🔒 Security best practices:"
echo ""
echo "1. Private key security:"
echo "   - Never share the private key ($PRIVATE_KEY_FILE)"
echo "   - Store securely with 600 permissions"
echo "   - Backup securely"
echo ""
echo "2. Key rotation:"
echo "   - Rotate DKIM keys annually"
echo "   - Keep old keys active during transition"
echo "   - Update DNS records when rotating"
echo ""
echo "3. Monitoring:"
echo "   - Monitor DMARC reports"
echo "   - Check mail server logs"
echo "   - Verify DKIM signatures regularly"
echo ""

# Create a summary file
SUMMARY_FILE="../dkim-setup-summary.txt"
echo "📝 Creating summary file: $SUMMARY_FILE"

cat > "$SUMMARY_FILE" << EOF
DKIM Setup Summary for $DOMAIN
Generated: $(date)

Files created:
- Private key: $KEY_DIR/$PRIVATE_KEY_FILE
- Public key: $KEY_DIR/$PUBLIC_KEY_FILE

DNS Record to add:
Type: TXT
Name: ${SELECTOR}._domainkey
Value: $(cat "$PUBLIC_KEY_FILE" | grep -o '"v=DKIM1[^"]*"')

Next steps:
1. Add DNS TXT record to FreeDNS
2. Copy private key to mail server
3. Configure OpenDKIM
4. Test DKIM signing
5. Monitor email delivery

Verification command:
dig TXT ${SELECTOR}._domainkey.$DOMAIN
EOF

echo ""
echo "✅ DKIM key generation complete!"
echo "📝 Summary saved to: $SUMMARY_FILE"
echo ""
echo "Next: Run ./scripts/dns-check-bad-mn.sh to verify DNS configuration"
echo ""