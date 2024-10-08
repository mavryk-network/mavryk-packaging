# SPDX-FileCopyrightText: 2020 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: LicenseRef-MIT-TQ
FROM alpine:3.17
RUN apk update
RUN apk --no-cache --virtual add rsync git m4 build-base patch unzip \
  bubblewrap wget pkgconfig gmp-dev libev-dev \
  hidapi-dev eudev-dev perl opam libusb-dev bash \
  autoconf automake libtool linux-headers cargo \
  libffi-dev zlib-dev zlib-static coreutils perl-utils cmake \
  protobuf protobuf-dev sqlite-dev
COPY ./build/build-rust.sh /build-rust.sh
RUN /build-rust.sh
COPY ./build/build-upx.sh /build-upx.sh
RUN /build-upx.sh
ARG MAVKIT_VERSION
RUN git clone --single-branch --depth 1 --branch "$MAVKIT_VERSION" https://gitlab.com/mavryk-network/mavryk-protocol.git mavryk
WORKDIR /mavryk
ENV OPAMYES true
COPY ./build/build-deps.sh /build-deps.sh
RUN /build-deps.sh
COPY ./build/build-mavryk.sh /build-mavryk.sh
ARG MAVKIT_EXECUTABLES
RUN /build-mavryk.sh
RUN upx $MAVKIT_EXECUTABLES
