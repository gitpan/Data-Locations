
##  Copyright (c) 1997 by Steffen Beyer. All rights reserved.
##  This package is free software; you can redistribute and/or
##  modify it under the same terms as Perl itself.

package Data::Locations::Proxy;

use strict;

use Carp;

use IO::Handle;

use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION $AUTOLOAD);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw();

$VERSION = "3.0";

sub AUTOLOAD
{
   croak "$AUTOLOAD(): method not implemented";
}

sub new
{
    croak 'Usage: $newfilehandle = $filehandle->new([$filename]);'
      if ((@_ < 1) || (@_ > 2));

    my($proto) = shift;
    my($proxy);

    if (ref($proto))  ##  object method (called by user)
    {
        return( ${tied *{$proto}}->new(@_) );
    }
    else              ##  class method (called by Data::Locations::Shell)
    {
        $proxy = IO::Handle->new();
        bless($proxy);
        return($proxy);
    }
}

sub filename
{
    croak
  'Usage: $filehandle->filename($filename); | $filename = $filehandle->filename();'
    if ((@_ < 1) || (@_ > 2));

    my($proxy) = shift;

    if (@_ > 0)
    {
        ${${tied *{$proxy}}}->filename(@_);
    }
    else
    {
        return( ${${tied *{$proxy}}}->filename() );
    }
}

sub dump
{
    croak 'Usage: $ok = $filehandle->dump([$filename]);'
      if ((@_ < 1) || (@_ > 2));

    my($proxy) = shift;

    return( ${${tied *{$proxy}}}->dump(@_) );
}

sub print
{
    croak 'Usage: $filehandle->print(@items);'
      if (@_ < 1);

    my($proxy) = shift;

    ${${tied *{$proxy}}}->print(@_);
}

sub println
{
    croak 'Usage: $filehandle->println(@items);'
      if (@_ < 1);

    my($proxy) = shift;

    ${${tied *{$proxy}}}->print(@_,"\n");
}

sub printf
{
    croak 'Usage: $filehandle->printf($format,@items);'
      if (@_ < 2);

    my($proxy) = shift;
    my($format) = shift;

    ${${tied *{$proxy}}}->print( sprintf($format,@_) );
}

sub read
{
    croak 'Usage: $item = $filehandle->read(); | @list = $filehandle->read();'
      if (@_ != 1);

    my($proxy) = shift;

    if (defined wantarray)
    {
        if (wantarray)
        {
            return( ${${tied *{$proxy}}}->readlist() );

        }
        else
        {
            return( ${${tied *{$proxy}}}->readitem() );
        }
    }
}

sub reset
{
    croak 'Usage: $filehandle->reset();'
      if (@_ != 1);

    my($proxy) = shift;

    ${${tied *{$proxy}}}->reset();
}

sub open  ##  just in case...
{
    croak 'Usage: $filehandle->open();'
      if (@_ != 1);

    my($proxy) = shift;

    ${${tied *{$proxy}}}->open();
}

sub close  ##  just in case...
{
    croak 'Usage: $filehandle->close();'
      if (@_ != 1);

    my($proxy) = shift;

    ${${tied *{$proxy}}}->close();
}

sub traverse
{
    croak 'Usage: $filehandle->traverse(\&callback_function);'
      if (@_ != 2);

    my($proxy) = shift;

    ${${tied *{$proxy}}}->traverse(@_);
}

sub delete
{
    croak 'Usage: $filehandle->delete();'
      if (@_ != 1);

    my($proxy) = shift;

    ${${tied *{$proxy}}}->delete();
}

sub tie
{
    croak "Usage: \$filehandle->tie('FILEHANDLE');"
      if (@_ != 2);

    my($proxy) = shift;

    ${tied *{$proxy}}->tie(@_);
}

1;

__END__

