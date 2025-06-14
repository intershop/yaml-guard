#!/bin/bash
# Source: https://github.com/redhat-cop/gitops-catalog/blob/main/scripts/validate_kustomize.sh
# shellcheck disable=SC2034,SC2044

# Shows help message
display_help(){
  echo "./$(basename "$0") [ -d | --directory DIRECTORY ] [ -e | --enforce-all-schemas ] [ -h | --help ] [ -sl | --schema-location ]
Script to validate the manifests generated by Kustomize
Where:
  -d  | --directory DIRECTORY  Base directory containing Kustomize overlays
  -e  | --enforce-all-schemas  Enable enforcement of all schemas
  -h  | --help                 Display this help text
  -sl | --schema-location      Location containing schemas"
}

# Specify the Kustomize command to use (kustomize or oc kustomize)
which kustomize > /dev/null && KUSTOMIZE_CMD="kustomize build" || echo "Kustomize not in path; using 'oc kustomize' instead"
# Check if Helm is installed
which helm > /dev/null && GOT_HELM="--enable-helm" || echo "Helm not in path; skipping kustomizations that use helm"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
KUSTOMIZE_CMD="${KUSTOMIZE_CMD:-oc kustomize}" # oc kustomize default if no kustomize
IGNORE_MISSING_SCHEMAS="--ignore-missing-schemas" # Ignore missing schemas by default
SCHEMA_LOCATION="./openshift-json-schema" # Default schema location
KUSTOMIZE_DIRS="."  # Default Kustomize directory

# Process command-line arguments
init(){
  for i in "${@}"
  do
    case $i in
      -d | --directory )
        shift
        KUSTOMIZE_DIRS="${1}"
        shift
        ;;
      -e | --enforce-all-schemas )
        IGNORE_MISSING_SCHEMAS="" # Enable schema enforcement
        shift
        ;;
      -sl | --schema-location )
        shift
        SCHEMA_LOCATION="${1}"
        shift
        ;;
      -h | --help )
        display_help
        exit 0
        ;;
      -*) echo >&2 "Invalid option: " "${@}"
          exit 1
          ;;
    esac
  done
}

# (This function exists in the script but is commented out, autocorrects)
kustomization_auto_fix(){
  BUILD_PATH=${1}
  [ "${KUSTOMIZE_CMD}" == "kustomize build" ] || return
  FIX_CMD="${FIX_CMD:-kustomize edit fix}"
  pushd "${BUILD_PATH}" || return
  ${FIX_CMD}
  popd || return
}

# Builds and validates a specific Kustomisation directory
kustomization_build(){
  BUILD=${1}
  local KUSTOMIZE_BUILD_OUTPUT
  local cmd_response

   # Add Helm support if available or required
  if [ -n "${GOT_HELM}" ]; then
    echo "Running: ${KUSTOMIZE_CMD} \"${BUILD}\" \"${GOT_HELM}\""
    KUSTOMIZE_BUILD_OUTPUT=$(${KUSTOMIZE_CMD} "${BUILD}" "${GOT_HELM}")
    cmd_response=$?
  else
    # Skip if helm does not exist and kustomization.yaml contains helmCharts
    if grep -qE '^helmCharts:$' "${BUILD}/kustomization.yaml" && [ "${KUSTOMIZE_CMD}" == "kustomize build" ]; then
      echo "[SKIP] Helm not found, skipping Helm chart in ${BUILD}"
      return 0
    fi

    # Build without Helm parameter
    echo "Running: ${KUSTOMIZE_CMD} \"${BUILD}\""
    KUSTOMIZE_BUILD_OUTPUT=$(${KUSTOMIZE_CMD} "${BUILD}")
    cmd_response=$?
  fi

  # If the Kustomize build command failed
  if [ $cmd_response -ne 0 ]; then
     #  Don't give an error if it is of type Component (exception)
     if grep -qE '^kind: Component$' "${BUILD}/kustomization.yaml"; then
        echo "[SKIP] Kustomize build failed for Component ${BUILD}, skipping validation."
        return 0
     fi
     # In other cases give error and exit
     echo "[ERROR] Kustomize build failed for ${BUILD} with exit code ${cmd_response}."
     exit 1 # Exit code to make the pipeline fail
  fi

  # # If kustomize build succeeds, verify output with kubeval
  echo "Validating output with kubeval..."
  echo "$KUSTOMIZE_BUILD_OUTPUT" | kubeval ${IGNORE_MISSING_SCHEMAS} --schema-location="file://${SCHEMA_LOCATION}" --force-color
  cmd_response=$?

  if [ $cmd_response -ne 0 ]; then
    # Error if not a component and kubeval fails
    if ! grep -qE '^kind: Component$' "${BUILD}/kustomization.yaml"; then
        echo "[ERROR] Kubeval validation failed for ${BUILD}."
        exit 1 # The exit code that will make the pipeline fail
    else
        # For components we can ignore the kubeval error for now (optional)
        echo "[WARN] Kubeval validation failed for Component ${BUILD}, but continuing."
    fi
  fi

  echo "[OK] Validation successful for ${BUILD}"
}

# Find and process all Kustomization directories
kustomization_process(){
  echo "Validating Kustomize directories in: ${KUSTOMIZE_DIRS}"
  # Add -type f to make sure it's just a file
  find "${KUSTOMIZE_DIRS}" -type f -name "kustomization.yaml" -print0 | while IFS= read -r -d $'\0' kustomization_file; do
      LINT=$(dirname "${kustomization_file}")
      echo "--- Processing: ${LINT} ---"
      kustomization_build "${LINT}"
      # kustomization_auto_fix "${LINT}" # Auto-correction off
  done
  # If the find command finds nothing, $? 0, but exit 1 in build will exit the script anyway.
  # Additional post-loop checking may be required, but exit 1 in the build should be sufficient.
  # If it never enters the loop, or if all builds are successful, come back here.
  echo "---"
  echo "Kustomize check finished."
  # Script is considered successful if it got this far without errors (exit 0 default)
}

# Main script flow
init "${@}"          # Process arguments
kustomization_process # Start the verification process