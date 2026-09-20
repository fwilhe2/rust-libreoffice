# SPDX-FileCopyrightText: 2025 Florian Wilhelm
#
# SPDX-License-Identifier: MIT

FROM docker.io/rust:1-trixie
ENV DEBIAN_FRONTEND=noninteractive

COPY debian-backports.sources /etc/apt/sources.list.d/debian-backports.sources

RUN apt-get -qq update && apt-get install -t trixie-backports --no-install-recommends -yqq libreoffice-calc libreoffice-l10n-de jing
