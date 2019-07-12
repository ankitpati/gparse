my $pid_file = $ENV{GPARSE_PID_FILE} // '/tmp/gparse.pid';
my $tls_cert = $ENV{GPARSE_TLS_CERT} // '/etc/ssl/certs/gparse.pem';
my $tls_key = $ENV{GPARSE_TLS_KEY} // '/etc/ssl/private/gparse.pem';

# Some PSGI environments export `$PORT` and expect the
# app to bind only an HTTP (not HTTPS) listener to it.
my $http_port = $ENV{PORT} // 80;

my $g_fonts = 'https://fonts.googleapis.com';
my $cf_ajax = 'https://cdnjs.cloudflare.com/ajax/libs';

my %version = (
    gparse => '1.0.0',
    jquery => '3.4.1',
    materialize => '1.0.0',
);

my %frontend = (
    script => {
        jquery => "$cf_ajax/jquery/$version{jquery}/jquery.min.js",
        materialize => "$cf_ajax/materialize/$version{materialize}/js/materialize.min.js",
    },
    style => {
        materialicons => "$g_fonts/css?family=Material+Icons",
        materialize => "$cf_ajax/materialize/$version{materialize}/css/materialize.min.css",
    },
);

{
    version => \%version,

    hypnotoad => {
        listen => [
            # Do not bind HTTPS listener if `$PORT` is exported.
            $ENV{PORT} ? () : "https://*:443?cert=$tls_cert&key=$tls_key",

            "http://*:$http_port",
        ],
        pid_file => $pid_file,
    },

    minify => {
        do_javascript => 'shrink',
        do_stylesheet => 'minify',
        html5 => 1,
        remove_comments => 1,
        remove_newlines => 1,
    },

    frontend => \%frontend,

    csp => {
        'default-src' => [
            "'none'",
        ],
        'script-src' => [
            "'unsafe-inline'",
            map s/\?.*$//r, values %{ $frontend{script} },
        ],
        'style-src' => [
            "'unsafe-inline'",
            map s/\?.*$//r, values %{ $frontend{style} },
        ],
        'font-src' => [
            $g_fonts,
            'https://fonts.gstatic.com',
        ],
        'img-src' => [
            'data:',
        ],
        'connect-src' => [
            "'self'",
        ],
    },
}
