#!/bin/echo docker build . -f
# -*- coding: utf-8 -*-
# SPDX-License-Identifier: Apache-2.0
#{
# Copyright: 2018-present Samsung Electronics France SAS, and other contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#}

FROM ubuntu:18.04
LABEL maintainer="Philippe Coval <rzr@users.sf.net>"

ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL en_US.UTF-8
ENV LANG ${LC_ALL}

RUN echo "#log: Configuring locales" \
  && set -x \
  && apt-get update -y \
  && apt-get install -y locales \
  && echo "${LC_ALL} UTF-8" | tee /etc/locale.gen \
  && locale-gen ${LC_ALL} \
  && dpkg-reconfigure locales \
  && sync

RUN echo "#log: Setup system" \
  && set -x \
  && apt-get update -y \
  && apt-get install -y \
  apt-transport-https \
  curl \
  git \
  make \
  npm \
  sudo \
  && apt-get clean \
  && sync

RUN echo "#log: Install iotjs" \
  && set -x \
  && sudo apt-get update -y \
  && apt-cache show iotjs || echo "TODO: iotjs is in debian:testing !"\
  && dpkg-architecture || :\
  && . /etc/os-release \
  && distro="${ID}_${VERSION_ID}" \
  && [ "debian" != "${ID}" ] || distro="${distro}.0" \
  && distro=$(echo "${distro}" | sed 's/.*/\u&/') \
  && [ "ubuntu" != "${ID}" ] || distro="x${distro}" \
  && url="http://download.opensuse.org/repositories/home:/rzrfreefr:/snapshot/$distro" \
  && file="/etc/apt/sources.list.d/org_opensuse_home_rzrfreefr_snapshot.list" \
  && echo "deb [allow-insecure=yes] $url /" | sudo tee "$file" \
  && sudo apt-get update -y \
  && apt-cache search --full iotjs \
  && version=$(apt-cache show "iotjs-snapshot" \
| grep 'Version:' | cut -d' ' -f2 | sort -n | head -n1 || echo 0) \
  && sudo apt-get install -y --allow-unauthenticated \
iotjs-snapshot="$version" iotjs="$version" \
  && which iotjs \
  && iotjs -h || echo "log: iotjs's usage expected to be printed before" \
  && sync

ENV project generic-sensor-lite
ADD . /usr/local/${project}/${project}
WORKDIR /usr/local/${project}/${project}
RUN echo "#log: ${project}: Preparing sources" \
  && set -x \
  && make setup \
  && make \
  && make check \
  && sync

WORKDIR /usr/local/${project}/${project}
RUN echo "#log: ${project}: Preparing sources" \
  && set -x \
  && make test \
  && sync
