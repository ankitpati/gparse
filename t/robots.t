#!/usr/bin/env perl

use Mojo::Base qw(-strict);
use Test::More tests => 9;
use Test::Mojo;

use HTTP::Status qw(:constants);

use File::Basename qw(dirname);
use File::Spec::Functions qw(rel2abs);
require (rel2abs(dirname __FILE__) . '/../src/gparse.pl');

my $t = Test::Mojo->new;

my $robots = $t->app->routes->lookup('robots')->to_string;

$t->get_ok ($robots)
  ->status_is (HTTP_OK, 'HTTP status')
  ->content_type_like (qr{^text/plain\b},
                       'Content-Type is text/plain')
  ->content_type_like (qr/\bcharset=UTF-8\b/, 'charset is UTF-8')
  ->header_exists_not ('Server', 'Server header not present')
  ->header_exists_not ('Content-Encoding',
                       'Content-Encoding header not present')
  ->header_exists_not ('Vary', 'Vary header not present')
  ->header_exists_not ('Content-Security-Policy',
                       'Content-Security-Policy not present')
  ->content_is ('', 'empty robots.txt')
;
