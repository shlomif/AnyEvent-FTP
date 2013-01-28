use strict;
use warnings;
use v5.10;
use Test::More tests => 8;
use AnyEvent::FTP::Client;
use FindBin ();
require "$FindBin::Bin/lib.pl";

my $client = eval { AnyEvent::FTP::Client->new };
diag $@ if $@;
isa_ok $client, 'AnyEvent::FTP::Client';

prep_client( $client );

our $config;

$client->connect($config->{host}, $config->{port})->recv;
$client->login($config->{user}, $config->{pass})->recv;

do {
  my $res = eval { $client->cwd($config->{dir})->recv };
  isa_ok $res, 'AnyEvent::FTP::Response';
  is $res->code, 250, 'code = 250';
};

do {
  my $res = eval { $client->pwd->recv };
  is $res, $config->{dir}, "dir = " . $config->{dir};
};

do {

  $client->cwd('t')->recv;
  isnt $client->pwd->recv, $config->{dir}, "in t dir";
  
  my $res = eval { $client->cdup->recv };
  diag $@ if $@;
  isa_ok $res, 'AnyEvent::FTP::Response';
  is $res->code, 250, 'code = 250';
  is $client->pwd->recv, $config->{dir}, "dir = " . $config->{dir};

};

$client->quit->recv;

