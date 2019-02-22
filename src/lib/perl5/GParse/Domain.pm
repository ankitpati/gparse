#!/usr/bin/env perl

package GParse::Domain;

use strict;
use warnings;

# UTF8 for Source Code, and File Handles
use utf8;
use open qw(:std :utf8);
use Unicode::UTF8 qw(decode_utf8);

use base qw(Exporter);
our @EXPORT_OK = qw(is_rulable is_public_suffix is_subdomain
                    parts_as_list parts_as_hash all_as_hash
                    get_domain_name get_root_domain
                    scheme username password hostname port path query anchor);

use Carp               qw(croak);
use LWP::Simple        qw(get);
use Net::IDN::Encode   qw(domain_to_unicode);
use Net::IDN::Nameprep qw(nameprep);

use constant {
    SUFFIX_LIST      => 'https://publicsuffix.org/list/public_suffix_list.dat',
    SUFFIX_FILE      => '/tmp/gparse-public-suffix-list.dat',
    REFRESH_INTERVAL => 60 * 60 * 24, # one day in seconds
    IMPROBABLE_SUBDOMAIN => 'xyzzy---improbable---subdomain',

    STRIP_URL => qr{^[\s.]*|[\s.]*$}, # Leading & trailing whitespace & dots.
    SPLIT_URL => qr{^(?:      # At the beginning, search for
        (?:
            (  [^:.]*    ):   # scheme followed by :
            (?![^:/\\]*\@)    # but not followed by @ unless preceded by : / \
        )?

        (?: [/\\]* )?         # protocol slashes

        (?: ([^\@/]*) \@)?    # username and/or password, followed by @

        (   [^:/\\?\#]+    )  # the hostname cannot contain : / \ ? #

        (?:  :    (   \d*) )? # :, and digits after that,
        (   [/\\]  [^?#]*  )? # / \, and anything but ? or # after that,
        (?:  \?   ( [^#]*) )? # ?, and anything but # after that,
        (?:  \#   (    .*) )? # #, and anything after that,
    )$}x,                     # and no more, or we have bogus data.
};

our $VERSION = '2.0.0';

my @suffixes;
my $last_fetched = 0;

my %cached_roots;
    # get_root_domains is expensive enough to justify maintaining a cache

sub _ensure_object {
    my $thing = shift;
    return ref $thing ? $thing : __PACKAGE__->new ( $thing );
}

sub _public_suffixes {
    my $time = time;

    return if $time - $last_fetched <= REFRESH_INTERVAL;
                        # shortcut return to avoid expensive disk access

    %cached_roots = ();
        # clear out the root domains cache

    my $timestamp;

    my $suffix_file;
    open $suffix_file, '<', SUFFIX_FILE and
        ($timestamp) = <$suffix_file> =~ /fetched.+?(\d+)/i;
                                          # look for the word 'fetched' on the
                                          # first line, followed by a UNIX
                                          # timestamp on the same line

    $timestamp //= 0;

    my $time_difference = $time - $timestamp;

    if ($time_difference > REFRESH_INTERVAL || $time_difference < 0) {
        close $suffix_file if $suffix_file;
            # ignore the existing suffix file, if it was existing at all

        my $suffix_list = get SUFFIX_LIST
            or die "Could not fetch ${\(SUFFIX_LIST)}!\n";

        #$suffix_list =~
         #s{// ===BEGIN PRIVATE DOMAINS===.*?// ===END PRIVATE DOMAINS===}{}gs;
               # some defensive programming to deal with multiple PRIVATE
               # sections in the file, and also account for them moving around
               # instead of always being appended at the end, like they
               # currently are, as on 13 Jun 2018

        $suffix_list =~ s{(?://|#).*?$}{}gm;
                                   # discard anything following a //, #

        $suffix_list =~ s/^\s+|\s+$//;
                                   # discard leading and trailing whitespace

        $suffix_list =~ s/\s+/\n/g;
                                   # replace multiple whitespaces with newline

        #$suffix_list =~ s/([^.!*\n]+)/${\(nameprep $1)}/gm;
                                    # nameprep everything that is not . ! * \n
                                # commented out because it is performance
                                # intensive, and we trust
                                # Mozilla to Do The Right Thing;
                                # uncomment when this assumption changes

        $suffix_list =~ s/\./\\./g;
                                    # replace . with \.

        $suffix_list =~ s/\*/[^.]+?/g;
                                    # replace * with [^.]+?
                                                        # match anything but .

        @suffixes = split /\n/, $suffix_list;

        open $suffix_file, '>', SUFFIX_FILE
            or die "Could not open ${\(SUFFIX_FILE)} for writing!\n";

        print $suffix_file "// Fetched by GParse at $time.\n";
        print $suffix_file $suffix_list;

        close $suffix_file;

        $last_fetched = $time;
    }
    else {
        @suffixes = <$suffix_file>;
            # read in the whole file at once; there is much regex to do

        chomp foreach @suffixes;

        close $suffix_file;

        $last_fetched = $timestamp;
    }

    return;
}

sub _sanitize_url {
    my $url = shift;
    return unless $url;

    croak "Not an object method!\n" if ref $url;

    $url =~ s/${\(STRIP_URL)}//g;

    my ($scheme, $userpass, $hostname, $port, $path, $query, $anchor)
        = $url =~ SPLIT_URL;

    $scheme   //= '';
    $userpass //= '';
    $hostname //= '';
    $port     //= '';
    $path     //= '';
    $query    //= '';
    $anchor   //= '';

    my ($username, $password) = split /:/, $userpass;
    $username //= '';
    $password //= '';

    $hostname = eval { domain_to_unicode nameprep $hostname };
    croak "Could not parse hostname!\n"
        if !$hostname || $hostname =~ /\.\./ || $hostname =~ /\s/;
                                        # catch malformed Unicode and Punycode
                                        #
                                        # '..' and ' ' get through all other
                                        # defenses; must be caught separately

    return wantarray ? ($scheme, $username, $password, $hostname,
                        $port, $path, $query, $anchor) : $hostname;
}

sub scheme {
    my $self = _ensure_object @_;
    return $self->{scheme} // '';
}

sub username {
    my $self = _ensure_object @_;
    return $self->{username} // '';
}

sub password {
    my $self = _ensure_object @_;
    return $self->{password} // '';
}

sub hostname {
    my $self = _ensure_object @_;
    return $self->{hostname} // '';
}

sub port {
    my $self = _ensure_object @_;
    return $self->{port} // '';
}

sub path {
    my $self = _ensure_object @_;
    return $self->{path} // '';
}

sub query {
    my $self = _ensure_object @_;
    return $self->{query} // '';
}

sub anchor {
    my $self = _ensure_object @_;
    return $self->{anchor} // '';
}

sub parts_as_list {
    my $self = _ensure_object @_;
    return ($self->scheme, $self->username, $self->password, $self->hostname,
            $self->port, $self->path, $self->query, $self->anchor);
}

sub parts_as_hash {
    my $self = _ensure_object @_;

    my %hash;
    @hash{qw( scheme username password hostname port path query anchor )}
        = ($self->scheme, $self->username, $self->password, $self->hostname,
           $self->port, $self->path, $self->query, $self->anchor);

    return %hash;
}

sub all_as_hash {
    my $self = _ensure_object @_;

    my %hash = $self->parts_as_hash;

    @hash{qw( is_rulable is_public_suffix is_subdomain domain public_suffix )}
        = ($self->is_rulable, $self->is_public_suffix, $self->is_subdomain,
           $self->get_domain_name, $self->get_root_domain);

    return %hash;
}

sub get_root_domain {
    my $self = _ensure_object @_;
    return unless $self->hostname;

    my $hostname = $self->hostname;

    _public_suffixes;

    return $cached_roots{$hostname} if exists $cached_roots{$hostname};

    my $longest_suffix = '';
    foreach my $suffix (@suffixes) {
        if (my ($exclude) = $suffix =~ /!(.*)$/) {
            return $cached_roots{$hostname} = ($exclude =~ /^[^.]+\.(.*)$/)[0]
                if $hostname =~ /(?:^|\.)$exclude$/;
                                # if suffix is an exclusion pattern, and
                                # domain matches it, effective TLD is
                                # one level below the suffix
        }
        elsif ($hostname =~ /(?:^|\.)($suffix)$/i) {
                                # anchoring and case-insensitivity are
                                # non-negotiable for security, and therefore
                                # done in code, and not in the list of
                                # suffix regexes

            $longest_suffix = $1
                if length $hostname > length $longest_suffix;
        }
    }

    return $cached_roots{$hostname}
                = length $hostname != length $longest_suffix && $longest_suffix;
                            # if domain is as long as the longest matched
                            # suffix, it is an effective TLD
}

sub get_domain_name {
    my $self = _ensure_object @_;

    my $root = $self->get_root_domain;
    return unless $root;

    return ($self->hostname =~ /([^.]+\.\Q$root\E)$/)[0];
}

sub is_rulable { return !!get_root_domain @_ }

sub is_public_suffix {
    my $self = _ensure_object @_;
    return unless $self->hostname;
    return $self->hostname eq __PACKAGE__->new
              ( IMPROBABLE_SUBDOMAIN.'.'.$self->hostname )->get_root_domain;
}

sub is_subdomain {
    my $self = _ensure_object @_;
    return unless $self->hostname;

    (my $hostname = $self->hostname) =~ s/^[^.]+\.//;
                                # strip away the 'www.' from 'www.example.com'

    return __PACKAGE__->new ( $hostname )->is_rulable;
            # a subdomain must be rulable after stripping away
            # the hostname, otherwise it is not a subdomain
}

sub new {
    my ($class, $url) = @_;

    my %self;
    @self{qw( scheme username password hostname port path query anchor )}
        = eval { _sanitize_url $url };

    return bless \%self, $class;
}

sub main {
    @ARGV or die "Usage:\n\t${\(split m|/|, $0)[-1]} [url]...\n";

    # UTF8 for Command Line Arguments
    @ARGV = map { decode_utf8 $_ } @ARGV unless utf8::is_utf8 $ARGV[0];

    foreach my $url (@ARGV) {
        my $bud = __PACKAGE__->new ($url);

        my @parts = $bud->parts_as_list;

        my $is_rulable       = $bud->is_rulable       ? 'Yes' : 'No';
        my $is_public_suffix = $bud->is_public_suffix ? 'Yes' : 'No';
        my $is_subdomain     = $bud->is_subdomain     ? 'Yes' : 'No';

        my $domain_name   = $bud->get_domain_name;
        my $public_suffix = $bud->get_root_domain;
        my $hostname      = $bud->hostname       ;

        my @details;

        push @details, "Rulable? $is_rulable"            ;
        push @details, "Public Suffix? $is_public_suffix";
        push @details, "Sub Domain? $is_subdomain"       ;

        push @details, "Domain: $domain_name"          if $domain_name;
        push @details, "Public Suffix: $public_suffix" if $public_suffix;

        local $" = ', ';
        print "$url -> @details\n\t@parts\n";
    }
}

main unless caller;

1;

__END__

=encoding utf8

=head1 NAME

GParse::Domain - domain-name utilities.

=head1 VERSION

13.0.0

=head1 SYNOPSIS

    use GParse::Domain;

    my $domain = 'foo.bar.co.uk';

    my $bud = GParse::Domain->new ( $domain );
    printf "%s %s a TLD or ccSLD or similar.\n",
        $domain,
        $bud->is_public_suffix ? 'is' : 'is not';

    # OR

    printf "%s %s a TLD or ccSLD or similar.\n",
        $domain,
        GParse::Domain->is_public_suffix($domain) ? 'is' : 'is not';

=head1 DESCRIPTION

This is a collection of domain name utilities. There are probably better
versions of these somewhere on CPAN, but L<Domain::PublicSuffix> is not one
of them.

Nothing is exported; everything should be called as an object method.

For compatibility with the old L<GParse::Domain> interface, subroutines
may also be called as class methods.

=head1 RISKS

The public suffix list is, well, public:  L<https://publicsuffix.org>

There is no special reason to trust Mozilla on this, so we should be at least
a little careful with the list data.

For starters, the C<PRIVATE DOMAINS> have been eliminated as they were
blatantly insecure for our purposes, and could be added to by anyone with a
GitHub account, including spammers.

For good measure, we now look for and eliminate multiple C<PRIVATE DOMAINS>
sections.

=head1 CONSTRUCTOR

=head2 C<new ($uri_fragment)>

Saves repeated computation because URIs will often be evaluated against
multiple C<is_*> methods of this module at a time.

Pre-sanitizes the URI, as this is a very expensive operation, and returns an
object that can be questioned via the methods below.

Preffered means of interacting with the new L<GParse::Domains>; the old
way is only provided for compatibility and should be removed later as it comes
with a performance penalty.

=head1 METHODS

The methods below do not take the C<$uri_fragment> argument when called as
object methods. They only need it when called as class methods.

They will C<croak> if called as object methods with the C<$uri_fragment>.

=head2 C<get_root_domain ($uri_fragment)>

Given a URI, return the parsed root domain name.

=over

=item C<www.example.co.uk>

=item C<http://www.example.co.uk/foobar?param1=val1&param2=val2>

=back

Returns the empty string, C<''>, if domain is:

=over

=item B<Effective TLD>

The domain is an effective TLD, and therefore does not have a root domain,
because it is itself a root domain.

=item B<Non-Existent TLD>

The domain simply cannot exist, because it does not match any known TLD.

=back

Returns C<undef> only if an error occurs while parsing.

=head2 C<get_domain_name ($uri_fragment)>

Given a URI, return the parsed registrable domain name.

=over

=item C<www.example.co.uk> C<example.co.uk>

=item C<test.example.ck> C<test.example.ck>

=back

Returns the empty string, C<''>, if domain does not have a root domain.

Returns C<undef> only if an error occurs while parsing.

=head2 C<hostname ($uri_fragment)>

Given a URI, return the parsed hostname.

=over

=item C<www.example.co.uk> C<www.example.co.uk>

=item C<http://www.example.co.uk/foobar> C<www.example.co.uk>

=back

Returns C<undef> if an error occurs while parsing.

=head2 C<is_public_suffix ($uri_fragment)>

Returns true if the domain in the URI fragment is a "public suffix" such as:

=over

=item C<co.uk>

=item C<co.uk/foobar>

=back

Returns C<undef> only if an error occurs while parsing.

=head2 C<is_rulable ($uri_fragment)>

Returns true if blacklisting or whitelisting rules should be allowed on the
domain in the URI.

=over

=item C<example.co.uk>

=item C<ftp://www.example.co.uk/>

=back

Can be used to ensure that overly broad rules cannot be created on an
effective TLD, and useless rules cannot be created for non-existent domains.

=head2 C<is_subdomain ($uri_fragment)>

Returns true if the domain in the URI fragment is a "subdomain," meaning
not a public suffix (TLD, ccSLD, etc), but still suffixed by a valid
public suffix.

=over

=item C<www.example.co.uk>

=item C<sftp://www.example.co.uk/foobar>

=back

Returns C<undef> only if an error occurs while parsing.

=head1 FEATURES

=head2 Data Source

L<The Mozilla Public Suffix List|https://publicsuffix.org/list/public_suffix_list.dat>

=head1 AUTHOR

Ankit Pati

=head1 TODO

=over

=item Keep the private stuff but mark it as such so we can use it.

=item Drop the old I<Class-Oriented> Interface

We currently support both the Object-Oriented, and the old Class-Oriented
interfaces. Once we have migrated all users of this module to OO, stop
supporting the Class-Oriented interface.

=back

=head1 COPYRIGHT

    Copyright © 2019. Licensed under the GNU GPLv3.

=cut
