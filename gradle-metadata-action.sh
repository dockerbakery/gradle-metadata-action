#!/bin/bash
# shellcheck disable=SC2155

GITHUB_OUTPUT=${GITHUB_OUTPUT:-/tmp/github_output}

# GitHub Actions helpers
gh_group() { echo "::group::$1"; }
gh_group_end() { echo "::endgroup::"; }
gh_set_output() { echo "$1=$2" >> "$GITHUB_OUTPUT"; }
gh_set_env() { 
    export "$1"="$2"
    echo "$1=\"$2\"" >> "$GITHUB_ENV";
}

# Gradle helpers
gradle_version() { ./gradlew --version | grep "Gradle" | cut -d " " -f 2; }
gradle_project_name() { ./gradlew properties | grep "name:" | cut -d " " -f 2; }
gradle_project_version() { ./gradlew properties | grep "version:" | cut -d " " -f 2; }
gradle_project_profile() { ./gradlew properties | grep "profile:" | cut -d " " -f 2; }
gradle_project_target() { ./gradlew properties | grep "targetCompatibility:" | cut -d " " -f 2; }
gradle_project_source() { ./gradlew properties | grep "sourceCompatibility:" | cut -d " " -f 2; }

# Pre-flight checks
if [ ! -f "./gradlew" ]; then
    echo "Gradle wrapper not found!"
    exit 1
fi

# Main
gh_set_env "GRADLE_VERSION" "$(gradle_version)"
gh_set_env "GRADLE_PROJECT_NAME" "$(gradle_project_name)"
gh_set_env "GRADLE_PROJECT_VERSION" "$(gradle_project_version)"
gh_set_env "GRADLE_PROJECT_PROFILE" "$(gradle_project_profile)"
gh_set_env "GRADLE_PROJECT_TARGET_COMPATIBILITY" "$(gradle_project_target)"
gh_set_env "GRADLE_PROJECT_SOURCE_COMPATIBILITY" "$(gradle_project_source)"

gh_group "Processing Gradle context"
gh_set_output "bake-file" "${GITHUB_ACTION_PATH}/gradle-metadata-action.hcl"
echo "Output:"
echo "- bake-file = ${GITHUB_ACTION_PATH}/gradle-metadata-action.hcl"
gh_group_end

gh_group "Bake definition"
docker buildx bake -f "${GITHUB_ACTION_PATH}/gradle-metadata-action.hcl" --print gradle-metadata-action
gh_group_end
