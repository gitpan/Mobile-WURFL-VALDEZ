package Mobile::WURFL::Device;

use 5.008004;
use strict;
use warnings;
use Carp;

use base 'Mobile::WURFL::Base';

our $VERSION = '0.01';
our $AUTOLOAD;

sub init {

  my $self = shift;
  my $args = shift;
  
  confess "missing data at initialization\n" unless defined $args->{device_data};
  
  $self->device_data( $args->{device_data} );

  return $self;
}

sub device_data {

  $_[0]->{'device_data'} = $_[1] if @_ > 1;
  $_[0]->{'device_data'};
}

sub _attribute {

  $_[0]->device_data->{attributes}{ $_[1] };
}

sub _list_attributes {

  sort keys %{ $_[0]->device_data->{ attributes } };
}

sub _capability {

  $_[0]->device_data->{capabilities}{ $_[1] };
}
  
sub _list_capabilities {

  sort keys %{ $_[0]->device_data->{ capabilities } };
}

sub AUTOLOAD {

  my $method = (split /::/, $AUTOLOAD)[ -1 ];
  return if $method eq 'DESTROY';

  if (defined $_[0]->device_data->{capabilities}{$method}) {
    return $_[0]->device_data->{capabilities}{$method};
  }
  
  confess "method '$method' not found\n";
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mobile::WURFL::Device - WURFL Device

=head1 SYNOPSIS

  use Mobile::WURFL::Device;

  my $device = Mobile::WURFL::Device->new({ device_data => $hashref });
  my $ua_string = $device->_attribute('user_agent');
  if ($device->gif eq 'true') {
    # do something 
  }

=head1 DESCRIPTION

Instantiated by L<Mobile::WURFL>, a Device lists the capabilities of a
mobile telephone handset identified by a B<user agent> string.

=over 12

=item C<new>

Accepts a hash reference, a key named B<device_data> can be used to feed
data to object constructor; data should be a reference to a structure like
this:

  { attributes => { attribute => value,
                    other     => value
                  },
    capabilities => { attribute => value,
                      other     => value
                    }
  }

=item C<_attribute>

accepts an attribute name and returns its value in the current Device; valid
attributes are:

=over 8 

=item C<user_agent>

User Agent string.

=item C<id>

unique identifier.

=item C<actual_device_root>

set to B<true> if current Device is an actual device.

=item C<fall_back>

the identifier of an other Device from which the current Device inherits other
capabilities.

=back

=item C<_list_attributes>

returns the sorted list of available attributes.

=item C<_list_capabilities>

returns the sorted list of available capabilites.

=item C<capability>

accepts an capability name and returns its value in the current Device; refer to WURFL documentation
for a list of valid capabilities.

=item C<AUTOLOAD>

if an AUTOLOADed method matches one of the WURFL capabilities, it returns the
corresponding value stored in the current Device (see C<capability> method).

=back

=head1 SEE ALSO

L<Mobile::WURFL>
L<http://wurfl.sourceforge.net>

=head1 AUTHOR

Valerio VALDEZ Paolini <valdez@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Valerio VALDEZ Paolini <valdez@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
