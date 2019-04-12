my $pid_file = $ENV{GPARSE_PID_FILE} // '/tmp/gparse.pid';
my $tls_cert = $ENV{GPARSE_TLS_CERT} // '/etc/ssl/certs/gparse.pem';
my $tls_key = $ENV{GPARSE_TLS_KEY} // '/etc/ssl/private/gparse.pem';

# Some PSGI environments export `$PORT` and expect the
# app to bind only an HTTP (not HTTPS) listener to it.
my $http_port = $ENV{PORT} // 80;

{
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

    version => {
        gparse => '1.0.0',
        jquery => '3.4.0',
        materialize => '1.0.0',
    },
}
