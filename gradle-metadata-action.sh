#!/bin/bash
# shellcheck disable=SC2155
# shellcheck disable=SC2269
# shellcheck disable=SC2086
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

# Action Inputs
GRADLE_METADATA_ACTION_CONTEXT="$1"
GRADLE_METADATA_ACTION_VERSION="$2"

# Gradle helpers
GRADLE_WRAPPER="./gradlew"
GRADLE_FLAGS=""

if [[ -n "${GRADLE_METADATA_ACTION_VERSION}" ]]; then
    GRADLE_FLAGS+="-Pversion=${GRADLE_METADATA_ACTION_VERSION} "
fi

gradle_exec() {
    echo "[info]: ${GRADLE_WRAPPER} --no-daemon --quiet ${GRADLE_FLAGS} $*"
    ${GRADLE_WRAPPER} --no-daemon --quiet ${GRADLE_FLAGS} "$@" 
}

gradle_get_prop() {
    jq -r ".${1}" "build-manifest.json"
}

# Pre-flight checks
gh_set_env "GRADLE_METADATA_ACTION" "true"

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

if [[ "${GRADLE_METADATA_ACTION_CONTEXT}" != "" ]]; then
    echo "Gradle context specified, switching to ${GRADLE_METADATA_ACTION_CONTEXT}."
    cd "${GRADLE_METADATA_ACTION_CONTEXT}" || {
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
# Gradle
gh_set_env "GRADLE_VERSION" "$(gradle_get_prop "GRADLE_VERSION")"
# Project
gh_set_env "GRADLE_PROJECT_NAME" "$(gradle_get_prop "PROJECT_NAME")"
gh_set_env "GRADLE_PROJECT_DESCRIPTION" "$(gradle_get_prop "PROJECT_DESCRIPTION")"
gh_set_env "GRADLE_PROJECT_GROUP" "$(gradle_get_prop "PROJECT_GROUP")"
gh_set_env "GRADLE_PROJECT_PROFILE" "$(gradle_get_prop "PROJECT_PROFILE")"
gh_set_env "GRADLE_PROJECT_VERSION" "$(gradle_get_prop "PROJECT_VERSION")"
# Build
gh_set_env "GRADLE_BUILD_ARTIFACT_ID" "$(gradle_get_prop "BUILD_ARTIFACT_ID")"
gh_set_env "GRADLE_BUILD_ARTIFACT" "$(gradle_get_prop "BUILD_ARTIFACT")"
# Compatibility
gh_set_env "GRADLE_TARGET_COMPATIBILITY" "$(gradle_get_prop "TARGET_COMPATIBILITY")"
gh_set_env "GRADLE_SOURCE_COMPATIBILITY" "$(gradle_get_prop "SOURCE_COMPATIBILITY")"

# Java
gh_set_env "JAVA_VENDOR" "$(gradle_get_prop "JAVA_VENDOR")"
gh_set_env "JAVA_VERSION" "$(gradle_get_prop "JAVA_VERSION")"

# Action Outputs
gh_set_output "name" "${GRADLE_PROJECT_NAME}"
gh_set_output "description" "${GRADLE_PROJECT_DESCRIPTION}"
gh_set_output "group" "${GRADLE_PROJECT_GROUP}"
gh_set_output "profile" "${GRADLE_PROJECT_PROFILE}"
gh_set_output "version" "${GRADLE_PROJECT_VERSION}"
gh_set_output "target-compatibility" "${TARGET_COMPATIBILITY}"
gh_set_output "source-compatibility" "${SOURCE_COMPATIBILITY}"
gh_set_output "bake-file" "${GITHUB_ACTION_PATH}/gradle-metadata-action.hcl"

echo "Output:"
echo "- name = ${GRADLE_PROJECT_NAME}"
echo "- description = ${GRADLE_PROJECT_DESCRIPTION}"
echo "- group = ${GRADLE_PROJECT_GROUP}"
echo "- profile = ${GRADLE_PROJECT_PROFILE}"
echo "- version = ${GRADLE_PROJECT_VERSION}"
echo "- target-compatibility = ${TARGET_COMPATIBILITY}"
echo "- source-compatibility = ${SOURCE_COMPATIBILITY}"
echo "- bake-file = ${GITHUB_ACTION_PATH}/gradle-metadata-action.hcl"
gh_group_end


gh_group "Environment variables"
echo "- GRADLE_VERSION=${GRADLE_VERSION}"
echo "- GRADLE_PROJECT_NAME=${GRADLE_PROJECT_NAME}"
echo "- GRADLE_PROJECT_DESCRIPTION=${GRADLE_PROJECT_DESCRIPTION}"
echo "- GRADLE_PROJECT_GROUP=${GRADLE_PROJECT_GROUP}"
echo "- GRADLE_PROJECT_PROFILE=${GRADLE_PROJECT_PROFILE}"
echo "- GRADLE_PROJECT_VERSION=${GRADLE_PROJECT_VERSION}"
echo "- GRADLE_BUILD_ARTIFACT_ID=${GRADLE_BUILD_ARTIFACT_ID}"
echo "- GRADLE_BUILD_ARTIFACT=${GRADLE_BUILD_ARTIFACT}"
echo "- GRADLE_TARGET_COMPATIBILITY=${GRADLE_TARGET_COMPATIBILITY}"
echo "- GRADLE_SOURCE_COMPATIBILITY=${GRADLE_SOURCE_COMPATIBILITY}"
echo "- JAVA_VENDOR=${JAVA_VENDOR}"
echo "- JAVA_VERSION=${JAVA_VERSION}"
gh_group_end

gh_group "Bake definition"
docker buildx bake -f "${GITHUB_ACTION_PATH}/gradle-metadata-action.hcl" --print gradle-metadata-action
gh_group_end
