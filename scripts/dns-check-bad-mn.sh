#!/bin/bash

# DNS Configuration Checker for bad.mn
# This script checks all DNS records for the bad.mn domain

DOMAIN="bad.mn"
MAIL_SUBDOMAIN="mail.bad.mn"

echo "=============================================="
echo "DNS Configuration Check for $DOMAIN"
echo "=============================================="
echo "Timestamp: $(date)"
echo ""

# Function to print section headers
print_header() {
    echo ""
    echo "--- $1 ---"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if dig is installed
if ! command_exists dig; then
    echo "Error: dig command not found. Please install dnsutils:"
    echo "sudo apt-get install dnsutils"
    exit 1
fi

# 1. Check A Records
print_header "A Records"
echo "Checking A records for $DOMAIN:"
dig +short A $DOMAIN | while read ip; do
    echo "  $DOMAIN → $ip"
done

echo ""
echo "Checking A record for mail subdomain:"
MAIL_IP=$(dig +short A $MAIL_SUBDOMAIN)
if [ -n "$MAIL_IP" ]; then
    echo "  $MAIL_SUBDOMAIN → $MAIL_IP"
else
    echo "  ❌ No A record found for $MAIL_SUBDOMAIN"
fi

# 2. Check MX Records
print_header "MX Records"
echo "Checking MX records for $DOMAIN:"
MX_RECORDS=$(dig +short MX $DOMAIN)
if [ -n "$MX_RECORDS" ]; then
    echo "$MX_RECORDS" | while read line; do
        echo "  $line"
    done
else
    echo "  ❌ No MX records found for $DOMAIN"
fi

# 3. Check SPF Records
print_header "SPF Records"
echo "Checking SPF (TXT) records for $DOMAIN:"
SPF_RECORDS=$(dig +short TXT $DOMAIN | grep "v=spf1")
if [ -n "$SPF_RECORDS" ]; then
    echo "  ✅ SPF Record found:"
    echo "  $SPF_RECORDS"
else
    echo "  ❌ No SPF record found for $DOMAIN"
fi

# 4. Check DKIM Records
print_header "DKIM Records"
echo "Checking DKIM records for selector1._domainkey.$DOMAIN:"
DKIM_RECORDS=$(dig +short TXT selector1._domainkey.$DOMAIN | grep "v=DKIM1")
if [ -n "$DKIM_RECORDS" ]; then
    echo "  ✅ DKIM Record found:"
    echo "  $DKIM_RECORDS"
else
    echo "  ❌ No DKIM record found for selector1._domainkey.$DOMAIN"
fi

# 5. Check DMARC Records
print_header "DMARC Records"
echo "Checking DMARC records for _dmarc.$DOMAIN:"
DMARC_RECORDS=$(dig +short TXT _dmarc.$DOMAIN | grep "v=DMARC1")
if [ -n "$DMARC_RECORDS" ]; then
    echo "  ✅ DMARC Record found:"
    echo "  $DMARC_RECORDS"
else
    echo "  ❌ No DMARC record found for _dmarc.$DOMAIN"
fi

# 6. Check Name Servers
print_header "Name Servers"
echo "Checking name servers for $DOMAIN:"
dig +short NS $DOMAIN | while read ns; do
    echo "  $ns"
done

# 7. Check All TXT Records
print_header "All TXT Records"
echo "All TXT records for $DOMAIN:"
dig +short TXT $DOMAIN | while read txt; do
    echo "  $txt"
done

# 8. DNS Health Summary
print_header "DNS Health Summary"
echo ""

# Check each component
HAS_A_RECORD=$(dig +short A $DOMAIN | wc -l)
HAS_MAIL_A_RECORD=$(dig +short A $MAIL_SUBDOMAIN | wc -l)
HAS_MX_RECORD=$(dig +short MX $DOMAIN | wc -l)
HAS_SPF_RECORD=$(dig +short TXT $DOMAIN | grep -c "v=spf1")
HAS_DKIM_RECORD=$(dig +short TXT selector1._domainkey.$DOMAIN | grep -c "v=DKIM1")
HAS_DMARC_RECORD=$(dig +short TXT _dmarc.$DOMAIN | grep -c "v=DMARC1")

echo "Domain A Records:      $([[ $HAS_A_RECORD -gt 0 ]] && echo "✅ Configured" || echo "❌ Missing")"
echo "Mail A Record:         $([[ $HAS_MAIL_A_RECORD -gt 0 ]] && echo "✅ Configured" || echo "❌ Missing")"
echo "MX Records:            $([[ $HAS_MX_RECORD -gt 0 ]] && echo "✅ Configured" || echo "❌ Missing")"
echo "SPF Record:            $([[ $HAS_SPF_RECORD -gt 0 ]] && echo "✅ Configured" || echo "❌ Missing")"
echo "DKIM Record:           $([[ $HAS_DKIM_RECORD -gt 0 ]] && echo "✅ Configured" || echo "❌ Missing")"
echo "DMARC Record:          $([[ $HAS_DMARC_RECORD -gt 0 ]] && echo "✅ Configured" || echo "❌ Missing")"

echo ""
TOTAL_CONFIGURED=$((HAS_A_RECORD > 0 ? 1 : 0))
TOTAL_CONFIGURED=$((TOTAL_CONFIGURED + (HAS_MAIL_A_RECORD > 0 ? 1 : 0)))
TOTAL_CONFIGURED=$((TOTAL_CONFIGURED + (HAS_MX_RECORD > 0 ? 1 : 0)))
TOTAL_CONFIGURED=$((TOTAL_CONFIGURED + (HAS_SPF_RECORD > 0 ? 1 : 0)))
TOTAL_CONFIGURED=$((TOTAL_CONFIGURED + (HAS_DKIM_RECORD > 0 ? 1 : 0)))
TOTAL_CONFIGURED=$((TOTAL_CONFIGURED + (HAS_DMARC_RECORD > 0 ? 1 : 0)))

echo "Configuration Status: $TOTAL_CONFIGURED/6 components configured"

if [ $TOTAL_CONFIGURED -eq 6 ]; then
    echo "🎉 All DNS records are properly configured!"
elif [ $TOTAL_CONFIGURED -ge 3 ]; then
    echo "⚠️  Partial configuration - mail may work but could have deliverability issues"
else
    echo "❌ Incomplete configuration - mail server will not work properly"
fi

# 9. Next Steps
if [ $TOTAL_CONFIGURED -lt 6 ]; then
    print_header "Next Steps"
    echo ""
    [ $HAS_MAIL_A_RECORD -eq 0 ] && echo "1. Add A record for mail.$DOMAIN pointing to your mail server IP"
    [ $HAS_MX_RECORD -eq 0 ] && echo "2. Add MX record pointing to mail.$DOMAIN with priority 10"
    [ $HAS_SPF_RECORD -eq 0 ] && echo "3. Add SPF TXT record: 'v=spf1 a:mail.$DOMAIN ~all'"
    [ $HAS_DKIM_RECORD -eq 0 ] && echo "4. Generate DKIM key and add DKIM TXT record"
    [ $HAS_DMARC_RECORD -eq 0 ] && echo "5. Add DMARC TXT record for email authentication policy"
    echo ""
    echo "For detailed instructions, see: dns-configuration-bad-mn.md"
fi

echo ""
echo "=============================================="
echo "DNS Check Complete"
echo "=============================================="