FROM registry.access.redhat.com/rhel7:latest
USER root

ADD yq_linux_amd64 /

RUN \
 yum-config-manager --add-repo https://arm.sero.gic.ericsson.se/artifactory/proj-redhat-repos-rpm-local/repos/rhel-x86_64-server-7-rhscl-1/ > /dev/null 2>&1 && \
 yum-config-manager --add-repo https://arm.sero.gic.ericsson.se/artifactory/proj-redhat-repos-rpm-local/repos/rhel-x86_64-server-7/ > /dev/null 2>&1 && \
 yum-config-manager --save --setopt=gpgcheck=0 > /dev/null 2>&1 && \
 yum install -y rh-python38-python-requests && \
 yum clean all
