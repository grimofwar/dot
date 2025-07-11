#!/usr/bin/env python3
"""
DNS Configuration Generator and Validator for Mail Domains
Supports Mail.bad.mn and Mail.Newera.sbs
"""

import json
import subprocess
import sys
from typing import Dict, List, Optional


class DNSConfigGenerator:
    """Generate DNS configurations for mail domains."""
    
    def __init__(self):
        self.domains = {
            'bad.mn': {
                'mail_subdomain': 'mail.bad.mn',
                'mail_server_ip': None,
                'web_server_ip': None,
                'dkim_public_key': None
            },
            'newera.sbs': {
                'mail_subdomain': 'mail.newera.sbs', 
                'mail_server_ip': None,
                'web_server_ip': None,
                'dkim_public_key': None
            }
        }
    
    def set_domain_config(self, domain: str, mail_server_ip: str, 
                         web_server_ip: str = None, dkim_public_key: str = None):
        """Set configuration for a domain."""
        if domain not in self.domains:
            raise ValueError(f"Domain {domain} not supported")
        
        self.domains[domain]['mail_server_ip'] = mail_server_ip
        self.domains[domain]['web_server_ip'] = web_server_ip or mail_server_ip
        self.domains[domain]['dkim_public_key'] = dkim_public_key
    
    def generate_dns_records(self, domain: str) -> Dict[str, List[Dict]]:
        """Generate DNS records for a domain."""
        if domain not in self.domains:
            raise ValueError(f"Domain {domain} not supported")
        
        config = self.domains[domain]
        mail_ip = config['mail_server_ip']
        web_ip = config['web_server_ip']
        dkim_key = config['dkim_public_key']
        mail_subdomain = config['mail_subdomain']
        
        if not mail_ip:
            raise ValueError(f"Mail server IP not set for {domain}")
        
        records = {
            'A_RECORDS': [
                {
                    'name': domain,
                    'type': 'A',
                    'value': web_ip,
                    'ttl': 3600
                },
                {
                    'name': mail_subdomain,
                    'type': 'A', 
                    'value': mail_ip,
                    'ttl': 3600
                }
            ],
            'MX_RECORDS': [
                {
                    'name': domain,
                    'type': 'MX',
                    'priority': 10,
                    'value': mail_subdomain,
                    'ttl': 3600
                }
            ],
            'TXT_RECORDS': [
                {
                    'name': domain,
                    'type': 'TXT',
                    'value': f'"v=spf1 mx a:{mail_subdomain} ip4:{mail_ip} ~all"',
                    'ttl': 3600,
                    'description': 'SPF Record'
                },
                {
                    'name': f'_dmarc.{domain}',
                    'type': 'TXT',
                    'value': f'"v=DMARC1; p=quarantine; rua=mailto:dmarc@{domain}; ruf=mailto:dmarc@{domain}; sp=quarantine; adkim=r; aspf=r"',
                    'ttl': 3600,
                    'description': 'DMARC Record'
                }
            ],
            'CAA_RECORDS': [
                {
                    'name': domain,
                    'type': 'CAA',
                    'value': '0 issue "letsencrypt.org"',
                    'ttl': 3600
                }
            ]
        }
        
        # Add DKIM record if key is provided
        if dkim_key:
            records['TXT_RECORDS'].append({
                'name': f'default._domainkey.{domain}',
                'type': 'TXT',
                'value': f'"v=DKIM1; k=rsa; p={dkim_key}"',
                'ttl': 3600,
                'description': 'DKIM Record'
            })
        
        return records
    
    def generate_zone_file(self, domain: str) -> str:
        """Generate BIND zone file format."""
        if domain not in self.domains:
            raise ValueError(f"Domain {domain} not supported")
        
        config = self.domains[domain]
        mail_ip = config['mail_server_ip']
        web_ip = config['web_server_ip']
        dkim_key = config['dkim_public_key']
        mail_subdomain = config['mail_subdomain'].split('.')[0]  # Get 'mail' part
        
        zone_file = f"""$TTL 3600
@   IN  SOA ns1.{domain}. admin.{domain}. (
    2024010101  ; Serial
    3600        ; Refresh
    1800        ; Retry
    604800      ; Expire
    86400       ; Minimum TTL
)

; Name servers
@           IN  NS      ns1.{domain}.
@           IN  NS      ns2.{domain}.

; A records
@           IN  A       {web_ip}
{mail_subdomain}        IN  A       {mail_ip}

; MX records
@           IN  MX  10  {mail_subdomain}.{domain}.

; TXT records for email security
@           IN  TXT     "v=spf1 mx a:{mail_subdomain}.{domain} ip4:{mail_ip} ~all"
_dmarc      IN  TXT     "v=DMARC1; p=quarantine; rua=mailto:dmarc@{domain}"
"""
        
        if dkim_key:
            zone_file += f'default._domainkey IN TXT "v=DKIM1; k=rsa; p={dkim_key}"\n'
        
        zone_file += f"""
; CAA record
@           IN  CAA     0 issue "letsencrypt.org"
"""
        
        return zone_file
    
    def generate_cloudflare_format(self, domain: str) -> List[Dict]:
        """Generate Cloudflare API format."""
        records = self.generate_dns_records(domain)
        cloudflare_records = []
        
        # Convert to Cloudflare format
        for record_type, record_list in records.items():
            for record in record_list:
                cf_record = {
                    'type': record['type'],
                    'name': record['name'].replace(f'.{domain}', '') if record['name'] != domain else '@',
                    'content': record['value'],
                    'ttl': record['ttl']
                }
                
                if record['type'] == 'MX':
                    cf_record['priority'] = record['priority']
                
                cloudflare_records.append(cf_record)
        
        return cloudflare_records
    
    def export_configuration(self, output_format: str = 'json') -> str:
        """Export all domain configurations."""
        all_configs = {}
        
        for domain in self.domains:
            if self.domains[domain]['mail_server_ip']:
                try:
                    all_configs[domain] = {
                        'dns_records': self.generate_dns_records(domain),
                        'zone_file': self.generate_zone_file(domain),
                        'cloudflare_format': self.generate_cloudflare_format(domain)
                    }
                except Exception as e:
                    all_configs[domain] = {'error': str(e)}
        
        if output_format == 'json':
            return json.dumps(all_configs, indent=2)
        
        return str(all_configs)


class DNSValidator:
    """Validate DNS configurations."""
    
    @staticmethod
    def check_dns_record(domain: str, record_type: str, expected_value: str = None) -> Dict:
        """Check if DNS record exists and matches expected value."""
        try:
            result = subprocess.run(
                ['dig', '+short', record_type, domain],
                capture_output=True, text=True, timeout=10
            )
            
            if result.returncode == 0:
                actual_value = result.stdout.strip()
                return {
                    'domain': domain,
                    'record_type': record_type,
                    'status': 'found',
                    'actual_value': actual_value,
                    'expected_value': expected_value,
                    'matches': actual_value == expected_value if expected_value else None
                }
            else:
                return {
                    'domain': domain,
                    'record_type': record_type,
                    'status': 'error',
                    'error': result.stderr
                }
        except subprocess.TimeoutExpired:
            return {
                'domain': domain,
                'record_type': record_type,
                'status': 'timeout'
            }
        except FileNotFoundError:
            return {
                'domain': domain,
                'record_type': record_type,
                'status': 'error',
                'error': 'dig command not found. Please install dnsutils.'
            }
    
    @staticmethod
    def validate_mail_domain(domain: str, expected_mail_ip: str = None) -> Dict:
        """Validate all mail-related DNS records for a domain."""
        results = {}
        
        # Check A record for mail subdomain
        mail_subdomain = f'mail.{domain}'
        results['mail_a_record'] = DNSValidator.check_dns_record(
            mail_subdomain, 'A', expected_mail_ip
        )
        
        # Check MX record
        results['mx_record'] = DNSValidator.check_dns_record(domain, 'MX')
        
        # Check SPF record
        results['spf_record'] = DNSValidator.check_dns_record(domain, 'TXT')
        
        # Check DKIM record
        results['dkim_record'] = DNSValidator.check_dns_record(
            f'default._domainkey.{domain}', 'TXT'
        )
        
        # Check DMARC record
        results['dmarc_record'] = DNSValidator.check_dns_record(
            f'_dmarc.{domain}', 'TXT'
        )
        
        return results
    
    @staticmethod
    def generate_validation_report(domains: List[str]) -> str:
        """Generate a validation report for multiple domains."""
        report = "DNS Validation Report\n"
        report += "=" * 50 + "\n\n"
        
        for domain in domains:
            report += f"Domain: {domain}\n"
            report += "-" * 30 + "\n"
            
            validation_results = DNSValidator.validate_mail_domain(domain)
            
            for check_name, result in validation_results.items():
                status_icon = "✓" if result['status'] == 'found' else "✗"
                report += f"{status_icon} {check_name}: {result['status']}\n"
                
                if result['status'] == 'found' and result.get('actual_value'):
                    report += f"  Value: {result['actual_value']}\n"
                elif result['status'] == 'error':
                    report += f"  Error: {result.get('error', 'Unknown error')}\n"
            
            report += "\n"
        
        return report


def main():
    """Main function to demonstrate usage."""
    print("DNS Configuration Generator for Mail Domains")
    print("=" * 50)
    
    # Example usage
    generator = DNSConfigGenerator()
    
    # Set configuration for domains
    # Replace these with actual values
    try:
        # Example configuration - replace with actual values
        generator.set_domain_config(
            'bad.mn',
            mail_server_ip='192.168.1.100',  # Replace with actual IP
            web_server_ip='192.168.1.101',   # Replace with actual IP
            dkim_public_key='YOUR_DKIM_PUBLIC_KEY_HERE'  # Replace with actual key
        )
        
        generator.set_domain_config(
            'newera.sbs',
            mail_server_ip='192.168.1.100',  # Replace with actual IP
            web_server_ip='192.168.1.101',   # Replace with actual IP
            dkim_public_key='YOUR_DKIM_PUBLIC_KEY_HERE'  # Replace with actual key
        )
        
        # Generate configurations
        print("\nGenerating DNS configurations...")
        
        for domain in ['bad.mn', 'newera.sbs']:
            print(f"\n--- Configuration for {domain} ---")
            
            # Generate DNS records
            records = generator.generate_dns_records(domain)
            print("DNS Records:")
            for record_type, record_list in records.items():
                print(f"  {record_type}:")
                for record in record_list:
                    print(f"    {record}")
            
            # Generate zone file
            print(f"\nZone file for {domain}:")
            print(generator.generate_zone_file(domain))
        
        # Export all configurations
        print("\n--- Complete Configuration Export ---")
        config_export = generator.export_configuration()
        print(config_export)
        
        # Validate existing DNS (if dig is available)
        print("\n--- DNS Validation ---")
        validator = DNSValidator()
        report = validator.generate_validation_report(['bad.mn', 'newera.sbs'])
        print(report)
        
    except Exception as e:
        print(f"Error: {e}")
        print("\nPlease set actual IP addresses and DKIM keys before running.")


if __name__ == "__main__":
    main()