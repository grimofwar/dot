# SMTP DNS Configuration Guide

This guide covers the complete setup of SMTP DNS records for email services.

## Prerequisites

- Domain name (e.g., `yourdomain.com`)
- Access to your domain's DNS management interface
- SMTP server details (if using external provider)

## 1. MX (Mail Exchange) Records

MX records specify which mail servers handle email for your domain.

### Example MX Records:
```
Type: MX
Name: @  (or yourdomain.com)
Value: 10 mail.yourdomain.com
TTL: 3600

Type: MX  
Name: @
Value: 20 mail2.yourdomain.com (backup)
TTL: 3600
```

### For Popular Email Providers:

#### Gmail/Google Workspace:
```
10 ASPMX.L.GOOGLE.COM
20 ALT1.ASPMX.L.GOOGLE.COM
20 ALT2.ASPMX.L.GOOGLE.COM
30 ALT3.ASPMX.L.GOOGLE.COM
30 ALT4.ASPMX.L.GOOGLE.COM
```

#### Microsoft 365:
```
0 yourdomain-com.mail.protection.outlook.com
```

## 2. A Records for Mail Servers

If you're hosting your own mail server:

```
Type: A
Name: mail
Value: 192.168.1.100 (your mail server IP)
TTL: 3600

Type: A
Name: smtp
Value: 192.168.1.100
TTL: 3600
```

## 3. SPF (Sender Policy Framework) Record

SPF records prevent email spoofing by specifying which servers can send email for your domain.

```
Type: TXT
Name: @
Value: "v=spf1 include:_spf.google.com ~all"
TTL: 3600
```

### SPF Record Examples:

#### For self-hosted server:
```
"v=spf1 ip4:192.168.1.100 ~all"
```

#### For multiple providers:
```
"v=spf1 include:_spf.google.com include:spf.protection.outlook.com ~all"
```

#### For Mailgun:
```
"v=spf1 include:mailgun.org ~all"
```

## 4. DKIM (DomainKeys Identified Mail) Records

DKIM provides email authentication through cryptographic signatures.

```
Type: TXT
Name: selector1._domainkey
Value: "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC..."
TTL: 3600
```

### Getting DKIM Keys:
- **Gmail**: Generated automatically in Google Admin Console
- **Microsoft 365**: Available in Exchange Admin Center
- **Self-hosted**: Generate using tools like OpenDKIM

## 5. DMARC (Domain-based Message Authentication) Record

DMARC builds on SPF and DKIM to provide additional email authentication.

```
Type: TXT
Name: _dmarc
Value: "v=DMARC1; p=quarantine; rua=mailto:dmarc@yourdomain.com; ruf=mailto:dmarc@yourdomain.com; sp=quarantine; adkim=r; aspf=r"
TTL: 3600
```

### DMARC Policy Options:
- `p=none` - Monitor only (recommended for testing)
- `p=quarantine` - Mark suspicious emails as spam
- `p=reject` - Reject emails that fail authentication

## 6. Additional DNS Records

### PTR (Reverse DNS) Record
Configure with your hosting provider:
```
192.168.1.100 -> mail.yourdomain.com
```

### CNAME Records (Optional)
```
Type: CNAME
Name: webmail
Value: mail.yourdomain.com
TTL: 3600

Type: CNAME
Name: imap
Value: mail.yourdomain.com
TTL: 3600

Type: CNAME
Name: pop3
Value: mail.yourdomain.com
TTL: 3600
```

## 7. Complete DNS Zone Example

```
; MX Records
@           IN MX 10 mail.yourdomain.com.
@           IN MX 20 mail2.yourdomain.com.

; A Records
mail        IN A  192.168.1.100
mail2       IN A  192.168.1.101
smtp        IN A  192.168.1.100

; SPF Record
@           IN TXT "v=spf1 ip4:192.168.1.100 ~all"

; DKIM Record
selector1._domainkey IN TXT "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC..."

; DMARC Record
_dmarc      IN TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc@yourdomain.com"

; CNAME Records
webmail     IN CNAME mail.yourdomain.com.
imap        IN CNAME mail.yourdomain.com.
pop3        IN CNAME mail.yourdomain.com.
```

## 8. Testing Your Configuration

### Command Line Tools:
```bash
# Test MX records
dig MX yourdomain.com

# Test SPF record
dig TXT yourdomain.com

# Test DKIM record
dig TXT selector1._domainkey.yourdomain.com

# Test DMARC record
dig TXT _dmarc.yourdomain.com
```

### Online Testing Tools:
- MXToolbox.com
- mail-tester.com
- dmarcanalyzer.com
- spf-record.com

## 9. Common SMTP Server Settings

### Port Configuration:
- **SMTP**: 25 (unencrypted), 587 (STARTTLS), 465 (SSL/TLS)
- **IMAP**: 143 (unencrypted), 993 (SSL/TLS)
- **POP3**: 110 (unencrypted), 995 (SSL/TLS)

### Security Settings:
- Always use encryption (TLS/SSL)
- Implement SMTP authentication
- Configure proper firewall rules

## 10. Troubleshooting

### Common Issues:
1. **DNS Propagation**: Changes can take 24-48 hours
2. **TTL Values**: Lower TTL during testing (300-600 seconds)
3. **SPF Record Errors**: Ensure proper syntax and include all mail sources
4. **DKIM Issues**: Verify selector and key format
5. **DMARC False Positives**: Start with `p=none` policy

### Testing Commands:
```bash
# Test SMTP connection
telnet mail.yourdomain.com 25

# Test with authentication
openssl s_client -connect mail.yourdomain.com:587 -starttls smtp

# Check DNS propagation
nslookup -type=MX yourdomain.com 8.8.8.8
```

## 11. Security Best Practices

1. **Enable DNSSEC** for your domain
2. **Use strong DMARC policies** after testing
3. **Regularly rotate DKIM keys**
4. **Monitor DMARC reports**
5. **Keep mail servers updated**
6. **Use fail2ban or similar protection**
7. **Implement rate limiting**

## 12. Monitoring and Maintenance

### Regular Tasks:
- Monitor DMARC reports weekly
- Check mail server logs for issues
- Verify DNS record integrity monthly
- Update security patches promptly
- Test email deliverability regularly

### Automation Scripts:
```bash
#!/bin/bash
# DNS Health Check Script
echo "Checking MX records..."
dig +short MX yourdomain.com

echo "Checking SPF record..."
dig +short TXT yourdomain.com | grep spf1

echo "Checking DKIM record..."
dig +short TXT selector1._domainkey.yourdomain.com

echo "Checking DMARC record..."
dig +short TXT _dmarc.yourdomain.com
```

This configuration will provide a robust email infrastructure with proper authentication and security measures in place.