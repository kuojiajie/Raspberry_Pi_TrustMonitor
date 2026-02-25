#!/bin/bash
# tools/gen_keypair.sh
# RSA key pair generator for digital signatures
# Generates public/private key pair for manifest signing

set -u

# Load TrustMonitor initialization system
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/trustmon_init.sh"

# Initialize this script
init_trustmon_script "gen_keypair.sh"

# Load environment variables
load_script_config "gen_keypair.sh"

# Configuration (using unified path manager)
KEY_SIZE="${RSA_KEY_SIZE:-2048}"
KEY_DIR="$KEYS_DIR"  # From path_manager.sh
PRIVATE_KEY_FILE="$KEY_DIR/private_key.pem"
PUBLIC_KEY_FILE="$KEY_DIR/public_key.pem"

# Logging functions
gen_keypair_log_info() {
    log_info "[KEYGEN] $1"
}

gen_keypair_log_warn() {
    log_warn "[KEYGEN] $1"
}

gen_keypair_log_error() {
    log_error "[KEYGEN] $1"
}

# Display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "RSA Key Pair Generator for Digital Signatures"
    echo ""
    echo "Options:"
    echo "  generate     Generate new RSA key pair"
    echo "  verify       Verify existing key pair"
    echo "  help         Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  RSA_KEY_SIZE     Key size in bits (default: 2048)"
    echo "  RSA_KEY_DIR      Key directory (default: ./keys)"
    echo ""
    echo "Examples:"
    echo "  $0 generate                    # Generate 2048-bit key pair"
    echo "  RSA_KEY_SIZE=4096 $0 generate # Generate 4096-bit key pair"
}

# Check OpenSSL availability
check_dependencies() {
    gen_keypair_log_info "Checking dependencies..."
    
    if ! command -v openssl >/dev/null 2>&1; then
        gen_keypair_log_error "OpenSSL is required but not installed"
        gen_keypair_log_error "Install with: sudo apt-get install openssl"
        exit 1
    fi
    
    gen_keypair_log_info "OpenSSL found: $(openssl version)"
}

# Create key directory
create_key_directory() {
    if [[ ! -d "$KEY_DIR" ]]; then
        gen_keypair_log_info "Creating key directory: $KEY_DIR"
        mkdir -p "$KEY_DIR"
        
        # Set restrictive permissions
        chmod 700 "$KEY_DIR"
        gen_keypair_log_info "Key directory created with restrictive permissions"
    else
        gen_keypair_log_info "Using existing key directory: $KEY_DIR"
    fi
}

# Backup existing keys
backup_existing_keys() {
    local backup_dir="$KEY_DIR/backup_$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$PRIVATE_KEY_FILE" ]] || [[ -f "$PUBLIC_KEY_FILE" ]]; then
        gen_keypair_log_warn "Existing keys found, creating backup..."
        mkdir -p "$backup_dir"
        
        if [[ -f "$PRIVATE_KEY_FILE" ]]; then
            cp "$PRIVATE_KEY_FILE" "$backup_dir/"
            gen_keypair_log_info "Private key backed up to: $backup_dir/private_key.pem"
        fi
        
        if [[ -f "$PUBLIC_KEY_FILE" ]]; then
            cp "$PUBLIC_KEY_FILE" "$backup_dir/"
            gen_keypair_log_info "Public key backed up to: $backup_dir/public_key.pem"
        fi
        
        gen_keypair_log_warn "Backup created in: $backup_dir"
    fi
}

# Generate RSA key pair
generate_key_pair() {
    gen_keypair_log_info "Generating RSA key pair..."
    gen_keypair_log_info "Key size: $KEY_SIZE bits"
    gen_keypair_log_info "Private key: $PRIVATE_KEY_FILE"
    gen_keypair_log_info "Public key: $PUBLIC_KEY_FILE"
    
    # Generate private key
    gen_keypair_log_info "Generating private key..."
    if openssl genpkey -algorithm RSA -out "$PRIVATE_KEY_FILE" \
        -pkeyopt rsa_keygen_bits:"$KEY_SIZE" 2>/dev/null; then
        gen_keypair_log_info "Private key generated successfully"
    else
        gen_keypair_log_error "Failed to generate private key"
        exit 1
    fi
    
    # Set restrictive permissions on private key
    chmod 600 "$PRIVATE_KEY_FILE"
    gen_keypair_log_info "Private key permissions set to 600"
    
    # Extract public key
    gen_keypair_log_info "Extracting public key..."
    if openssl rsa -pubout -in "$PRIVATE_KEY_FILE" -out "$PUBLIC_KEY_FILE" 2>/dev/null; then
        gen_keypair_log_info "Public key extracted successfully"
    else
        gen_keypair_log_error "Failed to extract public key"
        exit 1
    fi
    
    # Set public key permissions
    chmod 644 "$PUBLIC_KEY_FILE"
    gen_keypair_log_info "Public key permissions set to 644"
    
    # Display key information
    display_key_info
}

# Display key information
display_key_info() {
    gen_keypair_log_info "Key pair generation completed successfully!"
    gen_keypair_log_info "Key files:"
    gen_keypair_log_info "  Private: $PRIVATE_KEY_FILE"
    gen_keypair_log_info "  Public:  $PUBLIC_KEY_FILE"
    
    # Display key details
    gen_keypair_log_info "Key details:"
    if openssl pkey -in "$PRIVATE_KEY_FILE" -text -noout 2>/dev/null | grep -q "RSA"; then
        local key_bits
        key_bits=$(openssl pkey -in "$PRIVATE_KEY_FILE" -text -noout 2>/dev/null | grep "Public-Key" | grep -o "[0-9]* bit")
        gen_keypair_log_info "  Key size: $key_bits"
    fi
    
    # Display public key fingerprint
    local fingerprint
    fingerprint=$(openssl pkey -pubin -in "$PUBLIC_KEY_FILE" -outform DER 2>/dev/null | openssl dgst -sha256 -hex | cut -d' ' -f2)
    gen_keypair_log_info "  Public key fingerprint: $fingerprint"
    
    gen_keypair_log_info "Security reminder:"
    gen_keypair_log_info "  - Keep private key secure and never share it"
    gen_keypair_log_info "  - Backup keys in a secure location"
    gen_keypair_log_info "  - Use strong passphrases for additional security"
}

# Verify existing key pair
verify_key_pair() {
    gen_keypair_log_info "Verifying existing key pair..."
    
    if [[ ! -f "$PRIVATE_KEY_FILE" ]]; then
        gen_keypair_log_error "Private key not found: $PRIVATE_KEY_FILE"
        exit 1
    fi
    
    if [[ ! -f "$PUBLIC_KEY_FILE" ]]; then
        gen_keypair_log_error "Public key not found: $PUBLIC_KEY_FILE"
        exit 1
    fi
    
    # Verify private key
    gen_keypair_log_info "Verifying private key..."
    if openssl pkey -in "$PRIVATE_KEY_FILE" -check -noout 2>/dev/null; then
        gen_keypair_log_info "Private key is valid"
    else
        gen_keypair_log_error "Private key is invalid or corrupted"
        exit 1
    fi
    
    # Verify public key
    gen_keypair_log_info "Verifying public key..."
    if openssl pkey -pubin -in "$PUBLIC_KEY_FILE" -check -noout 2>/dev/null; then
        gen_keypair_log_info "Public key is valid"
    else
        gen_keypair_log_error "Public key is invalid or corrupted"
        exit 1
    fi
    
    # Check key pair match
    gen_keypair_log_info "Checking key pair match..."
    local private_pubkey
    private_pubkey=$(openssl rsa -pubout -in "$PRIVATE_KEY_FILE" -outform DER 2>/dev/null | openssl dgst -sha256 -hex | cut -d' ' -f2)
    local public_fingerprint
    public_fingerprint=$(openssl pkey -pubin -in "$PUBLIC_KEY_FILE" -outform DER 2>/dev/null | openssl dgst -sha256 -hex | cut -d' ' -f2)
    
    if [[ "$private_pubkey" == "$public_fingerprint" ]]; then
        gen_keypair_log_info "Key pair match verified successfully"
        display_key_info
    else
        gen_keypair_log_error "Key pair mismatch - keys do not correspond"
        exit 1
    fi
}

# Main execution
main() {
    local command="${1:-help}"
    
    case "$command" in
        "generate")
            check_dependencies
            create_key_directory
            backup_existing_keys
            generate_key_pair
            ;;
        "verify")
            check_dependencies
            verify_key_pair
            ;;
        "help"|"-h"|"--help")
            usage
            exit 0
            ;;
        *)
            gen_keypair_log_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
