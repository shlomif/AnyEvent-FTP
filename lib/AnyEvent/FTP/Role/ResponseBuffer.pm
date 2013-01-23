package AnyEvent::FTP::Role::ResponseBuffer;

use strict;
use warnings;
use v5.10;
use Role::Tiny;
use AnyEvent::FTP::Response;

# ABSTRACT: Response buffer role for asynchronous ftp client
# VERSION

sub on_once_response
{
  my($self, $cb) = @_;
  push @{ $self->{response_buffer}->{once} }, $cb;
}

sub on_each_response
{
  my($self, $cb) = @_;
  push @{ $self->{response_buffer}->{each} }, $cb;
}

sub process_message_line
{
  my($self, $line) = @_;

  if($line =~ s/^(\d\d\d)([- ])//)
  {
    $self->{response_buffer}->{code} //= $1;
    push @{ $self->{response_buffer}->{message} }, $line;
    if($2 eq ' ')
    {
      my $response = bless {
        code    => $self->{response_buffer}->{code},
        message => $self->{response_buffer}->{message},
      }, 'AnyEvent::FTP::Response';
      delete $self->{response_buffer}->{$_} for qw( code message );
      $_->($response) 
        for @{ $self->{response_buffer}->{once} },
            @{ $self->{response_buffer}->{each} };
      $self->{response_buffer}->{once} = [];
    }
  }
  elsif(@{ $self->{response_buffer}->{message} } > 0)
  {
    push @{ $self->{response_buffer}->{message} }, $line;
  }
  else
  {
    warn "bad message: $line";
  }
}

1;
