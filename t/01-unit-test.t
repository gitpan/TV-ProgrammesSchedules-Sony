#!perl

use strict; use warnings;
use TV::ProgrammesSchedules::Sony;
use Test::More tests => 9;

my ($tv);

eval { $tv = TV::ProgrammesSchedules::Sony->new(location => 'en-gb'); };
like($@, qr/ERROR: Input param has to be a ref to HASH./);

eval { $tv = TV::ProgrammesSchedules::Sony->new({xyz => 'en-gb'}); };
like($@, qr/ERROR: Missing key location./);

eval { $tv = TV::ProgrammesSchedules::Sony->new({location => 'en-gbx'}); };
like($@, qr/ERROR: Invalid value for location./);

eval { $tv = TV::ProgrammesSchedules::Sony->new({location => 'en-gb', yyyy => 2011}); };
like($@, qr/ERROR: Missing key mm from input hash./);

eval { $tv = TV::ProgrammesSchedules::Sony->new({location => 'en-gb', yyyy => 2011, mm => 4}); };
like($@, qr/ERROR: Missing key dd from input hash./);

eval { $tv = TV::ProgrammesSchedules::Sony->new({location => 'en-gb', mm => 4}); };
like($@, qr/ERROR: Missing key yyyy from input hash./);

eval { $tv = TV::ProgrammesSchedules::Sony->new({location => 'en-gb', yyyy => 2011, mm => 4}); };
like($@, qr/ERROR: Missing key dd from input hash./);

eval { $tv = TV::ProgrammesSchedules::Sony->new({location => 'en-gb', dd => 4}); };
like($@, qr/ERROR: Missing key yyyy from input hash./);

eval { $tv = TV::ProgrammesSchedules::Sony->new({location => 'en-gb', yyyy => 2011, dd => 11}); };
like($@, qr/ERROR: Missing key mm from input hash./);