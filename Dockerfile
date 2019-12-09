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

RUN git clone https://github.com/vlad2/git-sh.git
RUN make -C git-sh/
RUN make -C git-sh/ install
RUN rm -rf git-sh/

RUN useradd gparse

USER gparse

COPY . /opt/gparse
WORKDIR /opt/gparse
ENTRYPOINT ["bash"]
CMD ["-l"]
