#!/bin/bash

# DNS Validation Script for Mail Domains
# Validates DNS records for Mail.bad.mn and Mail.Newera.sbs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Domains to test
DOMAINS=("bad.mn" "newera.sbs")

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS")
            echo -e "${GREEN}✓${NC} $message"
            ;;
        "FAIL")
            echo -e "${RED}✗${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠${NC} $message"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ${NC} $message"
            ;;
    esac
}

# Function to check if command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_status "FAIL" "$1 command not found. Please install it."
        return 1
    fi
    return 0
}

# Function to test A record
test_a_record() {
    local domain=$1
    local subdomain=$2
    local expected_ip=$3
    
    print_status "INFO" "Testing A record for $subdomain"
    
    local result=$(dig +short A $subdomain 2>/dev/null)
    
    if [[ -z "$result" ]]; then
        print_status "FAIL" "No A record found for $subdomain"
        return 1
    fi
    
    if [[ -n "$expected_ip" && "$result" != "$expected_ip" ]]; then
        print_status "WARNING" "A record for $subdomain: $result (expected: $expected_ip)"
    else
        print_status "SUCCESS" "A record for $subdomain: $result"
    fi
    
    return 0
}

# Function to test MX record
test_mx_record() {
    local domain=$1
    
    print_status "INFO" "Testing MX record for $domain"
    
    local result=$(dig +short MX $domain 2>/dev/null)
    
    if [[ -z "$result" ]]; then
        print_status "FAIL" "No MX record found for $domain"
        return 1
    fi
    
    print_status "SUCCESS" "MX record for $domain: $result"
    
    # Check if MX points to mail subdomain
    if echo "$result" | grep -q "mail.$domain"; then
        print_status "SUCCESS" "MX record correctly points to mail.$domain"
    else
        print_status "WARNING" "MX record does not point to mail.$domain"
    fi
    
    return 0
}

# Function to test SPF record
test_spf_record() {
    local domain=$1
    
    print_status "INFO" "Testing SPF record for $domain"
    
    local result=$(dig +short TXT $domain 2>/dev/null | grep -i "v=spf1")
    
    if [[ -z "$result" ]]; then
        print_status "FAIL" "No SPF record found for $domain"
        return 1
    fi
    
    print_status "SUCCESS" "SPF record found: $result"
    
    # Check SPF policy
    if echo "$result" | grep -q "~all"; then
        print_status "SUCCESS" "SPF uses SoftFail policy (~all)"
    elif echo "$result" | grep -q "\-all"; then
        print_status "SUCCESS" "SPF uses HardFail policy (-all)"
    else
        print_status "WARNING" "SPF policy unclear or missing"
    fi
    
    return 0
}

# Function to test DKIM record
test_dkim_record() {
    local domain=$1
    local selector=${2:-"default"}
    
    print_status "INFO" "Testing DKIM record for $domain (selector: $selector)"
    
    local dkim_domain="${selector}._domainkey.$domain"
    local result=$(dig +short TXT $dkim_domain 2>/dev/null | grep -i "v=dkim1")
    
    if [[ -z "$result" ]]; then
        print_status "FAIL" "No DKIM record found for $dkim_domain"
        return 1
    fi
    
    print_status "SUCCESS" "DKIM record found"
    
    # Check key length indication
    if echo "$result" | grep -q "k=rsa"; then
        print_status "SUCCESS" "DKIM uses RSA keys"
    fi
    
    return 0
}

# Function to test DMARC record
test_dmarc_record() {
    local domain=$1
    
    print_status "INFO" "Testing DMARC record for $domain"
    
    local dmarc_domain="_dmarc.$domain"
    local result=$(dig +short TXT $dmarc_domain 2>/dev/null | grep -i "v=dmarc1")
    
    if [[ -z "$result" ]]; then
        print_status "FAIL" "No DMARC record found for $dmarc_domain"
        return 1
    fi
    
    print_status "SUCCESS" "DMARC record found: $result"
    
    # Check DMARC policy
    if echo "$result" | grep -q "p=none"; then
        print_status "INFO" "DMARC policy is 'none' (monitoring only)"
    elif echo "$result" | grep -q "p=quarantine"; then
        print_status "SUCCESS" "DMARC policy is 'quarantine'"
    elif echo "$result" | grep -q "p=reject"; then
        print_status "SUCCESS" "DMARC policy is 'reject'"
    fi
    
    return 0
}

# Function to test mail server connectivity
test_mail_server_connectivity() {
    local domain=$1
    local mail_server="mail.$domain"
    
    print_status "INFO" "Testing mail server connectivity for $mail_server"
    
    # Test SMTP port (25)
    if timeout 5 bash -c "</dev/tcp/$mail_server/25" 2>/dev/null; then
        print_status "SUCCESS" "SMTP port 25 is open on $mail_server"
    else
        print_status "WARNING" "SMTP port 25 is not accessible on $mail_server"
    fi
    
    # Test submission port (587)
    if timeout 5 bash -c "</dev/tcp/$mail_server/587" 2>/dev/null; then
        print_status "SUCCESS" "Submission port 587 is open on $mail_server"
    else
        print_status "WARNING" "Submission port 587 is not accessible on $mail_server"
    fi
    
    # Test IMAPS port (993)
    if timeout 5 bash -c "</dev/tcp/$mail_server/993" 2>/dev/null; then
        print_status "SUCCESS" "IMAPS port 993 is open on $mail_server"
    else
        print_status "WARNING" "IMAPS port 993 is not accessible on $mail_server"
    fi
}

# Function to test reverse DNS
test_reverse_dns() {
    local mail_server=$1
    
    print_status "INFO" "Testing reverse DNS for $mail_server"
    
    local ip=$(dig +short A $mail_server 2>/dev/null)
    if [[ -z "$ip" ]]; then
        print_status "FAIL" "Cannot resolve IP for $mail_server"
        return 1
    fi
    
    local reverse=$(dig +short -x $ip 2>/dev/null)
    if [[ -z "$reverse" ]]; then
        print_status "FAIL" "No reverse DNS found for $ip"
        return 1
    fi
    
    # Remove trailing dot
    reverse=${reverse%.}
    
    if [[ "$reverse" == "$mail_server" ]]; then
        print_status "SUCCESS" "Reverse DNS correctly points to $mail_server"
    else
        print_status "WARNING" "Reverse DNS points to $reverse (expected: $mail_server)"
    fi
    
    return 0
}

# Function to generate summary report
generate_summary() {
    local domain=$1
    local total_tests=$2
    local passed_tests=$3
    local failed_tests=$4
    
    echo ""
    echo "==============================================="
    echo "SUMMARY FOR $domain"
    echo "==============================================="
    echo "Total tests: $total_tests"
    echo "Passed: $passed_tests"
    echo "Failed: $failed_tests"
    
    local success_rate=$((passed_tests * 100 / total_tests))
    if [[ $success_rate -ge 80 ]]; then
        print_status "SUCCESS" "DNS configuration looks good ($success_rate% success rate)"
    elif [[ $success_rate -ge 60 ]]; then
        print_status "WARNING" "DNS configuration needs some attention ($success_rate% success rate)"
    else
        print_status "FAIL" "DNS configuration needs significant work ($success_rate% success rate)"
    fi
    echo ""
}

# Main function to test a domain
test_domain() {
    local domain=$1
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    echo ""
    echo "==============================================="
    echo "TESTING DOMAIN: $domain"
    echo "==============================================="
    
    # Test A record for main domain
    total_tests=$((total_tests + 1))
    if test_a_record "$domain" "$domain"; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
    
    # Test A record for mail subdomain
    total_tests=$((total_tests + 1))
    if test_a_record "$domain" "mail.$domain"; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
    
    # Test MX record
    total_tests=$((total_tests + 1))
    if test_mx_record "$domain"; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
    
    # Test SPF record
    total_tests=$((total_tests + 1))
    if test_spf_record "$domain"; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
    
    # Test DKIM record
    total_tests=$((total_tests + 1))
    if test_dkim_record "$domain"; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
    
    # Test DMARC record
    total_tests=$((total_tests + 1))
    if test_dmarc_record "$domain"; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
    
    # Test mail server connectivity
    total_tests=$((total_tests + 1))
    if test_mail_server_connectivity "$domain"; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
    
    # Test reverse DNS
    total_tests=$((total_tests + 1))
    if test_reverse_dns "mail.$domain"; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
    
    generate_summary "$domain" "$total_tests" "$passed_tests" "$failed_tests"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -d, --domain DOMAIN    Test specific domain only"
    echo "  -h, --help            Show this help message"
    echo "  -v, --verbose         Enable verbose output"
    echo ""
    echo "Examples:"
    echo "  $0                    # Test all configured domains"
    echo "  $0 -d bad.mn         # Test only bad.mn"
    echo "  $0 -d newera.sbs     # Test only newera.sbs"
}

# Main script execution
main() {
    local specific_domain=""
    local verbose=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--domain)
                specific_domain="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo "DNS Validation Script for Mail Domains"
    echo "======================================"
    
    # Check required commands
    if ! check_command "dig"; then
        exit 1
    fi
    
    # Test specific domain or all domains
    if [[ -n "$specific_domain" ]]; then
        test_domain "$specific_domain"
    else
        for domain in "${DOMAINS[@]}"; do
            test_domain "$domain"
        done
    fi
    
    echo ""
    print_status "INFO" "DNS validation complete!"
    echo ""
    echo "Next steps:"
    echo "1. Fix any failed or warning items"
    echo "2. Wait for DNS propagation (24-48 hours)"
    echo "3. Test email sending and receiving"
    echo "4. Monitor DMARC reports"
}

# Run main function with all arguments
main "$@"