my %version = (
    gparse => '1.0.0',
    jquery => '3.4.1',
    materialize => '1.0.0',
);

my $pid_file = $ENV{GPARSE_PID_FILE} // '/tmp/gparse.pid';
my $tls_cert = $ENV{GPARSE_TLS_CERT} // '/etc/ssl/certs/gparse.pem';
my $tls_key = $ENV{GPARSE_TLS_KEY} // '/etc/ssl/private/gparse.pem';

# Some PSGI environments export `$PORT` and expect the
# app to bind only an HTTP (not HTTPS) listener to it.
my $http_port = $ENV{PORT} // 80;

my $g_fonts = 'https://fonts.googleapis.com/css?family';
my $cf_ajax = 'https://cdnjs.cloudflare.com/ajax/libs';

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

    frontend => {
        jquery_js => "$cf_ajax/jquery/$version{jquery}/jquery.min.js",
        materialicons_css => "$g_fonts=Material+Icons",
        materialize_css => "$cf_ajax/materialize/$version{materialize}/css/materialize.min.css",
        materialize_js => "$cf_ajax/materialize/$version{materialize}/js/materialize.min.js",
    },
}