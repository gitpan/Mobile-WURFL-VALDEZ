package Mobile::WURFL;

use strict;
use warnings;
use Carp;

use BerkeleyDB ;
use Storable qw/freeze thaw/;

use Mobile::WURFL::Device;

use base 'Mobile::WURFL::Base';

our $VERSION = '0.02';


sub init {
  my $self = shift;
  
  $self->SUPER::init;

  my $metaname = 'dbase/wurfl.db';
  my $meta_db = BerkeleyDB::Btree->new(
    -Filename => $metaname,
    -Flags => DB_RDONLY
  ) or confess "Cannot open file $metaname: $!: $BerkeleyDB::Error\n";
  $self->meta_db( $meta_db );
  
  my $mapname = 'dbase/wurfl_map.db';
  my $map_db = BerkeleyDB::Btree->new(
    -Filename => $mapname,
    -Flags => DB_RDONLY
  ) or confess "Cannot open file $mapname: $!: $BerkeleyDB::Error\n";
  $self->map_db( $map_db );
  
  my $dbname = 'dbase/wurfl_data.db';
  my $data_db = BerkeleyDB::Btree->new(
    -Filename => $dbname,
    -Flags => DB_RDONLY
  ) or confess "Cannot open file $dbname: $!: $BerkeleyDB::Error\n";
  $self->data_db( $data_db );

  return $self;
}

sub meta_db {
  $_[0]->{'meta_db'} = $_[1] if @_ > 1;
  return $_[0]->{'meta_db'};
}

sub map_db {
  $_[0]->{'map_db'} = $_[1] if @_ > 1;
  return $_[0]->{'map_db'};
}

sub data_db {
  $_[0]->{'data_db'} = $_[1] if @_ > 1;
  return $_[0]->{'data_db'};
}

sub search {
  my $self = shift;
  my $uas = shift;
  
  my $device_id;
  my $found;
  
  while (not $found) {
    my $rc = $self->map_db->db_get("-$uas", $device_id);
    if ($rc == 0) {
      $found++;
    } else {
      chop $uas;
    }
  }
  
  my $buffer;
  $self->data_db->db_get($device_id, $buffer);
  my $s = thaw( $buffer );
  
  return Mobile::WURFL::Device->new({ device_data => $s });
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mobile::WURFL - List capabilities of mobile handsets using WURFL data

=head1 SYNOPSIS

  #!/usr/bin/perl
  
  use Mobile::WURFL;
  
  my $wurfl = Mobile::WURFL->new({ bdb => $bdb_dir });
  my $handset = $wurfl->search('Nokia6610');
  printf "can handle gif? %s\n", $handset->gif ? 'yes':'no', "\n";


=head1 DESCRIPTION

Beware: this is ALPHA software, not production ready!!!

The WURFL is an XML configuration file which contains information about
capabilities and features of several wireless devices. WURFL means Wireless
Universal Resource File and was created by Luca Passani and others. The official 
project site is:

  http://wurfl.sourceforge.net/
  
Mobile::WURFL provides a way to extract desired information from a WURFL
configuration file. Refer to C<Mobile::WURFL::Resource> for methods to
retrieve, parse and store a WURFL file.

A C<Mobile::WURFL> object can be used to retrive capabilities of mobile handsets;
C<Mobile::WURFL> provides the following methods:

=head3 C<new>

Accepts option in a hash reference; available options are:

=over

=item C<wurfl_bdb>

sets the directory containing BerkeleyDB databases of handsets
capabilities.

=back

=head3 C<search>

Accepts a user agent string as argument and returns a C<Mobile::WURFL::Device>.

=head1 SEE ALSO

L<Mobile::WURFL::Resource>,
L<Mobile::WURFL::Device>

=head1 AUTHOR

Valerio VALDEZ Paolini, <valdez@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Valerio VALDEZ Paolini

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
