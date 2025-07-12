#!/bin/bash

# --- Sealed Secrets Decryption Tool ---
# Author: cBarhate
# Purpose: Decrypt sealed secrets offline using private key and recovery mode

SEALED_DIR="./sealed"
KEY_DIR="./key"

echo "🔓 Sealed Secrets Recovery Tool"
echo "-----------------------------------------"
echo "⚠️  Ensure you're using the matching private key for the cert used to seal."
echo "⚠️  This only works with sealed secrets generated using the same key pair."
echo ""

# Check sealed/ dir
if [[ ! -d "$SEALED_DIR" ]]; then
  echo "❌ Directory '$SEALED_DIR' not found."
  exit 1
fi

# List sealed secret YAML files
sealed_files=($(ls "$SEALED_DIR"/*.yaml 2>/dev/null))
if [[ ${#sealed_files[@]} -eq 0 ]]; then
  echo "❌ No SealedSecret YAMLs found in $SEALED_DIR"
  exit 1
fi

echo "📄 Available sealed secrets:"
for i in "${!sealed_files[@]}"; do
  echo "  [$((i+1))] $(basename "${sealed_files[$i]}")"
done

read -p "Select sealed secret file to decrypt: " sealed_choice
if ! [[ "$sealed_choice" =~ ^[0-9]+$ ]] || [ "$sealed_choice" -lt 1 ] || [ "$sealed_choice" -gt "${#sealed_files[@]}" ]; then
  echo "❌ Invalid selection."
  exit 1
fi

sealed_file="${sealed_files[$((sealed_choice - 1))]}"

# Check key dir
if [[ ! -d "$KEY_DIR" ]]; then
  echo "❌ Directory '$KEY_DIR' not found."
  exit 1
fi

# List .key files
key_files=($(ls "$KEY_DIR"/*.key 2>/dev/null))
if [[ ${#key_files[@]} -eq 0 ]]; then
  echo "❌ No private key (.key) files found in $KEY_DIR"
  exit 1
fi

echo ""
echo "🔐 Available private keys:"
for i in "${!key_files[@]}"; do
  echo "  [$((i+1))] $(basename "${key_files[$i]}")"
done

read -p "Select private key to use for decryption: " key_choice
if ! [[ "$key_choice" =~ ^[0-9]+$ ]] || [ "$key_choice" -lt 1 ] || [ "$key_choice" -gt "${#key_files[@]}" ]; then
  echo "❌ Invalid key selection."
  exit 1
fi

key_path="${key_files[$((key_choice - 1))]}"
key_name=$(basename "$key_path")

# Perform recovery unseal
echo ""
echo "🔍 Decrypting sealed secret using '$key_name'..."

output=$(kubeseal --recovery-unseal --recovery-private-key "$key_path" --sealed-secret < "$sealed_file" 2>/dev/null)

if [[ $? -ne 0 ]]; then
  echo "❌ Decryption failed. Ensure the private key matches the certificate used to seal."
  exit 1
fi

echo ""
echo "✅ Decrypted Secret:"
echo "-----------------------------------------"
echo "$output"
echo "-----------------------------------------"
