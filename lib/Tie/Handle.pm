
##  Copyright (c) 1997 by Steffen Beyer. All rights reserved.
##  This package is free software; you can redistribute and/or
##  modify it under the same terms as Perl itself.

require 5.004;

package Tie::Handle;

use strict;

use Carp;

use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION $AUTOLOAD);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw();

$VERSION = "2.0";

sub AUTOLOAD
{
   croak "$AUTOLOAD(): method not implemented";
}

sub tie
{
    croak "Usage: \$object->tie({'FILEHANDLE',\$filehandle});"
      if (@_ != 2);

    my($object,$filehandle) = @_;

    if (ref($filehandle))  ##  file handle reference
    {
        if (ref($filehandle) !~ /^(?:File|IO::)Handle$/)
        {
            croak
  "Tie::Handle::tie(): not a 'FileHandle' or 'IO::Handle' object reference";
        }
    }
    else                   ##  symbolic file handle
    {
        $filehandle = caller() . '::' . $filehandle
          unless ($filehandle =~ /::|^STD(?:IN|OUT|ERR)$/);
    }
    no strict "refs";
    tie(*{$filehandle}, 'Tie::Handle', $object);
    use strict "refs";
}

sub TIEHANDLE
{
    croak "Usage: tie(*{\$filehandle}, 'Tie::Handle', \$object);"
      if (@_ != 2);

    shift;
    my($object) = shift;
    my($proxy);

    if (ref($object) &&
       (ref($object) !~ /^SCALAR$|^ARRAY$|^HASH$|^CODE$|^REF$/))
    {
        $proxy = \$object;
        bless($proxy);
        ${$proxy}->open();
        return($proxy);
    }
    else
    {
        croak "Tie::Handle::TIEHANDLE(): not an object reference";
    }
}

sub PRINT
{
    croak "Usage: print [FILEHANDLE|\$filehandle] \@items;"
      if (@_ < 1);

    my($proxy) = shift;

    ${$proxy}->print(@_);
}

sub PRINTF
{
    croak "Usage: printf [FILEHANDLE|\$filehandle] \$format, \@items;"
      if (@_ < 2);

    my($proxy) = shift;
    my($format) = shift;

    ${$proxy}->print( sprintf($format,@_) );
}

sub READLINE
{
    croak "Usage: {\$line,\@list} = <[FILEHANDLE|\$filehandle]>;"
      if (@_ != 1);

    my($proxy) = shift;

    return( ${$proxy}->read() );
}

sub GETC
{
    croak "Usage: \$key = getc([FILEHANDLE|\$filehandle]);"
      if (@_ != 1);

    my($proxy) = shift;

    return( ${$proxy}->getchar() );
}

sub READ
{
    croak
'Usage: $bytes = [sys]read({FILEHANDLE,$filehandle},$buffer,$length[,$offset]);'
    if ((@_ < 3) || (@_ > 4));

    my($proxy) = shift;

    return( ${$proxy}->blockread(@_) );
}

sub DESTROY
{
    my($proxy) = shift;

    ${$proxy}->close();
}

1;

__END__

=head1 NAME

Tie::Handle - tie arbitrary objects to file handles

See the module "Data::Locations" for an example of how to use
this module.

=head1 SYNOPSIS

=over 4

=item *

C<$object-E<gt>tie('FILEHANDLE');>

=item *

C<$object-E<gt>tie($filehandle);>

=item *

C<print @items;>

=item *

C<print FILEHANDLE @items;>

=item *

C<print $filehandle @items;>

=item *

C<printf $format, @items;>

=item *

C<printf FILEHANDLE $format, @items;>

=item *

C<printf $filehandle $format, @items;>

=item *

C<$line = E<lt>E<gt>;>

=item *

C<@list = E<lt>E<gt>;>

=item *

C<$line = E<lt>FILEHANDLEE<gt>;>

=item *

C<@list = E<lt>FILEHANDLEE<gt>;>

=item *

C<$line = E<lt>$filehandleE<gt>;>

=item *

C<@list = E<lt>$filehandleE<gt>;>

=item *

C<$key = getc();>

=item *

C<$key = getc(FILEHANDLE);>

=item *

C<$key = getc($filehandle);>

=item *

C<$bytes = [sys]read(FILEHANDLE,$buffer,$length[,$offset]);>

=item *

C<$bytes = [sys]read($filehandle,$buffer,$length[,$offset]);>

=item *

C<untie *FILEHANDLE;>

=item *

C<untie *{FILEHANDLE};>

=item *

C<untie $filehandle;>

=item *

C<untie *{$filehandle};>

=back

=head1 DESCRIPTION

This module facilitates the tying of file handles with (arbitrary)
objects.

File handles must be given either as symbolic file handles (like "STDOUT",
"MYHANDLE" or "MYPACKAGE::MYHANDLE") or as references as returned by the
object constructor method "new()" from the "IO::Handle" or "FileHandle"
class (either one works).

Your class "Your::Class" needs to:

    require Tie::Handle;

and to add "Tie::Handle" to the list of classes to inherit from:

    @ISA = qw(Exporter Tie::Handle);

in order to enable tying of file handles with objects of "Your::Class".

Note that your class "Your::Class" is also responsible for providing
(i.e., overloading) the appropriate methods needed to access your
objects:

=over 4

=item *

C<$object-E<gt>open();>

This method is invoked on the given object when a file handle is tied
to it.

For example you can reset the state information associated with the given
object (which is needed in most cases to be able to read item after item
with "C<$item = E<lt>FILEHANDLEE<gt>;>" from an object) with this method.

You can also define a dummy method of this name if nothing needs to be
done.

Note that a fatal error will occur ("method not implemented") when you try
to tie a file handle to one of your objects if you failed to provide this
method.

=item *

C<$object-E<gt>print(@items);>

This method is invoked on the given object when the associated file
handle is printed to with Perl's built-in "print()" or "printf()"
function.

The parameters given to a "print()" statement are simply handed over
to the object's "print()" method.

The parameters of a "printf()" statement are first processed using Perl's
built-in "sprintf()" function before being handed over to the object's
"print()" method.

See the section on "printf()" in L<perlfunc(1)> and L<printf(3)>
or L<sprintf(3)> on your system for more information about the
"printf()" function.

Note that a fatal error will occur ("method not implemented") when you try
to print to a tied file handle if you failed to provide this method.

=item *

C<$item = $object-E<gt>read();>

This method is called for the given object when the associated file handle
is read from using a statement like "C<$item = E<lt>FILEHANDLEE<gt>;>",
i.e., when the file handle is read from in SCALAR context.

For an explanation of "scalar" versus "array" or "list" context,
see the section on "Context" in L<perldata(1)>!

The method should return the next item of data to be read from the given
object or "undef" when there is no more data to read.

If no file handle is given explicitly, the statement "C<$item = E<lt>E<gt>;>"
will read from STDIN (which may or may not be tied to an object).

Note that a fatal error will occur ("method not implemented") when you try
to read from a tied file handle if you failed to provide this method.

=item *

C<@list = $object-E<gt>read();>

This method is called for the given object when the associated file handle
is read from using a statement like "C<@list = E<lt>FILEHANDLEE<gt>;>",
i.e., when the file handle is read from in ARRAY or LIST context.

For an explanation of "scalar" versus "array" or "list" context,
see the section on "Context" in L<perldata(1)>!

The method should return the contents of the associated object as one
(possibly very long) list (starting to read where the last "read()" left
off!) or an empty list if there is no more data that can be returned.

If no file handle is given explicitly, the statement "C<@list = E<lt>E<gt>;>"
will read from STDIN (which may or may not be tied to an object).

Note that a fatal error will occur ("method not implemented") when you try
to read from a tied file handle if you failed to provide this method.

=item *

C<$key = $object-E<gt>getchar();>

This method is called for the given object when the associated file handle
is read from using Perl's built-in function "getc()".

The method should return the next character (or byte) from the given object
or a null string if there are no more characters to be returned.

See the section on "getc()" in L<perlfunc(1)> for more details.

If no file handle is given explicitly, the statement "C<$key = getc();>"
will read from STDIN (which may or may not be tied to an object).

Note that a fatal error will occur ("method not implemented") when you try
to read from a tied file handle in this way if you failed to provide this
method.

=item *

C<$bytes = $object-E<gt>>C<blockread($buffer,$length[,$offset]);>

This method is called for the given object when the associated file handle
is read from using Perl's built-in function "read()" or "sysread()".

The method should store the next "$length" characters (or bytes) from
the given object in the scalar variable "$buffer", possibly at an offset
"$offset" (possibly requiring padding the scalar variable "$buffer" with
null characters!), and it should return the number of characters (or bytes)
actually read or "undef" if there was an error.

See the section on "read()" and/or "sysread()" in L<perlfunc(1)> for more
details.

Note that a fatal error will occur ("method not implemented") when you try
to read from a tied file handle in this way if you failed to provide this
method.

=item *

C<$object-E<gt>close();>

This method is invoked on the given object when the file handle is untied,
i.e., when the bond between the file handle and its associated object is
dissociated using one of the following alternatives:

                untie *FILEHANDLE;
                untie *{FILEHANDLE};
                untie $filehandle;
                untie *{$filehandle};

(depending on wether you are using a symbolic file handle, a file handle
object reference or a symbolic file handle stored in a scalar variable!)

For example you can reset the state information associated with the given
object (which is needed in most cases to be able to read item after item
with "C<$item = E<lt>FILEHANDLEE<gt>;>" from an object) with this method.

You can also define a dummy method of this name if nothing needs to be
done.

Note that a fatal error will occur ("method not implemented") when you try
to untie a file handle from its associated object if you failed to provide
this method.

=back

See the module "Data::Locations" for an example of how to implement
most of these methods.

REMEMBER that you may define the default output file handle using the
Perl function "select()" so that any subsequent "print()" or "printf()"
statement without an explicit file handle will send output to the chosen
default file handle automatically!

See the section on "select()" in L<perlfunc(1)> for more details!

IMPORTANT:

Note that "open()" and "close()" on a tied file handle have no effect
on the object which is tied to it!

(But beware that they attempt to open and close the specified file,
respectively, even though this is useless in this case!)

Note also that you will get errors if you try to read from a tied file
handle which you opened for output only using "open()", or vice-versa!

Therefore it is best not to use "open()" and "close()" on tied file
handles at all.

Instead, if you want to restart reading from the beginning of any given
object, rather invoke the corresponding method of your class on it (if
it provides one)!

In case your class "Your::Class" provides such a method (let's call it
"reset()" here) which allows you to reset the state information associated
with every object (needed to be able to read item after item from an object
sequentially), then instead of invoking that method directly using:

                $object->reset();

you can also invoke this method via its associated file handle,
like this:

                ${tied *FILEHANDLE}->reset();
                ${tied *{FILEHANDLE}}->reset();
                ${tied *{$filehandle}}->reset();

=head1 SEE ALSO

Data::Locations(3), perl(1), perldata(1),
perlfunc(1), perlsub(1), perlmod(1), perlref(1),
perlobj(1), perlbot(1), perltoot(1), perltie(1),
printf(3), sprintf(3).

=head1 VERSION

This man page documents "Tie::Handle" version 2.0.

=head1 AUTHOR

Steffen Beyer <sb@sdm.de>.

=head1 COPYRIGHT

Copyright (c) 1997 by Steffen Beyer. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute
and/or modify it under the same terms as Perl itself.

