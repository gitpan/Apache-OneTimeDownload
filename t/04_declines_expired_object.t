#!/usr/bin/perl
#

use strict;
use Apache::OneTimeDownload;
use Apache::FakeRequest ();
use Test::More tests => 2;
use MLDBM qw(DB_File);

# Over-ride dir_config stuff
{
	*Apache::FakeRequest::dir_config = sub {
		
		my $class = shift;
		my $key = shift;

		my %config = ( OneTimeDb => 't/db.db' );

		return $config{ $key };

	}
}


my $request = Apache::FakeRequest->new(
	path_info => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
	dir_config => 't/db.db'
);

my %db;

ok( (tie %db, "MLDBM", 't/db.db'), "t/db.db appears to have been tied");
$db{'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'} = { expires => 1 };
untie %db;

my $status = Apache::OneTimeDownload::handler( $request );

is( $status, '403', "Expired key returns a 403" );

