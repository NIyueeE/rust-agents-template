# Packages the static musl binary into a scratch image.
# Build context layout: bin/<arch>/rust-agents-template (created by release.yml).
FROM scratch

ARG TARGETARCH=amd64
WORKDIR /app
COPY bin/${TARGETARCH}/rust-agents-template /app/rust-agents-template
USER 1000:1000
ENTRYPOINT ["/app/rust-agents-template"]
