
###############################################################################
##                                                                           ##
##    Copyright (c) 1997, 1998 by Steffen Beyer.                             ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'              => 'Data::Locations',
    'VERSION_FROM'      => 'Locations.pm',
    'LIBS'              => [''],   # e.g., '-lm'
    'DEFINE'            => '',     # e.g., '-DHAVE_SOMETHING'
    'INC'               => '',     # e.g., '-I/usr/include/other'
    'dist'              => { COMPRESS => "gzip -9", SUFFIX => "gz" }
);

