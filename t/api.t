#!/usr/bin/env perl

use Mojo::Base qw(-strict);
use Test::More tests => 9;
use Test::Mojo;

use HTTP::Status qw(:constants);

use File::Basename qw(dirname);
use File::Spec::Functions qw(rel2abs);
require (rel2abs(dirname __FILE__) . '/../src/gparse.pl');

my $t = Test::Mojo->new;

my $api = $t->app->routes->lookup('api')->to_string;
$api =~ s|/\*url$||;

$t->get_ok ("$api/google.com")
  ->status_is (HTTP_OK, 'HTTP status')
  ->content_type_like (qr{^application/json\b},
                       'Content-Type is application/json')
  ->content_type_like (qr/\bcharset=UTF-8\b/, 'charset is UTF-8')
  ->header_exists_not ('Server', 'Server header not present')
  ->header_exists_not ('Content-Encoding',
                       'Content-Encoding header not present')
  ->header_exists_not ('Vary', 'Vary header not present')
  ->header_exists_not ('Content-Security-Policy',
                       'Content-Security-Policy not present')
  ->json_is ('/hostname' => 'google.com', 'JSON correct for simple domain')
;
