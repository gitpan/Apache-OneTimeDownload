use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::OneTimeDownload',
    'VERSION_FROM'	=> 'OneTimeDownload.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Digest::MD5' => 0.01, 'Test::More' => 0.01, MLDBM => 0.01, 'Apache::FakeRequest' => 0.01}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'OneTimeDownload.pm', # retrieve abstract from module
       AUTHOR     => 'Pete Sergeant <onetimedownload@clueball.com>') : ()),
);
