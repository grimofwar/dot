# DNS Configuration Implementation Checklist

## Pre-Implementation Checklist

### ✅ Prerequisites
- [ ] Mail server is set up and running
- [ ] Static IP address assigned to mail server
- [ ] Mail server software configured (Postfix, Dovecot, etc.)
- [ ] SSL certificates ready (Let's Encrypt recommended)
- [ ] Access to DNS management panel for both domains
- [ ] DKIM keys generated on mail server

### ✅ Information Gathering
- [ ] Mail server IP address: `________________`
- [ ] Web server IP address: `________________`
- [ ] DNS provider for bad.mn: `________________`
- [ ] DNS provider for newera.sbs: `________________`
- [ ] DKIM public key generated: `[ ]`

---

## Phase 1: Basic DNS Records (Day 1)

### For bad.mn

#### ✅ A Records
- [ ] Create A record: `bad.mn` → `WEB_SERVER_IP`
- [ ] Create A record: `mail.bad.mn` → `MAIL_SERVER_IP`

#### ✅ MX Records
- [ ] Create MX record: `bad.mn` → `mail.bad.mn` (Priority: 10)
- [ ] (Optional) Create backup MX: `bad.mn` → `mail2.bad.mn` (Priority: 20)

### For newera.sbs

#### ✅ A Records
- [ ] Create A record: `newera.sbs` → `WEB_SERVER_IP`
- [ ] Create A record: `mail.newera.sbs` → `MAIL_SERVER_IP`

#### ✅ MX Records
- [ ] Create MX record: `newera.sbs` → `mail.newera.sbs` (Priority: 10)
- [ ] (Optional) Create backup MX: `newera.sbs` → `mail2.newera.sbs` (Priority: 20)

### ✅ Initial Testing
- [ ] Run: `dig A bad.mn`
- [ ] Run: `dig A mail.bad.mn`
- [ ] Run: `dig MX bad.mn`
- [ ] Run: `dig A newera.sbs`
- [ ] Run: `dig A mail.newera.sbs`
- [ ] Run: `dig MX newera.sbs`

---

## Phase 2: Email Security Records (Day 2-3)

### ✅ SPF Records (Start with Soft Fail)

#### For bad.mn
- [ ] Create TXT record: `bad.mn`
- [ ] Value: `"v=spf1 mx a:mail.bad.mn ip4:MAIL_SERVER_IP ~all"`

#### For newera.sbs
- [ ] Create TXT record: `newera.sbs`
- [ ] Value: `"v=spf1 mx a:mail.newera.sbs ip4:MAIL_SERVER_IP ~all"`

### ✅ DKIM Records

#### For bad.mn
- [ ] Generate DKIM keys on mail server
- [ ] Create TXT record: `default._domainkey.bad.mn`
- [ ] Value: `"v=DKIM1; k=rsa; p=DKIM_PUBLIC_KEY"`

#### For newera.sbs
- [ ] Generate DKIM keys on mail server
- [ ] Create TXT record: `default._domainkey.newera.sbs`
- [ ] Value: `"v=DKIM1; k=rsa; p=DKIM_PUBLIC_KEY"`

### ✅ DMARC Records (Start with Monitoring)

#### For bad.mn
- [ ] Create TXT record: `_dmarc.bad.mn`
- [ ] Value: `"v=DMARC1; p=none; rua=mailto:dmarc@bad.mn; ruf=mailto:dmarc@bad.mn"`

#### For newera.sbs
- [ ] Create TXT record: `_dmarc.newera.sbs`
- [ ] Value: `"v=DMARC1; p=none; rua=mailto:dmarc@newera.sbs; ruf=mailto:dmarc@newera.sbs"`

---

## Phase 3: Additional Security Records (Day 4-5)

### ✅ CAA Records (Certificate Authority Authorization)

#### For bad.mn
- [ ] Create CAA record: `bad.mn`
- [ ] Value: `0 issue "letsencrypt.org"`

#### For newera.sbs
- [ ] Create CAA record: `newera.sbs`
- [ ] Value: `0 issue "letsencrypt.org"`

### ✅ SRV Records (Optional - for specific clients)

#### For bad.mn
- [ ] Create SRV record: `_imaps._tcp.bad.mn`
- [ ] Value: `0 5 993 mail.bad.mn`
- [ ] Create SRV record: `_submission._tcp.bad.mn`
- [ ] Value: `0 5 587 mail.bad.mn`

#### For newera.sbs
- [ ] Create SRV record: `_imaps._tcp.newera.sbs`
- [ ] Value: `0 5 993 mail.newera.sbs`
- [ ] Create SRV record: `_submission._tcp.newera.sbs`
- [ ] Value: `0 5 587 mail.newera.sbs`

---

## Phase 4: Reverse DNS Configuration

### ✅ PTR Records (Contact Hosting Provider)
- [ ] Contact hosting provider for reverse DNS setup
- [ ] Request PTR record: `MAIL_SERVER_IP` → `mail.bad.mn`
- [ ] Request PTR record: `MAIL_SERVER_IP` → `mail.newera.sbs` (if different IP)
- [ ] Verify reverse DNS: `dig -x MAIL_SERVER_IP`

---

## Phase 5: Testing and Validation

### ✅ DNS Propagation Check (Wait 24-48 hours)
- [ ] Test with multiple DNS checkers:
  - [ ] MXToolbox.com
  - [ ] WhatsMyDNS.net
  - [ ] DNS Checker

### ✅ Automated Testing
- [ ] Run validation script: `./validate_dns.sh`
- [ ] Run Python script: `python3 dns_configuration_script.py`
- [ ] Review all test results

### ✅ Manual DNS Testing
```bash
# Test basic records
dig A bad.mn
dig A mail.bad.mn
dig MX bad.mn
dig A newera.sbs
dig A mail.newera.sbs
dig MX newera.sbs

# Test security records
dig TXT bad.mn | grep spf
dig TXT default._domainkey.bad.mn
dig TXT _dmarc.bad.mn
dig TXT newera.sbs | grep spf
dig TXT default._domainkey.newera.sbs
dig TXT _dmarc.newera.sbs

# Test reverse DNS
dig -x MAIL_SERVER_IP
```

### ✅ Mail Server Connectivity Testing
- [ ] Test SMTP port: `telnet mail.bad.mn 25`
- [ ] Test submission port: `telnet mail.bad.mn 587`
- [ ] Test IMAPS port: `telnet mail.bad.mn 993`
- [ ] Test SMTP port: `telnet mail.newera.sbs 25`
- [ ] Test submission port: `telnet mail.newera.sbs 587`
- [ ] Test IMAPS port: `telnet mail.newera.sbs 993`

---

## Phase 6: Email Testing

### ✅ Basic Email Functionality
- [ ] Send test email from mail server
- [ ] Receive test email to mail server
- [ ] Check email headers for proper authentication
- [ ] Test with multiple email providers (Gmail, Outlook, Yahoo)

### ✅ Deliverability Testing
- [ ] Use Mail-tester.com for deliverability score
- [ ] Send emails to major providers and check spam folders
- [ ] Monitor bounce rates and delivery reports

---

## Phase 7: Monitoring and Maintenance

### ✅ DMARC Monitoring Setup
- [ ] Set up DMARC report collection
- [ ] Configure automated DMARC analysis
- [ ] Review weekly DMARC reports

### ✅ Security Hardening (After 2 weeks of monitoring)
- [ ] Update SPF from `~all` to `-all` (if no issues)
- [ ] Update DMARC from `p=none` to `p=quarantine`
- [ ] Monitor for 1 month, then consider `p=reject`

### ✅ Regular Maintenance Tasks
- [ ] Monthly DMARC report review
- [ ] Quarterly DKIM key rotation
- [ ] Annual DNS record audit
- [ ] Continuous monitoring setup

---

## Troubleshooting Checklist

### ✅ Common Issues
- [ ] **Emails going to spam**: Check SPF, DKIM, DMARC, reverse DNS
- [ ] **Cannot receive emails**: Verify MX records and mail server accessibility
- [ ] **DKIM verification failing**: Check DKIM record format and key matching
- [ ] **DNS not propagating**: Wait longer or check with multiple DNS servers

### ✅ Emergency Contacts
- [ ] DNS Provider Support: `________________`
- [ ] Hosting Provider Support: `________________`
- [ ] Mail Server Administrator: `________________`

---

## Configuration Commands Summary

### Using dig for testing:
```bash
# Basic tests
dig A bad.mn
dig MX bad.mn
dig TXT bad.mn

# Security tests
dig TXT default._domainkey.bad.mn
dig TXT _dmarc.bad.mn

# Reverse DNS test
dig -x YOUR_MAIL_SERVER_IP
```

### Using the provided scripts:
```bash
# Automated validation
./validate_dns.sh

# Test specific domain
./validate_dns.sh -d bad.mn

# Generate configuration
python3 dns_configuration_script.py
```

---

## Final Verification

### ✅ Complete System Test
- [ ] All DNS records resolve correctly
- [ ] Mail server accepts connections on all required ports
- [ ] Emails can be sent and received
- [ ] Authentication (SPF, DKIM, DMARC) passes
- [ ] Reverse DNS is properly configured
- [ ] No emails are marked as spam by major providers

### ✅ Documentation
- [ ] Document final IP addresses used
- [ ] Save DKIM keys securely
- [ ] Document any custom configurations
- [ ] Create backup of DNS zone files
- [ ] Set up monitoring alerts

---

## Security Best Practices Reminder

1. **Start Conservative**: Use `~all` for SPF and `p=none` for DMARC initially
2. **Monitor First**: Review DMARC reports before tightening policies
3. **Gradual Hardening**: Move to stricter policies over time
4. **Regular Updates**: Keep DKIM keys rotated and systems updated
5. **Multiple Testing**: Test email delivery with various providers
6. **Backup Planning**: Have fallback MX records and recovery procedures

---

## Notes Section

Use this space to document domain-specific configurations, custom settings, or issues encountered:

```
Domain: bad.mn
Mail Server IP: ________________
Notes: _________________________
___________________________________

Domain: newera.sbs
Mail Server IP: ________________
Notes: _________________________
___________________________________

DKIM Keys Location: ________________
Last Updated: ________________
Next Review Date: ________________
```