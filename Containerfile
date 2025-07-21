ARG ARCH=x86_64

FROM swift:6.1.2 AS app

ARG ARCH
ARG SDK_BUNDLE="0.0.1"
ARG SDK_CHECKSUM="df0b40b9b582598e7e3d70c82ab503fd6fbfdff71fd17e7f1ab37115a0665b3b"

RUN swift sdk install ${SWIFT_WEBROOT}/${SWIFT_BRANCH}/static-sdk/${SWIFT_VERSION}/${SWIFT_VERSION}_static-linux-${SDK_BUNDLE}.artifactbundle.tar.gz --checksum ${SDK_CHECKSUM}

WORKDIR /build

COPY . .

RUN swift package resolve
RUN swift build -c release --swift-sdk ${ARCH}-swift-linux-musl

WORKDIR /release

RUN cp "$(swift build --package-path /build -c release --swift-sdk ${ARCH}-swift-linux-musl --show-bin-path)/pgb" ./pgb

FROM alpine AS psql

ARG ARCH

RUN apk add --no-cache postgresql15-client postgresql16-client postgresql17-client rsync

RUN mkdir /psql

#TODO: script using ldd
RUN rsync -LR /lib/ld-musl-${ARCH}.so.1 /psql/
RUN rsync -LR /usr/lib/libpq.so.5 /psql/
RUN rsync -LR /usr/lib/libzstd.so.1 /psql/
RUN rsync -LR /usr/lib/libssl.so.3 /psql/
RUN rsync -LR /usr/lib/libcrypto.so.3 /psql/
RUN rsync -LR /usr/lib/liblz4.so.1 /psql/
RUN rsync -LR /usr/lib/libz.so.1 /psql/

FROM gcr.io/distroless/static

COPY --from=psql /psql/ /
COPY --from=psql /usr/libexec/postgresql15/pg_dump /usr/bin/pg_dump@15
COPY --from=psql /usr/libexec/postgresql16/pg_dump /usr/bin/pg_dump@16
COPY --from=psql /usr/libexec/postgresql17/pg_dump /usr/bin/pg_dump@17

COPY --from=app /release/pgb /pgb

STOPSIGNAL SIGTERM

ENTRYPOINT ["/pgb"]

LABEL org.opencontainers.image.source=https://github.com/ictorn/pgb
LABEL org.opencontainers.image.description="Postgres Backup Tool"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.authors="Tomasz Sądej"
