variable "GRADLE_VERSION" {}
variable "GRADLE_PROJECT_NAME" {}
variable "GRADLE_PROJECT_VERSION" {}
variable "GRADLE_PROJECT_PROFILE" {}
variable "GRADLE_PROJECT_TARGET_COMPATIBILITY" {}
variable "GRADLE_PROJECT_SOURCE_COMPATIBILITY" {}

target "gradle-metadata-action" {
    args = {
        GRADLE_VERSION = ${GRADLE_VERSION}
        GRADLE_PROJECT_NAME = ${GRADLE_PROJECT_NAME}
        GRADLE_PROJECT_VERSION = ${GRADLE_PROJECT_VERSION}
        GRADLE_PROJECT_PROFILE = ${GRADLE_PROJECT_PROFILE}
        GRADLE_PROJECT_TARGET_COMPATIBILITY = ${GRADLE_PROJECT_TARGET_COMPATIBILITY}
        GRADLE_PROJECT_SOURCE_COMPATIBILITY = ${GRADLE_PROJECT_SOURCE_COMPATIBILITY}
    }
}
