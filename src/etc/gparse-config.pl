use IO::Socket::SSL qw(SSL_VERIFY_PEER SSL_VERIFY_FAIL_IF_NO_PEER_CERT);

my $pid_file = $ENV{GPARSE_PID_FILE} // '/tmp/gparse.pid';

my %tls = (
    ca => $ENV{GPARSE_TLS_CA} // '/etc/ssl/certs/origin-pull-ca.pem',
    verify => SSL_VERIFY_PEER | SSL_VERIFY_FAIL_IF_NO_PEER_CERT,
    cert => $ENV{GPARSE_TLS_CERT} // '/etc/ssl/certs/gparse.pem',
    key => $ENV{GPARSE_TLS_KEY} // '/etc/ssl/private/gparse.pem',
);

# Some PSGI environments export `$PORT` and expect the
# app to bind only an HTTP (not HTTPS) listener to it.
my $http_port = $ENV{PORT} // 80;

my $g_fonts = 'https://fonts.googleapis.com';
my $cf_ajax = 'https://cdnjs.cloudflare.com/ajax/libs';
my $jsdlvr_npm = 'https://cdn.jsdelivr.net/npm';

my %version = (
    gparse => '1.0.0',
    jquery => '3.6.0',
    bootstrap => '5.0.0-beta2',
);

my %frontend = (
    script => {
        jquery => "$cf_ajax/jquery/$version{jquery}/jquery.min.js",
        bootstrap => "$jsdlvr_npm/bootstrap\@$version{bootstrap}/dist/js/bootstrap.bundle.min.js",
    },
    style => {
        materialicons => "$g_fonts/css?family=Material+Icons",
        bootstrap => "$jsdlvr_npm/bootstrap\@$version{bootstrap}/dist/css/bootstrap.min.css",
    },
);

my @csp_none = qw(
    base-uri
    default-src
    form-action
    frame-ancestors
);

my @csp_self = qw(
    connect-src
    navigate-to
);

{
    version => \%version,

    hypnotoad => {
        listen => [
            # Do not bind HTTPS listener if `$PORT` is exported.
            $ENV{PORT} ? () : ("https://*:443?" .
                                    join '&', map "$_=$tls{$_}", keys %tls),

            "http://*:$http_port",
        ],
        pid_file => $pid_file,
    },

    minify => {
        do_javascript => 'shrink',
        do_stylesheet => 'minify',
        do_csp => 'sha256',
        html5 => 1,
        remove_comments => 1,
        remove_newlines => 1,
    },

    frontend => \%frontend,

    # Content Security Policy
    csp => {
        'report-uri' => [
            'https://ankitpati.report-uri.com/r/d/csp/enforce',
        ],
        sandbox => [qw(
            allow-scripts
            allow-same-origin
        )],
        'script-src' => [
            map s/\?.*$//r, values %{ $frontend{script} },
        ],
        'style-src' => [
            map s/\?.*$//r, values %{ $frontend{style} },
        ],
        'font-src' => [
            $g_fonts,
            'https://fonts.gstatic.com',
        ],
        'img-src' => [
            'data:',
        ],
        (map { $_ => [ "'none'" ] } @csp_none),
        (map { $_ => [ "'self'" ] } @csp_self),
    },

    # Subresource Integrity
    sri => {
        script => {
            jquery => 'sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=',
            bootstrap => 'sha256-tfbRzZ36wuPoeUKXyuewrLOzcfgdO2ovc4ozuYRWMs4=',
        },
        style => {
            bootstrap => 'sha256-nq7J0kse50upWdNiXRDsuGd/AkfaHz0hX8HgCUsCASY=',
        },
    },
}
