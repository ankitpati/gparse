# G-Parse

Split URLs as email clients would do, and extract rulable domains from them.

---

## Dependencies

### Mandatory
    HTML::Packer
    IO::Compress::Brotli
    IO::Socket::SSL
    LWP::Protocol::https
    LWP::Simple
    Mojolicious
    Net::IDN::Encode
    Net::IDN::Nameprep
    Net::SSLeay

### Performance-Enhancing Optionals
    CSS::Packer
    Cpanel::JSON::XS
    EV
    IO::Socket::Socks
    JavaScript::Packer
    Net::DNS::Native
    Role::Tiny

---

## How to Run?

### Live-Reloading Development Server

    morbo /opt/gparse/src/gparse.pl

#### Stop

Press `Ctrl + C` to exit.

### Pre-Forking Production Server

    hypnotoad /opt/gparse/src/gparse.pl

#### Hot-Deployment

After code changes, repeat above command.

#### Stop

    hypnotoad --stop /opt/gparse/src/gparse.pl

---

## See it in Action!

[Landing page.](https://gparse.ankitpati.in "G-Parse")

[Query through the UI.](https://gparse.ankitpati.in/#https://username:password@www.sitpune.%E0%A4%AD%E0%A4%BE%E0%A4%B0%E0%A4%A4.edu.in.kyoto.jp:8080/ankitpati?hello#anchor "Displays a nice table.")

[Query through the API.](https://gparse.ankitpati.in/https://username:password@www.sitpune.%E0%A4%AD%E0%A4%BE%E0%A4%B0%E0%A4%A4.edu.in.kyoto.jp:8080/ankitpati?hello "Returns JSON.")
