# DNS Configuration for Mail Domains

This repository contains comprehensive documentation and tools for configuring DNS records for mail domains **Mail.bad.mn** and **Mail.Newera.sbs**.

## 📁 Files Overview

### Documentation
- **`dns_mail_configuration.md`** - Complete DNS configuration guide with all required records
- **`dns_configuration_checklist.md`** - Step-by-step implementation checklist
- **`import_files_documentation.md`** - Python import system documentation (from DOT project analysis)

### Tools
- **`dns_configuration_script.py`** - Python script for generating and validating DNS configurations
- **`validate_dns.sh`** - Bash script for automated DNS validation and testing

## 🚀 Quick Start

### 1. Prerequisites
Before starting, ensure you have:
- Mail server set up with static IP
- Access to DNS management panels
- Required tools installed: `dig`, `python3`

### 2. Generate DNS Configuration
```bash
# Edit the script with your actual IP addresses and DKIM keys
python3 dns_configuration_script.py
```

### 3. Follow Implementation Checklist
Use `dns_configuration_checklist.md` for step-by-step implementation.

### 4. Validate Configuration
```bash
# Make script executable (first time only)
chmod +x validate_dns.sh

# Test all domains
./validate_dns.sh

# Test specific domain
./validate_dns.sh -d bad.mn
```

## 📋 Required DNS Records

### Basic Records
- **A Records**: Point domains and mail subdomains to IP addresses
- **MX Records**: Define mail exchange servers

### Security Records
- **SPF**: Prevent email spoofing
- **DKIM**: Digital signature verification
- **DMARC**: Domain-based message authentication policy
- **CAA**: Certificate authority authorization

## 🔧 Configuration Templates

### For bad.mn
```dns
bad.mn.                 A       YOUR_WEB_SERVER_IP
mail.bad.mn.           A       YOUR_MAIL_SERVER_IP
bad.mn.                MX  10  mail.bad.mn.
bad.mn.                TXT     "v=spf1 mx a:mail.bad.mn ip4:YOUR_MAIL_SERVER_IP ~all"
default._domainkey.bad.mn. TXT "v=DKIM1; k=rsa; p=YOUR_DKIM_PUBLIC_KEY"
_dmarc.bad.mn.         TXT     "v=DMARC1; p=quarantine; rua=mailto:dmarc@bad.mn"
```

### For newera.sbs
```dns
newera.sbs.            A       YOUR_WEB_SERVER_IP
mail.newera.sbs.       A       YOUR_MAIL_SERVER_IP
newera.sbs.            MX  10  mail.newera.sbs.
newera.sbs.            TXT     "v=spf1 mx a:mail.newera.sbs ip4:YOUR_MAIL_SERVER_IP ~all"
default._domainkey.newera.sbs. TXT "v=DKIM1; k=rsa; p=YOUR_DKIM_PUBLIC_KEY"
_dmarc.newera.sbs.     TXT     "v=DMARC1; p=quarantine; rua=mailto:dmarc@newera.sbs"
```

## 🧪 Testing Commands

### Manual Testing
```bash
# Basic DNS tests
dig A bad.mn
dig A mail.bad.mn
dig MX bad.mn
dig TXT bad.mn

# Security record tests
dig TXT default._domainkey.bad.mn
dig TXT _dmarc.bad.mn

# Reverse DNS test
dig -x YOUR_MAIL_SERVER_IP
```

### Automated Testing
```bash
# Run comprehensive validation
./validate_dns.sh

# Generate configuration files
python3 dns_configuration_script.py
```

## 📊 Implementation Phases

### Phase 1: Basic Records (Day 1)
- Set up A and MX records
- Test basic connectivity

### Phase 2: Security Records (Day 2-3)
- Configure SPF, DKIM, DMARC
- Start with monitoring mode

### Phase 3: Additional Security (Day 4-5)
- Add CAA records
- Configure SRV records (optional)

### Phase 4: Reverse DNS
- Contact hosting provider
- Set up PTR records

### Phase 5: Testing & Validation
- Use provided scripts
- Manual testing
- DNS propagation checks

### Phase 6: Email Testing
- Send/receive test emails
- Check deliverability scores

### Phase 7: Monitoring & Hardening
- Review DMARC reports
- Gradually tighten security policies

## ⚠️ Important Variables to Replace

Before implementation, replace these placeholders:
- `YOUR_MAIL_SERVER_IP` - Your mail server's public IP
- `YOUR_WEB_SERVER_IP` - Your web server's IP (can be same as mail)
- `YOUR_DKIM_PUBLIC_KEY` - Generated DKIM public key
- `YOUR_NS1_IP` / `YOUR_NS2_IP` - Name server IPs (if self-hosting DNS)

## 🔍 Troubleshooting

### Common Issues
1. **DNS not propagating** - Wait 24-48 hours, check multiple DNS servers
2. **Emails going to spam** - Verify SPF, DKIM, DMARC, reverse DNS
3. **Cannot receive emails** - Check MX records and firewall settings
4. **DKIM failing** - Verify key format and mail server configuration

### Validation Tools
- Use `./validate_dns.sh` for automated checking
- Check MXToolbox.com for comprehensive testing
- Use Mail-tester.com for deliverability scoring

## 📚 Additional Resources

### DNS Providers
- Cloudflare DNS
- Route 53 (AWS)
- Google Cloud DNS
- Traditional registrar DNS panels

### Mail Server Software
- Postfix + Dovecot
- Microsoft Exchange
- Zimbra
- iRedMail

### Monitoring Tools
- DMARC Analyzer
- Postmaster Tools (Google)
- Mail delivery monitoring services

## 🛡️ Security Best Practices

1. **Start Conservative**: Use `~all` for SPF and `p=none` for DMARC initially
2. **Monitor First**: Review DMARC reports before hardening
3. **Gradual Hardening**: Progressively tighten policies
4. **Regular Rotation**: Rotate DKIM keys annually
5. **Continuous Monitoring**: Set up alerts for mail delivery issues

## 📝 Support

For issues or questions:
1. Check the troubleshooting section in `dns_mail_configuration.md`
2. Run validation scripts for diagnostic information
3. Consult your DNS provider's documentation
4. Contact your hosting provider for reverse DNS setup

## 📄 License

This documentation and tooling is provided as-is for educational and implementation purposes. Adapt to your specific requirements and security policies.

---

**Remember**: DNS changes can take 24-48 hours to propagate globally. Always test thoroughly before going into production!
