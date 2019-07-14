package HTML::Packer::CSP;

use strict;
use warnings;

use Carp qw(croak);
use Digest::SHA qw(sha256_base64);
use Regexp::RegGrp;

use parent qw(HTML::Packer);

my $hash_algo = 'sha256';

sub csp {
    my $self = shift;

    return unless $self->{csp};

    my %csp = %{ $self->{csp} };

    $csp{'script-src'} = [map "'$hash_algo-$_='", @{ $csp{'script-src'} }];
    $csp{'style-src'} = [map "'$hash_algo-$_='", @{ $csp{'style-src'} }];

    return %csp;
}

sub minify {
    my ($self, $input, $opts) = @_;

    croak 'First argument must be a SCALARref!' if 'SCALAR' ne ref $input;

    my $html = wantarray ? ref ($input) ? $$input : $input :
                           ref ($input) ? $input : \$input ;

    if ('HASH' eq ref $opts) {
        foreach my $field (@HTML::Packer::BOOLEAN_ACCESSORS) {
            $self->$field ($opts->{$field}) if defined $opts->{$field};
        }

        $self->do_javascript ($opts->{do_javascript})
            if defined $opts->{do_javascript};
        $self->do_stylesheet ($opts->{do_stylesheet})
            if defined $opts->{do_stylesheet};
    }

    if (not $self->no_compress_comment and
        ${$html} =~ /$HTML::Packer::PACKER_COMMENT/s) {

        return wantarray ? $$html : () if $1 eq '_no_compress_';
    }

    # (re)initialize variables used in the closures
    $HTML::Packer::remove_comments = $self->remove_comments ||
                       $self->remove_comments_aggressive;
    $HTML::Packer::remove_comments_aggressive
        = $self->remove_comments_aggressive;
    $HTML::Packer::remove_newlines = $self->remove_newlines;
    $HTML::Packer::html5 = $self->html5;
    $HTML::Packer::do_javascript = $self->do_javascript;
    $HTML::Packer::do_stylesheet = $self->do_stylesheet;
    $HTML::Packer::js_packer = $self->javascript_packer;
    $HTML::Packer::css_packer = $self->css_packer;
    $HTML::Packer::reggrp_ws = $self->reggrp_whitespaces;

    # hacky way to get around ->init being called before ->minify
    $self = $self->init if $HTML::Packer::remove_comments_aggressive;

    $self->reggrp_global->exec ($html);
    $self->reggrp_whitespaces->exec ($html);
    if ($self->remove_newlines) {
        $self->reggrp_newlines_tags->exec ($html);
        $self->reggrp_newlines->exec ($html);
    }
    $self->reggrp_void_elements->exec ($html) if $self->html5;
    $self->reggrp_global->restore_stored ($html);

    return $$html if wantarray;
}

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
                && ($opening =~ /$js_type_re/i or $opening !~ /type/i)) {

                $opening =~ s` type="(text/)?(java|ecma)script"``i
                    if $HTML::Packer::html5;

                if ($HTML::Packer::js_packer and
                    $HTML::Packer::do_javascript) {

                    $HTML::Packer::js_packer->minify (\$content,
                        { compress => $HTML::Packer::do_javascript });

                    $content = "/*<![CDATA[*/$content/*]]>*/"
                        unless $HTML::Packer::html5;
                }

                {
                    no strict 'refs';
                    push @{ $self->{csp}{'script-src'} },
                         &{ "${hash_algo}_base64" } ($content);
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

                {
                    no strict 'refs';
                    push @{ $self->{csp}{'style-src'} },
                         &{ "${hash_algo}_base64" } ($content);
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

1;

__END__

=encoding utf8

=head1 NAME

HTML::Packer::CSP - CSP-friendly frontend to HTML::Packer

=head1 VERSION

0.1

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

To keep things simple, we only offer a SHA256 hash, and not any other hash or
nonce. Nonces also make each server response unique, thereby hindering
caching, or worse, introducing caching-related vulnerabilities where dumb
proxy servers are involved.

=head1 FUTURE-PROOFING

If SHA256 is ever cracked like MD5 or SHA1, simply upgrading to a secure
algorithm here is sufficient, without changing any dependent code, because
CSP takes the algorithm with the hash.

=head1 CONSTRUCTOR

=head2 C<init>

Overloaded with the magic necessary to make C<csp> work.

=head1 METHODS

Refer to my C<parent>, L<HTML::Packer>, in addition to the following:

=head2 C<minify>

Had to be overloaded due to a bug in L<HTML::Packer> whereby it uses the
C<eq __PACKAGE__> construct instead of the saner C<-E<gt>isa (__PACKAGE__)>,
thereby disallowing sub-classes from correctly functioning.

This should go if upstream fixes the underlying problem.

=head2 C<csp>

Returns a hash that looks like this:

    (
        'script-src' => [qw( sha256-...= sha256-...= )],
        'style-src'  => [qw( sha256-...= sha256-...= )],
    )

with each element of the C<ARRAY>refs containing a CSP-friendly hash for a
C<E<lt>scriptE<gt>> or C<E<lt>styleE<gt>> tag.

=head1 AUTHOR

All due credits to the original authors, maintainers, and contributors of
L<HTML::Packer> and dependencies, alongwith the following:

    Ankit Pati (ANKITPATI) <contact@ankitpati.in>

=head1 COPYRIGHT

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

    Copyright © 2019 Ankit Pati.

=cut
