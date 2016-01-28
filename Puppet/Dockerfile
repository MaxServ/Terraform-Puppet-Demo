# Copyright 2016 Remco Overdijk - MaxServ B.V.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/. */

FROM centos:centos7

MAINTAINER remco@maxserv.com

ENV PUPPET_VERSION 3.7.5

RUN rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs && rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
RUN yum install -y puppet-$PUPPET_VERSION
RUN yum install -y puppet-server-$PUPPET_VERSION
RUN gem install r10k
RUN gem install deep_merge

ADD puppet.conf /etc/puppet/puppet.conf
ADD hiera.yaml /etc/puppet/hiera.yaml
ADD Puppetfile /etc/puppet/Puppetfile
ADD hieradata /etc/puppet/hieradata
ADD modules/demo /etc/puppet/modules/demo
ADD manifests/site.pp /etc/puppet/manifests/site.pp

WORKDIR /etc/puppet
RUN r10k puppetfile install

EXPOSE 8140

ENTRYPOINT [ "/usr/bin/puppet", "master", "--no-daemonize", "--verbose" ]
