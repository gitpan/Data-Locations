
##  Copyright (c) 1997 by Steffen Beyer. All rights reserved.
##  This package is free software; you can redistribute and/or
##  modify it under the same terms as Perl itself.

package Data::Locations::Shell;

use strict;

use Carp;

use Data::Locations::Proxy;

use Data::Locations;

use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

require Exporter;

require Tie::Handle;

@ISA = qw(Exporter Tie::Handle);

@EXPORT = qw();

@EXPORT_OK = qw();

$VERSION = "3.0";

sub new
{
    croak 'Usage: $newfilehandle = Data::Locations::Shell->new([$filename]);'
      if ((@_ < 1) || (@_ > 2));

    my($proto) = shift;
    my($location,$proxy,$filehandle);

    if (ref($proto))  ##  object method (called by Data::Locations::Proxy)
    {
        $location = ${$proto}->new(@_);
    }
    else              ##  class method (called by user)
    {
        $location = Data::Locations->new(@_);
    }

    $proxy = \$location;
    bless($proxy);

    $filehandle = Data::Locations::Proxy->new();
    $proxy->tie($filehandle);

    return( $filehandle );
}

sub open
{
    my($proxy) = shift;

    ${$proxy}->open();
}

sub close
{
    my($proxy) = shift;

    ${$proxy}->close();
}

sub print
{
    croak 'Usage: print $filehandle @items;'
      if (@_ < 1);

    my($proxy) = shift;

    ${$proxy}->print(@_);
}

sub printf
{
    croak 'Usage: printf $filehandle $format, @items;'
      if (@_ < 2);

    my($proxy) = shift;
    my($format) = shift;

    ${$proxy}->print( sprintf($format,@_) );
}

sub read
{
    croak 'Usage: $item = <$filehandle>; | @list = <$filehandle>;'
      if (@_ != 1);

    my($proxy) = shift;

    if (defined wantarray)
    {
        if (wantarray)
        {
            return( ${$proxy}->readlist() );
        }
        else
        {
            return( ${$proxy}->readitem() );
        }
    }
}

sub dump
{
    croak 'Usage: $ok = Data::Locations::Shell->dump();'
      if (@_ != 1);

    return( Data::Locations->dump() );
}

sub reset
{
    croak 'Usage: Data::Locations::Shell->reset();'
      if (@_ != 1);

    Data::Locations->reset();
}

sub traverse
{
    croak 'Usage: Data::Locations::Shell->traverse(\&callback_function);'
      if (@_ != 2);

    Data::Locations->traverse(@_);
}

sub delete
{
    croak 'Usage: Data::Locations::Shell->delete();'
      if (@_ != 1);

    Data::Locations->delete();
}

1;

__END__

=head1 NAME

Data::Locations::Shell - adds additional features to Data::Locations

"use Data::Locations::Shell;" INSTEAD of "use Data::Locations;" and
replace all occurrences of "Data::Locations" in your program by
"Data::Locations::Shell".

The advantage of using "Data::Locations::Shell" instead of "Data::Locations"
is that you don't need TWO object references for the SAME location anymore:
One for the location itself and one for the file handle the location has been
tied to.

Instead, you have only ONE object reference you can do everything with:
Use it as a file handle in Perl's built-in functions for dealing with files,
AND use it to invoke methods from the "Data::Locations" class, at the same
time!

Note also that this module is fully compatible with "Data::Locations",
i.e., if you change all occurrences of "Data::Locations" in your program
to "Data::Locations::Shell", your program should work exactly as before -
with the added benefit that you don't need to "tie()" your locations to
a file handle explicitly anymore in order to be able to use
"C<print $location @items;>" and "C<$item = E<lt>$locationE<gt>;>",
for instance, as shown below (for a more detailed description of these
methods, see L<Data::Locations(3)>).

Note however that "Data::Locations::Shell" needs Perl version 5.004 (or
higher) in order to run (whereas "Data::Locations" can do with previous
versions of Perl).

=head1 SYNOPSIS

=over 4

=item *

C<use Data::Locations::Shell;>

=item *

C<$filehandle = Data::Locations::Shell-E<gt>new();>

=item *

C<$filehandle = Data::Locations::Shell-E<gt>new($filename);>

=item *

C<$subfilehandle = $filehandle-E<gt>new();>

=item *

C<$subfilehandle = $filehandle-E<gt>new($filename);>

=item *

C<$filehandle-E<gt>filename($filename);>

=item *

C<$filename = $filehandle-E<gt>filename();>

=item *

C<$filehandle-E<gt>print(@items);>

=item *

C<$filehandle-E<gt>println(@items);>

=item *

C<$filehandle-E<gt>printf($format,@items);>

=item *

C<print $filehandle @items;>

=item *

C<printf $filehandle $format, @items;>

=item *

C<$ok = Data::Locations::Shell-E<gt>dump();>

=item *

C<$ok = $filehandle-E<gt>dump();>

=item *

C<$ok = $filehandle-E<gt>dump($filename);>

=item *

C<$item = $filehandle-E<gt>read();>

=item *

C<@list = $filehandle-E<gt>read();>

=item *

C<$item = E<lt>$filehandleE<gt>;>

=item *

C<@list = E<lt>$filehandleE<gt>;>

=item *

C<Data::Locations::Shell-E<gt>reset();>

=item *

C<$filehandle-E<gt>reset();>

=item *

C<Data::Locations::Shell-E<gt>traverse(\&callback_function);>

=item *

C<$filehandle-E<gt>traverse(\&callback_function);>

=item *

C<Data::Locations::Shell-E<gt>delete();>

=item *

C<$filehandle-E<gt>delete();>

=item *

C<$filehandle-E<gt>tie('FILEHANDLE');>

=back

=head1 DESCRIPTION

See L<Data::Locations(3)> for a full description.

Note that you can "tie()" the same location to several file handles at the
same time, hence the existence of the "tie()" method in this module as well.

Note further that once you did "use Data::Locations::Shell;" you can also
use all the methods of the module "Data::Locations" (because "Data::Locations"
is loaded implicitly and automatically by "Data::Locations::Shell"), i.e.,
you can have "Data::Locations" and "Data::Locations::Shell" objects at the
same time, but there is no way of converting an object of the class
"Data::Locations" into one of the class "Data::Locations::Shell"!

=head1 SEE ALSO

Data::Locations(3), Tie::Handle(3), IO::Handle(1),
perl(1), perldata(1), perlfunc(1), perlsub(1),
perlmod(1), perlref(1), perlobj(1), perlbot(1),
perltoot(1), perltie(1), printf(3), sprintf(3).

=head1 VERSION

This man page documents "Data::Locations::Shell" version 3.0.

=head1 AUTHOR

Steffen Beyer <sb@sdm.de>.

=head1 COPYRIGHT

Copyright (c) 1997 by Steffen Beyer. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute
and/or modify it under the same terms as Perl itself.

