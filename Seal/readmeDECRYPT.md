# 🔓 Sealed Secrets Decryption CLI Tool

This document provides complete notes for **decrypting SealedSecrets offline** using the `kubeseal` CLI (v0.24.0+).

> This complements the `seal.sh` tool. This tool does **not** apply secrets to a Kubernetes cluster.

---

## 📆 Prerequisites

* `kubeseal` v0.24.0 or newer (required for `--recovery-unseal`)
* Matching private key (`tls.key`) that was used to seal the secret
* SealedSecret YAML (output of the sealing script)
* Bash shell (Linux/macOS/WSL)

---

## 🔠 Directory Structure

```bash
.
├── keys/              # Private keys (e.g., controller.key)
├── sealed/            # SealedSecret YAML files
├── decrypted/         # Output folder for decrypted secrets
├── decrypt.sh         # Decryption script
```

---

## 🔄 Decryption Flow

1. Tool lists sealed secrets from `./sealed`
2. You choose a YAML file
3. Tool lists private keys from `./keys`
4. You select a key
5. It runs `kubeseal --recovery-unseal --recovery-private-key <key> < sealed-secret.yaml`
6. Saves output to `./decrypted/latest.yaml`

---

## 📅 Usage

```bash
chmod +x decrypt.sh
./decrypt.sh
```

To enable debug logs:

```bash
./decrypt.sh debug=true
```

This will show:

* Selected YAML file
* Selected private key
* Full kubeseal command

---

## 🌐 What is Decrypted?

You must input a complete **SealedSecret YAML**:

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: dummy-secret
  namespace: dummy-namespace
spec:
  encryptedData:
    secret: AgAx9SDV...
```

The script will output a **Kubernetes Secret**:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: dummy-secret
  namespace: dummy-namespace
type: Opaque
data:
  secret: bXlwYXNzd29yZA==
```

---

## 🔑 Retrieving the Private Key

Run this to get the active key from the Sealed Secrets controller:

```bash
kubectl get secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key=active
```

Extract key to a file:

```bash
kubectl get secret <secret-name> -n sealed-secrets -o jsonpath='{.data.tls.key}' | base64 -d > ./keys/controller.key
```

> 🔐 Only cluster admins can retrieve this.

---

## ❓ Common Issues

| Issue                           | Solution                                                       |
| ------------------------------- | -------------------------------------------------------------- |
| `unknown flag: --sealed-secret` | You are using an older `kubeseal`. Upgrade to v0.24.0 or newer |
| Empty output                    | Private key doesn't match the certificate                      |
| Decryption failed               | Wrong YAML format or mismatched key                            |
| Permissions error               | Fix ownership or chmod of the key file                         |

---

## 📄 Debug Logging

Run with:

```bash
./decrypt.sh debug=true
```

You will see:

* Selected secret YAML
* Selected private key
* Key path
* Decryption command

> Use this to troubleshoot errors silently hidden in normal mode.

---

## 🚫 Security Notes

* Never commit your private key to Git.
* Use this tool only for local or dev environments.
* The decrypted secret should not be stored long-term.

---

## 🌐 References

* [kubeseal documentation](https://kubeseal.dev)
* [bitnami-labs/sealed-secrets](https://github.com/bitnami-labs/sealed-secrets)

---

## 🛠️ Author

Created by **cBarhate** for secure GitOps-style workflows, supporting full offline secret recovery without access to Kubernetes cluster APIs.

---
