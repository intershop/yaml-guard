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

## 🐳 Building the Image

To build the Docker image locally, run:

```bash
docker build -t intershophub/yaml-guard .
```

---

## 🚀 Usage

### Interactive Shell

Run the image and start an interactive shell:

```bash
docker run -it --rm -v $(pwd):/src intershophub/yaml-guard bash
```

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

## 📌 Notes

- The working directory inside the container is set to `/src`.
- Make sure your manifests are mounted into the `/src` path when running the container.
- You can customize the `validate_kustomize.sh` script to suit your validation workflow.

---


## 📝 License

This project is distributed under the MIT License.
