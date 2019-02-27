# G-Parse

Split URLs as email clients would do, and extract rulable domains from them.

## Dependencies

### Mandatory
    IO::Socket::SSL
    LWP::Simple
    Mojolicious
    Net::IDN::Encode
    Net::IDN::Nameprep
    Unicode::UTF8

### Performance-Enhancing Optionals
    Cpanel::JSON::XS
    Net::DNS::Native

## How to Run?

### Live-Reloading Development Server:

    morbo /path/to/gparse/src/gparse

Press `Ctrl + C` to exit.

### Pre-Forking Production Server:

    hypnotoad /path/to/gparse/src/gparse

Hot-deployment after code changes by repeating above command.

Stop the server by:

    hypnotoad --stop /path/to/gparse/src/gparse

## See it in Action!

[Landing page.](https://gparse.ankitpati.in "G-Parse")

[Query through the UI.](https://gparse.ankitpati.in/#https://username:password@www.sitpune.%E0%A4%AD%E0%A4%BE%E0%A4%B0%E0%A4%A4.edu.in.kyoto.jp:8080/ankitpati?hello#anchor "Displays a nice table.")

[Query through the API.](https://gparse.ankitpati.in/https://username:password@www.sitpune.%E0%A4%AD%E0%A4%BE%E0%A4%B0%E0%A4%A4.edu.in.kyoto.jp:8080/ankitpati?hello "Returns JSON.")
