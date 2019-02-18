# G-Parse

Split URLs as email clients would do, and extract rulable domains from them.

## Dependencies

    IO::Socket::SSL
    LWP::Simple
    Mojolicious::Lite
    Net::IDN::Encode
    Net::IDN::Nameprep
    Unicode::UTF8

## How to Run?

### Live-Reloading Development Server:

    morbo /path/to/gparse/src/gparse

Press `Ctrl + C` to exit.

### Pre-Forking Production Server:

    hypnotoad /path/to/gparse/src/gparse

Hot-deployment after code changes by repeating above command.

Stop the server by:

    hypnotoad --stop /path/to/gparse/src/gparse
