
###############################################################################
##                                                                           ##
##    Copyright (c) 1997, 1998, 1999 by Steffen Beyer.                       ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

package Data::Locations;

use strict;
use vars qw($VERSION);

use Carp;
use Symbol;

$VERSION = "4.3";

my $Dummy = '[Error: stale reference!]';  ##  Dummy class name

my $Class = 'Data::Locations';            ##  This class's name

my $Count = 0;                            ##  Counter of all existing locations

BEGIN { *print = \&PRINT; *printf = \&PRINTF; *read = \&READLINE; }

sub new
{
    croak
    "Usage: \$[top|sub]location = [$Class|\$location]->new( [ \$filename ] );\n"
      if ((@_ < 1) || (@_ > 2));

    my($outer) = shift;
    my($file,$name,$inner);

    $file = '';
    $file = shift if (@_ > 0);
    if (defined $file)
    {
        if (ref($file))
        {
            croak "${Class}::new(): reference not allowed as filename";
        }
        else { $file = "$file"; }
    }
    else { $file = ''; }

    $name = 'LOCATION' . $Count++;   ## Generate a unique name

no strict "refs";
    $inner = \*{$Class.'::'.$name};  ## Create a reference to glob value
use strict "refs";

    bless($inner, $Class);           ## Bless glob to become an object

    tie(*{$inner}, $Class, $inner);  ## Tie glob to itself

    ${*{$inner}} = $inner;           ## Store copy of ref in $ slot of glob

    @{*{$inner}} = ( );              ## Use @ slot of glob for the data

    ${*{$inner}}{'file'}  = $file;   ## Use % slot for object attributes
    ${*{$inner}}{'outer'} = { };
    ${*{$inner}}{'inner'} = { };
    ${*{$inner}}{'top'}   = 0;

    ##  Note that $hash{$ref} is exactly the same as $hash{"$ref"}
    ##  because references are automatically converted to strings
    ##  when they are used as keys of a hash!

    if (ref($outer))  ##  Object method
    {
        push(@{*{$outer}}, $inner);
        ${*{$outer}}{'inner'}{$inner} = $inner;
        ${*{$inner}}{'outer'}{$outer} = $outer;
    }
    else              ##  Class method
    {
        ${*{$inner}}{'top'} = 1;
    }
    return $inner;
}

sub TIEHANDLE
{
    return $_[1];
}

sub filename
{
    croak "Usage: [ \$filename = ] \$location->filename( [ \$filename ] );\n"
      if ((@_ < 1) || (@_ > 2));

    my($location) = shift;
    my($file);

    if (@_ > 0)
    {
        $file = shift;
        if (defined $file)
        {
            if (ref($file))
            {
                croak "${Class}::filename(): reference not allowed as filename";
            }
            else { $file = "$file"; }
        }
        else { $file = ''; }
        ${*{$location}}{'file'} = $file;
    }
    else
    {
        return ${*{$location}}{'file'};
    }
}

sub toplevel
{
    croak "Usage: [ \$flag = ] \$location->toplevel( [ \$flag ] );\n"
      if ((@_ < 1) || (@_ > 2));

    my($location) = shift;

    if (@_ > 0)
    {
        ${*{$location}}{'top'} = $_[0] & 1;
    }
    else
    {
        return ${*{$location}}{'top'};
    }
}

sub _self_contained_
{
    my($outer,$inner) = @_;
    my($list,$item);

    return 1 if ($outer eq $inner);
    $list = ${*{$inner}}{'inner'};
    foreach $item (keys %{$list})
    {
        $inner = ${$list}{$item};
        return 1 if (&_self_contained_($outer,$inner));
    }
    return 0;
}

sub PRINT  ##  Aliased to "print"
{
    croak "Usage: \$location->print(\@items);\n"
      if (@_ < 1);

    my($outer) = shift;
    my($inner);

    ITEM:
    foreach $inner (@_)
    {
        if (ref($inner))
        {
            if (ref($inner) ne $Class)
            {
                carp "${Class}::print(): reference '".ref($inner)."' ignored"
                  if $^W;
                next ITEM;
            }
            if (&_self_contained_($outer,$inner))
            {
                croak "${Class}::print(): infinite recursion loop attempted";
            }
            else
            {
                push(@{*{$outer}}, $inner);
                ${*{$outer}}{'inner'}{$inner} = $inner;
                ${*{$inner}}{'outer'}{$outer} = $outer;
                ${*{$inner}}{'top'} = 0;
            }
        }
        else
        {
            push(@{*{$outer}}, $inner);
        }
    }
}

sub PRINTF  ##  Aliased to "printf"
{
    croak "Usage: \$location->printf(\$format, \@items);\n"
      if (@_ < 2);

    my($location) = shift;
    my($format) = shift;

    $location->print( sprintf($format, @_) );
}

sub println
{
    croak "Usage: \$location->println(\@items);\n"
      if (@_ < 1);

    my($location) = shift;

    $location->print(@_, "\n");

    ##  We use a separate "\n" here (instead of concatenating it
    ##  with the last item) in case the last item is a reference!
}

sub _read_item_
{
    my($location) = @_;
    my($stack,$entry,$index,$where,$item);

    if (exists ${*{$location}}{'stack'})
    {
        $stack = ${*{$location}}{'stack'};
    }
    else
    {
        $stack = [ [ 0, $location ] ];
        ${*{$location}}{'stack'} = $stack;
    }

    if (@{$stack})
    {
        $entry = ${$stack}[0];
        $index = ${$entry}[0];
        $where = ${$entry}[1];
        if ((ref($where) eq $Class) && ($index < @{*{$where}}))
        {
            $item = ${*{$where}}[$index];
            ${$entry}[0]++;
            if (ref($item))
            {
                if (ref($item) eq $Class)
                {
                    unshift(@{$stack}, [ 0, $item ]);
                }
                return &_read_item_($location);
            }
            else { return $item; }
        }
        else
        {
            shift(@{$stack});
            return &_read_item_($location);
        }
    }
    else { return undef; }
}

sub _read_list_
{
    my($location) = @_;
    my(@result);
    my($item);

    while ($item = &_read_item_($location))
    {
        push(@result, $item);
    }
    return( @result );
}

sub READLINE  ##  Aliased to "read"
{
    croak "Usage: [ \$item | \@list ] = \$location->read();\n"
      if (@_ != 1);

    my($location) = shift;

    if (defined wantarray)
    {
        if (wantarray)
        {
            return( &_read_list_($location) );
        }
        else
        {
            return &_read_item_($location);
        }
    }
}

sub reset
{
    croak "Usage: [$Class|\$location]->reset();\n"
      if (@_ != 1);

    my($location) = @_;

    if (ref($location))  ##  Object method
    {
        delete ${*{$location}}{'stack'};
    }
    else                 ##  Class method
    {
        foreach $location (keys %Data::Locations::)
        {
            if ($location =~ /^LOCATION\d+$/)
            {
                delete ${*{$Data::Locations::{$location}}}{'stack'};
            }
        }
    }
}

sub _traverse_recursive_
{
    my($location,$callback) = @_;
    my($item);

    if (ref($callback) ne 'CODE')
    {
        croak "${Class}::traverse(): not a code reference";
    }

    foreach $item (@{*{$location}})
    {
        if (ref($item))
        {
            if (ref($item) eq $Class)
            {
                &_traverse_recursive_($item,$callback);
            }
        }
        else
        {
            &{$callback}($item);
        }
    }
}

sub traverse
{
    croak "Usage: [$Class|\$location]->traverse(\\&callback_function);\n"
      if (@_ != 2);

    my($location,$callback) = @_;

    if (ref($callback) ne 'CODE')
    {
        croak "${Class}::traverse(): not a code reference";
    }

    if (ref($location))  ##  Object method
    {
        &_traverse_recursive_($location,$callback);
    }
    else                 ##  Class method
    {
        foreach $location (keys %Data::Locations::)
        {
            if ($location =~ /^LOCATION\d+$/)
            {
                if (${*{$Data::Locations::{$location}}}{'top'})
                {
                    &{$callback}( ${*{$Data::Locations::{$location}}} );
                }
            }
        }
    }
}

sub _dump_recursive_
{
    my($location,$filehandle) = @_;
    my($item);

    foreach $item (@{*{$location}})
    {
        if (ref($item))
        {
            if (ref($item) eq $Class)
            {
                &_dump_recursive_($item,$filehandle);
            }
        }
        else
        {
            print $filehandle $item;
        }
    }
}

sub _dump_location_
{
    local(*FILEHANDLE);
    my($location) = shift;
    my($file);

    $file = ${*{$location}}{'file'};
    $file = shift if (@_ > 0);
    if (defined $file)
    {
        if (ref($file))
        {
            croak "${Class}::dump(): reference not allowed as filename";
        }
        else { $file = "$file"; }
    }
    else { $file = ''; }

    if ($file =~ /^\s*$/)
    {
        carp "${Class}::dump(): filename missing or empty" if $^W;
        return 0;
    }
    unless ($file =~ /^\s*[>\|+]/)
    {
        $file = '>' . $file;
    }
    unless (open(FILEHANDLE, $file))
    {
        carp "${Class}::dump(): can't open file '$file': \L$!\E" if $^W;
        return 0;
    }
    &_dump_recursive_($location,*FILEHANDLE);
    unless (close(FILEHANDLE))
    {
        carp "${Class}::dump(): can't close file '$file': \L$!\E" if $^W;
        return 0;
    }
    return 1;
}

sub dump
{
    croak
    "Usage: \$ok = [ $Class->dump(); | \$location->dump( [ \$filename ] ); ]\n"
      if ((@_ < 1) || (@_ > 2) || ((@_ == 2) && !ref($_[0])));

    my($location) = shift;
    my($ok);

    if (ref($location))  ##  Object method
    {
        if (@_ > 0)
        {
            return &_dump_location_($location,$_[0]);
        }
        else
        {
            return &_dump_location_($location);
        }
    }
    else                 ##  Class method
    {
        $ok = 1;
        foreach $location (keys %Data::Locations::)
        {
            if ($location =~ /^LOCATION\d+$/)
            {
                if (${*{$Data::Locations::{$location}}}{'top'})
                {
                    $ok = 0 unless
                      &_dump_location_( ${*{$Data::Locations::{$location}}} );
                }
            }
        }
        return $ok;
    }
}

sub delete
{
    croak "Usage: [$Class|\$location]->delete();\n"
      if (@_ != 1);

    my($outer) = shift;
    my($list,$item,$inner,$link);

    if (ref($outer))  ##  Object method
    {
        $list = ${*{$outer}}{'inner'};
        foreach $item (keys %{$list})
        {
            $inner = ${$list}{$item};
            $link = ${*{$inner}}{'outer'};
            delete ${$link}{$outer};
            unless (%{$link})
            {
                ${*{$inner}}{'top'} = 1;
            }
        }
        @{*{$outer}} = ( );
        ${*{$outer}}{'inner'} = { };
        delete ${*{$outer}}{'stack'};
    }
    else              ##  Class method
    {
        foreach $item (keys %Data::Locations::)
        {
            if ($item =~ /^LOCATION\d+$/)
            {
                bless( \*{$Data::Locations::{$item}},  ## Prevent further use
                  $Dummy);
                undef ${*{$Data::Locations::{$item}}}; ## Break self-reference
                undef @{*{$Data::Locations::{$item}}}; ## Free memory (data!)
                undef %{*{$Data::Locations::{$item}}}; ## Clear obj attributes
                delete $Data::Locations::{$item};      ## Remove symtab entry
            }
        }
        $Count = 0;
    }
}

sub tie
{
    croak
  "Usage: \$location->tie( [ 'FH' | *FH | \\*FH | *{FH} | \\*{FH} | \$fh ] );\n"
      if (@_ != 2);

    my($location,$filehandle) = @_;

    $filehandle =~ s/^\*//;
    $filehandle = Symbol::qualify($filehandle, caller);
no strict "refs";
    tie(*{$filehandle}, $Class, $location);
use strict "refs";
}

1;

__END__

=head1 NAME

Data::Locations - magic insertion points in your data

=head1 PREFACE

Did you already encounter the problem that you had to produce some
data in a particular order, but that some piece of the data was still
unavailable at the point in the sequence where it belonged and where
it should have been produced?

Did you also have to resort to cumbersome and tedious measures such
as storing the first and the last part of your data separately, then
producing the missing middle part, and finally putting it all together?

In this simple case, involving only one later-on-insertion, you might
still put up with this solution.

But if there is more than one later-on-insertion, requiring the handling
of many fragments of data, you will probably get annoyed and frustrated.

You might even have to struggle with limitations of the file system of
your operating system, or handling so many files might considerably slow
down your application due to excessive file input/output.

And if you don't know exactly beforehand how many later-on-insertions
there will be (if this depends dynamically on the data being processed),
and/or if the pieces of data you need to insert need additional (nested)
insertions themselves, things will get really tricky, messy and troublesome.

In such a case you might wonder if there wasn't an elegant solution to
this problem.

This is where the "C<Data::Locations>" module comes in: It handles such
insertion points automatically for you, no matter how many and how deeply
nested, purely in memory, requiring no (inherently slower) file input/output
operations.

(The underlying operating system will automatically take care if the amount
of data becomes too large to be handled fully in memory, though, by swapping
out unneeded parts.)

Moreover, it also allows you to insert the same fragment of data into
SEVERAL different places.

This increases space efficiency because the same data is stored in
memory only once, but used multiple times.

Potential infinite recursion loops are detected automatically and
refused.

In order to better understand the underlying concept, think of
"C<Data::Locations>" as virtual files with almost random access:
You can write data to them, you can say "reserve some space here
which I will fill in later", and continue writing data.

And you can of course also read from these virtual files, at any time,
in order to see the data that a given virtual file currently contains.

When you are finished filling in all the different parts of your virtual
file, you can write its contents to a physical, real file this time, or
process it otherwise (purely in memory, if you wish).

Note that this module handles your data completely transparent, which
means that you can use it equally well for text AND binary data.

You might also be interested to know that this module and its concept
has already heavily been put to use in the automatic code generation
of large software projects.

=head1 SYNOPSIS

  use Data::Locations;

  new
      $toplocation = Data::Locations->new();
      $toplocation = Data::Locations->new($filename);
      $sublocation = $location->new();
      $sublocation = $location->new($filename);

  filename
      $location->filename($filename);
      $filename = $location->filename();

  toplevel
      $flag = $location->toplevel();
      $location->toplevel($flag);

  print
      $location->print(@items);
      print $location @items;

  printf
      $location->printf($format, @items);
      printf $location $format, @items;

  println
      $location->println(@items);

  read
      $item = $location->read();
      $item = <$location>;
      @list = $location->read();
      @list = <$location>;

  reset
      Data::Locations->reset();
      $location->reset();

  traverse
      Data::Locations->traverse(\&callback_function);
      $location->traverse(\&callback_function);

  dump
      $ok = Data::Locations->dump();
      $ok = $location->dump();
      $ok = $location->dump($filename);

  delete
      Data::Locations->delete();
      $location->delete();

  tie
      $location->tie('FILEHANDLE');
      $location->tie(*FILEHANDLE);
      $location->tie(\*FILEHANDLE);
      $location->tie(*{FILEHANDLE});
      $location->tie(\*{FILEHANDLE});
      $location->tie($filehandle);
      tie(*FILEHANDLE, "Data::Locations", $location);
      tie($filehandle, "Data::Locations", $location);

  tied
      $location = tied *FILEHANDLE;
      $location = tied $filehandle;

  untie
      untie *FILEHANDLE;
      untie $filehandle;

  select
      $filehandle = select();
      select($location);
      $oldfilehandle = select($newlocation);

=head1 LIMITATIONS

In the current implementation of this module, locations are global
variables and do not automatically destroy themselves when your
last reference to one of them goes out of scope.

This is mainly due to the fact that, in the current implementation,
locations contain self-references, which are essential in order to
be able to use locations as file handles and objects simultaneously.

Because locations are global variables, and because some (class)
methods (see the section DESCRIPTION below for details) act on ALL
locations, there may be undesirable side effects if more than one
module is using locations at the same time, i.e., in the same program.

For instance dumping all locations from one module using the class method
"C<dump()>" will also dump the locations of all other modules.

Truly local locations are on the wish list for the next major release
(version 5.0) of this module. Stay tuned.

=head1 DESCRIPTION

=over 4

=item *

C<use Data::Locations;>

Enables the use of locations in your program.

=item *

C<$toplocation = Data::Locations-E<gt>new();>

The CLASS METHOD "C<new()>" creates a new top-level location.

A "top-level" location is a location which isn't embedded (nested)
in any other location.

Note that CLASS METHODS are invoked using the NAME of their class, i.e.,
"C<Data::Locations>" in this case, in contrast to OBJECT METHODS which
are invoked using an object REFERENCE such as returned by the class's
object constructor method (which "C<new()>" happens to be).

Any location that you intend to dump to a file later on in your program needs
to have a filename associated with it, which you can either specify using one
of the variants of the "C<new()>" method where you supply a filename (as the
one shown immediately below), or by setting this filename using the method
"C<filename()>" (see further below), or by specifying an explicit filename
when invoking the "C<dump()>" method itself (see also further below) on
a particular location.

Otherwise an error will occur when you try to dump the location (in fact,
a warning message is printed to the screen (if the "C<-w>" switch is set)
and the location will simply not be dumped to a file, but program execution
continues).

=item *

C<$toplocation = Data::Locations-E<gt>new($filename);>

This variant of the CLASS METHOD "C<new()>" creates a new top-level
location (where "top-level" means a location which isn't embedded
in any other location) and assigns a default filename to it.

Note that this filename is simply passed through to the Perl "C<open()>"
function later on (which is called internally when you dump your locations
to a file), which means that any legal Perl filename may be used such as
">-" (for writing to STDOUT) and "| more", to give you just two of the
more exotic examples!

See the section on "C<open()>" in L<perlfunc(1)> for more details!

=item *

C<$sublocation = $location-E<gt>new();>

The OBJECT METHOD "C<new()>" creates a new location which is embedded
in the given location "C<$location>" at the current position (defined
by what has been printed to the embedding location till this moment).

Such nested locations usually do not need a filename associated with
them (because they will be dumped to the same file as the location in
which they are embedded), unless you want to dump this location to a
file of its own, additionally.

In the latter case, use the variant of the "C<new()>" method shown
immediately below or the method "C<filename()>" (see below) to set
this filename, or call the method "C<dump()>" (described further
below) with an appropriate filename argument.

=item *

C<$sublocation = $location-E<gt>new($filename);>

This variant of the OBJECT METHOD "C<new()>" creates a new location
which is embedded in the given location "C<$location>" at the current
position (defined by what has been printed to the embedding location
till this moment) and assigns a default filename to it.

See the section on "C<open()>" in L<perlfunc(1)> for details about the
exact syntax of Perl filenames (this includes opening pipes to other
programs as a very interesting and useful application, for example).

=item *

C<$location-E<gt>filename($filename);>

This object method stores a filename along with the given location
which will be used as the default filename when dumping that location.

You may set the filename associated with any given location using this
method any number of times.

Note that you can use this very same method "C<filename()>" in order to
retrieve the default filename that has been stored along with a given
location if you call it WITHOUT any parameters (see also immediately
below).

=item *

C<$filename = $location-E<gt>filename();>

When called without parameters, this object method returns the default
filename that has previously been stored along with the given location,
using either the method "C<new()>" or this very same method, "C<filename()>"
(but with a filename passed to it as its (only) argument).

=item *

C<$flag = $location-E<gt>toplevel();>

Use this method to find out if any given location is a "top-level" location
or not, i.e., if the given location is embedded in any other location or not.

Note that locations created by the CLASS METHOD "C<new()>" all start their
life-cycle as top-level locations, whereas locations which are embedded in
some other location by using the OBJECT METHOD "C<new()>" or the method
"C<print()>" (see further below for details) are NOT, by definition,
top-level locations.

Whenever a top-level location is embedded in another location (using the
method "C<print()>" - see further below for more details), it automatically
loses its "top-level" status.

On the other hand side, when you throw away the contents of a location
(using the method "C<delete()>" - see further below for details), the
other locations that may have been embedded in the deleted location may
become "orphans" which have no "parents" anymore, i.e., which are not
embedded in any other location anymore. These "orphan" locations will
automatically become "top-level" locations.

The method returns "true" ("C<1>") if the given location is a top-level
location, and "false" ("C<0>") otherwise, provided that the method is
called without parameters.

=item *

C<$location-E<gt>toplevel($flag);>

You can also use the method "C<toplevel()>" to clear or set the "toplevel"
attribute of any given location.

The "toplevel" attribute of each location determines wether it is eligible
for processing by the CLASS METHODS "C<dump()>" and "C<traverse()>" (see
further below for details) or not.

Usually, the "toplevel" attribute is set and cleared automatically by this
module as needed.

Therefore, you shouldn't need to use this method to change the "toplevel"
attribute of a location under any normal circumstances.

There is one conceivable exception, though, if you want to do some "reuse"
of the contents of a top-level location by embedding it in some other
location.

You might for example want to store a C header file in a top-level location
and to include it in some C source file at the same time (i.e., you might
need to write the resulting C headers to a file of their own and still want
to write this very same information to a different file as part of the
information of that file, without duplicating this information in memory).

Because a top-level location automatically loses its "top-level" status
whenever it is embedded in another location, you will have to set the
"toplevel" attribute of the location in question again AFTER embedding
it (see the description of the method "C<print()>" immediately below
for details about how to do that) using this method.

The method expects one parameter, which should either be "C<0>" (for
clearing the "toplevel" attribute) or "C<1>" (in order to set the
"toplevel" attribute).

Use this method with precaution!

=item *

C<$location-E<gt>print(@items);>

This object method prints the given arguments to the indicated
location, i.e., appends the given items to the given location.

IMPORTANT FEATURE:

Note that you can EMBED any given location IN MORE THAN ONE surrounding
location using this method!

Simply use a statement similar to this one:

        $location->print($sublocation);

This embeds location "C<$sublocation>" in location "C<$location>" at
the current position (defined by what has been printed to location
"C<$location>" till this moment).

(Note that the name "C<$sublocation>" above refers only to the fact
that this location is going to be embedded in the location "C<$location>".
"C<$sublocation>" may actually be ANY location you like, even a top-level
location. Beware though that a top-level location will automatically lose
its "top-level" status by doing so. If this is not what you want, you can
always use the method "C<toplevel()>" (for a description, see further above)
to set its "toplevel" attribute again, AFTER embedding it.)

This is especially useful if you are generating data once in your
program which you need at several places in your output.

This saves a lot of memory because only a reference of the embedded
location is stored in every embedding location, instead of all the
data, which is stored in memory only once!

Note that other references than "Data::Locations" object references are
illegal, trying to "print" such a reference to a location will result
in a warning message (if the "C<-w>" switch is set) and the reference
will simply be ignored.

Note also that potential infinite recursions (which would occur when
a given location contained itself, directly or indirectly!) are
detected automatically and refused (with an appropriate error message
and program abortion).

Because of the necessity for this check, it is more efficient to
embed locations using the object method "C<new()>" (where possible)
than with this mechanism, because embedding an empty new location
is always possible without checking.

REMEMBER that in order to minimize the number of "C<print()>" method calls
in your program (remember that lazyness is a programmer's virtue!) you
can always use the "here-document" syntax:

  $location->print(<<"VERBATIM");
  Article: $article
    Price: $price
    Stock: $stock
  VERBATIM

Remember also that the type of quotes (single/double) around the
terminating string ("VERBATIM" in this example) determines wether
variables inside the given text will be interpolated or not!

See L<perldata(1)> for more details!

=item *

C<print $location @items;>

Note that you can also use Perl's built-in operator "C<print>" for
printing to a file handle to actually print data to the given location
instead.

Note though that opening a location with "C<open()>" should be avoided:
The corresponding file or pipe will actually be created, but data will
nevertheless be sent to and read from the given location instead.

Likewise, closing a location with "C<close()>" has no effect other
than closing the corresponding (dummy) file or pipe.

=item *

C<$location-E<gt>printf($format, @items);>

This method is an analogue of the Perl (and C library) function
"C<printf()>".

See the section on "C<printf()>" in L<perlfunc(1)> and L<printf(3)> or
L<sprintf(3)> on your system for an explanation of its use.

=item *

C<printf $location $format, @items;>

Note that you can also use Perl's built-in operator "C<printf>" for
printing to a file handle to actually print data to the given location
instead.

Note though that opening a location with "C<open()>" should be avoided:
The corresponding file or pipe will actually be created, but data will
nevertheless be sent to and read from the given location instead.

Likewise, closing a location with "C<close()>" has no effect other
than closing the corresponding (dummy) file or pipe.

=item *

C<$location-E<gt>println(@items);>

This is (in principle) the same method as the "C<print()>" method described
further above, except that it appends a "newline" character ("C<\n>") to the
list of items being printed to the given location.

Note that this newline character is NOT appended (i.e., concatenated) to
the last item of the given list of items, but that it is rather stored as
an item of its own.

This is mainly because the last item of the given list could be a reference
(of another location), and also to make sure that the data (which could be
binary data) being stored in the given location is not altered (i.e.,
falsified) in any way.

This also allows the given list of items to be empty (in that case, there
wouldn't be a "last item" anyway to which the newline character could be
appended).

=item *

C<$item = $location-E<gt>read();>

In "scalar" context, the object method "C<read()>" returns the next item
of data from the given location.

If you have never read from this particular location before, "C<read()>"
will automatically start at the beginning.

Otherwise each call of "C<read()>" will return successive items from
the given location, thereby traversing the given location recursively
through all embedded locations which it may or may not contain.

To start reading at the beginning of the given location again, invoke
the method "C<reset()>" (see a little further below for a description)
on that location.

The method returns "C<undef>" when there is no more data to read.

Calling "C<read()>" again thereafter will simply continue to return
"C<undef>", even if you print some more data to the given location
in the meantime (!).

Remember to use "C<reset()>" if you want to read data from this particular
location again!

Finally, note that you can read from two (or any number of) different
locations at the same time, even if any of them is embedded (directly
or indirectly) in any other of the locations you are currently reading
from, without any interference!

This is because the state information associated with each "C<read()>"
operation is stored along with the (given) location for which the
"C<read()>" method has been called, and NOT with the locations the
"C<read()>" visits during its recursive descent.

=item *

C<$item = E<lt>$locationE<gt>;>

Note that you can also use Perl's built-in diamond operator "C<E<lt>E<gt>>"
for reading from a file handle to actually read data from the given location
instead.

BEWARE that unlike reading from a file, reading from a location in
this manner will return the items that have been stored in the given
location in EXACTLY the same way as they have been written to that
location previously, i.e., the data is NOT read back line by line,
with "C<\n>" as the line separator, but item by item, whatever the
items are!

(Note that you can also store binary data in locations, which will likewise
be read back in exactly the same way as it has been stored previously!)

=item *

C<@list = $location-E<gt>read();>

In "array" or "list" context, the object method "C<read()>" returns the
rest of the contents of the given location, starting from where the
last "C<read()>" left off, or from the beginning of the given location
if you never read from this particular location before or if you called
the method "C<reset()>" (see a little further below for a description)
for this location just before calling "C<read()>".

The method returns a single (possibly very long!) list containing
all the items of data the given location and all of its embedded
locations (if any) contain - in other words, the data contained
in all these nested locations is returned in a "flattened" way.

The method returns an empty list if the given location is empty
or if the last "C<read()>" read past the end of the data in the
given location.

Remember to use "C<reset()>" whenever you want to be sure to read
the contents of the given location from the very beginning!

For an explanation of "scalar" versus "array" or "list" context,
see the section on "Context" in L<perldata(1)>!

=item *

C<@list = E<lt>$locationE<gt>;>

Note that you can also use Perl's built-in diamond operator "C<E<lt>E<gt>>"
for reading from a file handle to actually read data from the given location
instead.

BEWARE that unlike reading from a file, reading from a location in
this manner will return the list of items that has been stored in
the given location in EXACTLY the same way as it has been written
to that location previously, i.e., the data is NOT read back as a
list of lines, with "C<\n>" as the line separator, but as a list
of items, whatever these items are!

(Note that you can also store binary data in locations, which will likewise
be read back in exactly the same way as it has been stored previously!)

=item *

C<Data::Locations-E<gt>reset();>

The CLASS METHOD "C<reset()>" calls the OBJECT METHOD "C<reset()>"
(see immediately below) for EVERY location that exists - NOT just
for the top-level locations.

=item *

C<$location-E<gt>reset();>

The OBJECT METHOD "C<reset()>" deletes the state information associated
with the given location which is used by the "C<read()>" method in order
to determine the next item of data to return.

After using "C<reset()>" on a given location, any subsequent "C<read()>" on
the same location will start reading at the beginning of that location.

This method has no other (side) effects whatsoever.

The method does nothing if there is no state information associated
with the given location, i.e., if the location has never been accessed
using the "C<read()>" method or if "C<reset()>" has already been called
for it before.

=item *

C<Data::Locations-E<gt>traverse(\&callback_function);>

The CLASS METHOD "C<traverse()>" cycles through all top-level locations
(IN NO PARTICULAR ORDER!) and calls the callback function you specified
once for each of them.

Expect one parameter handed over to your callback function which is
the object reference to the location in question.

Since callback functions can do a lot of unwanted things, use this
method with precaution!

=item *

C<$location-E<gt>traverse(\&callback_function);>

The OBJECT METHOD "C<traverse()>" performs a recursive descent on
the given location just as the method "C<dump()>" does internally,
but instead of printing the items of data contained in the location
to a file, this method calls the callback function you specified
once for each item stored in the location.

Expect one parameter handed over to your callback function which
is the next chunk of data contained in the given location (or the
locations embedded therein).

Since callback functions can do a lot of unwanted things, use this
method with precaution!

Please refer to the example given at the bottom of this document for
more details about how to use these two variants of the "C<traverse()>"
method!

Using the object method "C<traverse()>" is actually an alternate way of
reading back the contents of a given location (besides using the method
"C<read()>") completely in memory (i.e., without writing the contents of
the given location to a file and reading that file back in).

Note that the method "C<traverse()>" is completely independent from the
method "C<read()>" and that it has nothing to do with the state information
associated with the "C<read()>" method (which can be reset to point to the
beginning of the location using the method "C<reset()>").

This means that you can "C<traverse()>" and "C<read()>" (and "C<reset()>")
the same location at the same time without any interference.

=item *

C<$ok = Data::Locations-E<gt>dump();>

This CLASS METHOD dumps all top-level locations to their default
files (whose filenames must have been stored previously along with
each location using the method "C<new()>" or "C<filename()>").

Note that a warning message will be printed (if the "C<-w>" switch is set)
if any of the top-level locations happens to lack a default filename and
that the respective location will simply not be dumped to a file!

Did I mention that you should definitely consider using the "C<-w>" switch?

(Program execution continues in order to facilitate debugging of
your program and to save a maximum of your data in memory which
would be lost otherwise!)

Moreover, should any problem arise with any of the top-level locations
(for instance no filename given or filename invalid or unable to open
the specified file), then this method returns "false" ("C<0>").

The method returns "true" ("C<1>") only if ALL top-level locations
have been written to their respective files successfully.

Note also that a ">" is prepended to this default filename just
before opening the file if the default filename does not begin
with ">", "|" or "+" (leading white space is ignored).

This does not change the filename which is stored along with the
location, however.

Finally, note that this method does not affect the contents of
the locations that are being dumped.

If you want to delete all your locations once they have been dumped
to their respective files, call the class method "C<delete()>"
(explained further below) EXPLICITLY.

=item *

C<$ok = $location-E<gt>dump();>

The OBJECT METHOD "C<dump()>" dumps the given location to its default
file (whose filename must have been stored previously along with
this location using the method "C<new()>" or "C<filename()>").

Note that a warning message will be printed (if the "C<-w>" switch is set)
if the location happens to lack a default filename and that the location
will simply not be dumped to a file!

(Program execution continues in order to facilitate debugging of
your program and to save a maximum of your data in memory which
would be lost otherwise!)

Moreover, should any problem arise with the given location (for
instance no filename given or filename invalid or unable to open
the specified file), then this method returns "false" ("C<0>").

The method returns "true" ("C<1>") if the given location has been
successfully written to its respective file.

Note also that a ">" is prepended to this default filename just
before opening the file if the default filename does not begin
with ">", "|" or "+" (leading white space is ignored).

This does not change the filename which is stored along with the
location, however.

Finally, note that this method does not affect the contents of
the location being dumped.

If you want to delete this location once it has been dumped, call
the object method "C<delete()>" (explained further below) EXPLICITLY.

=item *

C<$ok = $location-E<gt>dump($filename);>

This variant of the OBJECT METHOD "C<dump()>" does the same as the
variant described immediately above, except that it overrides the
default filename stored along with the given location and uses the
indicated filename instead.

Note that the stored filename is just being overridden, BUT NOT
CHANGED.

I.e., if you call the method "C<dump()>" again without a filename argument
after calling it with an explicit filename argument once, the initial
filename stored with the given location will be used, NOT the filename
that you specified explicitly the last time when you called "C<dump()>"!

Should any problem arise with the given location (for instance if the
given filename is invalid or empty or if Perl was unable to open the
specified file), then this method returns "false" ("C<0>").

The method returns "true" ("C<1>") if the given location has been
successfully written to the specified file.

(Note that if the given filename is empty or contains only white space,
the method does NOT fall back to the filename previously stored along
with the given location, because doing so could overwrite valuable data!)

Note also that a ">" is prepended to the given filename if it does not
begin with ">", "|" or "+" (leading white space is ignored).

Finally, note that this method does not affect the contents of
the location being dumped.

If you want to delete this location once it has been dumped, call
the object method "C<delete()>" (explained below) EXPLICITLY.

=item *

C<Data::Locations-E<gt>delete();>

The CLASS METHOD "C<delete()>" deletes ALL locations and their contents
(NOT just all the top-level locations), which allows you to start over
completely from scratch.

Note that you do not need to call this method in order to initialize
this class before using it; the "C<use Data::Locations;>" statement
is sufficient.

BEWARE that any references to locations you might still be holding
in your program become invalid by invoking this method!

If you try to invoke a method using such an invalidated reference,
an error message (with program abortion) similar to this one will
occur:

  Can't locate object method "method" via package
  "[Error: stale reference!]" at program.pl line 65.

Note also that unlike other (typical) Perl objects (or "classes"),
locations are NOT automatically removed from memory (i.e.,
"garbage-collected") when your last reference pointing to any given
location is assigned a new value or if it goes out of scope (i.e.,
when the surrounding block ends to which your reference of a location
is local), even if this location is not embedded in any other location.

The reason for this is that you still might be interested in the location's
contents (which might be embedded in other locations and hence might still
be needed) even if you don't care about the reference to access it anymore.

This means that you can safely throw away the reference you got back
from the "C<Data::Locations>" constructor method ("C<new()>") as soon
as you don't need to directly access this location anymore.

It will nevertheless be dumped to a file when you call
"C<Data::Locations-E<gt>dump();>" thereafter IF it is either a top-level
location itself or if it is (directly or indirectly) embedded in a top-level
location.

If you want to "destroy" a single location (i.e., if you want to get
rid of its contents), call the OBJECT METHOD "C<delete()>" (described
immediately below) instead!

=item *

C<$location-E<gt>delete();>

The OBJECT METHOD "C<delete()>" deletes the CONTENTS of the given location -
the location CONTINUES TO EXIST and REMAINS EMBEDDED where it was!

The associated filename as well as the "toplevel" attribute stored along
with the given location are also NOT AFFECTED by this.

Note that a complete removal of the given location itself from memory
INCLUDING all references to this location (which may still be embedded
somewhere in other locations) is unnecessary if subsequently you do not
print anything to this location anymore!

If the given location is a top-level location, you might want to set the
associated filename to "/dev/null", though, using the method "C<filename()>"
(before or after deleting the location, this makes no difference), or to
clear its "top-level" status by using the method "C<toplevel()>" (for a
description of these methods, see further above).

BEWARE that the locations that were previously embedded in the given
(now deleted) location may not be contained in any other location anymore
after invoking this method!

If this happens, the affected "orphan" locations will automatically be
promoted to "top-level" locations.

Note however that you may have to define a default filename for these
orphaned locations (if you haven't done so previously) before invoking
"C<Data::Locations-E<gt>dump();>" in order to avoid data loss and the
warning message that will occur otherwise!

(The warning message will appear only if the "C<-w>" switch is set, though.)

=item *

C<$location-E<gt>tie('FILEHANDLE');>

=item *

C<$location-E<gt>tie(*FILEHANDLE);>

=item *

C<$location-E<gt>tie(\*FILEHANDLE);>

=item *

C<$location-E<gt>tie(*{FILEHANDLE});>

=item *

C<$location-E<gt>tie(\*{FILEHANDLE});>

Although locations behave like file handles themselves, i.e., even though
they allow you to use Perl's built-in operators "C<print>", "C<printf>"
and the diamond operator "C<E<lt>E<gt>>" for writing data to and reading
data from them, it is sometimes desirable to be able to redirect the
input/output from/to other file handles in a program to locations.

As an example, it might be desirable to "catch" the output that is being
sent to STDOUT and STDERR by some program in two separate locations.

(On Windows NT/95 platforms, this is probably the only way to redirect
the system's standard error device!)

The method "C<tie()>" (be careful not to confuse the METHOD "C<tie()>"
and the Perl OPERATOR "C<tie>"!) provides the means for doing so.

Simply invoke the method "C<tie()>" for the location which should be
"tied" to a file handle, and provide either the name, a typeglob or a
typeglob reference of the file handle in question as the (unique)
parameter to this method call.

After that, printing data to this file handle will actually send this
data to its "tied" location, and reading from this file handle will
actually read the data from the tied location instead.

Note that you don't need to explicitly "C<open>" or "C<close>" this
tied file handle (in fact you should NEVER try to do so!), even if
this file handle has never been explicitly opened before, and that
you can read from AND write to the associated location without any
further ado.

The physical file or terminal the tied file handle may have been
connected to previously is simply put on hold, i.e., it is NOT written
to or read from anymore, until you "C<untie>" the connection between
the file handle and the location (see further below for more details
about "C<untie>").

Note that you don't need to qualify the predefined file handles STDIN,
STDOUT and STDERR, which are enforced by Perl to be in package "main",
and file handles belonging to your own package, but that it causes no
harm if you do (provided that you supply the correct package name).

The only file handles you need to qualify are custom file handles belonging
to packages other than the one from which the method "C<tie()>" is called.

Examples:

          $location->tie('STDOUT');
          $location->tie('MYFILE');
          $location->tie('Other::Class::FILE');
          $location->tie(*STDERR);
          $location->tie(\*main::TEMP);

Please also refer to the example given at the bottom of this document
for more details about tying file handles to locations (especially
concerning STDERR).

See L<perlfunc(1)> and L<perltie(1)> for more details about "tying"
in general.

=item *

C<$location-E<gt>tie($filehandle);>

Note that you can also tie file handles to locations which have been created
by using the standard Perl modules "C<FileHandle>" and "C<IO::File>":

              use FileHandle;
              $fh = FileHandle->new();
              $location->tie($fh);

              use IO::File;
              $fh = IO::File->new();
              $location->tie($fh);

=item *

C<tie(*FILEHANDLE, "Data::Locations", $location);>

=item *

C<tie($filehandle, "Data::Locations", $location);>

Finally, note that you are not forced to use the METHOD "C<tie()>", and
that you can also use the OPERATOR "C<tie>" directly, as shown above!

=item *

C<$location = tied *FILEHANDLE;>

=item *

C<$location = tied $filehandle;>

The Perl operator "C<tied>" can be used to get back a reference to the
object the given file handle is "tied" to.

This can be used to invoke methods for this object, as follows:

          (tied *FILEHANDLE)->method();
          (tied $filehandle)->method();

See L<perlfunc(1)> for details.

=item *

C<untie *FILEHANDLE;>

=item *

C<untie $filehandle;>

The Perl operator "C<untie>" is used to cut the "magic" connection between
a file handle and its associated object.

Note that a warning message such as

  untie attempted while 7 inner references still exist

will be issued if the "C<-w>" switch is set and if more than one reference
to the tied object (i.e., in addition to the one possessed by the tied file
handle in question) exists.

With locations, this will be the rule, because locations are linked together
internally in many ways (in order to implement the embedding of locations).

To get rid of this warning message at this particular point in your program
while retaining the "C<-w>" switch activated in general, use the following
approach:

  {
      local($^W) = 0;     ##  Temporarily disable the "-w" switch
      untie *FILEHANDLE;
  }

(Note the surrounding braces which limit the effect of disabling the "C<-w>"
switch.)

See L<perlfunc(1)> and L<perltie(1)> for more details.

=item *

C<$filehandle = select();>

=item *

C<select($location);>

=item *

C<$oldfilehandle = select($newlocation);>

Remember that you can define the default output file handle using Perl's
built-in function "C<select()>".

"C<print>" (and "C<printf>") statements without explicit file handle always
send their output to the currently selected default file handle, which is
usually "STDOUT".

"C<select()>" always returns the current default file handle and allows you
to define a new default file handle at the same time.

By selecting a location as the default file handle, all subsequent "C<print>"
and "C<printf>" statements (without explicit file handle) will send their
output to that location:

  select($location);
  print "Hello, World!\n";  ##  prints to "$location"

See the section on "C<select()>" in L<perlfunc(1)> for more details!

=back

=head1 WARNING

"C<Data::Locations>" are rather delicate objects; they are valid Perl
file handles B<AS WELL AS> valid Perl objects B<AT THE SAME TIME>.

As a consequence, B<YOU CANNOT INHERIT> from the "C<Data::Locations>"
class, i.e., it is B<NOT> possible to create a derived class or subclass
from the "C<Data::Locations>" class!

Trying to do so will cause many severe malfunctions, most of which
will not be apparent immediately.

Chances are also great that by adding new attributes to a
"C<Data::Locations>" object you will clobber its (quite tricky)
underlying data structure.

Therefore, use embedding and delegation instead, rather than
inheritance, as shown below:

  package My::Class;
  use Data::Locations;
  sub new
  {
      my $self = shift;
      my ($location, $object);
      if (ref($self)) { $location = $self->{'location'}->new(); }
      else            { $location =     Data::Locations->new(); }
      $object = { 'location'   => $location,
                  'attribute1' => $whatever,
                  'attribute2' => $whatelse };
      bless($object, ref($self) || $self);
  }
  sub AUTOLOAD
  {
      my $self = shift;
      return if $AUTOLOAD =~ /::DESTROY$/;
      $AUTOLOAD =~ s/^My::Class:://;
      if (ref($self)) { $self->{'location'}->$AUTOLOAD(@_); }
      else            {     Data::Locations->$AUTOLOAD(@_); }
  }
  1;

Note that using this scheme, all methods available for
"C<Data::Locations>" objects are also (automatically and
directly) available for "C<My::Class>" objects, i.e.,

  use My::Class;
  $obj = My::Class->new();
  $obj->filename('test.txt');
  $obj->print("This is ");
  $sub = $obj->new();
  $obj->print("information.");
  @items = $obj->read();
  print "<", join('|', @items), ">\n";
  $sub->print("an additional piece of ");
  $obj->reset();
  @items = $obj->read();
  print "<", join('|', @items), ">\n";
  My::Class->dump();

will work as expected (unless you redefine these methods in
"C<My::Class>").

Moreover, with this scheme, you are free to add new methods
and/or attributes as you please.

The class "C<My::Class>" can also be subclassed without any
restrictions.

However, "C<My::Class>" objects are B<NOT> valid Perl file handles;
therefore, they cannot be used as such in combination with Perl's
built-in operators for file access.

=head1 EXAMPLE #1

  #!/usr/local/bin/perl -w

  use Data::Locations;

  use strict;
  no strict "vars";

  $head = Data::Locations->new();  ##  E.g. for interface definitions
  $body = Data::Locations->new();  ##  E.g. for implementation

  $head->filename("example.h");
  $body->filename("example.c");

  $common = $head->new();    ##  Embed a new location in "$head"
  $body->print($common);     ##  Embed this same location in "$body"

  ##  Create some more locations...

  $copyright = Data::Locations->new();
  $includes  = Data::Locations->new();
  $prototype = Data::Locations->new();

  ##  ...and embed them in location "$common":

  $common->print($copyright,$includes,$prototype);

  ##  Note that the above is just to show you an alternate
  ##  (but less efficient) way! Normally you would use:
  ##
  ##      $copyright = $common->new();
  ##      $includes  = $common->new();
  ##      $prototype = $common->new();

  $head->println(";");  ##  The final ";" after a function prototype
  $body->println();     ##  Just a newline after a function header

  $body->println("{");
  $body->println('    printf("Hello, world!\n");');
  $body->println("}");

  $includes->print("#include <");
  $library = $includes->new();     ##  Nesting even deeper still...
  $includes->println(">");

  $prototype->print("void hello(void)");

  $copyright->println("/*");
  $copyright->println("    Copyright (c) 1997, 1998, 1999 by Steffen Beyer.");
  $copyright->println("    All rights reserved.");
  $copyright->println("*/");

  $library->print("stdio.h");

  $copyright->filename("default.txt");

  $copyright->dump(">-");

  print "default filename = '", $copyright->filename(), "'\n";

  Data::Locations->dump();

  __END__

When executed, this example will print

  /*
      Copyright (c) 1997, 1998, 1999 by Steffen Beyer.
      All rights reserved.
  */
  default filename = 'default.txt'

to the screen and create the following two files:

  ::::::::::::::
  example.c
  ::::::::::::::
  /*
      Copyright (c) 1997, 1998, 1999 by Steffen Beyer.
      All rights reserved.
  */
  #include <stdio.h>
  void hello(void)
  {
      printf("Hello, world!\n");
  }

  ::::::::::::::
  example.h
  ::::::::::::::
  /*
      Copyright (c) 1997, 1998, 1999 by Steffen Beyer.
      All rights reserved.
  */
  #include <stdio.h>
  void hello(void);

=head1 EXAMPLE #2

  #!/usr/local/bin/perl -w

  use Data::Locations;

  use strict;
  no strict "vars";

  $html = Data::Locations->new("example.html");

  $html->println("<HTML>");
  $head = $html->new();
  $body = $html->new();
  $html->println("</HTML>");

  $head->println("<HEAD>");
  $tohead = $head->new();
  $head->println("</HEAD>");

  $body->println("<BODY>");
  $tobody = $body->new();
  $body->println("</BODY>");

  $tohead->print("<TITLE>");
  $title = $tohead->new();
  $tohead->println("</TITLE>");

  $tohead->print('<META NAME="description" CONTENT="');
  $description = $tohead->new();
  $tohead->println('">');

  $tohead->print('<META NAME="keywords" CONTENT="');
  $keywords = $tohead->new();
  $tohead->println('">');

  $tobody->println("<CENTER>");

  $tobody->print("<H1>");
  $tobody->print($title);      ##  Re-using this location!!
  $tobody->println("</H1>");

  $contents = $tobody->new();

  $tobody->println("</CENTER>");

  $title->print("'Data::Locations' Example HTML-Page");

  $description->println("Example for generating HTML pages");
  $description->print("using 'Data::Locations'");

  $keywords->print("locations, magic, insertion points,\n");
  $keywords->print("nested, recursive");

  $contents->println("This page was generated using the");
  $contents->println("<P>");
  $contents->println("&quot;<B>Data::Locations</B>&quot;");
  $contents->println("<P>");
  $contents->println("module for Perl.");

  Data::Locations->dump();

  __END__

When executed, this example will produce
the following file ("example.html"):

  <HTML>
  <HEAD>
  <TITLE>'Data::Locations' Example HTML-Page</TITLE>
  <META NAME="description" CONTENT="Example for generating HTML pages
  using 'Data::Locations'">
  <META NAME="keywords" CONTENT="locations, magic, insertion points,
  nested, recursive">
  </HEAD>
  <BODY>
  <CENTER>
  <H1>'Data::Locations' Example HTML-Page</H1>
  This page was generated using the
  <P>
  &quot;<B>Data::Locations</B>&quot;
  <P>
  module for Perl.
  </CENTER>
  </BODY>
  </HTML>

=head1 EXAMPLE #3

  #!/usr/local/bin/perl -w

  ##  Note that this example only works as described if the "-w" switch
  ##  is set!

  package Non::Sense;

  ##  (This is to demonstrate that this example works with ANY package)

  use Data::Locations;
  use FileHandle;

  use strict;
  use vars qw($level0 $level1 $level2 $level3 $fh $fake);

  ##  Create the topmost location:

  $level0 = Data::Locations->new("level0.txt");

  print $level0 <<'VERBATIM';
  Printing first line to location 'level0' via OPERATOR 'print'.
  VERBATIM

  ##  Create an embedded location (nested 1 level deep):

  $level1 = $level0->new();

  $level0->print(<<'VERBATIM');
  Printing last line to location 'level0' via METHOD 'print'.
  VERBATIM

  ##  Now "tie" the embedded location to file handle STDOUT:

  $level1->tie('STDOUT');

  print "Printing to location 'level1' via STDOUT.\n";

  ##  Create another location (which will be embedded later):

  $level2 = Data::Locations->new();

  ##  Create a file handle ("IO::Handle" works equally well):

  $fh = FileHandle->new();

  ##  Now "tie" the location "$level2" to this file handle "$fh":

  $level2->tie($fh);

  ##  And select "$fh" as the default output file handle:

  select($fh);

  print "Printing to location 'level2' via default file handle '\$fh'.\n";

  ##  Embed location "$level2" in location "$level1":

  print $level1 $level2;

  ##  (Automatically removes "toplevel" status from location "$level2")

  print STDOUT "Printing to location 'level1' explicitly via STDOUT.\n";

  ##  Create a third embedded location (nested 3 levels deep):

  $level3 = $level2->new();

  ##  Restore STDOUT as the default output file handle:

  select(STDOUT);

  print $fh "Printing to location 'level2' via file handle '\$fh'.\n";

  ##  Trap all warnings:

  $SIG{__WARN__} = sub
  {
      print STDERR "WARNING intercepted:\n", @_, "End Of Warning.\n";
  };

  ##  Note that WITHOUT this trap, warnings would go to the system
  ##  standard error device DIRECTLY, WITHOUT passing through the
  ##  file handle STDERR!

  ##  Now "tie" location "$level3" to file handle STDERR:

  $level3->tie(*STDERR);

  ##  Provoke a warning message (don't forget the "-w" switch!):

  $fake = \$fh;
  $level3->print($fake);

  ##  Provoke another warning message (don't forget the "-w" switch!):

  $level3->dump();

  {
      ##  Silence warning that reference count of location is still > 0:

      local($^W) = 0;

      ##  And untie file handle STDOUT from location "$level1":

      untie *STDOUT;
  }

  print "Now STDOUT goes to the screen again.\n";

  ##  Read from location "$level3":

  while (<STDERR>)  ##  Copy warning messages to the screen:
  {
      print if
      (s/^Data::Locations::.+?\(\):\s+(.+?)\s+at\s+.+$/Warning: $1/m);
  }

  while (<STDERR>) { print; }

  ##  (Prints nothing because location was already read past its end)

  ##  Reset the internal reading mark:

  (tied *{STDERR})->reset();

  ##  (You should usually use "$level3->reset();", though!)

  while (<STDERR>) { print; }

  ##  (Copies the contents of location "$level3" to the screen)

  ##  Write output file "level0.txt":

  Data::Locations->dump();

  __END__

When running this example, the following text will be printed to the screen
(provided that you did use the "C<-w>" switch!):

  Now STDOUT goes to the screen again.
  Warning: reference 'REF' ignored
  Warning: filename missing or empty
  WARNING intercepted:
  Data::Locations::print(): reference 'REF' ignored at test.pl line 92
  End Of Warning.
  WARNING intercepted:
  Data::Locations::dump(): filename missing or empty at test.pl line 96
  End Of Warning.

The example also produces an output file named "level0.txt" with the
following contents:

  Printing first line to location 'level0' via OPERATOR 'print'.
  Printing to location 'level1' via STDOUT.
  Printing to location 'level2' via default file handle '$fh'.
  WARNING intercepted:
  Data::Locations::print(): reference 'REF' ignored at test.pl line 92
  End Of Warning.
  WARNING intercepted:
  Data::Locations::dump(): filename missing or empty at test.pl line 96
  End Of Warning.
  Printing to location 'level2' via file handle '$fh'.
  Printing to location 'level1' explicitly via STDOUT.
  Printing last line to location 'level0' via METHOD 'print'.

=head1 EXAMPLE #4

The following code fragment is an example of how you can use the callback
mechanism of this class to collect the contents of all top-level locations
in a string (which is printed to the screen in this example):

  sub concat
  {
      $string .= $_[0];
  }

  sub list
  {
      $string .= $ruler;
      $string .= "\"" . $_[0]->filename() . "\":\n";
      $string .= $ruler;
      $_[0]->traverse(\&concat);
      $string .= "\n" unless ($string =~ /\n$/);
  }

  $ruler = '=' x 78 . "\n";

  $string = '';

  Data::Locations->traverse(\&list);

  $string .= $ruler;

  print $string;

=head1 SEE ALSO

perl(1), perldata(1), perlfunc(1), perlsub(1),
perlmod(1), perlref(1), perlobj(1), perlbot(1),
perltoot(1), perltie(1), printf(3), sprintf(3).

=head1 VERSION

This man page documents "Data::Locations" version 4.3.

=head1 AUTHOR

  Steffen Beyer
  Ainmillerstr. 5 / App. 513
  D-80801 Munich
  Germany

  mailto:sb@engelschall.com
  http://www.engelschall.com/u/sb/download/

B<Please contact me by e-mail whenever possible!>

=head1 COPYRIGHT

Copyright (c) 1997, 1998, 1999 by Steffen Beyer.
All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, i.e., under the
terms of the "Artistic License" or the "GNU General Public License".

Please refer to the files "Artistic.txt" and "GNU_GPL.txt"
in this distribution for details!

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

