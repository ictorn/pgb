FROM swift:6.0.3 AS app

ARG SDK_BUNDLE="0.0.1"
ARG SDK_CHECKSUM="67f765e0030e661a7450f7e4877cfe008db4f57f177d5a08a6e26fd661cdd0bd"

RUN swift sdk install ${SWIFT_WEBROOT}/${SWIFT_BRANCH}/static-sdk/${SWIFT_VERSION}/${SWIFT_VERSION}_static-linux-${SDK_BUNDLE}.artifactbundle.tar.gz --checksum ${SDK_CHECKSUM}

WORKDIR /build

COPY . .

RUN swift package resolve
RUN swift build -c release --swift-sdk x86_64-swift-linux-musl

WORKDIR /release

RUN cp "$(swift build --package-path /build -c release --swift-sdk x86_64-swift-linux-musl --show-bin-path)/pgb" ./pgb

FROM alpine AS psql

RUN apk add --no-cache postgresql-client

FROM gcr.io/distroless/static

COPY --from=psql /lib/ld-musl-x86_64.so.1 /lib/ld-musl-x86_64.so.1
COPY --from=psql /usr/lib/libpq.so.5 /usr/lib/libpq.so.5
COPY --from=psql /usr/lib/libzstd.so.1 /usr/lib/libzstd.so.1
COPY --from=psql /usr/lib/libssl.so.3 /usr/lib/libssl.so.3
COPY --from=psql /usr/lib/libcrypto.so.3 /usr/lib/libcrypto.so.3
COPY --from=psql /usr/lib/liblz4.so.1 /usr/lib/liblz4.so.1
COPY --from=psql /usr/lib/libz.so.1 /usr/lib/libz.so.1
COPY --from=psql /usr/bin/pg_dump /dump
COPY --from=app /release/pgb /pgb

STOPSIGNAL SIGTERM

ENTRYPOINT ["/pgb"]
