FROM docker.io/library/perl

LABEL org.opencontainers.image.authors="Ankit Pati <contact@ankitpati.in>"
LABEL org.opencontainers.image.source="https://gitlab.com/ankitpati/gparse/-/raw/master/Dockerfile"
LABEL org.opencontainers.image.licenses="GPL-3.0+"

RUN apt update
RUN apt dist-upgrade -y

ENV PERL_CPANM_OPT="--from https://www.cpan.org/ --verify"

# keep the following section sorted & uniq’d
RUN apt install -y \
    bash-completion \
    git \
    libdigest-sha-perl \
    libmodule-signature-perl \
    man-db \
    vim-nox \
;

# keep the following section sorted & uniq’d
RUN cpanm \
    Digest::SHA \
    Module::Signature \
;

# keep the following section sorted & uniq’d
RUN cpanm \
    CSS::Packer \
    Cpanel::JSON::XS \
    EV \
    Future::AsyncAwait \
    HTML::Packer \
    IO::Compress::Brotli \
    IO::Socket::SSL \
    IO::Socket::Socks \
    JavaScript::Packer \
    LWP::Protocol::https \
    LWP::Simple \
    Mojolicious \
    Net::DNS::Native \
    Net::IDN::Encode \
    Net::IDN::Nameprep \
    Role::Tiny \
    Test::Pod \
    Test::Pod::Coverage \
;

RUN useradd gparse

USER gparse

WORKDIR /home/gparse

RUN \
    git clone --depth=1 'https://gitlab.com/ankitpati/git-sh.git' && \
    make -C git-sh/ PREFIX='$(HOME)/.local' install && \
    rm -rf git-sh/ && \
    \
    git clone --depth=1 'https://gitlab.com/ankitpati/dotfiles.git' && \
    make -C dotfiles/ install && \
    rm -rf dotfiles/ && \
    \
    git clone --depth=1 'https://gitlab.com/ankitpati/scripts.git' && \
    make -C scripts/ install && \
    rm -rf scripts/ && \
true

COPY . /opt/gparse
WORKDIR /opt/gparse
ENTRYPOINT ["bash", "-l"]
