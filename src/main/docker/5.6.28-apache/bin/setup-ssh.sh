#!/usr/bin/env bash
apt-get update \
    && apt-get install -y openssh-server supervisor \
    && mkdir /var/run/sshd \
    && sed -i 's/^PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/session\s*required\s*pam_loginuid.so/session optional pam_loginuid.so/g' /etc/pam.d/sshd \
    && echo 'export VISIBLE=now' >> /etc/profile