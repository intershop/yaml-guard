**⚠️ This repository has been migrated to [cloud-cicd-yaml-guard](https://dev.azure.com/intershop-com/Products/_git/cloud-cicd-yaml-guard).**


# 🛠️ Kustomize & YAML Validator Docker Image

This Docker image is designed for validating Kubernetes manifests using tools like `yamllint`, `kustomize`, and `kubeconform`. It can be integrated into CI/CD pipelines to ensure configuration quality and correctness.

---

## 🧰 Included Tools

- **yamllint** – Lints YAML files for syntax and style errors.
- **kustomize** – For Kubernetes-native configuration management.
- **kubeconform** – Validates Kubernetes manifests against schemas.
- **jq, curl, git, bash, ca-certificates** – Essential system utilities.
- **validate_kustomize.sh** – Custom script for validating kustomizations with kubeconform.

---

## 🐳 Pull the Image

To pull  the Docker image locally, run:

```bash
docker pull intershophub/yaml-guard:latest
```

---

## 🚀 Usage
### Lint a YAML file

```bash
docker run --rm \
  -v "$PWD":/yamls \
  intershophub/yaml-guard \
  yamllint -c /src/.yamllint /yamls
```

### Validate Kustomizations

```bash
docker run --rm \
  -v "$PWD":/src \
  intershophub/yaml-guard \
  bash /usr/local/bin/validate_kustomize.sh -d /src
```

---

## 📁 File Structure

```
.
├── Dockerfile
├── LICENSE
├── README.md
└── scripts
    └── validate_kustomize.sh
```

---

## 🔍 YAML Linting Rules (yamllint)

This project uses [`yamllint`](https://yamllint.readthedocs.io) to ensure YAML files follow a consistent and clean structure. Below are the active linting rules configured for this repository.

### `line-length`
```yaml
line-length:
  max: 120
  level: warning
```
Warns when any line exceeds 120 characters. Helps maintain readability across editors and platforms.

**Example (❌ Too long):**
```yaml
description: This is a very long string that exceeds the allowed 120 character limit for a single line in YAML files.
```

**Example (✅ Correct):**
```yaml
description: >
  This is a long string that
  has been wrapped for readability.
```

---

### `comments`
```yaml
comments:
  min-spaces-from-content: 1
  level: warning
```
Requires at least one space between the `#` symbol and the comment content.

**Example (❌ Incorrect):**
```yaml
#No space after hash
```

**Example (✅ Correct):**
```yaml
# Properly formatted comment
```

---

### `trailing-spaces`
```yaml
trailing-spaces:
  level: warning
```
Warns about unnecessary whitespace at the end of lines.

**Example (❌ Incorrect):**
```yaml
key: value␣␣␣
```

---

### `colons`
```yaml
colons:
  max-spaces-before: 0
  max-spaces-after: 1
  level: warning
```
Controls spacing around `:` in key-value pairs. No space allowed before `:`, and only one space allowed after.

**Example (❌ Incorrect):**
```yaml
key :  value
```

**Example (✅ Correct):**
```yaml
key: value
```

---

### `new-line-at-end-of-file`
```yaml
new-line-at-end-of-file:
  level: warning
```
Warns if the file does not end with a newline character. Helps with POSIX compatibility and clean diffs in version control.

---

### `indentation`
```yaml
indentation:
  level: error
```
Ensures consistent indentation. Incorrect indentation can lead to broken YAML parsing.

**Example (❌ Incorrect):**
```yaml
metadata:
 name: config-map
```

**Example (✅ Correct):**
```yaml
metadata:
  name: config-map
```

---

### `document-start`
```yaml
document-start:
  level: warning
```
Warns when YAML files do not start with `---`, which is the standard document start indicator in multi-document YAML files.

**Example (❌ Missing):**
```yaml
apiVersion: v1
```

**Example (✅ Correct):**
```yaml
---
apiVersion: v1
```

---

These rules help maintain clean, readable, and consistent YAML configurations across the project. Any violations will be flagged during CI runs to ensure high code quality.

## 📌 Notes

- The working directory inside the container is set to `/src`.
- Make sure your manifests are mounted into the `/src` path when running the container.
- You can customize the `validate_kustomize.sh` script to suit your validation workflow.

---


## 📝 License

This project is distributed under the MIT License.
