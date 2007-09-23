use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mobile::WURFL',
    VERSION_FROM      => 'lib/Mobile/WURFL.pm', # finds $VERSION
    PREREQ_PM         => {
      BerkeleyDB => 0
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mobile/WURFL.pm', # retrieve abstract from module
       AUTHOR         => 'Valerio VALDEZ Paolini <valdez@pan.org>') : ()),
);