
=head1 NAME

Apache::OneTimeDownload - Tolerant mechanism for expiring downloads

=head2 DESCRIPTION

Allows you to distribute files that expire a given time after
the first download

=head2 SYNOPSIS

In your Apache config:

 PerlModule Apache::OneTimeDownload
 
 <Location /download>
		PerlHandle Apache:OneTimeDownload
		SetHandler perl-script
		PerlSetVar OneTimeDb  /home/sheriff/download_access.db
		PerlSetVar OneTimeWindow 3600
		PerlSetVar OneTimeDownloadDirectory /home/sheriff/downloads/
	</Location>

Example authorize.pl...

	#!/usr/bin/perl
	
	use Apache::OneTimeURL;
	
	my $file = $ARGV[0];
	my $comment = $ARGV[1-];
	my $db = '/opt/secret/access.db'

	print Apache::OneTimeURL::authorize( $db, $comment, $file );

and then:

 % authorize.pl TopSecret.pdf Given out on IRC...
 2c61de78edd612cf79c0d73a3c7c94fb

Which might mean:

	http://www.sheriff.com/download/2c61de78edd612cf79c0d73a3c7c94fb

=head1 CONFIG

=head2 OneTimeDb

The location of the DB file where key->file mappings will be kept

=head2 OneTimeWindow

The amount of time after a download you wish the file to remain
before it expires. An hour is a good sized window...

=head2 OneTimeDownloadDirectory

The directory from which you're serving your file downloads -
probably not one that's accessible from the web...

=head1 &authorize

Adds a key to the db. Accepts these arguments, in this order:

=head2 db name

Absolute path of the database

=head2 comment

Plain text comments about the file

=head2 file

Location of the file - this has the download directory
stuck at the beginning of it when it comes to download
time...

=head2 expires

Time in seconds until the file expires before anyone
has downloaded it. Defaults to a week.

=head1 AUTHOR

Pete Sergeant -- C<onetimedownload@clueball.com>

=head1 COPYRIGHT

Copyright 2004 B<Pete Sergeant>.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

require 5;

package Apache::OneTimeDownload;

use vars qw($VERSION);

use strict;

use Apache;
use Apache::Constants;
use MLDBM qw(DB_File);
use Data::Dumper;
use Digest::MD5 qw(md5_hex);

$VERSION = '1.00';

sub handler {

    my $r = shift;

  # Read in the key we're using

    my ($key) = $r->path_info() =~ /([a-f0-9]{32})/ or return NOT_FOUND; 

  # Load our database

    my $db_name = $r->dir_config("OneTimeDb")
      or die "Database not specified in OneTimeDb!";

    my %db; tie %db, "MLDBM", $db_name
      or die "Couldn't open database $db_name: $!";

  # Does the key exist?
		
    return FORBIDDEN if !exists $db{$key};

    my $file = $db{$key};

  # Has the object expired?

    my $time_until_expiry = $file->{expires} - time();

    unless ($time_until_expiry > 0) {

        return FORBIDDEN;

    }

  # Does the object need it's expiry date shortened?

    my $window = $r->dir_config("OneTimeWindow") || 3600;

    if ( $time_until_expiry > $window ) {

      $file->{downloaded} = 1;
      $file->{expires} = ( time() + ( $window - 1 ) );
      $db{$key} = $file;

    }

    my $file_path = $r->dir_config("OneTimeDownloadDirectory") . $file->{file};

    untie %db;

  # Return the file

    my $subr = $r->lookup_file( $file_path  );

    $r->content_type( $subr->content_type );
    $r->header_out("Content-Disposition", "inline; filename='" . $file->{file} . "'");

    $r->send_http_header;

    return $subr->run;

}


sub authorize {

  my ($db_name, $comments, $file, $expiry) = @_;

  my $key = md5_hex(time().{}.rand().$$);

  my %db; tie %db, "MLDBM", $db_name or die "Couldn't open database: $!";

  $db{$key} = {

    comments   => $comments,
    expires    => $expiry || ( time() + 604800 ),
    file       => $file,
    downloaded => 0,
    count      => 0

  };

  untie %db;
  return $key;

}



1;
