                  =========================================
                    Package "Data::Locations" Version 4.2
                  =========================================


This package is available for download either from my web site at

                  http://www.engelschall.com/u/sb/download/

or from any CPAN (= "Comprehensive Perl Archive Network") mirror server:

                  http://www.perl.com/CPAN/authors/id/STBEY/


Prerequisites:
--------------

Perl version 5.004 (subversion 0) or higher.


What does it do:
----------------

Data::Locations - magic insertion points in your data

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

This is where the "Data::Locations" module comes in: It handles such
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
"Data::Locations" as virtual files with almost random access:
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


Installation:
-------------

Please see the file "INSTALL.txt" in this distribution for installation
instructions.


Changes:
--------

Please refer to the file "CHANGES.txt" in this distribution for a version
history of changes and possible incompatibilities.


Documentation:
--------------

The documentation to this package is included in POD format (= "Plain Old
Documentation") in the file "Locations.pm" in this distribution, the human-
readable markup-language standard for Perl documentation.

By building this package, this documentation will automatically be converted
into a man page, which will also automatically be installed in your Perl tree
for further reference during installation, where it can be accessed via the
command "man Data::Locations" (UNIX) or "perldoc Data::Locations" (UNIX and
Win32).


Credits:
--------

Many thanks go to Mr. Gero Scholz (now Head of Department for Core Business
IT-Components at the Dresdner Bank in Frankfurt, Germany) for his personal
support and for writing the "ProMAC" macro processor (some sort of a precursor
to Perl, in spirit) and for implementing the concept of "locations" in it,
which inspired me to write this Perl module!

Mr. Scholz owes his own inspiration to the "DELTA" macro processor (a tool
widely used during the seventies, as it seems), where a rudimentary version
of the concept of "locations" was implemented and where its name ("locations")
seems to originate from.


Legal issues:
-------------

This package with all its parts is

Copyright (c) 1997, 1998 by Steffen Beyer.
All rights reserved.

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, i.e., under the
terms of the "Artistic License" or the "GNU General Public License".

Please refer to the files "Artistic.txt" and "GNU_GPL.txt" in
this distribution for details!


Author's note:
--------------

If you have any questions, suggestions or need any assistance, please
let me know!

I hope you will find this module beneficial!

Yours,
--
  Steffen Beyer <sb@engelschall.com> http://www.engelschall.com/u/sb/
       "There is enough for the need of everyone in this world,
         but not for the greed of everyone." - Mahatma Gandhi
