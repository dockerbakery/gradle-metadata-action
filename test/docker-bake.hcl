target "gradle-metadata-action" {}

target "application" {
    inherits = [ "gradle-metadata-action" ]
    context = "./"
    dockerfile = "Dockerfile"
    platforms = [ "linux/amd64" ]
}
