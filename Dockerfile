FROM fedora:latest
LABEL maintainer="Ankit Pati <contact@ankitpati.in>"

RUN sed -z 's/\ntsflags=nodocs\n/\n/' -i /etc/dnf/dnf.conf
RUN echo 'fastestmirror=true' >> /etc/dnf/dnf.conf
RUN echo 'deltarpm=true' >> /etc/dnf/dnf.conf

RUN dnf update -y

RUN dnf install -y perl
RUN dnf install -y perl'(App::cpanminus)'

ENV PERL_CPANM_OPT="--mirror https://cpan.metacpan.org/"
RUN cpanm App::cpanminus
RUN cpanm App::cpanoutdated
RUN cpan-outdated -p | xargs cpanm

# keep the following section sorted & uniq’d
RUN cpanm CSS::Packer
RUN cpanm Cpanel::JSON::XS
RUN cpanm EV
RUN cpanm HTML::Packer
RUN cpanm IO::Compress::Brotli
RUN cpanm IO::Socket::SSL
RUN cpanm IO::Socket::Socks
RUN cpanm JavaScript::Packer
RUN cpanm LWP::Protocol::https
RUN cpanm LWP::Simple
RUN cpanm Mojolicious
RUN cpanm Net::DNS::Native
RUN cpanm Net::IDN::Encode
RUN cpanm Net::IDN::Nameprep
RUN cpanm Role::Tiny
RUN cpanm Test::Pod
RUN cpanm Test::Pod::Coverage
RUN cpanm Unicode::UTF8

# keep the following section sorted & uniq’d
RUN dnf install -y bash-completion
RUN dnf install -y git
RUN dnf install -y man-db
RUN dnf install -y procps-ng
RUN dnf install -y vim-enhanced

RUN git clone https://github.com/rtomayko/git-sh.git
RUN make -C git-sh/
RUN make -C git-sh/ install
RUN rm -rf git-sh/

ENV GPARSEUSER="gparse"

RUN groupadd "$GPARSEUSER"
RUN useradd -g "$GPARSEUSER" "$GPARSEUSER"
RUN echo "$GPARSEUSER ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$GPARSEUSER"

USER $GPARSEUSER:$GPARSEUSER

RUN echo 'cd /opt/gparse' >> ~/.bashrc
RUN echo 'source ~/.bashrc' >> ~/.bash_profile

# keep the following section sorted & uniq’d
ENV TEST_EV="1"
ENV TEST_HYPNOTOAD="1"
ENV TEST_IPV6="1"
ENV TEST_MORBO="1"
ENV TEST_ONLINE="1"
ENV TEST_POD="1"
ENV TEST_PREFORK="1"
ENV TEST_SOCKS="1"
ENV TEST_SUBPROCESS="1"
ENV TEST_TLS="1"
ENV TEST_UNIX="1"

USER root:root

ADD https://gitlab.com/ankitpati/scripts/raw/master/src/nutshell.sh \
    /usr/bin/nutshell

RUN chmod +x /usr/bin/nutshell

ENTRYPOINT ["nutshell", "gparse:gparse", "/opt/gparse", "--"]
CMD ["-l"]
