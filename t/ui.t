#!/usr/bin/env perl

use Mojo::Base qw(-strict);
use Mojo::DOM;
use Mojo::UserAgent;
use Test::More tests => 32;
use Test::Mojo;

use HTTP::Status qw(:constants);
use IO::Uncompress::Brotli qw(unbro);
use Digest::SHA qw(sha256_base64 sha384_base64 sha512_base64);

use File::Basename qw(dirname);
use File::Spec::Functions qw(rel2abs);
require (rel2abs(dirname __FILE__) . '/../src/gparse.pl');

my $t = Test::Mojo->new;

# We expect the UI to be a single, stringifiable endpoint. The app will be in
# an inconsistent state if this assumption doesn’t hold, so it’s okay to blow
# the tests up.
$t->get_ok ($t->app->routes->lookup('ui')->to_string . '/')
  ->status_is (HTTP_OK, 'HTTP status')
  ->content_type_like (qr{^text/html\b}, 'Content-Type is text/html')
  ->content_type_like (qr/\bcharset=UTF-8\b/, 'charset is UTF-8')
  ->header_exists_not ('Server', 'Server header not present')

  # Compression is unconditional for the UI. We do not expect to serve the UI
  # to non-browser clients. Even there, old browsers like IE are excluded.
  ->header_is ('Content-Encoding' => 'br', 'Content-Encoding is br (Brotli)')
  ->header_exists_not ('Vary', 'Vary header not present')

  ->header_is ('Referrer-Policy' => 'no-referrer', 'Referrer-Policy is tight')

  ->header_like ('Content-Security-Policy' =>
                 qr/(?:^|; )base-uri 'none'(?:;|$)/,
                 'Tight CSP base-uri')

  ->header_like ('Content-Security-Policy' =>
                 qr/(?:^|; )default-src 'none'(?:;|$)/,
                 'Tight CSP default-src')

  ->header_like ('Content-Security-Policy' =>
                 qr/(?:^|; )form-action 'none'(?:;|$)/,
                 'Tight CSP form-action')

  ->header_like ('Content-Security-Policy' =>
                 qr/(?:^|; )frame-ancestors 'none'(?:;|$)/,
                 'Tight CSP frame-ancestors')

  ->header_like ('Content-Security-Policy' =>
                 qr/(?:^|; )connect-src 'self'(?:;|$)/,
                 'Tight CSP connect-src')

  ->header_like ('Content-Security-Policy' =>
                 qr/(?:^|; )navigate-to 'self'(?:;|$)/,
                 'Tight CSP navigate-to')

  ->header_like ('Content-Security-Policy' =>
                 qr{(?:^|; )report-uri https://\w+},
                 'Report URI present and points to HTTPS endpoint')

  ->header_unlike ('Content-Security-Policy' =>
                   qr/(?:^|; )script-src [^;]*'unsafe-/,
                   'No unsafe- in CSP script-src')

  ->header_unlike ('Content-Security-Policy' =>
                   qr/(?:^|; )style-src [^;]*'unsafe-/,
                   'No unsafe- in CSP style-src')
;

my $html = unbro $t->tx->res->text, 1_000_000; # Maximum 1 MB uncompressed.
like $html, qr/^<!DOCTYPE html>/, 'using HTML5 DOCTYPE';
is split (/\n/, $html), 1, 'HTML has been minified into a single line';

my $dom = Mojo::DOM->new ($html);

# Basic sanity checks.
is $dom->find($_)->size, 1, "Only one <$_>" foreach qw(html head body);

# JavaScript event handlers must not be in HTML, as it impedes obfuscation.
is $dom->find("[on$_]")->size, 0, "No on$_ handlers"
    foreach qw(click hashchange load select);

# `integrity` attribute must be present on all linked styles, except GFonts.
is $dom->find('link[href][rel="stylesheet"]' .
              ':not([href^=https://fonts.googleapis.com]):not([integrity])')
       ->size, 0, 'No non-GFonts <style> elements without SRI';

# `integrity` attribute must be present on all linked scripts.
is $dom->find('script[src]:not([integrity])')->size, 0,
    'No <script> elements without SRI';

# Check returned SRI hashes for currency. Be careful, it may be a CDN attack.
my $ua = Mojo::UserAgent->new;
$dom->find('link[href][integrity], script[src][integrity]')->each (sub {
    my $uri = $_->attr ($_->tag eq 'link' ? 'href' : 'src');
    my $sri = $_->attr ('integrity');

    my ($algo, $got_hash) = $sri =~ /^([a-z0-9]+)-(.*)=$/;

    my $content = $ua->get($uri)->result->body;
    my $expected_hash = eval {
        no strict 'refs';
        &{ "${algo}_base64" } ($content);
    };

    is $got_hash, $expected_hash, "URI: $uri, SRI: $sri";
});

# All embedded JavaScript must `"use strict";`
$dom->find('script')->each (sub {
    my $text = $_->text;
    return if $text =~ /^\s*$/;
    like $text, qr/^\s*"use strict";/, 'Embedded JavaScript is strict';
});
