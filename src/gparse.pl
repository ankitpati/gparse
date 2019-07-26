#!/usr/bin/env perl

use Mojolicious::Lite;
plugin Config => { file => 'etc/gparse-config.pl' };

use Mojo::File qw(path);
use Unicode::UTF8 qw(decode_utf8);

use lib path(__FILE__)->sibling('lib/perl5')->to_string;

use HTML::Packer;
use IO::Compress::Brotli qw(bro);
use GParse::Domain qw(all_as_hash);

my $config = app->config;
my $cache = app->renderer->cache;
my $packer = HTML::Packer->init;

{
    # Clean unnecessary routes.
    my $extra = app->static->extra;
    delete $extra->{$_} foreach keys %$extra;
}

sub handlerless_template_path {
    my ($renderer, $options) = @_;
    my $template_name = $renderer->template_name ($options) or return;
    $template_name =~ s/\.html\.ep_once$//;
    -r and return $_ foreach map { "$_/$template_name" } @{$renderer->paths};
    return;
}

app->renderer->add_handler (ep_once => sub {
    my ($renderer, $c, $output, $options) = @_;

    my $path = handlerless_template_path ($renderer, $options)
        or die "$options->{template} missing on template path";

    my $content = $cache->get ($path);
    unless (defined $content) {
        $content = $c->render_to_string (
            inline => decode_utf8 (path($path)->slurp),
            handler => 'ep',
        );

        $cache->set ($path => $content);
    }

    $$output = $content;
});

hook after_render => sub {
    my ($c, $output, $format) = @_;

    return unless $format eq 'html';

    my $url_hit = $c->tx->req->url->to_string;

    my $content = $cache->get ($url_hit);
    unless (defined $content) {
        $packer->minify ($output, $config->{minify});

        my %csp;
        my %config_csp = %{ $config->{csp} // {} };
        my %packer_csp = $packer->csp;

        push @{ $csp{$_} }, @{ $config_csp{$_} } foreach keys %config_csp;
        push @{ $csp{$_} }, @{ $packer_csp{$_} } foreach keys %packer_csp;

        $cache->set ($url_hit => {
            output => (bro $$output),
            csp => (join '; ', map { join ' ', $_, @{ $csp{$_} } } keys %csp),
        });
    }
    $content = $cache->get ($url_hit);

    my $h = $c->res->headers;
    $h->append (Vary => 'Accept-Encoding');
    $h->content_encoding ('br');

    $h->content_security_policy ($content->{csp});
    $$output = $content->{output};
};

hook after_dispatch => sub {
    my $c = shift;
    $c->res->headers->remove ('Server');
};

get '/*url' => sub {
    my $c = shift;

    my $url = $c->stash ('url');

    # Stringify query, as it is not picked up in `$url` on unencoded `GET`s.
    my $query = $c->req->params->to_string;
    $url .= "?$query" if $query;

    my %response = all_as_hash $url;

    # Convert Perl truthy/falsy values to JS booleans. Refer to `Mojo::JSON`.
    foreach (keys %response) {
        $response{$_} //= '';
        $response{$_} = $response{$_} ? \1 : \0 if /^is_\w+/;
    }

    $c->render (json => \%response);
} => 'api';

get '/' => sub {
    my $c = shift;
    $c->render ('gparse.html', handler => 'ep_once');
} => 'ui';

app->start;

__END__
