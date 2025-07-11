#!/bin/bash

# --- Sealed Secrets Decode Tool ---

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RESET='\033[0m'

KEY_DIR="./key"

echo -e "${CYAN}🔓 Sealed Secret Decoder${RESET}"

# This checks if openssl is available
if ! command -v openssl >/dev/null 2>&1; then
  echo -e "${RED}❌ Error: 'openssl' command not found. Please install it.${RESET}"
  exit 1
fi

# This checks if key directory exists
if [[ ! -d "$KEY_DIR" ]]; then
  echo -e "${RED}❌ Directory '$KEY_DIR' not found. Please create it and add your .key files.${RESET}"
  exit 1
fi

# List .key files
keys=($(ls "$KEY_DIR"/*.key 2>/dev/null))
if [[ ${#keys[@]} -eq 0 ]]; then
  echo -e "${RED}❌ No private keys (.key) found in $KEY_DIR${RESET}"
  exit 1
fi

echo ""
echo -e "${YELLOW}🔑 Available private keys:${RESET}"
for i in "${!keys[@]}"; do
  echo -e "  [${CYAN}$((i+1))${RESET}] $(basename "${keys[$i]}")"
done

echo ""
read -p "Enter the number of the private key to use: " key_choice

if ! [[ "$key_choice" =~ ^[0-9]+$ ]] || [ "$key_choice" -lt 1 ] || [ "$key_choice" -gt "${#keys[@]}" ]; then
  echo -e "${RED}❌ Invalid selection.${RESET}"
  exit 1
fi

key_path="${keys[$((key_choice - 1))]}"
key_name=$(basename "$key_path")

echo ""
read -p "Paste the sealed secret string to decode: " sealed_value

echo ""
echo -e "${YELLOW}🔍 Decoding using key '${CYAN}${key_name}${YELLOW}'...${RESET}"

# Try to decode base64 and decrypt
decoded=$(echo "$sealed_value" | base64 -d 2>/dev/null | openssl rsautl -decrypt -inkey "$key_path" 2>/dev/null)

if [[ $? -ne 0 || -z "$decoded" ]]; then
  echo -e "${RED}❌ Failed to decode secret. Ensure the key matches the one used for sealing.${RESET}"
  exit 1
fi

echo ""
echo -e "${GREEN}✅ Secret decoded successfully!${RESET}"
echo -e "${CYAN}${decoded}${RESET}"
echo ""
