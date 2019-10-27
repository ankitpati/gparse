FROM perl
LABEL maintainer="Ankit Pati <contact@ankitpati.in>"

RUN apt update
RUN apt dist-upgrade -y

ENV PERL_CPANM_OPT="--mirror https://cpan.metacpan.org/"

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

# keep the following section sorted & uniq’d
RUN apt install -y bash-completion
RUN apt install -y git
RUN apt install -y man-db
RUN apt install -y vim-nox
RUN apt install -y sudo

RUN git clone https://github.com/vlad2/git-sh.git
RUN make -C git-sh/
RUN make -C git-sh/ install
RUN rm -rf git-sh/

ENV GPARSEUSER="gparse"

RUN groupadd "$GPARSEUSER"
RUN useradd -g "$GPARSEUSER" "$GPARSEUSER"
RUN echo "$GPARSEUSER ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$GPARSEUSER"

USER $GPARSEUSER:$GPARSEUSER

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

COPY . /opt/gparse
WORKDIR /opt/gparse
ENTRYPOINT ["bash"]
CMD ["-l"]
