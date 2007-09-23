# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mobile-WURFL-Resource.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
# 1
BEGIN { use_ok('Mobile::WURFL::Resource') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $resource = Mobile::WURFL::Resource->new;

# 2
isa_ok( $resource, 'Mobile::WURFL::Resource');

# 3
is( $resource->wurfl_xml, 'wurfl.xml', 'default xml resource file');
# 4
is( $resource->wurfl_bdb, '/tmp/', 'default bdb directory');
# 5
is( $resource->wurfl_uri, 'http://wurfl.sourceforge.net/wurfl.xml', 'default URI directory');

$resource = Mobile::WURFL::Resource->new({});

$resource->wurfl_xml( 'sample.xml');
# 6
is( $resource->wurfl_xml, 'sample.xml', 'assignment test: xml resource file');

$resource->wurfl_bdb('./bdb');
# 7
is( $resource->wurfl_bdb, './bdb', 'assignment test: bdb directory');

$resource->wurfl_uri('file:./test.xml');
# 8
is( $resource->wurfl_uri, 'file:./test.xml', 'assignment test: URI');

# 9
is( $resource->update, 1, 'update');
# 10
is( $resource->error, 0, 'error ok');

$resource->wurfl_uri('notfound.xml');
# 11
is( $resource->update, 0, 'update error');

# 12
ok( $resource->error, 'error ok');

# 13
is( $resource->parse, 0, 'parse');

#quale path usa per il file xml da parsare? aggiungiamo un file sbagliato apposta?
#sistemare i file di test e le dir, non sporcare la dir dei test

# todo: 
# file temporanei in dir dedicata
# 

#manca un metodo per avere una lista completa dei telefoni
#sarebbe comodo un modo per estrarre i dati in formato CSV
