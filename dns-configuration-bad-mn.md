# DNS Configuration for bad.mn Domain

## Current DNS Status

Based on the DNS analysis performed, here's the current configuration:

### Existing Records:
- **Domain**: bad.mn
- **Name Servers**: ns1.afraid.org, ns2.afraid.org, ns3.afraid.org, ns4.afraid.org (FreeDNS)
- **A Records**: 
  - bad.mn → 169.47.130.75
  - bad.mn → 70.39.97.239
- **MX Records**: **NOT CONFIGURED** ❌
- **SPF Records**: **NOT CONFIGURED** ❌
- **DKIM Records**: **NOT CONFIGURED** ❌
- **DMARC Records**: **NOT CONFIGURED** ❌

## Required Configuration for mail.bad.mn

### 1. A Record for Mail Server
```
Type: A
Name: mail
Value: [YOUR_MAIL_SERVER_IP]
TTL: 3600
```

### 2. MX Records
```
Type: MX
Name: @
Value: 10 mail.bad.mn
TTL: 3600

Type: MX
Name: @
Value: 20 mail2.bad.mn (backup - optional)
TTL: 3600
```

### 3. SPF Record
```
Type: TXT
Name: @
Value: "v=spf1 a:mail.bad.mn ip4:[YOUR_MAIL_SERVER_IP] ~all"
TTL: 3600
```

### 4. DKIM Record (Generate keys first)
```
Type: TXT
Name: selector1._domainkey
Value: "v=DKIM1; k=rsa; p=[YOUR_DKIM_PUBLIC_KEY]"
TTL: 3600
```

### 5. DMARC Record
```
Type: TXT
Name: _dmarc
Value: "v=DMARC1; p=quarantine; rua=mailto:dmarc@bad.mn; ruf=mailto:dmarc@bad.mn; sp=quarantine; adkim=r; aspf=r"
TTL: 3600
```

## Configuration Steps

### Step 1: Determine Mail Server IP
First, decide where your mail server will be hosted:
- Use one of the existing IPs (169.47.130.75 or 70.39.97.239)
- Or set up a new dedicated mail server

### Step 2: Configure DNS Records
Since you're using FreeDNS, log into your FreeDNS account at https://freedns.afraid.org and add the following records:

1. **Add A Record for mail subdomain**:
   - Subdomain: mail
   - Domain: bad.mn
   - Destination: [YOUR_MAIL_SERVER_IP]

2. **Add MX Record**:
   - Type: MX
   - Subdomain: (leave blank for @)
   - Domain: bad.mn  
   - Destination: mail.bad.mn
   - Priority: 10

3. **Add SPF TXT Record**:
   - Type: TXT
   - Subdomain: (leave blank for @)
   - Domain: bad.mn
   - Destination: "v=spf1 a:mail.bad.mn ~all"

### Step 3: Generate DKIM Keys
```bash
# Install OpenDKIM
sudo apt-get install opendkim opendkim-tools

# Generate DKIM key pair
sudo opendkim-genkey -t -s selector1 -d bad.mn

# This creates:
# - selector1.private (private key - keep secure)
# - selector1.txt (public key for DNS)
```

### Step 4: Add DKIM and DMARC Records
1. **DKIM Record**:
   - Type: TXT
   - Subdomain: selector1._domainkey
   - Domain: bad.mn
   - Destination: [content from selector1.txt file]

2. **DMARC Record**:
   - Type: TXT
   - Subdomain: _dmarc
   - Domain: bad.mn
   - Destination: "v=DMARC1; p=quarantine; rua=mailto:dmarc@bad.mn"

## Complete DNS Zone Configuration

```dns
; A Records
@           IN A    169.47.130.75
@           IN A    70.39.97.239
mail        IN A    [YOUR_MAIL_SERVER_IP]

; MX Records
@           IN MX   10 mail.bad.mn.
@           IN MX   20 mail2.bad.mn.  ; Optional backup

; SPF Record
@           IN TXT  "v=spf1 a:mail.bad.mn ~all"

; DKIM Record
selector1._domainkey IN TXT "v=DKIM1; k=rsa; p=[YOUR_DKIM_PUBLIC_KEY]"

; DMARC Record
_dmarc      IN TXT  "v=DMARC1; p=quarantine; rua=mailto:dmarc@bad.mn"

; Optional CNAME Records
smtp        IN CNAME mail.bad.mn.
imap        IN CNAME mail.bad.mn.
pop3        IN CNAME mail.bad.mn.
webmail     IN CNAME mail.bad.mn.
```

## Verification Commands

After configuring DNS records, verify them with:

```bash
# Check MX records
dig MX bad.mn

# Check A record for mail subdomain
dig A mail.bad.mn

# Check SPF record
dig TXT bad.mn

# Check DKIM record
dig TXT selector1._domainkey.bad.mn

# Check DMARC record
dig TXT _dmarc.bad.mn
```

## Mail Server Configuration

### Postfix Configuration (/etc/postfix/main.cf)
```
myhostname = mail.bad.mn
mydomain = bad.mn
myorigin = $mydomain
inet_interfaces = all
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain

# SMTP Authentication
smtpd_sasl_auth_enable = yes
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth

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

### OpenDKIM Configuration (/etc/opendkim.conf)
```
Syslog                  yes
UMask                   022
Domain                  bad.mn
KeyFile                 /etc/opendkim/keys/bad.mn/selector1.private
Selector                selector1
Socket                  inet:8891@localhost
PidFile                 /var/run/opendkim/opendkim.pid
UserID                  opendkim:opendkim
TrustAnchorFile         /usr/share/dns/root.key
```

## Security Considerations

1. **Use Strong Passwords**: For all email accounts
2. **Enable Fail2Ban**: To prevent brute force attacks
3. **Regular Updates**: Keep mail server software updated
4. **Firewall Configuration**: Only open necessary ports (25, 587, 993, 995)
5. **SSL/TLS Certificates**: Use Let's Encrypt for free certificates
6. **Monitor Logs**: Regularly check mail server logs

## Testing Email Delivery

### Online Testing Tools:
- mail-tester.com
- mxtoolbox.com
- dmarcanalyzer.com

### Command Line Testing:
```bash
# Test SMTP connection
telnet mail.bad.mn 25

# Test with SSL
openssl s_client -connect mail.bad.mn:587 -starttls smtp

# Send test email
echo "Test email body" | mail -s "Test Subject" test@gmail.com
```

## Troubleshooting

### Common Issues:

1. **DNS Propagation**: Changes can take 24-48 hours
2. **Port Blocking**: ISPs may block port 25
3. **Reverse DNS**: Configure PTR record with hosting provider
4. **Spam Filtering**: Properly configure SPF, DKIM, and DMARC

### Log Files to Check:
- `/var/log/mail.log`
- `/var/log/postfix.log`
- `/var/log/dovecot.log`

## Maintenance Schedule

- **Daily**: Check mail queue and logs
- **Weekly**: Review DMARC reports
- **Monthly**: Update software and review security
- **Quarterly**: Rotate DKIM keys
- **Annually**: Renew SSL certificates