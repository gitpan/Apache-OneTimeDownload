#!/usr/bin/perl
#

use strict;
use Apache::OneTimeDownload;
use Apache::FakeRequest ();
use Test::More tests => 4;
use MLDBM qw(DB_File);

# Over-ride dir_config stuff
{
	*Apache::FakeRequest::dir_config = sub {
		
		my $class = shift;
		my $key = shift;

		my %config = ( OneTimeDb => 't/db.db', OneTimeWindow => '3600' );

		return $config{ $key };

	};

	*Apache::FakeRequest::lookup_file = sub {

		return Apache::FakeRequest->new()

	};

	*Apache::FakeRequest::run = sub { 1 }
	
}


my $request = Apache::FakeRequest->new(
	path_info => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
	dir_config => 't/db.db'
);

my %db;

ok( (tie %db, "MLDBM", 't/db.db'), "t/db.db appears to have been tied");
$db{'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'} = { expires => ( time() + (3600*24) ) };
untie %db;

my $status = Apache::OneTimeDownload::handler( $request );

ok( (tie %db, "MLDBM", 't/db.db'), "t/db.db appears to have been tied");

ok( ( $db{'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'}->{expires} < time() + (3600*2) ),
	"Expiry reduced to less than two hours away" );
ok( ( $db{'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'}->{expires} > time()  ),
	"Expiry is still some time in the future" );



