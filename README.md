## About

Gradle Metadata Action for Docker Buildx Bake.

## Usage

### Bake definition

This action also handles a bake definition file that can be used with the Docker Bake action. You just have to declare an empty target named `gradle-metadata-action` and inherit from it.

```hcl
// docker-bake.hcl
target "docker-metadata-action" {}
target "gradle-metadata-action" {}

target "build" {
  inherits = ["docker-metadata-action", "gradle-metadata-action"]
  context = "./"
  dockerfile = "Dockerfile"
  platforms = [
    "linux/amd64",
    "linux/arm/v6",
    "linux/arm/v7",
    "linux/arm64",
    "linux/386"
  ]
}
```

```yml
name: ci

on:
  push:
    branches:
      - 'main'
    tags:
      - 'v*'
  pull_request:
    branches:
      - 'main'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Docker meta
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: |
            name/app
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha

      - name: Gradle meta
        id: gradle-meta
        uses: dockerbakery/gradle-metadata-action@v1

      - uses: docker/bake-action@v2
        with:
          files: |
            ./docker-bake.hcl
            ${{ steps.meta.outputs.bake-file }}
            ${{ steps.gradle-meta.outputs.bake-file }}
          targets: build
```

## Output

> Output of `docker buildx bake -f gradle-metadata-action.hcl --print gradle-metadata-action` command.

```json
{
  "group": {
    "default": {
      "targets": [
        "gradle-metadata-action"
      ]
    }
  },
  "target": {
    "gradle-metadata-action": {
      "args": {
        "GRADLE_VERSION": "8.0.2",
        "GRADLE_PROJECT_NAME": "example-project",
        "GRADLE_PROJECT_VERSION": "1.0.0-SNAPSHOT",
        "GRADLE_PROJECT_PROFILE": "production",
        "GRADLE_PROJECT_TARGET_COMPATIBILITY": "11",
        "GRADLE_PROJECT_SOURCE_COMPATIBILITY": "11"
      }
    }
  }
}
```

## Resources

- [GitHub Action Environment variables](https://docs.github.com/en/actions/learn-github-actions/environment-variables)
- [Workflow commands for GitHub Actions](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions)
- [Bake File Definitions](https://github.com/docker/buildx/blob/master/docs/guides/bake/file-definition.md)
