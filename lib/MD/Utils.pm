# -*- Perl -*-
#***********************************************************************
#
# mimedefang.pl
#
# Perl scanner which parses MIME messages and filters or removes
# objectionable attachments.
#
# This program may be distributed under the terms of the GNU General
# Public License, Version 2, or (at your option) any later version.
#
# This program was derived from the sample program "mimeexplode"
# in the MIME-Tools Perl module distribution.
#
#***********************************************************************

package MD::Utils;

use strict;
use warnings;

#***********************************************************************
# %PROCEDURE: expand_ipv6_address
# %ARGUMENTS:
#  addr -- an IPv6 address
# %RETURNS:
#  An IPv6 address with all zero fields explicitly expanded, and
#  any field shorter than 4 hex digits padded out with zeros.
#***********************************************************************
sub expand_ipv6_address
{
    my ($addr) = @_;

    return '0000:0000:0000:0000:0000:0000:0000:0000' if ($addr eq '::');
    if ($addr =~ /::/) {
	# Do nothing if more than one pair of colons
	return $addr if ($addr =~ /::.*::/);

	# Make sure we don't begin or end with ::
	$addr = "0000$addr" if $addr =~ /^::/;
	$addr .= '0000' if $addr =~ /::$/;

	# Count number of colons
	my $colons = ($addr =~ tr/:/:/);
	if ($colons < 8) {
	    my $missing = ':' . ('0000:' x (8 - $colons));
	    $addr =~ s/::/$missing/;
	}
    }

    # Pad short fields
    return join(':', map { (length($_) < 4 ? ('0' x (4-length($_)) . $_) : $_) } (split(/:/, $addr)));
}

#***********************************************************************
# %PROCEDURE: reverse_ip_address_for_rbl
# %ARGUMENTS:
#  addr -- an IPv4 or IPv6 address
# %RETURNS:
#  The appropriately-reversed address for RBL lookups.
#***********************************************************************
sub reverse_ip_address_for_rbl
{
    my ($addr) = @_;
    if ($addr =~ /:/) {
	$addr = expand_ipv6_address($addr);
	$addr =~ s/://g;
	return join('.', reverse(split(//, $addr)));
    }

    return join('.', reverse(split(/\./, $addr)));
}

#***********************************************************************
# %PROCEDURE: percent_encode
# %ARGUMENTS:
#  str -- a string, possibly with newlines and control characters
# %RETURNS:
#  A string with unsafe chars encoded as "%XY" where X and Y are hex
#  digits.  For example:
#  "foo\r\nbar\tbl%t" ==> "foo%0D%0Abar%09bl%25t"
#***********************************************************************
sub percent_encode {
    my($str) = @_;
    $str =~ s/([^\x21-\x7e]|[%\\'"])/sprintf("%%%02X", unpack("C", $1))/ge;
    #" Fix emacs highlighting...
    return $str;
}

#***********************************************************************
# %PROCEDURE: percent_encode_for_graphdefang
# %ARGUMENTS:
#  str -- a string, possibly with newlines and control characters
# %RETURNS:
#  A string with unsafe chars encoded as "%XY" where X and Y are hex
#  digits.  For example:
#  "foo\r\nbar\tbl%t" ==> "foo%0D%0Abar%09bl%25t"
# This differs slightly from percent_encode because we don't encode
# quotes or spaces, but we do encode commas.
#***********************************************************************
sub percent_encode_for_graphdefang {
    my($str) = @_;
    $str =~ s/([^\x20-\x7e]|[%\\,])/sprintf("%%%02X", unpack("C", $1))/ge;
    #" Fix emacs highlighting...
    return $str;
}

#***********************************************************************
# %PROCEDURE: percent_decode
# %ARGUMENTS:
#  str -- a string encoded by percent_encode
# %RETURNS:
#  The decoded string.  For example:
#  "foo%0D%0Abar%09bl%25t" ==> "foo\r\nbar\tbl%t"
#***********************************************************************
sub percent_decode {
    my($str) = @_;
    $str =~ s/%([0-9A-Fa-f]{2})/pack("C", hex($1))/ge;
    return $str;
}

#***********************************************************************
# %PROCEDURE: time_str
# %ARGUMENTS:
#  None
# %RETURNS:
#  The current time in the form: "YYYY-MM-DD-HH:mm:ss"
# %DESCRIPTION:
#  Returns a string representing the current time.
#***********************************************************************
sub time_str {
    my($sec, $min, $hour, $mday, $mon, $year, $junk);
    ($sec, $min, $hour, $mday, $mon, $year, $junk) = localtime(time());
    return sprintf("%04d-%02d-%02d-%02d.%02d.%02d",
		   $year + 1900, $mon+1, $mday, $hour, $min, $sec);
}

#***********************************************************************
# %PROCEDURE: hour_str
# %ARGUMENTS:
#  None
# %RETURNS:
#  The current time in the form: "YYYY-MM-DD-HH"
# %DESCRIPTION:
#  Returns a string representing the current time.
#***********************************************************************
sub hour_str {
    my($sec, $min, $hour, $mday, $mon, $year, $junk);
    ($sec, $min, $hour, $mday, $mon, $year, $junk) = localtime(time());
    return sprintf('%04d-%02d-%02d-%02d', $year+1900, $mon+1, $mday, $hour);
}

1;
