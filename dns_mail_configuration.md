# DNS Configuration for Mail Domains

## Domains to Configure
- **Mail.bad.mn**
- **Mail.Newera.sbs**

## Required DNS Records Overview

For a complete mail server setup, you'll need the following DNS record types:
- **A Records** - Point domains to IP addresses
- **MX Records** - Mail exchange records
- **SPF Records** - Sender Policy Framework (TXT)
- **DKIM Records** - DomainKeys Identified Mail (TXT)
- **DMARC Records** - Domain-based Message Authentication (TXT)
- **PTR Records** - Reverse DNS (configured at hosting provider)

## Prerequisites

Before configuring DNS records, ensure you have:
- [ ] Mail server IP address(es)
- [ ] DKIM public key from your mail server
- [ ] Access to DNS management panel
- [ ] Reverse DNS configured at hosting provider

---

## DNS Configuration for Mail.bad.mn

### Basic Records

#### A Records
```
Name: mail.bad.mn
Type: A
Value: YOUR_MAIL_SERVER_IP
TTL: 3600

Name: bad.mn (or @)
Type: A  
Value: YOUR_WEB_SERVER_IP
TTL: 3600
```

#### MX Records
```
Name: bad.mn (or @)
Type: MX
Priority: 10
Value: mail.bad.mn
TTL: 3600

Name: bad.mn (or @)
Type: MX
Priority: 20
Value: mail2.bad.mn (backup, optional)
TTL: 3600
```

### Email Security Records

#### SPF Record
```
Name: bad.mn (or @)
Type: TXT
Value: "v=spf1 mx a:mail.bad.mn ip4:YOUR_MAIL_SERVER_IP ~all"
TTL: 3600
```

#### DKIM Record
```
Name: default._domainkey.bad.mn
Type: TXT
Value: "v=DKIM1; k=rsa; p=YOUR_DKIM_PUBLIC_KEY"
TTL: 3600
```

#### DMARC Record
```
Name: _dmarc.bad.mn
Type: TXT
Value: "v=DMARC1; p=quarantine; rua=mailto:dmarc@bad.mn; ruf=mailto:dmarc@bad.mn; sp=quarantine; adkim=r; aspf=r"
TTL: 3600
```

---

## DNS Configuration for Mail.Newera.sbs

### Basic Records

#### A Records
```
Name: mail.newera.sbs
Type: A
Value: YOUR_MAIL_SERVER_IP
TTL: 3600

Name: newera.sbs (or @)
Type: A
Value: YOUR_WEB_SERVER_IP
TTL: 3600
```

#### MX Records
```
Name: newera.sbs (or @)
Type: MX
Priority: 10
Value: mail.newera.sbs
TTL: 3600

Name: newera.sbs (or @)
Type: MX
Priority: 20
Value: mail2.newera.sbs (backup, optional)
TTL: 3600
```

### Email Security Records

#### SPF Record
```
Name: newera.sbs (or @)
Type: TXT
Value: "v=spf1 mx a:mail.newera.sbs ip4:YOUR_MAIL_SERVER_IP ~all"
TTL: 3600
```

#### DKIM Record
```
Name: default._domainkey.newera.sbs
Type: TXT
Value: "v=DKIM1; k=rsa; p=YOUR_DKIM_PUBLIC_KEY"
TTL: 3600
```

#### DMARC Record
```
Name: _dmarc.newera.sbs
Type: TXT
Value: "v=DMARC1; p=quarantine; rua=mailto:dmarc@newera.sbs; ruf=mailto:dmarc@newera.sbs; sp=quarantine; adkim=r; aspf=r"
TTL: 3600
```

---

## Additional Security Records

### CAA Records (Certificate Authority Authorization)
```
# For Mail.bad.mn
Name: bad.mn
Type: CAA
Value: 0 issue "letsencrypt.org"

# For Mail.Newera.sbs
Name: newera.sbs
Type: CAA
Value: 0 issue "letsencrypt.org"
```

### SRV Records (Optional - for specific services)
```
# IMAP over SSL
Name: _imaps._tcp.bad.mn
Type: SRV
Priority: 0
Weight: 5
Port: 993
Target: mail.bad.mn

# SMTP Submission
Name: _submission._tcp.bad.mn
Type: SRV
Priority: 0
Weight: 5
Port: 587
Target: mail.bad.mn
```

---

## DNS Zone File Format Examples

### Zone File for bad.mn
```bind
$TTL 3600
@   IN  SOA ns1.bad.mn. admin.bad.mn. (
    2024010101  ; Serial
    3600        ; Refresh
    1800        ; Retry
    604800      ; Expire
    86400       ; Minimum TTL
)

; Name servers
@           IN  NS      ns1.bad.mn.
@           IN  NS      ns2.bad.mn.

; A records
@           IN  A       YOUR_WEB_SERVER_IP
mail        IN  A       YOUR_MAIL_SERVER_IP
ns1         IN  A       YOUR_NS1_IP
ns2         IN  A       YOUR_NS2_IP

; MX records
@           IN  MX  10  mail.bad.mn.

; TXT records for email security
@           IN  TXT     "v=spf1 mx a:mail.bad.mn ip4:YOUR_MAIL_SERVER_IP ~all"
_dmarc      IN  TXT     "v=DMARC1; p=quarantine; rua=mailto:dmarc@bad.mn"
default._domainkey IN TXT "v=DKIM1; k=rsa; p=YOUR_DKIM_PUBLIC_KEY"

; CAA record
@           IN  CAA     0 issue "letsencrypt.org"
```

### Zone File for newera.sbs
```bind
$TTL 3600
@   IN  SOA ns1.newera.sbs. admin.newera.sbs. (
    2024010101  ; Serial
    3600        ; Refresh
    1800        ; Retry
    604800      ; Expire
    86400       ; Minimum TTL
)

; Name servers
@           IN  NS      ns1.newera.sbs.
@           IN  NS      ns2.newera.sbs.

; A records
@           IN  A       YOUR_WEB_SERVER_IP
mail        IN  A       YOUR_MAIL_SERVER_IP
ns1         IN  A       YOUR_NS1_IP
ns2         IN  A       YOUR_NS2_IP

; MX records
@           IN  MX  10  mail.newera.sbs.

; TXT records for email security
@           IN  TXT     "v=spf1 mx a:mail.newera.sbs ip4:YOUR_MAIL_SERVER_IP ~all"
_dmarc      IN  TXT     "v=DMARC1; p=quarantine; rua=mailto:dmarc@newera.sbs"
default._domainkey IN TXT "v=DKIM1; k=rsa; p=YOUR_DKIM_PUBLIC_KEY"

; CAA record
@           IN  CAA     0 issue "letsencrypt.org"
```

---

## Configuration Steps

### 1. Pre-Configuration Checklist
- [ ] Obtain mail server IP address
- [ ] Generate DKIM keys on mail server
- [ ] Configure reverse DNS (PTR record) with hosting provider
- [ ] Prepare mail server software (Postfix, Dovecot, etc.)

### 2. DNS Configuration Order
1. **Create A records first** (mail.domain.tld)
2. **Add MX records** pointing to mail subdomain
3. **Configure SPF record** (start with soft fail ~all)
4. **Generate and add DKIM record**
5. **Set up DMARC policy** (start with p=none for testing)
6. **Add CAA records** for certificate security

### 3. Testing Commands
```bash
# Test MX records
dig MX bad.mn
dig MX newera.sbs

# Test A records
dig A mail.bad.mn
dig A mail.newera.sbs

# Test SPF records
dig TXT bad.mn | grep spf
dig TXT newera.sbs | grep spf

# Test DKIM records
dig TXT default._domainkey.bad.mn
dig TXT default._domainkey.newera.sbs

# Test DMARC records
dig TXT _dmarc.bad.mn
dig TXT _dmarc.newera.sbs
```

---

## Common DNS Provider Interfaces

### Cloudflare Format
```
Type: A
Name: mail
Content: YOUR_MAIL_SERVER_IP
TTL: Auto

Type: MX
Name: @
Content: mail.bad.mn
Priority: 10
TTL: Auto

Type: TXT
Name: @
Content: v=spf1 mx a:mail.bad.mn ip4:YOUR_MAIL_SERVER_IP ~all
TTL: Auto
```

### cPanel/WHM Format
```
A Record:
Host: mail.bad.mn
Points to: YOUR_MAIL_SERVER_IP

MX Record:
Domain: bad.mn
Priority: 10
Destination: mail.bad.mn

TXT Record:
Host: bad.mn
TXT Data: v=spf1 mx a:mail.bad.mn ip4:YOUR_MAIL_SERVER_IP ~all
```

---

## Security Best Practices

### SPF Policy Levels
- **~all** (SoftFail) - Recommended for initial setup
- **-all** (HardFail) - Use after confirming everything works
- **?all** (Neutral) - Not recommended for production

### DMARC Policy Progression
1. **p=none** - Monitor only (initial setup)
2. **p=quarantine** - Mark suspicious emails
3. **p=reject** - Reject unauthorized emails (final stage)

### DKIM Key Management
- Use 2048-bit RSA keys minimum
- Rotate DKIM keys annually
- Use descriptive selectors (e.g., 2024jan._domainkey)

---

## Troubleshooting Common Issues

### Problem: Emails marked as spam
**Solutions:**
- Verify SPF record is correct
- Ensure DKIM is properly signed
- Check reverse DNS (PTR) record
- Implement DMARC policy

### Problem: Cannot receive emails
**Solutions:**
- Verify MX record points to correct server
- Check A record for mail subdomain
- Ensure mail server is running and accessible
- Check firewall rules (ports 25, 587, 993, 995)

### Problem: DKIM verification failing
**Solutions:**
- Verify DKIM public key in DNS matches private key
- Check DKIM selector name
- Ensure no line breaks in DKIM record
- Verify mail server DKIM configuration

---

## Variables to Replace

Before implementing, replace these variables with actual values:

- **YOUR_MAIL_SERVER_IP** - Your mail server's public IP address
- **YOUR_WEB_SERVER_IP** - Your web server's IP address (if different)
- **YOUR_DKIM_PUBLIC_KEY** - Generated DKIM public key (without spaces/line breaks)
- **YOUR_NS1_IP** / **YOUR_NS2_IP** - Your name server IP addresses

---

## Monitoring and Maintenance

### Regular Checks
- Monthly DMARC report review
- Quarterly DKIM key rotation
- Annual DNS record audit
- Continuous mail delivery monitoring

### Tools for Monitoring
- MXToolbox.com - DNS and mail server testing
- Mail-tester.com - Email deliverability testing
- DMARC Analyzer - DMARC report analysis
- Google Postmaster Tools - Gmail delivery insights

This configuration provides a robust foundation for mail delivery with strong security practices for both domains.