# Tsung
#
#
# VERSION               1.6.0

FROM          centos:centos6
MAINTAINER    Jonathan Easterman <jonathaneasterman@gmail.com>

RUN yum update -y
RUN rpm -Uvh "http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm"
RUN yum -y install perl-Log-Log4perl-RRDs.noarch gnuplot perl-Template-Toolkit firefox tar
RUN yum -y install jq erlang

# until EPEL gets tsung 1.6.0 we're compiling it again, taking advantage of the dependencies that were installed with the previous tsung version
# Yes, this is the lazy version of upgrading tsung ...
RUN curl http://tsung.erlang-projects.org/dist/tsung-1.6.0.tar.gz --output /tmp/tsung-1.6.0.tar.gz \
    && cd /tmp/ \
    && tar -xvf ./tsung-1.6.0.tar.gz \
    && cd tsung-1.6.0 \
    && ./configure \
    && make debug \
    && make install \
    && rm -rf /tmp/tsung*

#
# setup SSH Access on Port 22, with the ssh clients using port 21 by default
RUN yum -y install openssh openssh-server openssh-clients
RUN ssh-keygen -N "" -f /root/.ssh/id_rsa && \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys && \
    echo "Port 21" > /root/.ssh/config && \
    echo "StrictHostKeyChecking no" >> /root/.ssh/config && \
    echo "UserKnownHostsFile /dev/null" >> /root/.ssh/config

RUN mkdir -p /var/log/tsung && echo "" > /var/log/tsung/tsung.log

EXPOSE 22
# expose Tsung's GUI available with Tsung 1.6.0
EXPOSE 8091

# EPMD port: http://www.erlang.org/doc/man/epmd.html#environment_variables
EXPOSE 4369
ENV ERL_EPMD_PORT=4369

# Erlang needs this environment variable
ENV BINDIR=/usr/lib64/erlang/erts-5.8.5/

# mount a location on the disk to access the test scripts
RUN mkdir -p /usr/local/tsung
VOLUME ["/usr/local/tsung"]


EXPOSE 9001-9050
#
# make sure inet_dist_listen_* properties are available when Erlang runs
#
RUN sed -i.bak s/"64000"/"9001"/g /usr/bin/tsung
RUN sed -i.bak s/"65500"/"9050"/g /usr/bin/tsung
RUN printf "[{kernel,[{inet_dist_listen_min,9001},{inet_dist_listen_max,9050}]}]. \n\n" > /root/sys.config
RUN sed -i.bak s/"erlexec"/"erlexec -config \/root\/sys "/g /usr/bin/erl

# setup for auto-discovery of the tsung nodes
RUN yum -y install crontabs
COPY ./scripts/tsung-update-hosts.sh /usr/bin/tsung-update-hosts
RUN chmod +x /usr/bin/tsung-update-hosts
RUN mkdir -p /etc/tsung/
RUN echo "* * * * * /usr/bin/tsung-update-hosts >> /var/log/tsung/tsung-update-hosts.log 2>&1" > /etc/crontab
RUN touch /var/log/tsung/tsung-update-hosts.log

# Port used by Erlang to SSH into the Slaves
# default value is 21
ENV ERL_SSH_PORT 21

COPY ./scripts/tsung-runner.sh /usr/bin/tsung-runner
RUN chmod +x /usr/bin/tsung-runner

ENTRYPOINT ["tsung-runner"]


