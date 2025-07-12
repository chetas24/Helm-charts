#!/bin/bash

# --- Sealed Secrets Decryption Tool ---
# Author: cBarhate
# Purpose: Offline decryption of SealedSecrets using private key. It won't apply to cluster
# NOTE: Requires kubeseal v0.24.0+ for --recovery-unseal support, recovery can we done only inthis version or above

SEALED_DIR="./sealed"
KEY_DIR="./key"
OUTPUT_DIR="./decrypted"

YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No color

echo -e "${YELLOW}🔓 Sealed Secrets Recovery Tool${NC}"
echo "-----------------------------------------"
echo -e "${YELLOW}⚠️  This tool only works if the private key matches the certificate used to seal.${NC}"
echo ""

# This will Check sealed/ dir
if [[ ! -d "$SEALED_DIR" ]]; then
  echo -e "${RED}❌ Directory '$SEALED_DIR' not found.${NC}"
  exit 1
fi

sealed_files=($(ls "$SEALED_DIR"/*.yaml 2>/dev/null))
if [[ ${#sealed_files[@]} -eq 0 ]]; then
  echo -e "${RED}❌ No SealedSecret YAMLs found in $SEALED_DIR${NC}"
  exit 1
fi

# This will show us available yamls we can select sealed secret
echo -e "${YELLOW}📄 Available sealed secrets:${NC}"
for i in "${!sealed_files[@]}"; do
  echo "  [$((i+1))] $(basename "${sealed_files[$i]}")"
done

read -p "Select sealed secret file to decrypt: " sealed_choice
if ! [[ "$sealed_choice" =~ ^[0-9]+$ ]] || [ "$sealed_choice" -lt 1 ] || [ "$sealed_choice" -gt "${#sealed_files[@]}" ]; then
  echo -e "${RED}❌ Invalid selection.${NC}"
  exit 1
fi

sealed_file="${sealed_files[$((sealed_choice - 1))]}"

# This will Check key/ dir
if [[ ! -d "$KEY_DIR" ]]; then
  echo -e "${RED}❌ Directory '$KEY_DIR' not found.${NC}"
  exit 1
fi

key_files=($(ls "$KEY_DIR"/*.key 2>/dev/null))
if [[ ${#key_files[@]} -eq 0 ]]; then
  echo -e "${RED}❌ No private key (.key) files found in $KEY_DIR${NC}"
  exit 1
fi

# This will show available keys and prompt to select private key
echo ""
echo -e "${YELLOW}🔐 Available private keys:${NC}"
for i in "${!key_files[@]}"; do
  echo "  [$((i+1))] $(basename "${key_files[$i]}")"
done

read -p "Select private key to use for decryption: " key_choice
if ! [[ "$key_choice" =~ ^[0-9]+$ ]] || [ "$key_choice" -lt 1 ] || [ "$key_choice" -gt "${#key_files[@]}" ]; then
  echo -e "${RED}❌ Invalid key selection.${NC}"
  exit 1
fi

key_path="${key_files[$((key_choice - 1))]}"
key_name=$(basename "$key_path")

# Ensure output dir
# Check if decrypted output directory exists
if [[ ! -d "$OUTPUT_DIR" ]]; then
  echo -e "${RED}❌ Directory '$OUTPUT_DIR' not found.${NC}"
  exit 1
fi

echo ""
echo -e "${YELLOW}🔍 Decrypting sealed secret using '${key_name}'...${NC}"

output=$(kubeseal --recovery-unseal --recovery-private-key "$key_path" --sealed-secret < "$sealed_file" 2>/dev/null)

if [[ $? -ne 0 ]]; then
  echo -e "${RED}❌ Decryption failed. Make sure the private key matches the certificate used to seal.${NC}"
  exit 1
fi

echo ""
echo -e "${GREEN}✅ Decrypted Secret:${NC}"
echo "-----------------------------------------"
echo "$output"
echo "-----------------------------------------"

# Save decrypted output
echo "$output" > "$OUTPUT_DIR/latest.yaml"
echo ""
echo -e "${GREEN}💾 Decrypted secret saved to: ${OUTPUT_DIR}/latest.yaml${NC}"
