package Mobile::WURFL::Base;

use 5.008004;
use strict;
use warnings;

our $VERSION = '0.01';

use Carp;
use Data::Dumper; # FIXME


sub new {

  my $class = shift;
  my $args = shift;
  
  confess "argument must be HASHREF" if $args and ref($args) ne 'HASH';
  
  my $self = bless { }, $class;


  return $self->init( $args );
}

sub init {

  my ($self, $args) = @_;

  $self->wurfl_uri( $args->{uri} || $self->default_wurfl_uri );
  $self->wurfl_xml( $args->{xml} || $self->default_wurfl_xml );
  $self->wurfl_bdb( $args->{bdb} || $self->default_wurfl_bdb );

  return $self;
}

#sub default_wurfl_uri { 'http://www.nusho.it/wurfl/dl.php?t=d&f=wurfl.xml' }
sub default_wurfl_uri { 'http://wurfl.sourceforge.net/wurfl.xml' }
sub default_wurfl_xml { 'wurfl.xml' }
sub default_wurfl_bdb { '/tmp/' }

sub wurfl_uri {

  $_[0]->{'wurfl_uri'} = $_[1] if @_ > 1;
  $_[0]->{'wurfl_uri'};
}

sub wurfl_xml {

  $_[0]->{'wurfl_xml'} = $_[1] if @_ > 1;
  $_[0]->{'wurfl_xml'};
}

sub wurfl_bdb {

  $_[0]->{'wurfl_bdb'} = $_[1] if @_ > 1;
  $_[0]->{'wurfl_bdb'};
}

sub error {

  $_[0]->{'error'} = $_[1] if @_ > 1;
  $_[0]->{'error'};
}

sub error_message {

  $_[0]->{'error_message'} = $_[1] if @_ > 1;
  $_[0]->{'error_message'};
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mobile::WURFL::Base - Mobile::WURFL base class

=head1 SYNOPSIS

  use base 'Mobile::WURFL::Base';

=head1 DESCRIPTION

Provides common class methods to other classes.

=over 12

=item C<new>

Basic constructor, blesses an hash and calls C<init>. Accepts a hash reference.

=item C<init>

Initialize the current instance setting up some defaults using the following methods.

=item C<default_wurfl_xml>

returns the default filename for the WURFL XML file.

=item C<wurfl_xml>

holds the current filename of the WURFL XML file.

=item C<default_wurfl_bdb>

return the default directory where all WURFL BerkeleyDB data reside.

=item C<wurfl_bdb>

holds the directory where reside all WURFL BerkeleyDB data.

=item C<default_wurfl_uri>

return the default URL from where a WURFL XML file can downloaded.

=item C<wurfl_uri>

holds the current URL from where a WURFL XML file can downloaded.

=back

=head1 SEE ALSO

L<Mobile::WURFL>

=head1 AUTHOR

Valerio VALDEZ Paolini, <valdez@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Valerio VALDEZ Paolini

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
