
###############################################################################
##                                                                           ##
##    Copyright (c) 1997, 1998, 1999 by Steffen Beyer.                       ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use ExtUtils::MakeMaker;

use Config;

WriteMakefile(
    'NAME'              => 'Data::Locations',
    'VERSION_FROM'      => 'Locations.pm',
    'LIBS'              => [''],   # e.g., '-lm'
    'DEFINE'            => '',     # e.g., '-DHAVE_SOMETHING'
    'INC'               => '',     # e.g., '-I/usr/include/other'
#   ($] >= 5.005 ?
#       ('ABSTRACT'     => 'Magic (recursive) insertion points in your data',
#        'AUTHOR'       => 'Steffen Beyer (sb@engelschall.com)') : ()),
#   ($] >= 5.005 && $ eq 'MSWin32' && $Config{archname} =~ /-object\b/i ?
#       ('CAPI'         => 'TRUE') : ()),
    'dist'              => { COMPRESS => "gzip -9", SUFFIX => "gz" }
);

