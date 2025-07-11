# Email Setup Summary for bad.mn Domain

## Current Status (Automated Analysis)

✅ **Domain A Records**: Configured (70.39.97.239, 169.47.130.75)  
❌ **Mail A Record**: Missing  
❌ **MX Records**: Missing  
❌ **SPF Record**: Missing  
❌ **DKIM Record**: Missing  
❌ **DMARC Record**: Missing  

**Configuration Status**: 1/6 components configured  
**Current State**: ❌ Mail server will not work properly

## Quick Setup Checklist

### 1. Choose Mail Server IP
Select one of your existing IPs or set up a dedicated mail server:
- Option A: Use 70.39.97.239
- Option B: Use 169.47.130.75  
- Option C: Set up new dedicated mail server

### 2. FreeDNS Configuration (https://freedns.afraid.org)

Add these records to your FreeDNS account:

| Type | Name/Subdomain | Value | Priority |
|------|---------------|-------|----------|
| A | mail | [YOUR_MAIL_SERVER_IP] | - |
| MX | @ | mail.bad.mn | 10 |
| TXT | @ | "v=spf1 a:mail.bad.mn ~all" | - |
| TXT | selector1._domainkey | [DKIM_PUBLIC_KEY] | - |
| TXT | _dmarc | "v=DMARC1; p=quarantine; rua=mailto:dmarc@bad.mn" | - |

### 3. Generate DKIM Keys
```bash
# Run the DKIM key generation script
./scripts/generate-dkim-keys.sh

# This will create:
# - dkim-keys/selector1.private (keep secure)
# - dkim-keys/selector1.txt (add to DNS)
```

### 4. Verify Configuration
```bash
# Run the DNS check script
./scripts/dns-check-bad-mn.sh

# Should show 6/6 components configured when done
```

## Files Created

| File | Purpose | Location |
|------|---------|----------|
| `smtp-dns-configuration.md` | General SMTP DNS guide | Root directory |
| `dns-configuration-bad-mn.md` | Specific bad.mn configuration | Root directory |
| `configs/bad-mn-dns-zone.txt` | DNS zone file template | configs/ |
| `scripts/dns-check-bad-mn.sh` | DNS verification script | scripts/ |
| `scripts/generate-dkim-keys.sh` | DKIM key generator | scripts/ |

## Detailed Setup Steps

### Step 1: FreeDNS Login
1. Go to https://freedns.afraid.org
2. Log into your account
3. Click "DNS" in the menu
4. Find your domain: bad.mn

### Step 2: Add A Record for Mail Server
- Type: A
- Subdomain: mail
- Domain: bad.mn
- Destination: [YOUR_MAIL_SERVER_IP]

### Step 3: Add MX Record
- Type: MX
- Subdomain: (leave blank)
- Domain: bad.mn
- Destination: mail.bad.mn
- Priority: 10

### Step 4: Add SPF Record
- Type: TXT
- Subdomain: (leave blank)
- Domain: bad.mn
- Destination: "v=spf1 a:mail.bad.mn ~all"

### Step 5: Generate and Add DKIM Record
```bash
# Generate DKIM keys
./scripts/generate-dkim-keys.sh

# Add the TXT record from the output:
# Type: TXT
# Subdomain: selector1._domainkey
# Domain: bad.mn
# Destination: [DKIM public key from script output]
```

### Step 6: Add DMARC Record
- Type: TXT
- Subdomain: _dmarc
- Domain: bad.mn
- Destination: "v=DMARC1; p=quarantine; rua=mailto:dmarc@bad.mn"

## Mail Server Configuration

### Recommended Mail Server Software
- **Postfix** + **Dovecot** (most common)
- **Mail-in-a-Box** (easy setup)
- **iRedMail** (comprehensive solution)
- **Mailcow** (Docker-based)

### Basic Postfix Configuration
```
# /etc/postfix/main.cf
myhostname = mail.bad.mn
mydomain = bad.mn
myorigin = $mydomain
inet_interfaces = all
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain

# TLS Configuration
smtpd_use_tls = yes
smtpd_tls_cert_file = /etc/ssl/certs/mail.bad.mn.pem
smtpd_tls_key_file = /etc/ssl/private/mail.bad.mn.key

# DKIM Configuration  
milter_default_action = accept
milter_protocol = 2
smtpd_milters = inet:localhost:8891
non_smtpd_milters = inet:localhost:8891
```

## Testing and Verification

### DNS Verification Commands
```bash
# Check all DNS records
./scripts/dns-check-bad-mn.sh

# Individual record checks
dig MX bad.mn
dig A mail.bad.mn
dig TXT bad.mn
dig TXT selector1._domainkey.bad.mn
dig TXT _dmarc.bad.mn
```

### Mail Server Testing
```bash
# Test SMTP connection
telnet mail.bad.mn 25

# Test with SSL
openssl s_client -connect mail.bad.mn:587 -starttls smtp

# Send test email
echo "Test message" | mail -s "Test Subject" test@gmail.com
```

### Online Testing Tools
- **MXToolbox**: https://mxtoolbox.com
- **Mail Tester**: https://mail-tester.com  
- **DMARC Analyzer**: https://dmarcanalyzer.com
- **SPF Record Check**: https://spf-record.com

## Security Configuration

### SSL/TLS Certificates
```bash
# Get Let's Encrypt certificate
sudo certbot certonly --standalone -d mail.bad.mn

# Or use existing certificate if available
```

### Firewall Configuration
```bash
# Open necessary ports
sudo ufw allow 25    # SMTP
sudo ufw allow 587   # SMTP Submission  
sudo ufw allow 993   # IMAP SSL
sudo ufw allow 995   # POP3 SSL
```

### Fail2Ban Protection
```bash
# Install and configure fail2ban
sudo apt-get install fail2ban

# Configure for mail services
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## Monitoring and Maintenance

### Daily Checks
- Monitor mail queue: `mailq`
- Check logs: `tail -f /var/log/mail.log`
- Verify services: `systemctl status postfix dovecot`

### Weekly Tasks
- Review DMARC reports
- Check spam folder rates
- Monitor bounce rates

### Monthly Tasks
- Update software packages
- Review security logs
- Test backup/restore procedures

### Annual Tasks
- Rotate DKIM keys
- Renew SSL certificates
- Security audit

## Troubleshooting

### Common Issues

1. **Email marked as spam**
   - Verify SPF, DKIM, DMARC records
   - Check reverse DNS (PTR record)
   - Monitor IP reputation

2. **Cannot send email**
   - Check MX records
   - Verify SMTP configuration
   - Check firewall rules

3. **Cannot receive email**
   - Verify A record for mail subdomain
   - Check MX record priority
   - Verify mail server is running

### Log Files
- `/var/log/mail.log` - General mail logs
- `/var/log/postfix.log` - Postfix specific
- `/var/log/dovecot.log` - Dovecot specific

## Support Resources

### Documentation
- Postfix: http://postfix.org/documentation.html
- Dovecot: https://wiki.dovecot.org
- OpenDKIM: http://opendkim.org

### Communities
- Server Fault: https://serverfault.com
- Mail Server discussions on Reddit: r/selfhosted
- FreeDNS Support: https://freedns.afraid.org/support/

## Next Steps

1. **Choose your mail server IP** from the available options
2. **Run the DKIM generator**: `./scripts/generate-dkim-keys.sh`  
3. **Add all DNS records** to FreeDNS as outlined above
4. **Wait for DNS propagation** (up to 24 hours)
5. **Verify with DNS check**: `./scripts/dns-check-bad-mn.sh`
6. **Set up mail server software** on your chosen IP
7. **Test email sending and receiving**
8. **Monitor and fine-tune** configuration

---

*Last updated: $(date)*  
*Configuration files and scripts available in this workspace*