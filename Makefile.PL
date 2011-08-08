use strict;use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'TV::ProgrammesSchedules::Sony',
    AUTHOR        => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM  => 'lib/TV/ProgrammesSchedules/Sony.pm',
    ABSTRACT_FROM => 'lib/TV/ProgrammesSchedules/Sony.pm',
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'TV-ProgrammesSchedules-Sony-*' },
    PREREQ_PM     => {
        'Test::More'      => 0,
        'Readonly'        => '1.03',
        'Time::localtime' => '1.02',
        'HTTP::Request'   => '1.40',
        'LWP::UserAgent'  => '2.33',
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
);