#!/bin/bash
GRADLE_METADATA_GRADLE_WRAPPER="./gradlew"
GRADLE_METADATA_GRADLE_WRAPPER_ARGS="--no-daemon --info"
GRADLE_METADATA_ACTION_CONTEXT=${GRADLE_METADATA_ACTION_CONTEXT:${1}}
GRADLE_METADATA_ACTION_VERSION=${GRADLE_METADATA_ACTION_VERSION:${2}}

echo "::group::Checking environment"
if [[ -z "${JAVA_HOME}" ]]; then
	echo "::error::Unable to locate Java installation, please consider using \"uses: actions/setup-java@v4\" to install Java."
	exit 1
else
	echo "Java installation found at: ${JAVA_HOME}"
fi
echo "::endgroup::"

echo "::group::Activating Gradle context"
if [[ "${GRADLE_METADATA_ACTION_CONTEXT}" != "" ]]; then
	echo "Gradle context specified, switching to ${GRADLE_METADATA_ACTION_CONTEXT}."
	cd "${GRADLE_METADATA_ACTION_CONTEXT}" || {
		echo "::error::Failed to switch to Gradle context"
		exit 1
	}
else
	echo "Gradle context not specified, using current directory."
fi
echo "::endgroup::"

echo "::group::Detecting Gradle wrapper"
if [ ! -f "${GRADLE_METADATA_GRADLE_WRAPPER}" ]; then
	if [ ! "$(command -v gradle)" ]; then
		echo "::error::Neither Gradle wrapper nor Gradle CLI found"
		exit 1
	fi
	
	GRADLE_METADATA_GRADLE_WRAPPER=$(which gradle)
	echo "Using Gradle CLI: ${GRADLE_METADATA_GRADLE_WRAPPER}"
else
	echo "Using Gradle wrapper: ${GRADLE_METADATA_GRADLE_WRAPPER}"
fi
echo "::endgroup::"

echo "::group::Processing Gradle project"
if [[ -n "${GRADLE_METADATA_ACTION_VERSION}" ]]; then
	echo "Set project version to: ${GRADLE_METADATA_ACTION_VERSION}"
	GRADLE_METADATA_GRADLE_WRAPPER_ARGS+=" -Pversion=${GRADLE_METADATA_ACTION_VERSION} "
fi
CMD="${GRADLE_METADATA_GRADLE_WRAPPER} --init-script ${GITHUB_ACTION_PATH}/gradle/init.gradle ${GRADLE_METADATA_GRADLE_WRAPPER_ARGS} gradle-metadata-action"
echo "::debug::Executing command: ${CMD}"
${CMD}
if [ $? -ne 0 ]; then
	echo "::error::Failed to process Gradle project"
	exit 1
fi
echo "::endgroup::"

source "${GITHUB_ENV}"
echo "::group::Bake definition"
cat "${GRADLE_METADATA_OUTPUT_BAKE_FILE}"
echo ""; echo "::endgroup::"

exit 0
