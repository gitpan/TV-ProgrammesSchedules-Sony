package TV::ProgrammesSchedules::Sony;

use strict; use warnings;

use overload q("") => \&as_string, fallback => 1;

use Carp;
use Readonly;
use Data::Dumper;
use LWP::UserAgent;
use Time::localtime;
use HTTP::Request::Common;

=head1 NAME

TV::ProgrammesSchedules::Sony - Interface to Sony TV Programmes Schedules.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

Readonly my $BASE_URL  => 'http://www.setasia.tv';
Readonly my $LOCATIONS => 
{    
    'en-au' => 'Australia',
    'en-ca' => 'Canada',
    'en-nz' => 'New Zealand',
    'en-pk' => 'Pakistan',
    'en-za' => 'South Africa',
    'en-gb' => 'UK & Europe',
    'en-ae' => 'United Arab Emirates',
    'en-us' => 'USA'
};

=head1 SYNOPSIS

Sony Entertainment Television  was launched in the Indian sub-continent and the Middle East in 
October 1995. The channel is a joint partnership between Sony Pictures Entertainment and Argos 
Communications Enterprises a Singapore based entertainment company specialising in South Asian 
program production and media services.

As a result of the rapid and considerable success that Sony Entertainment Television enjoyed in 
the Indian sub-continent and the Middle East, the decision was taken to establish international 
feeds  known as Sony Entertainment Television Asia. Major operations encompass the UK & Europe, 
the USA, Africa and Australasia.

The  channel  is  now  available  throughout the world - a truly global operation bringing high 
quality entertainment to South Asians everywhere.

=head1 CONSTRUCTOR

The constructor expects a reference to an anonymous hash as input parameter. Table below shows 
the possible value of various keys (location, yyyy, mm, dd). The yyyy, mm and dd are optional. 
If missing picks up the current year, month and day. Currently covers SetAsia ONLY.

However plans are to cover others like SetIndia, MAXtelevision, SABTV, MAX Asia.

    ----------------------------------------------------
    | Name                 | Location | YYYY | MM | DD |
    ----------------------------------------------------
    | Australia            |   en-au  | 2011 |  4 |  7 |
    | Canada               |   en-ca  | 2011 |  4 |  7 |
    | New Zealand          |   en-nz  | 2011 |  4 |  7 |
    | Pakistan             |   en-pk  | 2011 |  4 |  7 |
    | South Africa         |   en-za  | 2011 |  4 |  7 |
    | UK & Europe          |   en-gb  | 2011 |  4 |  7 |
    | United Arab Emirates |   en-ae  | 2011 |  4 |  7 |
    | USA                  |   en-us  | 2011 |  4 |  7 |
    ----------------------------------------------------    

=cut

sub new
{
    my $class = shift;
    my $param = shift;
    
    _validate_param($param);
    $param->{_browser} = LWP::UserAgent->new();
    unless (defined($param->{yyyy}) && defined($param->{mm}) && defined($param->{dd}))
    {
        my $today = localtime; 
        $param->{yyyy} = $today->year+1900;
        $param->{mm}   = $today->mon+1;
        $param->{dd}   = $today->mday;
    }    
    bless $param, $class;
    return $param;
}

=head1 METHODS

=head2 get_url()

Prepare and return URL using the given information.

    use strict; use warnings;
    use TV::ProgrammesSchedules::Sony;
    
    my $sony = TV::ProgrammesSchedules::Sony->new({ location => 'en-gb' });
    print $sony->get_url();

=cut

sub get_url
{
    my $self = shift;
    return sprintf("%s/%s/schedule#%04d-%02d-%02d", 
            $BASE_URL, 
            $self->{location},
            $self->{yyyy}, 
            $self->{mm}, 
            $self->{dd});
}

=head2 get_listings()

Return the programmes listings for the given location. Data would be in the form of reference 
to a list containing anonymous hash with keys time, time and url for each of the programmes.

    use strict; use warnings;
    use TV::ProgrammesSchedules::Sony;
    
    my $sony     = TV::ProgrammesSchedules::Sony->new({ location => 'en-gb' });
    my $listings = $sony->get_listings();

=cut

sub get_listings
{
    my $self     = shift;
    my $url      = $self->get_url();
    my $browser  = $self->{_browser};
    my $response = $browser->request(POST $url);
    croak("ERROR: Couldn't connect to [$url].\n") 
        unless $response->is_success;
    
    my ($contents, $listings, $program, $line);
    $contents = $response->content;
    $contents = _trim($contents);
    $contents =~ /\<tbody>(.*?)\<\/tbody\>/m;
    $contents = _trim($1);
    while ($contents =~ s/\<tr class\=(.*?)\<\/tr\>//)
    {
        $program =  {};
        $line    =  _trim($1);
        $line    =~ s/\<td width\=(.*?)\<\/td>//;
        $program->{time} = _fetch_time($1);
        if ($line =~ /\<a href=\"(.*?)\"\>(.*)\<\/a\>/)
        {
            $program->{url}   = sprintf("%s%s", $BASE_URL, $1);
            $program->{title} = _trim($2);
        }
        elsif ($line =~ /\<td class=\"text\">(.*?)\<\/td\>/)
        {
            $program->{title} = _trim($1);
        }
        push @$listings, $program;
    }
    return $listings;
}

=head2 as_string()

Returns listings in a human readable format.

    use strict; use warnings;
    use TV::ProgrammesSchedules::Sony;

    my $sony = TV::ProgrammesSchedules::Sony->new({ location => 'en-gb' });

    print $sony->as_string();

    # or even simply
    print $sony;

=cut

sub as_string
{
    my $self = shift;
    my ($listings);
    
    $self->{listings} = $self->get_listings()
        unless defined($self->{listings});

    foreach (@{$self->{listings}})
    {
        $_->{url} = 'N/A' unless defined($_->{url});
        $listings .= sprintf("  Start Time: %s\n", $_->{time});
        $listings .= sprintf("       Title: %s\n", $_->{title});
        $listings .= sprintf("         URL: %s\n", $_->{url});
        $listings .= "-------------------\n";
    }
    return $listings;
}

sub _fetch_time
{
    my $data = shift;
    $data =~ /(\d\d\:\d\d\s[A|P]M)/;
    return $1;
}

sub _trim
{
    my $data = shift;
    $data =~ s/^\s+//g;
    $data =~ s/\s+$//g;
    $data =~ s/\s+/ /g;
    $data =~ s/[\n\r]//g;    
    return $data;
}

sub _validate_param
{
    my $param = shift;
    
    croak("ERROR: Input param has to be a ref to HASH.\n")
        if (ref($param) ne 'HASH');
    croak("ERROR: Missing key location.\n")
        unless exists($param->{location});
    croak("ERROR: Invalid value for location.\n")
        unless exists($LOCATIONS->{$param->{location}});
    croak("ERROR: Missing key mm from input hash.\n")
        if (defined($param->{yyyy}) && !exists($param->{mm}));
    croak("ERROR: Missing key dd from input hash.\n")
        if (defined($param->{yyyy}) && !exists($param->{dd}));
    croak("ERROR: Missing key yyyy from input hash.\n")
        if (defined($param->{mm}) && !exists($param->{yyyy}));
    croak("ERROR: Missing key dd from input hash.\n")
        if (defined($param->{mm}) && !exists($param->{dd}));
    croak("ERROR: Missing key yyyy from input hash.\n")
        if (defined($param->{dd}) && !exists($param->{yyyy}));
    croak("ERROR: Missing key mm from input hash.\n")
        if (defined($param->{dd}) && !exists($param->{mm}));
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tv-programmesschedules-sony at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TV-ProgrammesSchedules-Sony>.  
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TV::ProgrammesSchedules::Sony

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TV-ProgrammesSchedules-Sony>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TV-ProgrammesSchedules-Sony>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TV-ProgrammesSchedules-Sony>

=item * Search CPAN

L<http://search.cpan.org/dist/TV-ProgrammesSchedules-Sony/>

=back

=head1 ACKNOWLEDGEMENTS

TV::ProgrammesSchedules::Sony provides information from SetAsia official website. This information should 
be used as it is without any modifications. Sony Entertainment Television groups remain the sole owner of 
the data.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mohammad S Anwar.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 DISCLAIMER

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1; # End of TV::ProgrammesSchedules::Sony