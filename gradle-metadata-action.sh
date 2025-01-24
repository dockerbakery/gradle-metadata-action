#!/bin/bash
GRADLE_METADATA_GRADLE_WRAPPER="./gradlew"
GRADLE_METADATA_GRADLE_WRAPPER_ARGS="--no-daemon --info --init-script"
GRADLE_METADATA_ACTION_CONTEXT=${GRADLE_METADATA_ACTION_CONTEXT:${1}}
GRADLE_METADATA_ACTION_VERSION=${GRADLE_METADATA_ACTION_VERSION:${2}}

echo "::group::Activating Gradle context"
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
CMD="${GRADLE_METADATA_GRADLE_WRAPPER} ${GRADLE_METADATA_GRADLE_WRAPPER_ARGS} "${GITHUB_ACTION_PATH}/gradle/init.gradle" gradle-metadata-action"
echo "::debug::Executing command: ${CMD}"
${CMD}
if [ $? -ne 0 ]; then
	echo "::error::Failed to process Gradle project"
	exit 1
fi
echo "::endgroup::"

source "${GITHUB_ENV}"
echo "::group::Gradle Metadata"
cat "${GRADLE_METADATA_OUTPUT_BAKE_FILE}"
echo ""; echo "::endgroup::"

if [ "$(command -v docker)" ]; then
	echo "::group::Bake definition"
	docker buildx bake -f "${GRADLE_METADATA_OUTPUT_BAKE_FILE}" --print gradle-metadata-action
	echo "::endgroup::"
fi

exit 0
