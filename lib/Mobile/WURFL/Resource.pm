package Mobile::WURFL::Resource;

use 5.008004;
use strict;
use warnings;
use Carp;
use Data::Dumper; # FIXME

use XML::LibXML;
use BerkeleyDB ;
use Storable qw/freeze/;
use LWP::Simple;
use File::Temp qw/ :POSIX /;
use File::Copy qw/ move /;

use base 'Mobile::WURFL::Base';

our $VERSION = '0.01';

sub parsed_data {

  $_[0]->{'parsed_data'} = $_[1] if @_ > 1;
  $_[0]->{'parsed_data'};
}

sub parsed {

  $_[0]->{'parsed'} = $_[1] if @_ > 1;
  $_[0]->{'parsed'};
}

sub version_fields {

  sort keys %{ $_[0]->parsed_data->{fields}{ version } };
}

sub version {

  $_[0]->parsed_data->{ version };
}

sub attribute_fields {

  sort keys %{ $_[0]->parsed_data->{fields}{ attributes } };
}

sub capability_fields {

  sort keys %{ $_[0]->parsed_data->{fields}{ capabilities } };
}

sub update {

  my ($self, $uri, $xml) = @_;

  $uri ||= $self->wurfl_uri;
  $xml ||= $self->wurfl_xml;
  my $tmp_name = tmpnam().".$$";

  my $rc = LWP::Simple::getstore( $uri, $tmp_name);

  if ($rc == 200) {
    $self->error(0);
    move($tmp_name, $xml) or die "can't move $tmp_name to $xml: $!";
  } else {
    $self->error(1);
    $self->error_message("$rc");
  }

  return $rc == 200 ? 1 : 0;
}

sub parse {

  my ($self, $xml) = @_;

  $self->parsed(0);
  
  my $o = {};
  
  eval {
    my $parser = XML::LibXML->new();
    my $doc = $parser->parse_file( $xml || $self->wurfl_xml );
    
    my ($wurfl) = $doc->getElementsByTagName('wurfl');
    
    my ($version) = $wurfl->getElementsByTagName('version');
    foreach my $field (qw/ver last_updated official_url/) {
      $o->{version}{$field} = $version->getElementsByTagName($field)->[0]->textContent;
      $o->{fields}{version}{ $field }++;
    }
    
    my ($devices) = $wurfl->getElementsByTagName('devices');
    foreach my $device ( $devices->childNodes ) {
      next unless $device->nodeName eq 'device';
      my $device_id = $device->getAttribute( 'id' );
      my $user_agent = $device->getAttribute( 'user_agent' );
      $o->{user_agents}{$user_agent} = $device_id;
      
      foreach my $attribute ( $device->attributes ) {
        my $name = $attribute->nodeName;
        $o->{devices}{$device_id}{attributes}{ $name } = $attribute->getValue;
        $o->{fields}{attributes}{ $name }++;
      }
      
      foreach my $group ( $device->childNodes ) {
        next unless $group->nodeName eq 'group';
        #my $group_id = $group->getAttribute( 'id' );
        
        foreach my $capability ( $group->childNodes ) {
          next unless $capability->nodeName eq 'capability';
          my $name =  $capability->getAttribute( 'name' );
          $o->{devices}{$device_id}{capabilities}{ $name } = $capability->getAttribute( 'value' );
          $o->{fields}{capabilities}{ $name }++;
        }
      }
    }

  };
  
  if ($@) {
    $self->error(1);
    $self->error_message("$@");
    $self->parsed(0);
  } else {
    $self->error(0);
    $self->parsed_data( $o );
    $self->parsed(1);
  }
  
  return $self->error;
}


sub create_bdb {

  my ($self, $bdb) = @_;

  unless ($self->parsed) {
    $self->error(1);
    $self->error_message('no data parsed');
    return 0;
  }

  my $tmp_name = tmpnam().".$$";

  my $db_version = BerkeleyDB::Btree->new(
    -Filename => $tmp_name,
    -Subname  => 'version',
    -Flags    => DB_CREATE
  ) or die "Cannot open file $tmp_name: $!: $BerkeleyDB::Error" ;

  while (my ($field, $value) = each %{ $self->version }) {
    print "<v>$field: $value\n";
    $db_version->db_put( $field, $value );
  }

  $db_version->db_close;

  my $db_capabilities = BerkeleyDB::Btree->new(
    -Filename => $tmp_name,
    -Subname => 'capabilities',
    -Flags   => DB_CREATE
  ) or die "Cannot open file $tmp_name: $!: $BerkeleyDB::Error" ;

  foreach my $capability ($self->capability_fields) {
    $db_capabilities->db_put( $capability, 1 );
  }
  
  $db_capabilities->db_close;

  my $db_attributes = BerkeleyDB::Btree->new(
    -Filename => $tmp_name,
    -Subname => 'attributes',
    -Flags   => DB_CREATE
  ) or die "Cannot open file $tmp_name: $!: $BerkeleyDB::Error" ;

  foreach my $attribute ($self->attribute_fields) {
    $db_attributes->db_put( $attribute, 1 );
  }

  $db_attributes->db_close;
  
  my $tmp_name_map = tmpnam().".$$";

  my $db_map = BerkeleyDB::Btree->new(
    -Filename => $tmp_name_map,
    -Flags   => DB_CREATE
  ) or die "Cannot open file $tmp_name_map: $!: $BerkeleyDB::Error" ;

  my $tmp_name_data = tmpnam().".$$";

  my $db_devices = BerkeleyDB::Btree->new(
    -Filename => $tmp_name_data,
    -Flags   => DB_CREATE
  ) or die "Cannot open file $tmp_name_data: $!: $BerkeleyDB::Error" ;

  my $count = 0;
  my $error;
  my $o = $self->parsed_data;

  while (my ($user_agent, $device_id) = each %{ $o->{user_agents} }) {

    my %final;
    my $current_id = $device_id;
    $final{attributes} = $o->{devices}{$device_id}{attributes};

    my $stop = 0;
    while (not $stop) {

      my $current = $o->{devices}{$current_id};

      while (my ($name, $value) = each %{ $current->{capabilities} }) {
        $final{capabilities}{$name} = $value
        unless (defined $final{capabilities}{$name});
      }

      $stop++ if $current->{attributes}{id} eq 'generic';
      $current_id = $current->{attributes}{fall_back};
    }

    $error = $db_map->db_put("-$user_agent", $device_id);
    confess "map_ua/db_put: $!: $BerkeleyDB::Error\n" if $error;

    $error = $db_devices->db_put($device_id, freeze \%final);
    confess "devices/db_put: $!: $BerkeleyDB::Error\n" if $error;

    if ($count % 250 == 0) {
      $error = $db_devices->db_sync;
      confess "devices/db_sync: $!: $BerkeleyDB::Error\n" if $error;

      $error = $db_map->db_sync;
      confess "map_ua/db_sync: $!: $BerkeleyDB::Error\n" if $error;
    }

    $count++;
  }

  $db_devices->db_sync;
  $db_devices->db_close;

  $db_map->db_sync;
  $db_map->db_close;

  $bdb ||= $self->wurfl_bdb;

  move($tmp_name, "$bdb/wurfl.db") or die "$bdb/wurfl.db: $!";
  move($tmp_name_map, "$bdb/wurfl_map.db") or die "$bdb/wurfl_map.db: $!";
  move($tmp_name_data, "$bdb/wurfl_data.db") or die "$bdb/wurfl_data.db: $!";

  return 1;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mobile::WURFL::Resource - WURFL Resource

=head1 SYNOPSIS

  #!/usr/bin/perl
  # use this to bootstrap a WURFL database
  use Mobile::WURFL::Resource;
  
  my $resource = Mobile::WURFL::Resource->new;
  print "where are our BDBs? ", $resource->wurfl_bdb, "\n";
  print "where is our WURFL XML file? ", $resource->wurfl_xml, "\n";
  
  if (not -e $xml_file) {
    $resource->update;
    die sprintf "%s",  if $resource->error;
  }
  
  $resource->parse;
  die sprintf( "parse error: %s\n", $resource->error_message) if $resource->error;
  
  print join "\n -", 'attributes:', $resource->attribute_fields, "\n";
  print join "\n -", 'capabilities:', $resource->capability_fields, "\n";
  
  print "saved? ", $resource->create_bdb, "\n";

=head1 DESCRIPTION

This class provides some methods to retrieve a WURFL Resource, a simple XML file, from a remote server,
parse and save it into a BerkeleyDB for later uses.

=over 12

=item C<new>

Accepts a reference to a hash with following parameters:

=over 6

=item C<wurfl_uri>

...

=item C<wurfl_xml>

...

=item C<wurfl_bdb>

...

=back

=item C<update>

tries to retrieve a new copy of the remote resource file; sets C<error> as needed.


=item C<error>

true if some error occurred.


=item C<error_message>

a possibly meaningful message explaining what happened.


=item C<parse>

parse the resource pointed by C<wurfl_xml>; sets C<error> as needed.

=item C<parsed>

true if some data was parsed .

=item C<create_bdb>

saves parsed informations into some BerkeleyDB archives.

=back


=head1 TO DO

Use eval {} inside C<create_bdb> to intercept fatal errors and set an error
message.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>ws-vas@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
