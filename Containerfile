# Packages the static musl binary into a scratch image.
# Build context layout: bin/<arch>/<bin> (created by just image).
FROM scratch

ARG TARGETARCH=amd64
ARG BIN
# Links the GHCR package to its repository when the release job passes the URL.
ARG SOURCE_URL=""
LABEL org.opencontainers.image.source=$SOURCE_URL

WORKDIR /app
COPY bin/${TARGETARCH}/${BIN} /app/app
USER 1000:1000
ENTRYPOINT ["/app/app"]
