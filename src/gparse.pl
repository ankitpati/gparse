#!/usr/bin/env perl

use Mojolicious::Lite;
plugin Config => { file => 'etc/gparse-config.pl' };

use Mojo::File qw(path);
use Encode qw(decode);

use lib path(__FILE__)->sibling('lib/perl5')->to_string;

use HTML::Packer;
use IO::Compress::Brotli qw(bro);
use URI;

use GParse::Domain qw(all_as_hash);

my $config = app->config;
my $cache = app->renderer->cache;
my $types = app->types;
my $packer = HTML::Packer->init;

{
    # Clean unnecessary routes.
    my $extra = app->static->extra;
    delete $extra->{$_} foreach keys %$extra;
}

sub _handlerless_template_path {
    my ($renderer, $options) = @_;
    my $template_name = $renderer->template_name ($options) or return;
    $template_name =~ s/\.html\.(?:ep|data)_once$//;
    -r and return $_ foreach map { "$_/$template_name" } @{$renderer->paths};
    return;
}

sub _render_once_handler {
    my ($renderer, $c, $output, $options) = @_;

    my $path = _handlerless_template_path $renderer, $options
        or die "$options->{template} missing on template path";

    my $content = $cache->get ($path);
    unless (defined $content) {
        my $handler = $options->{handler};

        my $bytes = path($path)->slurp;

        if ($handler eq 'ep_once') {
            $content = $c->render_to_string (
                inline => decode ('UTF-8', $bytes),
                handler => 'ep',
            );
        }
        elsif ($handler eq 'data_once') {
            my $u = URI->new('data:');
            $u->media_type ($types->file_type ($path));
            $u->data ($bytes);
            $content = "$u";
        }

        $cache->set ($path => $content);
    }

    $$output = $content;
    return;
}

app->renderer->add_handler(ep_once => \&_render_once_handler)
             ->add_handler(data_once => \&_render_once_handler);

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
    $h->content_encoding ('br')
      ->content_security_policy ($content->{csp})
      ->add ('Referrer-Policy' => 'no-referrer')
    ;

    $$output = $content->{output};
};

hook after_dispatch => sub {
    my $c = shift;
    $c->res->headers->remove ('Server');
};

helper style_sri => sub {
    my ($c, $style) = @_;

    my $uri = $config->{frontend}{style}{$style};
    my $sri = $config->{sri}{style}{$style} // '';

    $sri = qq{integrity="$sri"} if $sri;

    qq{<link href="$uri" $sri crossorigin="anonymous" rel="stylesheet" />};
};

helper script_sri => sub {
    my ($c, $script) = @_;

    my $uri = $config->{frontend}{script}{$script};
    my $sri = $config->{sri}{script}{$script} // '';

    $sri = qq{integrity="$sri"} if $sri;

    qq{<script src="$uri" $sri crossorigin="anonymous"></script>};
};

helper ep_tag => sub {
    my ($c, $filename) = @_;

    # <start>, </end> tags
    my ($start, $end);

    if ($filename =~ /\.css$/i) {
        $start = '<style>';
        $end = '</style>';
    }
    elsif ($filename =~ /\.js$/i) {
        $start = '<script>';
        $end = '</script>';
    }
    elsif ($filename =~ /\.mjs$/i) {
        $start = '<script type="module">';
        $end = '</script>';
    }
    else {
        die 'Unknown filetype for EP';
    }

    return
        $start . $c->render_to_string($filename, handler => 'ep_once') . $end;
};

helper data_attr => sub {
    my ($c, $filename) = @_;
    $c->render_to_string ($filename, handler => 'data_once');
};

get '/robots.txt' => { text => '', format => 'txt' } => 'robots';

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
