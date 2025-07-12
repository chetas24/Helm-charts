
````markdown
# 🔐 Sealed Secrets CLI Tool (Encryption Only)

A portable Bash-based CLI to **seal plaintext secrets** using Kubernetes Sealed Secrets.  
This tool generates GitOps-ready `SealedSecret` YAMLs offline, using a chosen public certificate — without touching the cluster.

---

## 📦 What Are Sealed Secrets?

Sealed Secrets are **encrypted Kubernetes secrets** created using the `kubeseal` tool and decrypted by a **controller** running in your Kubernetes/OpenShift cluster.

They let you:
- Store secrets safely in Git (GitOps)
- Encrypt offline using a public certificate
- Decrypt only in cluster using the private key managed by the controller

---

## ⚙️ Tool Overview

This tool allows you to:

✅ Prompt and seal any string value  
✅ Select a certificate from a local folder  
✅ Output a complete `SealedSecret` YAML  
✅ Works offline, **no cluster access required**  
✅ Prevents accidental cluster apply  
✅ Prevents secrets with unsafe formatting (e.g., trailing spaces)  
✅ Supports debug logging mode

> 🔐 This tool only performs **sealing (encryption)**. A separate tool handles decryption.

---

## 📁 Folder Structure

```bash
project-root/
├── certs/           # Folder containing *.crt public keys
├── sealed/          # Output folder for sealed YAMLs 
├── keys/            # (Used by decrypt tool)
├── decrypted/
├── seal.sh          # Main sealing script
├── decrypt.sh       # (Used separately for decryption)
└── readmeseal.md    # This file
````

---

## 🧰 Dependencies

* `kubeseal` v0.9+ (used for encryption)
* `bash` shell (Linux/macOS/WSL)
* No cluster or kubectl/oc required
* No private key needed for sealing

---

## 📌 Usage

```bash
./seal.sh
```

To enable debug logging:

```bash
./seal.sh debug=true
```

---

## ✨ Features

### ✅ Interactive Input

* Prompts for a plaintext secret value (e.g., password, token, client ID)
* Validates that the value:

  * Has no leading/trailing whitespace
  * Warns for internal whitespace (e.g., `"my password"`)

### ✅ Certificate Selection

* Reads available `*.crt` files from `certs/` folder
* Lets you choose which cert to seal with

### ✅ SealedSecret Generation

* Uses `stringData` and `type: Opaque`
* SealedSecret YAML is printed to terminal and saved to `sealed/latest.yaml`
* Uses a **static dummy** name and namespace:

  ```yaml
  metadata:
    name: dummy-secret
    namespace: dummy-namespace
  ```

---

## 🧠 Concepts & Background

### 🔐 Kubeseal Input Modes

#### 1. **Raw Mode**

```bash
echo -n "mypassword" | kubeseal --raw --cert tls.crt --scope=cluster-wide
```

* Outputs a single encrypted string
* Fast, but not a full YAML

#### 2. **YAML Mode**

```bash
kubeseal --cert tls.crt --scope=cluster-wide --format=yaml < my-secret.yaml
```

* Outputs full `SealedSecret` resource
* Great for GitOps workflows

✅ **This tool uses YAML mode.**

---

### 🏷 Supported `Secret` Fields

We generate secrets like:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: dummy-secret
  namespace: dummy-namespace
type: Opaque
stringData:
  secret: mypassword
```

### ✅ `stringData` is preferred over `data` to avoid manual base64 encoding.

---

## 📛 Sealing Scope Options

| Scope              | Description                            |
| ------------------ | -------------------------------------- |
| `strict` (default) | Tied to exact name + namespace         |
| `namespace-wide`   | Tied to namespace, name doesn't matter |
| `cluster-wide`     | Works for any name/namespace           |

### ✅ This tool uses `--scope=cluster-wide`.

This allows sealed secrets to work **across all environments**, regardless of final namespace.

---

## 🔐 Public Certificate Handling

The cert used to seal is retrieved from your cluster’s Sealed Secret controller:

```bash
kubeseal --fetch-cert \
  --controller-name=sealed-secrets \
  --controller-namespace=sealed-secrets > certs/prod.crt
```

💡 You can have multiple certs like `dev.crt`, `prod.crt`, etc.

---

## 🚫 Safety: Prevents Accidental Apply

* Never applies anything to the cluster
* `kubectl` and `oc` are not used
* All secrets are saved in `sealed/` for GitOps pipelines

---

## 🧪 Validations

* ❌ Rejects values with leading/trailing whitespace
* ⚠️ Warns for internal whitespace and asks for confirmation
* 📛 Rejects invalid cert choices or missing folders
* 🔐 Supports debug mode to show internal command flow

---

## 🐞 Debug Mode

Run the tool with:

```bash
./seal.sh debug=true
```

This will show:

* Certificate selected
* Input value
* Raw secret YAML before sealing
* Sealing command used

---

## 📌 Limitations

* Only seals **one value at a time** (key = `secret`)
* Always generates YAML with dummy metadata
* Designed for **offline GitOps workflows**

---

## 🧪 Examples

```bash
# Seal 'mypassword' using certs/dev.crt
# Saved as sealed/latest.yaml

./seal.sh
```

> 💡 You can commit `sealed/latest.yaml` to Git and apply via ArgoCD, FluxCD, etc.

---

## 📂 Sample Output (sealed/latest.yaml)

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: dummy-secret
  namespace: dummy-namespace
spec:
  encryptedData:
    secret: AgB...
  template:
    metadata:
      name: dummy-secret
      namespace: dummy-namespace
    type: Opaque
```

---

## 📖 References

* [https://github.com/bitnami-labs/sealed-secrets](https://github.com/bitnami-labs/sealed-secrets)
* [https://kubeseal.dev](https://kubeseal.dev)

---

🛠 Maintained by: **cBarhate**

```