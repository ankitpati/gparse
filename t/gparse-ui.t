#!/usr/bin/env perl

use Mojo::Base qw(-strict);
use Test::More tests => 11;
use Test::Mojo;

use HTTP::Status qw(:constants);
use IO::Uncompress::Brotli qw(unbro);

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

  # Compression is unconditional for the UI. We do not expect to serve the UI
  # to non-browser clients. Even there, old browsers like IE are excluded.
  ->header_is ('Content-Encoding' => 'br', 'Content-Encoding is br (Brotli)')
  ->header_exists_not ('Vary', 'Vary header not present')

  ->header_like ('Content-Security-Policy' =>
                 qr/(?:^|; )default-src 'none'(?:;|$)/,
                 'Tight CSP default-src')

  ->header_unlike ('Content-Security-Policy' =>
                   qr/(?:^|; )script-src [^;]*'unsafe-/,
                   'No unsafe- in CSP script-src')

  ->header_unlike ('Content-Security-Policy' =>
                   qr/(?:^|; )style-src [^;]*'unsafe-/,
                   'No unsafe- in CSP style-src')
;

my $html = unbro $t->tx->res->text, 1_000_000; # Maximum 1 MB uncompressed.
like $html, qr/^<!DOCTYPE html>/, 'using HTML5 DOCTYPE';
is split ("\n", $html), 1, 'HTML has been minified into a single line';
