#!/bin/bash

# --- Sealed Secrets CLI Tool (v2) ---
# Author: cBarhate
# Purpose: Seal a plaintext value into a full SealedSecret YAML (offline, no applyto cluster)
# It uses scope as cluster-wide
# uses static name and namespace as we are using cluster-wide
# I will try to create binary out of this using shc

CERT_DIR="./seal"
SECRET_NAME="dummy-secret"
SECRET_NAMESPACE="dummy-namespace"
KEY_NAME="secret"  # Static key name used in stringData

echo "🔐 Sealed Secrets Generator (YAML Mode)"

# This ensure cert directory exists
if [[ ! -d "$CERT_DIR" ]]; then
  echo "❌ Directory '$CERT_DIR' not found. Please create it and add your .crt files."
  exit 1
fi

# This loads all available certificates
certs=($(ls "$CERT_DIR"/*.crt 2>/dev/null))
if [[ ${#certs[@]} -eq 0 ]]; then
  echo "❌ No certificates (.crt) found in $CERT_DIR"
  exit 1
fi

# This will List cert options
echo ""
echo "📄 Available certificates:"
for i in "${!certs[@]}"; do
  echo "  [$((i+1))] $(basename "${certs[$i]}")"
done

# This will Select certificate
echo ""
read -p "Enter the number of the certificate to use: " cert_choice
if ! [[ "$cert_choice" =~ ^[0-9]+$ ]] || [ "$cert_choice" -lt 1 ] || [ "$cert_choice" -gt "${#certs[@]}" ]; then
  echo "❌ Invalid certificate selection."
  exit 1
fi

cert_path="${certs[$((cert_choice - 1))]}"
cert_name=$(basename "$cert_path")

# Prompt for secret value
echo ""
read -p "Enter the value to seal: " input_value

# This will validate whitespace
if [[ "$input_value" =~ ^[[:space:]] || "$input_value" =~ [[:space:]]$ ]]; then
  echo "❌ Error: Value contains leading or trailing whitespace. Please remove it and try again."
  exit 1
fi

if [[ "$input_value" =~ [[:space:]] ]]; then
  echo ""
  echo "⚠️  Warning: Your value contains whitespace inside:"
  echo "    ➤ '$input_value'"
  read -p "Are you sure you want to continue? (y/n): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "❌ Aborted by user."
    exit 1
  fi
fi

# This is the sealing process
echo ""
echo "🔒 Sealing using '$cert_name' with key '$KEY_NAME'..."

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

# if [[ $? -ne 0 ]]; then
#   echo "❌ Failed to seal secret. Make sure the certificate is valid."
#   exit 1
# fi

# Outputs final SealedSecret
echo ""
echo "✅ SealedSecret YAML:"
echo ""
echo "$sealed_output"
