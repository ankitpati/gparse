package HTML::Packer::CSP;

use strict;
use warnings;

use Carp qw(croak);
use Digest::SHA qw(sha256_base64 sha384_base64 sha512_base64);
use Regexp::RegGrp;

use parent qw(HTML::Packer);

our @CSP_OPTS = qw(sha256 sha384 sha512);

# these variables are used in the closures defined in the init function
# below - we have to use globals as using $self within the closures leads
# to a reference cycle and thus memory leak, and we can't scope them to
# the init method as they may change. they are set by the minify sub
our ($do_csp, %csp);

sub init {
    my $class = shift;
    my $self = $class->SUPER::init (@_);

    $self->{$HTML::Packer::GLOBAL_REGGRP}{reggrp_data}[2]{store} = sub {
        my ($opening, undef, $content, $closing) = @{ $_[0]->{submatches} };

        if ($content) {
            my $opening_script_re = '<\s*script' .
                ($HTML::Packer::html5 ? '[^>]*>' :
                                        '[^>]*(?:java|ecma)script[^>]*>');
            my $opening_style_re = '<\s*style' .
                ($HTML::Packer::html5 ? '[^>]*>' : '[^>]*text\/css[^>]*>');
            my $js_type_re = q<type=['"]((application|text)/){0,1}(x-){0,1}> .
                             q<(java|ecma)script['"]>;

            if ($opening =~ /$opening_script_re/i
                and ($opening =~ /$js_type_re/i or $opening !~ /type/i)) {

                $opening =~ s` type="(text/)?(java|ecma)script"``i
                    if $HTML::Packer::html5;

                if ($HTML::Packer::js_packer and
                    $HTML::Packer::do_javascript) {

                    $HTML::Packer::js_packer->minify (\$content,
                        { compress => $HTML::Packer::do_javascript });

                    $content = "/*<![CDATA[*/$content/*]]>*/"
                        unless $HTML::Packer::html5;
                }

                if ($do_csp) {
                    no strict 'refs';
                    push @{ $csp{'script-src'} },
                         &{ "${do_csp}_base64" } ($content);
                }
            }
            elsif ($opening =~ /$opening_style_re/i) {
                $opening =~ s` type="text/css"``i if $HTML::Packer::html5;

                if ($HTML::Packer::css_packer and
                    $HTML::Packer::do_stylesheet) {

                    $HTML::Packer::css_packer->minify (\$content,
                        { compress => $HTML::Packer::do_stylesheet });

                    $content = "\n$content"
                        if $HTML::Packer::do_stylesheet eq 'pretty';
                }

                if ($do_csp) {
                    no strict 'refs';
                    push @{ $csp{'style-src'} },
                         &{ "${do_csp}_base64" } ($content);
                }
            }
        }
        else {
            $content = '';
        }

        $HTML::Packer::reggrp_ws->exec (\$opening);
        $HTML::Packer::reggrp_ws->exec (\$closing);

        return "$opening$content$closing";
    };

    $self->{"_reggrp_$HTML::Packer::GLOBAL_REGGRP"} = Regexp::RegGrp->new ({
        reggrp => $self->{$HTML::Packer::GLOBAL_REGGRP}{reggrp_data},
        restore_pattern => qr/<!--~(\d+)~-->/,
    });

    return $self;
}

sub minify {
    my $self = shift;
    my (undef, $opts) = @_;

    %csp = ();

    $self->do_csp ($opts->{do_csp})
        if 'HASH' eq ref $opts and defined $opts->{do_csp};

    $do_csp = $self->do_csp;

    return $self->SUPER::minify (@_);
}

sub do_csp {
    my ($self, $value) = @_;
    return $self->{_do_csp} = $value
        if defined $value and grep $value eq $_, @CSP_OPTS;
    return $self->{_do_csp};
}

sub csp {
    my $self = shift;

    return unless $do_csp and %csp;

    return (
        'script-src' => [map "'$do_csp-$_='", @{ $csp{'script-src'} }],
        'style-src' => [map "'$do_csp-$_='", @{ $csp{'style-src'} }],
    );
}

1;

__END__

=encoding utf8

=head1 NAME

HTML::Packer::CSP - CSP-friendly frontend to HTML::Packer

=head1 VERSION

0.2

=head1 SYNOPSIS

    use HTML::Packer::CSP;

    my $packer = HTML::Packer::CSP->init;

    $packer->minify ($scalarref, $opts);
    my %csp = $packer->csp; # overwritten by each minify call!

=head1 DESCRIPTION

L<HTML::Packer> often processes, or at least passes through unmodified,
embedded C<E<lt>scriptE<gt>> and C<E<lt>styleE<gt>> tags within the HTML code.

These tags break under any of the “safe,” i.e., not C<unsafe> prefixed, CSPs
for C<script-src> and C<style-src>, unless a nonce or a hash is provided.

This module is an attempt to remedy this situation by exposing a SHA256 hash
in a CSP-friendly format for each C<E<lt>scriptE<gt>> and C<E<lt>styleE<gt>>
tag, so C<unsafe> CSP policies do not have to be used.

=head1 LIMITATION

To keep things simple, we only offer a hashes, and not nonces.

Nonces also make each server response unique, thereby hindering caching, or
worse, introducing caching-related vulnerabilities where dumb proxy servers
are involved.

=head1 CONSTRUCTOR

=head2 C<init>

Overloaded with the magic necessary to make C<csp> work.

=head1 METHODS

Refer to my C<parent>, L<HTML::Packer>, in addition to the following:

=head2 C<minify>

Overloaded to deal with C<do_csp> option, that lets the user choose a hash
algorithm.

This should go if upstream accepts the patch.

=head2 C<csp>

Returns a hash that looks like this:

    (
        'script-src' => [qw( sha256-...= sha256-...= )],
        'style-src'  => [qw( sha256-...= sha256-...= )],
    )

with each element of the C<ARRAY>refs containing a CSP-friendly hash for a
C<E<lt>scriptE<gt>> or C<E<lt>styleE<gt>> tag.

=head2 C<do_csp>

Defines hash algorithm for CSP hashes of embedded C<E<lt>scriptE<gt>> and
C<E<lt>styleE<gt>> tags.

Allowed values are C<'sha256'>, C<'sha384'>, C<'sha512'>.

It may be left blank or set to a Perl false value to indicate that hashes
should not be calculated, if performance is a concern.

=head1 AUTHOR

All due credits to the original authors, maintainers, and contributors of
L<HTML::Packer> and dependencies, alongwith the following:

    Ankit Pati (ANKITPATI) <contact@ankitpati.in>

=head1 COPYRIGHT

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

    Copyright © 2019 Ankit Pati.

=cut
