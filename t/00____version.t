#!perl -w

use strict;
no strict "vars";

use Data::Locations;

# ======================================================================
#   $version = $Data::Locations::VERSION;
# ======================================================================

print "1..1\n";

$n = 1;
if ($Data::Locations::VERSION eq "5.3")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

