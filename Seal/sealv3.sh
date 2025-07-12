#!/bin/bash

# --- Sealed Secrets CLI Tool (v3) ---
# Author: cBarhate
# Purpose: Seal a plaintext value into a full SealedSecret YAML (offline, no apply to cluster)
# It uses scope as cluster-wide with static name/namespace
# Run with: ./seal.sh [debug=true]

CERT_DIR="./certs"
SEALED_DIR="./sealed"
SECRET_NAME="dummy-secret"
SECRET_NAMESPACE="dummy-namespace"
KEY_NAME="secret"  # Static key name used in stringData

# Enable debug logs if passed
DEBUG=false
if [[ "$1" == "debug=true" ]]; then
  DEBUG=true
fi

# Colors
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

log_debug() {
  if $DEBUG; then
    echo -e "${YELLOW}[DEBUG] $1${NC}"
  fi
}

echo -e "${YELLOW}🔐 Sealed Secrets Generator (YAML Mode)${NC}"

# Check cert directory
log_debug "Checking if certificate directory exists: $CERT_DIR"
if [[ ! -d "$CERT_DIR" ]]; then
  echo -e "${RED}❌ Directory '$CERT_DIR' not found. Please create it and add your .crt files.${NC}"
  exit 1
fi

# Load certificates
certs=($(ls "$CERT_DIR"/*.crt 2>/dev/null))
log_debug "Found ${#certs[@]} certificate(s)"

if [[ ${#certs[@]} -eq 0 ]]; then
  echo -e "${RED}❌ No certificates (.crt) found in $CERT_DIR${NC}"
  exit 1
fi

# Show certificates to user
echo ""
echo -e "${YELLOW}📄 Available certificates:${NC}"
for i in "${!certs[@]}"; do
  echo "  [$((i+1))] $(basename "${certs[$i]}")"
done

# Select certificate
echo ""
read -p "Enter the number of the certificate to use: " cert_choice

if ! [[ "$cert_choice" =~ ^[0-9]+$ ]] || [ "$cert_choice" -lt 1 ] || [ "$cert_choice" -gt "${#certs[@]}" ]; then
  echo -e "${RED}❌ Invalid certificate selection.${NC}"
  exit 1
fi

cert_path="${certs[$((cert_choice - 1))]}"
cert_name=$(basename "$cert_path")
log_debug "Selected certificate: $cert_name ($cert_path)"

# Prompt for secret value
echo ""
read -p "Enter the value to seal: " input_value

# Validate whitespace
if [[ "$input_value" =~ ^[[:space:]] || "$input_value" =~ [[:space:]]$ ]]; then
  echo -e "${RED}❌ Error: Value contains leading or trailing whitespace. Please remove it and try again.${NC}"
  exit 1
fi

if [[ "$input_value" =~ [[:space:]] ]]; then
  echo ""
  echo -e "${YELLOW}⚠️  Warning: Your value contains whitespace inside:${NC}"
  echo "    ➤ '$input_value'"
  read -p "Are you sure you want to continue? (y/n): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "${RED}❌ Aborted by user.${NC}"
    exit 1
  fi
fi

# Check sealed directory
log_debug "Checking if sealed output directory exists: $SEALED_DIR"
if [[ ! -d "$SEALED_DIR" ]]; then
  echo -e "${RED}❌ Directory '$SEALED_DIR' not found. Please create it first.${NC}"
  exit 1
fi

echo ""
echo -e "${YELLOW}🔒 Sealing using '$cert_name' with key '$KEY_NAME'...${NC}"
log_debug "Executing kubeseal with scope=cluster-wide and format=yaml"

# Seal the value into YAML
sealed_output=$(kubeseal --cert "$cert_path" --scope=cluster-wide --format=yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
  namespace: $SECRET_NAMESPACE
type: Opaque
stringData:
  $KEY_NAME: $input_value
EOF
)

# Output to console
echo ""
echo -e "${GREEN}✅ SealedSecret YAML:${NC}"
echo "-------------------------------------------"
echo "$sealed_output"
echo "-------------------------------------------"

# Save to file
sealed_file="$SEALED_DIR/latest.yaml"
echo "$sealed_output" > "$sealed_file"
log_debug "Sealed output saved to: $sealed_file"

echo ""
echo -e "${GREEN}💾 YAML saved to: $sealed_file${NC}"
