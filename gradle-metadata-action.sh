#!/bin/bash
# shellcheck disable=SC2155
set -e

GITHUB_ACTION_PATH=${GITHUB_ACTION_PATH}
GITHUB_ENV=${GITHUB_ENV}
GITHUB_OUTPUT=${GITHUB_OUTPUT}

# GitHub Actions helpers
gh_group() { echo "::group::$1"; }
gh_group_end() { echo "::endgroup::"; }
gh_set_output() { echo "$1=$2" >> "$GITHUB_OUTPUT"; }
gh_set_env() { 
    export "$1"="$2"
    echo "$1=$2" >> "$GITHUB_ENV";
}

# Gradle helpers
GRADLE_WRAPPER="./gradlew"
gradle_exec() {
    ${GRADLE_WRAPPER} --no-daemon --quiet "$@"
}

gradle_get_prop() {
    jq -r ".${1}" "build-manifest.json"
}

# Action Inputs
GMA_CONTEXT="$1"
GMA_VERSION="$2"

# Pre-flight checks
# Switching Gradle context directory
gh_group "Activating Gradle context"
if [ ! -f "${GRADLE_WRAPPER}" ]; then
    if [ ! "$(command -v gradle)" ]; then
        echo "[error]: Gradle wrapper not found!"
        exit 1
    else
        echo "[info]: using system Gradle wrapper"
        GRADLE_WRAPPER="gradle"
    fi
fi

if [[ "${GMA_CONTEXT}" != "" ]]; then
    echo "Gradle context specified, switching to ${GMA_CONTEXT}."
    cd "${GMA_CONTEXT}" || {
        echo "[error]: Unable to load Gradle context!"
        exit 1
    }
else
    echo "No Gradle context specified, using current directory."
fi
gh_group_end

# Main
gh_group "Generating Gradle build manifest"
gradle_exec --init-script "${GITHUB_ACTION_PATH}/gradle/init.gradle" build-manifest
echo "Output:"
cat build-manifest.json
gh_group_end

gh_group "Processing Gradle context"
# Set environment variables
# Project
gh_set_env "GRADLE_PROJECT_NAME" "$(gradle_get_prop "PROJECT_NAME")"
gh_set_env "GRADLE_PROJECT_DESCRIPTION" "$(gradle_get_prop "PROJECT_DESCRIPTION")"
gh_set_env "GRADLE_PROJECT_GROUP" "$(gradle_get_prop "PROJECT_GROUP")"
gh_set_env "GRADLE_PROJECT_PROFILE" "$(gradle_get_prop "PROJECT_PROFILE")"
gh_set_env "GRADLE_PROJECT_VERSION" "$(gradle_get_prop "PROJECT_VERSION")"
# Build
gh_set_env "GRADLE_BUILD_ARTIFACT_ID" $(gradle_get_prop "BUILD_ARTIFACT_ID")
gh_set_env "GRADLE_BUILD_ARTIFACT" $(gradle_get_prop "BUILD_ARTIFACT")
# Compatibility
gh_set_env "GRADLE_TARGET_COMPATIBILITY" "$(gradle_get_prop "TARGET_COMPATIBILITY")"
gh_set_env "GRADLE_SOURCE_COMPATIBILITY" "$(gradle_get_prop "SOURCE_COMPATIBILITY")"

# Java
gh_set_env "JAVA_VENDOR" "$(gradle_get_prop "JAVA_VENDOR")"
gh_set_env "JAVA_VERSION" "$(gradle_get_prop "JAVA_VERSION")"

gh_set_output "bake-file" "${GITHUB_ACTION_PATH}/gradle-metadata-action.hcl"
echo "Output:"
echo "- bake-file = ${GITHUB_ACTION_PATH}/gradle-metadata-action.hcl"
gh_group_end


gh_group "Environment variables"
echo "- GRADLE_PROJECT_NAME=${GRADLE_PROJECT_NAME}"
echo "- GRADLE_PROJECT_DESCRIPTION=${GRADLE_PROJECT_DESCRIPTION}"
echo "- GRADLE_PROJECT_GROUP=${GRADLE_PROJECT_GROUP}"
echo "- GRADLE_PROJECT_PROFILE=${GRADLE_PROJECT_PROFILE}"
echo "- GRADLE_PROJECT_VERSION=${GRADLE_PROJECT_VERSION}"
echo "- GRADLE_BUILD_ARTIFACT_ID=${GRADLE_BUILD_ARTIFACT_ID}"
echo "- GRADLE_BUILD_ARTIFACT=${GRADLE_BUILD_ARTIFACT}"
echo "- GRADLE_TARGET_COMPATIBILITY=${GRADLE_TARGET_COMPATIBILITY}"
echo "- GRADLE_SOURCE_COMPATIBILITY=${GRADLE_SOURCE_COMPATIBILITY}"
gh_group_end

gh_group "Bake definition"
docker buildx bake -f "${GITHUB_ACTION_PATH}/gradle-metadata-action.hcl" --print gradle-metadata-action
gh_group_end
