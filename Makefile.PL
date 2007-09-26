use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'Mobile::WURFL',
  VERSION_FROM      => 'lib/Mobile/WURFL.pm',
  PREREQ_PM         => {
    BerkeleyDB  => 0,
    XML::LibXML => 0,
    File::Copy  => 0,
    File::Temp  => 0,
    LWP::Simple => 0,
    Storable    => 0,
  },
  ($] >= 5.005 ? ## Add these new keywords supported since 5.005
 (ABSTRACT_FROM  => 'lib/Mobile/WURFL.pm', # retrieve abstract from module
  AUTHOR         => 'Valerio VALDEZ Paolini <valdez@pan.org>') :
  ()
 ),
);
