#!/usr/bin/perl
#

use strict;
use Apache::OneTimeDownload;
use Apache::FakeRequest ();
use Test::More tests => 1;

my $request = Apache::FakeRequest->new(
	path_info => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
);

my $status = Apache::OneTimeDownload::handler( $request );

is( $status, '404', "Too-short key returns a 404" );

