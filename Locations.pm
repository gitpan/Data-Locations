
##  Copyright (c) 1997 by Steffen Beyer. All rights reserved.
##  This package is free software; you can redistribute and/or
##  modify it under the same terms as Perl itself.

package Data::Locations;

use strict;

use Carp;

use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

require Exporter;

require Tie::Handle;

@ISA = qw(Exporter Tie::Handle);

@EXPORT = qw();

@EXPORT_OK = qw();

$VERSION = "2.0";

@Data::Locations::List = ();  ##  sequential list of all existing locations

sub new
{
    croak
  "Usage: \$newlocation = {Data::Locations,\$location}->new([\$filename]);"
    if ((@_ < 1) || (@_ > 2));

    my($outer) = shift;
    my($filename,$inner,$class);

    $filename = '';
    $filename = shift if (@_ > 0);

    if (ref($filename))
    {
        croak "Data::Locations::new(): reference not allowed as filename";
    }

    $inner = { };
    $inner->{'file'}  = $filename;
    $inner->{'data'}  = [ ];
    $inner->{'outer'} = { };
    $inner->{'inner'} = { };
    $inner->{'top'}   = 0;

    ##  Note that $hash{$ref} is exactly the same as
    ##  $hash{"$ref"} because references are automatically
    ##  converted into strings when they are used as keys of a hash!!!

    if (ref($outer))  ##  object method
    {
        $class = ref($outer);
        bless($inner, $class);              ##  MUST come first!
        push(@{$outer->{'data'}}, $inner);
        $outer->{'inner'}->{$inner} = $inner;
        $inner->{'outer'}->{$outer} = $outer;
    }
    else              ##  class method
    {
        $class = $outer || 'Data::Locations';
        bless($inner, $class);
        $inner->{'top'} = 1;
    }
    push(@Data::Locations::List, $inner);
    return( $inner );
}

sub set_filename
{
    croak "Usage: \$location->set_filename(\$filename);"
      if (@_ != 2);

    my($location,$filename) = @_;

    if (ref($filename))
    {
        croak
      "Data::Locations::set_filename(): reference not allowed as filename";
    }

    $location->{'file'} = $filename;
}

sub get_filename
{
    croak "Usage: \$location->get_filename();"
      if (@_ != 1);

    my($location) = shift;

    return( $location->{'file'} );
}

#################################################################
##                                                             ##
##  The following function is intended for internal use only!  ##
##  Use it only if you know exactly what you are doing!        ##
##                                                             ##
#################################################################

sub self_contained
{
    croak "Usage: if (self_contained(\$outer,\$inner))"
      if (@_ != 2);

    my($outer,$inner) = @_;
    my($list,$item);

    return(1) if ($outer eq $inner);
    $list = $inner->{'inner'};
    foreach $item (keys(%{$list}))
    {
        $inner = $list->{$item};
        return(1) if (self_contained($outer,$inner));
    }
    return(0);
}

sub print
{
    croak "Usage: \$location->print(\@items);"
      if (@_ < 1);

    my($outer) = shift;
    my($inner,$message);

    foreach $inner (@_)
    {
        if (ref($inner))
        {
            if (ref($inner) eq 'Data::Locations')
            {
                if (self_contained($outer,$inner))
                {
                    croak
                  "Data::Locations::print(): infinite recursion loop attempted";
                }
                else
                {
                    push(@{$outer->{'data'}}, $inner);
                    $outer->{'inner'}->{$inner} = $inner;
                    $inner->{'outer'}->{$outer} = $outer;
                }
            }
            else
            {
                $message =
  "Data::Locations::print(): illegal reference '".ref($inner)."' ignored";
                carp $message if $^W;
            }
        }
        else
        {
            push(@{$outer->{'data'}}, $inner);
        }
    }
}

sub println
{
    croak "Usage: \$location->println(\@items);"
      if (@_ < 1);

    my($location) = shift;

    $location->print(@_,"\n");

    ##  We use a separate "\n" here (instead of concatenating it
    ##  with the last item) in case the last item is a reference!
}

sub printf
{
    croak "Usage: \$location->printf(\$format,\@items);"
      if (@_ < 2);

    my($location) = shift;
    my($format) = shift;

    $location->print( sprintf($format,@_) );
}

###############################################################
##                                                           ##
##  The following method is intended for internal use only!  ##
##  Use it only if you know exactly what you are doing!      ##
##                                                           ##
###############################################################

sub dump_recursive
{
    croak "Usage: \$location->dump_recursive();"
      if (@_ != 1);

    my($location) = shift;
    my($item);

    foreach $item (@{$location->{'data'}})
    {
        if (ref($item))
        {
            if (ref($item) eq 'Data::Locations')
            {
                $item->dump_recursive();
            }
        }
        else
        {
            print LOCATION $item;
        }
    }
}

###############################################################
##                                                           ##
##  The following method is intended for internal use only!  ##
##  Use it only if you know exactly what you are doing!      ##
##                                                           ##
###############################################################

sub dump_location
{
    croak "Usage: \$ok = \$location->dump_location([\$filename]);"
      if ((@_ < 1) || (@_ > 2));

    my($location) = shift;
    my($filename,$message);

    $filename = $location->{'file'};
    $filename = shift if (@_ > 0);

    if (ref($filename))
    {
        croak
      "Data::Locations::dump_location(): reference not allowed as filename";
    }
    if ($filename =~ /^\s*$/)
    {
        carp "Data::Locations::dump_location(): no filename given" if $^W;
        return(0);
    }
    unless ($filename =~ /^\s*[>\|+]/)
    {
        $filename = '>' . $filename;
    }
    unless (open(LOCATION, $filename))
    {
        $message =
      "Data::Locations::dump_location(): can't open file '$filename': ".lc($!);
        carp $message if $^W;
        return(0);
    }
    $location->dump_recursive();
    close(LOCATION);
    return(1);
}

sub dump
{
    croak
  "Usage: \$ok = Data::Locations->dump(); | \$ok = \$location->dump([\$filename]);"
    if ((@_ < 1) || (@_ > 2) || ((@_ == 2) && !ref($_[0])));

    my($location) = shift;
    my($ok);

    if (ref($location))  ##  object method
    {
        if (@_ > 0)
        {
            if (ref($_[0]))
            {
                croak
              "Data::Locations::dump(): reference not allowed as filename";
            }
            return( $location->dump_location($_[0]) );
        }
        else
        {
            return( $location->dump_location() );
        }
    }
    else                 ##  class method
    {
        $ok = 1;
        foreach $location (@Data::Locations::List)
        {
            if ($location->{'top'})
            {
                unless ($location->dump_location()) { $ok = 0; }
            }
        }
        return( $ok );
    }
}

###############################################################
##                                                           ##
##  The following method is intended for internal use only!  ##
##                                                           ##
###############################################################

sub readline
{
    croak "Usage: \$line = \$location->readline();"
      if (@_ != 1);

    my($location) = shift;
    my($stack,$entry,$index,$array,$item);

    if (defined $location->{'stack'})
    {
        $stack = $location->{'stack'};
    }
    else
    {
        $stack = [ [ 0, $location->{'data'} ] ];
        $location->{'stack'} = $stack;
    }
    if (scalar(@{$stack}))
    {
        $entry = ${$stack}[0];
        $index = $entry->[0];
        $array = $entry->[1];
        if ($index > $#{$array})
        {
            shift(@{$stack});
            return( $location->readline() );
        }
        else
        {
            $item = ${$array}[$index];
            $entry->[0] = ++$index;
            if (ref($item))
            {
                if (ref($item) eq 'Data::Locations')
                {
                    $entry = [ 0, $item->{'data'} ];
                    unshift(@{$stack}, $entry);
                }
                return( $location->readline() );
            }
            else
            {
                return($item);
            }
        }
    }
    else
    {
        return(undef);
    }
}

###############################################################
##                                                           ##
##  The following method is intended for internal use only!  ##
##                                                           ##
###############################################################

sub readlist
{
    croak "Usage: \@list = \$location->readlist();"
      if (@_ != 1);

    my($location) = shift;
    my(@result);
    my($item);

    while ($item = $location->readline())
    {
        push(@result, $item);
    }
    return( @result );
}

sub read
{
    croak "Usage: \$line = \$location->read(); | \@list = \$location->read();"
      if (@_ != 1);

    my($location) = shift;

    if (defined wantarray)
    {
        if (wantarray)
        {
            return( $location->readlist() );
        }
        else
        {
            return( $location->readline() );
        }
    }
}

sub reset
{
    croak "Usage: {Data::Locations,\$location}->reset();"
      if (@_ != 1);

    my($location) = shift;

    if (ref($location))  ##  object method
    {
        if (defined $location->{'stack'})
        {
            delete $location->{'stack'};
        }
    }
    else                 ##  class method
    {
        foreach $location (@Data::Locations::List)
        {
            if (defined $location->{'stack'})
            {
                delete $location->{'stack'};
            }
        }
    }
}

###############################################################
##                                                           ##
##  The following method is intended for internal use only!  ##
##  Use it only if you know exactly what you are doing!      ##
##                                                           ##
###############################################################

sub traverse_recursive
{
    croak "Usage: \$location->traverse_recursive(\\&callback_function);"
      if (@_ != 2);

    my($location,$callback) = @_;
    my($item);

    if (ref($callback) ne 'CODE')
    {
        croak "Data::Locations::traverse_recursive(): not a code reference";
    }

    foreach $item (@{$location->{'data'}})
    {
        if (ref($item))
        {
            if (ref($item) eq 'Data::Locations')
            {
                $item->traverse_recursive($callback);
            }
        }
        else
        {
            &{$callback}($item);
        }
    }
}

####################################################################
##                                                                ##
##  The following method is intended for experienced users only!  ##
##  Use with extreme precaution!                                  ##
##                                                                ##
####################################################################

sub traverse
{
    croak
  "Usage: {Data::Locations,\$location}->traverse(\\&callback_function);"
    if (@_ != 2);

    my($location,$callback) = @_;

    if (ref($callback) ne 'CODE')
    {
        croak "Data::Locations::traverse(): not a code reference";
    }

    if (ref($location))  ##  object method
    {
        $location->traverse_recursive($callback);
    }
    else                 ##  class method
    {
        foreach $location (@Data::Locations::List)
        {
            if ($location->{'top'})
            {
                &{$callback}($location);
            }
        }
    }
}

sub delete
{
    croak "Usage: {Data::Locations,\$location}->delete();"
      if (@_ != 1);

    my($outer) = shift;
    my($list,$item,$inner,$link);

    if (ref($outer))  ##  object method
    {
        $list = $outer->{'inner'};
        foreach $item (keys(%{$list}))
        {
            $inner = $list->{$item};
            $link = $inner->{'outer'};
            delete $link->{$outer};
            unless (scalar(%{$link}))
            {
                $inner->{'top'} = 1;
            }
        }
        $outer->{'data'}  = [ ];
        $outer->{'inner'} = { };
    }
    else              ##  class method
    {
        foreach $outer (@Data::Locations::List)
        {
            $outer->{'file'}  = '';   ##  We need to do this explicitly
            $outer->{'data'}  = [ ];  ##  in order to free memory because
            $outer->{'outer'} = { };  ##  the user might still be in
            $outer->{'inner'} = { };  ##  possession of references
            $outer->{'top'}   = 0;    ##  to these locations!

            bless($outer, "[Error: stale reference!]");
        }
        undef @Data::Locations::List;
        @Data::Locations::List = ();
    }
}

###############################################################
##                                                           ##
##  The following method is intended for internal use only!  ##
##                                                           ##
###############################################################

sub open
{
    $_[0]->reset();
}

###############################################################
##                                                           ##
##  The following method is intended for internal use only!  ##
##                                                           ##
###############################################################

sub close
{
    $_[0]->reset();
}

1;

__END__

=head1 NAME

Data::Locations - recursive placeholders in the data you generate

"Locations" free you from the need to GENERATE data in the
same order in which it will be USED later.

They allow you to define insertion points in the middle of your
data which you can fill in later, at any time you want!

For instance you do not need to write output files in rigidly
sequential order anymore using this module.

Instead, write the data to locations in the order which is the most
appropriate and natural for you!

When you're finished, write your data to a file or process it otherwise,
purely in memory (faster!).

Most important: You can nest these placeholders in any way you want!

Potential infinite recursions are detected automatically and refused.

This means that you can GENERATE data ONLY ONCE in your program and
USE it MANY TIMES at different places, while the data itself is stored
in memory only once.

Maybe a picture will help to better understand this concept:

Think of "locations" as folders (or drawers) containing papers
in a sequential order, most of which contain printable text or
data, while some may contain the name of another folder (or drawer).

When dumping a location to a file, the papers contained in it are
printed one after another in the order they were originally stored.
When a paper containing the name of another location is encountered,
however, the contents of that location are processed before continuing
to print the remaining papers of the current location. And so forth,
in a recursive descent.

Note that you are not confined to dumping locations to a file,
you can also process them directly in memory!

Note further that you may create as many locations with as many
embedded locations, as many nesting levels deep as your available
memory will permit.

Not even Clodsahamp's multidimensionally expanded tree house (see
Alan Dean Foster's fantasy novel "Spellsinger" for more details!)
can compare with this! C<:-)>

See L<Tie::Handle(3)> and the example given at the end of this manpage
for how to tie data locations to file handles in order to further simplify
writing data to and reading data from locations.

=head1 SYNOPSIS

=over 4

=item *

C<use Data::Locations;>

=item *

C<$location = Data::Locations-E<gt>new();>

=item *

C<$location = Data::Locations-E<gt>new($filename);>

=item *

C<$sublocation = $location-E<gt>new();>

=item *

C<$sublocation = $location-E<gt>new($filename);>

=item *

C<$location-E<gt>set_filename($filename);>

=item *

C<$filename = $location-E<gt>get_filename();>

=item *

C<$location-E<gt>print(@items);>

=item *

C<$location-E<gt>println(@items);>

=item *

C<$location-E<gt>printf($format,@items);>

=item *

C<$ok = Data::Locations-E<gt>dump();>

=item *

C<$ok = $location-E<gt>dump();>

=item *

C<$ok = $location-E<gt>dump($filename);>

=item *

C<$line = $location-E<gt>read();>

=item *

C<@list = $location-E<gt>read();>

=item *

C<Data::Locations-E<gt>reset();>

=item *

C<$location-E<gt>reset();>

=item *

C<Data::Locations-E<gt>traverse(\&callback_function);>

=item *

C<$location-E<gt>traverse(\&callback_function);>

=item *

C<Data::Locations-E<gt>delete();>

=item *

C<$location-E<gt>delete();>

=item *

C<$location-E<gt>tie('FILEHANDLE');>

=item *

C<$location-E<gt>tie($filehandle);>

=back

=head1 TROUBLE-SHOOTING

Note that the warning messages which this module might want to issue
will only appear if you use the C<-w> switch!

Use this switch either on the command line:

                % perl -w example.pl

or append it to the "shell-bang" line at the top of (i.e., the very
first line of) your script:

                #!/usr/local/bin/perl -w

Remember: If something strange has gone wrong with your program and
you're not sure where you should look for help, try the C<-w> switch
first. It will often point out exactly where the trouble is.

Whenever you get mysterious behavior, try the C<-w> switch!!! Whenever
you don't get mysterious behavior, try using C<-w> anyway.

=head1 DESCRIPTION

=over 4

=item *

C<use Data::Locations;>

Enables the use of locations in your program.

=item *

C<$location = Data::Locations-E<gt>new();>

The CLASS METHOD "new()" creates a new top-level location
("top-level" means that it isn't embedded in any other location).

Note that CLASS METHODS are invoked using the NAME of their class, i.e.,
"Data::Locations" in this case, in contrast to OBJECT METHODS which
are invoked using an object reference such as returned by the class's
object constructor method (which "new()" happens to be).

Any location that you intend to dump to a file later on in your program
needs to have a filename associated with it, which you can either specify
using one of the variants of the "new()" method where you supply a filename
(as the one shown immediately below), or by setting this filename using the
method "set_filename()" (see further below), or by specifying an explicit
filename when invoking the "dump()" method (see also further below) itself
on a particular location.

Otherwise an error will occur when you try to dump the location (in fact,
a warning message is printed to the screen (if the C<-w> switch is set)
and the location will simply not be dumped to a file but program execution
continues).

=item *

C<$location = Data::Locations-E<gt>new($filename);>

This variant of the CLASS METHOD "new()" creates a new top-level
location ("top-level" means that it isn't embedded in any other
location) and assigns a default filename to it.

Note that this filename is simply passed through to the Perl "open()"
function later on (which is called internally when you dump your locations
to a file), which means that any legal Perl filename may be used such as
">-" (for writing to STDOUT) and "| more", to give you just two of the
more exotic examples!

See the section on "open()" in L<perlfunc(1)> for more details!

=item *

C<$sublocation = $location-E<gt>new();>

The OBJECT METHOD "new()" creates a new location which is embedded
in the given location "$location" at the current position (defined
by what has been printed to the embedding location till this moment).

Such nested locations usually do not need a filename associated with
them (because they will be dumped to the same file as the location in
which they are embedded), unless you want to dump this location to a
file of its own, additionally.

In the latter case, use the variant of the "new()" method shown
immediately below or the method "set_filename()" (see below) to
set this filename, or call the method "dump()" (explained further
below) with an appropriate filename argument.

=item *

C<$sublocation = $location-E<gt>new($filename);>

This variant of the OBJECT METHOD "new()" creates a new location
which is embedded in the given location "$location" at the current
position (defined by what has been printed to the embedding location
till this moment) and assigns a default filename to it.

See the section on "open()" in L<perlfunc(1)> for more details about
what filenames you may use (i.e., which filenames are legal)!

=item *

C<$location-E<gt>set_filename($filename);>

This object method stores a filename along with the given location
which will be used as the default filename when dumping that location.

You may set the filename associated with any given location using this
method any number of times.

See the method "get_filename()" immediately below for retrieving
the default filename that has been stored along with a given location.

=item *

C<$filename = $location-E<gt>get_filename();>

This object method returns the default filename that has previously
been stored along with the given location, using either the method
"new()" or the method "set_filename()".

=item *

C<$location-E<gt>print(@items);>

This object method prints the given arguments to the indicated
location, i.e., appends the given items to the given location.

IMPORTANT FEATURE:

Note that you can EMBED any given location IN MORE THAN ONE surrounding
location using this method!

Simply use a statement similar to this one:

        $location->print($sublocation);

This embeds location "$sublocation" in location "$location" at the
current position (defined by what has been printed to location
"$location" till this moment).

This is especially useful if you are generating data once in your
program which you need at several places in your output.

This saves a lot of memory because only a reference of the embedded
location is stored in every embedding location instead of all the
data, which is stored only once!

Note that other references than "Data::Locations" object references are
illegal, trying to "print" such a reference to a location will result
in a warning message (if the C<-w> switch is set) and the reference will
simply be ignored.

Note also that potential infinite recursions (which would occur when
a given location contained itself, directly or indirectly!) are
detected automatically and refused (with an appropriate error message
and program abortion).

Because of the necessity for this check, it is more efficient to
embed locations using the object method "new()" (where possible)
than with this mechanism, because embedding an empty new location
is always possible without checking.

REMEMBER that in order to minimize the number of "print()" method calls
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

C<$location-E<gt>println(@items);>

Same as the "print()" method above, except that a "newline" character
("C<\n>") is appended at the end of the list of items to be printed
(just a newline character is printed if no arguments (= an empty
argument list) are given).

=item *

C<$location-E<gt>printf($format,@items);>

This method is an analogue of the Perl (and C library) function
"printf()".

See the section on "printf()" in L<perlfunc(1)> and L<printf(3)>
or L<sprintf(3)> on your system for an explanation of its possible
uses.

=item *

C<$ok = Data::Locations-E<gt>dump();>

This CLASS METHOD dumps all top-level locations to their default
files (whose filenames must have been stored previously along with
each location using the method "new()" or "set_filename()").

Note that a warning message will be printed (if the C<-w> switch is set)
if any of the top-level locations happens to lack a default filename and
that the respective location will simply not be dumped to a file!

Did I mention that you should definitely consider using the C<-w> switch?

(Program execution continues in order to facilitate debugging of
your program and to save a maximum of your data in memory which
would be lost otherwise!)

Moreover, should any problem arise with any of the top-level locations
(for instance no filename given or filename invalid or unable to open
the specified file), then this method returns "false" (0).

The method returns "true" (1) only if ALL top-level locations have
been written to their respective files successfully.

Note also that a ">" is prepended to this default filename just
before opening the file if the default filename does not begin
with ">", "|" or "+" (leading white space is ignored).

This does not change the filename which is stored along with the
location, however.

Finally, note that this method does not affect the contents of
the locations that are being dumped.

If you want to delete all your locations once they have been dumped
to their respective files, call the class method "delete()" (explained
further below) EXPLICITLY.

=item *

C<$ok = $location-E<gt>dump();>

The OBJECT METHOD "dump()" dumps the given location to its default
file (whose filename must have been stored previously along with
this location using the method "new()" or "set_filename()").

Note that a warning message will be printed (if the C<-w> switch is set)
if the location happens to lack a default filename and that the location
will simply not be dumped to a file!

(Program execution continues in order to facilitate debugging of
your program and to save a maximum of your data in memory which
would be lost otherwise!)

Moreover, should any problem arise with the given location (for
instance no filename given or filename invalid or unable to open
the specified file), then this method returns "false" (0).

The method returns "true" (1) if the given location has been
successfully written to its respective file.

Note also that a ">" is prepended to this default filename just
before opening the file if the default filename does not begin
with ">", "|" or "+" (leading white space is ignored).

This does not change the filename which is stored along with the
location, however.

Finally, note that this method does not affect the contents of
the location being dumped.

If you want to delete this location once it has been dumped, call
the object method "delete()" (explained further below) EXPLICITLY.

=item *

C<$ok = $location-E<gt>dump($filename);>

This variant of the OBJECT METHOD "dump()" does the same as the
variant described immediately above, except that it overrides the
default filename stored along with the given location and uses the
indicated filename instead.

Note that the stored filename is just being overridden, BUT NOT
CHANGED.

I.e., if you call the method "dump()" again without a filename argument
after calling it with an explicit filename argument once, the initial
filename stored with the given location will be used, NOT the filename
that you specified explicitly the last time when you called "dump()"!

Should any problem arise with the given location (for instance if the
given filename is invalid or if Perl was unable to open the specified
file), then this method returns "false" (0).

The method returns "true" (1) if the given location has been
successfully written to the specified file.

(Note that if the given filename is empty or contains only white space,
the method does NOT fall back to the filename previously stored along
with the given location because doing so could overwrite valuable data!)

Note also that a ">" is prepended to the given filename if it does not
begin with ">", "|" or "+" (leading white space is ignored).

Finally, note that this method does not affect the contents of
the location being dumped.

If you want to delete this location once it has been dumped, call
the object method "delete()" (explained further below) EXPLICITLY.

=item *

C<$line = $location-E<gt>read();>

In "scalar" context, the object method "read()" returns the next item
of data from the given location.

If you have never read from this particular location before, "read()"
will automatically start at the beginning.

Otherwise each call of "read()" will return successive items from
the given location, thereby traversing the given location recursively
through all embedded locations it may or may not contain.

To start reading at the beginning of the given location again, invoke
the method "reset()" (see a little further below) on that location.

The method returns "undef" when there is no more data to read.

(Calling "read()" again thereafter will simply continue to return "undef")

Note that you can continue to read data from the given location even
after receiving "undef" from this method if you "print()" some more
data to this location before attempting to "read()" from it again!

Remember to use "reset()" if this is not what you want.

Finally, note that you can read from two (or any number of) different
locations at the same time, even if any of them is embedded (directly
or indirectly) in any other, without any interference!

This is because the state information associated with each "read()"
operation is stored along with the (given) location for which the
"read()" method has been called, and NOT with the locations the
"read()" visits during its recursive descent.

=item *

C<@list = $location-E<gt>read();>

In "array" or "list" context, the object method "read()" returns the
rest of the contents of the given location, starting from where the
last "read()" left off, or from the beginning of the given location
if you never read from this particular location before or if you
called the method "reset()" (see below this method) for this location
just before calling "read()".

The method returns a single (possibly very long!) list containing
all the items of data the given location and all of its embedded
locations (if any) contain - i.e., the data contained in all these
nested locations is returned in a "flattened" way.

The method returns an empty list if the given location is empty
or if the last "read()" read past the end of the data in the
given location.

Remember to use "reset()" whenever you want to make absolutely sure
that you will be reading the whole contents of the given location!

For an explanation of "scalar" versus "array" or "list" context,
see the section on "Context" in L<perldata(1)>!

=item *

C<Data::Locations-E<gt>reset();>

The CLASS METHOD "reset()" calls the OBJECT METHOD "reset()" (see
immediately below) for EVERY location that exists - NOT just for
the top-level locations!

=item *

C<$location-E<gt>reset();>

The OBJECT METHOD "reset()" deletes the state information associated with
the given location which is used by the "read()" method to determine the
next item of data it should return.

After using "reset()" on a given location, any subsequent "read()" on the
same location will start reading at the beginning of that location.

This method has no other (side) effects whatsoever.

The method does nothing if there is no state information associated
with the given location, i.e., if the location has never been accessed
using the "read()" method or if "reset()" has already been called for
it before.

=item *

C<Data::Locations-E<gt>traverse(\&callback_function);>

The CLASS METHOD "traverse()" cycles through all top-level locations
(in the order in which they were created) and calls the callback
function you specified once for each of them.

Expect one parameter handed over to your callback function which is
the object reference to the location in question.

Since callback functions can do a lot of unwanted things, use this
method with great precaution!

=item *

C<$location-E<gt>traverse(\&callback_function);>

The OBJECT METHOD "traverse()" performs a recursive descent on the
given location just as the method "dump()" does internally, but
instead of printing the items of data contained in the location
to a file, this method calls the callback function you specified
once for each item stored in the location.

Expect one parameter handed over to your callback function which
is the next chunk of data contained in the given location (or the
locations embedded therein).

Since callback functions can do a lot of unwanted things, use this
method with great precaution!

See at the end of this manpage for an example of how to use the two
variants of the "traverse()" method!

Using the object method "traverse()" is an alternate way of reading
back the contents of a given location - besides using the (object)
method "read()" - completely in memory (i.e., without writing the
contents of the given location to a file and reading that file back
in).

Note that the method "traverse()" is completely independent from the
method "read()" and that it has nothing to do with the state information
associated with the "read()" method (which can be reset to point to the
beginning of the location using the method "reset()").

This means that you can "traverse()" and "read()" (and "reset()") the
same location at the same time without any interference.

=item *

C<Data::Locations-E<gt>delete();>

The CLASS METHOD "delete()" deletes all locations and their contents,
which allows you to start over completely from scratch.

Note that you do not need to call this method in order to initialize
this class before using it; the "C<use Data::Locations;>" statement
is sufficient.

BEWARE that any references to locations you might still be holding
in your program become invalid by invoking this method!

If you try to invoke a method using such an invalidated reference,
an error message (with program abortion) similar to this one will
occur:

C<Can't locate object method "method" via package "[Error: stale reference!]">
C<at program.pl line 65.>

=item *

C<$location-E<gt>delete();>

The OBJECT METHOD "delete()" deletes the CONTENTS of the given location -
the location CONTINUES TO EXIST and REMAINS EMBEDDED where it was!

The associated filename stored along with the given location is also
NOT AFFECTED by this.

Note that a complete removal of the given location itself INCLUDING all
references to this location which may still be embedded somewhere in other
locations is unnecessary if, subsequently, you do not print anything to
this location anymore!

If the given location is a top-level location, you might want to set the
associated filename to "/dev/null", though, using the method "set_filename()"
(before or after deleting the location, this makes no difference).

BEWARE that the locations that were previously embedded in the given
(now deleted) location may not be contained in any other location anymore
after invoking this method!

If this happens, the affected "orphan" locations will be transformed into
top-level locations automatically.

Note however that you may have to define a default filename for these
orphaned locations (if you haven't done so previously) before invoking
"C<Data::Locations-E<gt>dump();>" in order to avoid data loss and the
warning message that will occur otherwise!

(The warning message will appear only if the C<-w> switch is set, though)

=item *

C<$location-E<gt>tie('FILEHANDLE');>

The object method "tie()" is inherited from the module "Tie::Handle"
and allows you to tie a file handle to a location so that you can
access the location as though it was a file, using Perl's built-in
functions for handling files.

Note that this feature depends on Perl version 5.004 or higher and cannot
be used with previous versions of Perl (see the installation instructions
in the "README" file in this distribution for how to disable this feature
in such a case, since trying to use this feature with Perl versions prior
to 5.004 will result in compilation errors).

You can either specify the file handle to which your location should
be tied by name (called a "symbolic" file handle) or by reference
(as explained further below).

A symbolic file handle can be given either as a literal string such as
"STDOUT", "MYHANDLE" or "MYPACKAGE::MYHANDLE", or as a Perl variable
containing that name.

Note, by the way, that the type of quotes used to enclose these literal
symbolic file handles does not matter, unless you are building the name
of your file handle using interpolated variables such as in
"C<${prefix}${name}${suffix}>", for example, where double quotes are
essential.

After a file handle has been tied to a location, you can use all of Perl's
built-in functions (except for "getc()", "read()" and "sysread()") for
dealing with files on that location (via its associated file handle)!

See L<Tie::Handle(3)> and L<perlfunc(1)> for more details, as well as
the example given at the end of this manpage.

Note however that "open()" and "close()" on a tied file handle have no
effect on the location which is tied to it!

(But beware that they attempt to open and close the specified file,
respectively, even though this is useless in this case!)

Note also that you will get errors if you try to read from a tied file
handle which you opened for output only using "open()", or vice-versa!

Therefore it is best not to use "open()" and "close()" on tied file
handles at all.

Instead, if you want to restart reading from the beginning of any given
location, rather invoke the method "reset()" on it!

Note further that always when you tie a file handle to a location the
method "reset()" is called internally for that location.

The same happens when you untie a file handle from its associated
location, i.e., when you dissociate the bond between the two; in
this case, "reset()" is called again in order to leave the location
in a well-defined state.

=item *

C<$location-E<gt>tie($filehandle);>

Use this variant of the object method "tie()" to specify the file handle
to which the given location shall be tied BY REFERENCE, or if you have a
scalar variable containing the name of the (symbolic) file handle to use.

To supply a file handle object reference to this method, you must first
call the object constructor method "new()" of either the "FileHandle" or
the "IO::Handle" class (either one works):

        $filehandle = FileHandle->new();
        $filehandle = IO::Handle->new();

(Don't forget to "use FileHandle;" or "use IO::Handle;" before that!)

Then you can tie that file handle to one of the locations of this module.

In order not to confuse the variables containing object references to
your locations and the variables containing file handles, I suggest to
use some naming convention to differentiate between the two.

For example you could use "C<$loc_E<lt>nameE<gt>>" for location object
references and "C<$fh_E<lt>nameE<gt>>" for file handles - the variables
with the same "C<E<lt>nameE<gt>>" would then refer to exactly the same
location.

=back

=head1 EXAMPLE #1

  #!/usr/local/bin/perl -w

  use strict;
  no strict "vars";

  use Data::Locations;

  $head = Data::Locations->new();  ##  E.g. for interface definitions
  $body = Data::Locations->new();  ##  E.g. for implementation

  $head->set_filename("example.h");
  $body->set_filename("example.c");

  $common = $head->new();    ##  Embed a new location in "$head"
  $body->print($common);     ##  Embed this same location in "$body"

  ##  Create some more locations...

  $copyright = Data::Locations->new("/dev/null");
  $includes  = Data::Locations->new("/dev/null");
  $prototype = Data::Locations->new("/dev/null");

  ##  ...and embed them in location "$common":

  $common->print($copyright,$includes,$prototype);

  ##  This is just to show you an alternate (though less efficient) way!
  ##  Normally you would use:
  ##      $copyright = $common->new();
  ##      $includes  = $common->new();
  ##      $prototype = $common->new();

  $head->println(";");  ##  The final ";" after a prototype
  $body->println();     ##  Just a newline after a function header

  $body->println("{");
  $body->println('    printf("Hello, world!\n");');
  $body->println("}");

  $includes->print("#include <");
  $library = $includes->new();     ##  Nesting even deeper still...
  $includes->println(">");

  $prototype->print("void hello(void)");

  $copyright->println("/*");
  $copyright->println("   Copyright (c) 1997 by Steffen Beyer.");
  $copyright->println("   All rights reserved.");
  $copyright->println("*/");

  $library->print("stdio.h");

  $copyright->set_filename("default.txt");

  $copyright->dump(">-");

  print "default filename = '", $copyright->get_filename(), "'\n";

  Data::Locations->dump();

  __END__

When executed, this example will print

  /*
     Copyright (c) 1997 by Steffen Beyer.
     All rights reserved.
  */
  default filename = 'default.txt'

to the screen and create the following two files:

  ::::::::::::::
  example.c
  ::::::::::::::
  /*
     Copyright (c) 1997 by Steffen Beyer.
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
     Copyright (c) 1997 by Steffen Beyer.
     All rights reserved.
  */
  #include <stdio.h>
  void hello(void);

=head1 EXAMPLE #2

  #!/usr/local/bin/perl -w

  use strict;
  no strict "vars";

  use Data::Locations;

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
  $tobody->print($title);      ##  re-using this location!!
  $tobody->println("</H1>");

  $contents = $tobody->new();

  $tobody->println("</CENTER>");

  $title->print("Locations Example HTML-Page");

  $description->print("Example for generating HTML pages");
  $description->print(" using 'Locations'");

  $keywords->print("Locations, magic, recursive");

  $contents->println("This page was generated using the");
  $contents->println("<P>");
  $contents->println("&quot;<B>Locations</B>&quot;");
  $contents->println("<P>");
  $contents->println("module for Perl.");

  Data::Locations->dump();

  __END__

When executed, this example will produce
the following file ("example.html"):

  <HTML>
  <HEAD>
  <TITLE>Locations Example HTML-Page</TITLE>
  <META NAME="description" CONTENT="Example for generating HTML pages using 'Locations'">
  <META NAME="keywords" CONTENT="Locations, magic, recursive">
  </HEAD>
  <BODY>
  <CENTER>
  <H1>Locations Example HTML-Page</H1>
  This page was generated using the
  <P>
  &quot;<B>Locations</B>&quot;
  <P>
  module for Perl.
  </CENTER>
  </BODY>
  </HTML>

=head1 EXAMPLE #3

  #!/usr/local/bin/perl -w

  ##  WARNING: use the "-w" switch or this example won't work as described!

  package Non::Sense;  ##  works equally well with other packages than "main"!

  use strict;
  use vars qw($level0 $level1 $level2 $level3 $fh $fake);

  use FileHandle;
  use Data::Locations;

  $level0 = Data::Locations->new("level0.txt");  ##  create topmost location

  $level0->print(<<'VERBATIM');
  First line : $level0 : ->print() : (here-doc syntax)
  VERBATIM

  $level1 = $level0->new();    ##  create 1st nested location (1 level deep)

  $level0->print(<<'VERBATIM');
  Last line : $level0 : ->print() : (here-doc syntax)
  VERBATIM

  $level1->tie('STDOUT');      ##  tie this location to file handle STDOUT

  print 'First line : $level1 : print "..." : (default: STDOUT)'."\n";

  $level2 = $level1->new();    ##  create 2nd nested location (2 levels deep)

  $fh = FileHandle->new();     ##  create new file handle (IO::Handle also works)

  $level2->tie($fh);           ##  tie this location to file handle $fh

  select($fh);                 ##  select $fh as the default file handle

  print 'First line : $level2 : print "..." : (default: $fh)'."\n";

  print STDOUT 'Last line : $level1 : print STDOUT "..." : (default: $fh)'."\n";

  $level3 = $level2->new();    ##  create 3rd nested location (3 levels deep)

  select(STDOUT);              ##  re-enable STDOUT as the default file handle

  print $fh 'Last line : $level2 : print $fh "..." : (default: STDOUT)'."\n";

  $SIG{__WARN__} = sub         ##  trap all warnings
  {
      print STDERR "WARNING intercepted:\n", @_, "End Of Warning.\n";
  };

  ##  NOTE  that without this trap, warnings go to the system standard error
  ##        channel DIRECTLY, WITHOUT passing through the file handle STDERR!

  $level3->tie('STDERR');      ##  tie this location to file handle STDERR

  $fake = \$fh;

  $level3->print($fake);       ##  provoke a warning message (-w switch!)

  $level3->dump();             ##  provoke another warning message (-w switch!)

  untie *STDOUT;               ##  untie location $level1 and file handle STDOUT

  while (<STDERR>)             ##  read from location $level3
  {
      if (/^Data::Locations::/)
      {
          s/\n+//g;
          s/^.+\(\):\s*//;
          print "Warning: $_\n";
      }
  }

  while (<STDERR>) { print; }  ##  prints nothing because location wasn't reset

  ${tied *STDERR}->reset();    ##  alternative:  $level3->reset();

  while (<STDERR>) { print; }  ##  now prints contents of location $level3

  Data::Locations->dump();     ##  write output file "level0.txt"

  __END__

When running this example, the following text will be printed to the screen
(provided that you used the C<-w> switch!):

  Warning: illegal reference 'REF' ignored at test.pl line 59
  Warning: no filename given at test.pl line 61
  WARNING intercepted:
  Data::Locations::print(): illegal reference 'REF' ignored at test.pl line 59
  End Of Warning.
  WARNING intercepted:
  Data::Locations::dump_location(): no filename given at test.pl line 61
  End Of Warning.

The example also produces an output file named "level0.txt" with the
following contents:

  First line : $level0 : ->print() : (here-doc syntax)
  First line : $level1 : print "..." : (default: STDOUT)
  First line : $level2 : print "..." : (default: $fh)
  WARNING intercepted:
  Data::Locations::print(): illegal reference 'REF' ignored at test.pl line 59
  End Of Warning.
  WARNING intercepted:
  Data::Locations::dump_location(): no filename given at test.pl line 61
  End Of Warning.
  Last line : $level2 : print $fh "..." : (default: STDOUT)
  Last line : $level1 : print STDOUT "..." : (default: $fh)
  Last line : $level0 : ->print() : (here-doc syntax)

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
      $string .= "\"" . $_[0]->get_filename() . "\":\n";
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

Tie::Handle(3), perl(1), perldata(1), perlfunc(1),
perlsub(1), perlmod(1), perlref(1), perlobj(1),
perlbot(1), perltoot(1), perltie(1), printf(3),
sprintf(3).

=head1 VERSION

This man page documents "Data::Locations" version 2.0.

=head1 AUTHOR

Steffen Beyer <sb@sdm.de>.

=head1 COPYRIGHT

Copyright (c) 1997 by Steffen Beyer. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute
and/or modify it under the same terms as Perl itself.

