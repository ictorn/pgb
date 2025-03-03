ARG ARCH=x86_64

FROM swift:6.0.3 AS app

ARG ARCH
ARG SDK_BUNDLE="0.0.1"
ARG SDK_CHECKSUM="67f765e0030e661a7450f7e4877cfe008db4f57f177d5a08a6e26fd661cdd0bd"

RUN swift sdk install ${SWIFT_WEBROOT}/${SWIFT_BRANCH}/static-sdk/${SWIFT_VERSION}/${SWIFT_VERSION}_static-linux-${SDK_BUNDLE}.artifactbundle.tar.gz --checksum ${SDK_CHECKSUM}

WORKDIR /build

COPY . .

RUN swift package resolve
RUN swift build -c release --swift-sdk ${ARCH}-swift-linux-musl

WORKDIR /release

RUN cp "$(swift build --package-path /build -c release --swift-sdk ${ARCH}-swift-linux-musl --show-bin-path)/pgb" ./pgb

FROM alpine AS psql

ARG ARCH

RUN apk add --no-cache postgresql-client rsync

RUN mkdir /psql

RUN rsync -LR /lib/ld-musl-${ARCH}.so.1 /psql/
RUN rsync -LR /usr/lib/libpq.so.5 /psql/
RUN rsync -LR /usr/lib/libzstd.so.1 /psql/
RUN rsync -LR /usr/lib/libssl.so.3 /psql/
RUN rsync -LR /usr/lib/libcrypto.so.3 /psql/
RUN rsync -LR /usr/lib/liblz4.so.1 /psql/
RUN rsync -LR /usr/lib/libz.so.1 /psql/
RUN rsync -LR /usr/bin/pg_dump /psql/

FROM gcr.io/distroless/static

COPY --from=psql /psql/ /
COPY --from=app /release/pgb /pgb

STOPSIGNAL SIGTERM

ENTRYPOINT ["/pgb"]

LABEL org.opencontainers.image.source=https://github.com/ictorn/pgb
LABEL org.opencontainers.image.description="Postgres Backup Tool"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.authors="Tomasz Sądej"
