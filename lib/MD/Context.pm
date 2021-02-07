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

package MD::Context;

use strict;
use warnings;

#***********************************************************************
# %PROCEDURE: in_message_context
# %ARGUMENTS:
#  name -- a string to syslog if we are not in a message context
# %RETURNS:
#  1 if we are processing a message; 0 otherwise.  Returns 0 if
#  we're in filter_relay, filter_sender or filter_recipient
#***********************************************************************
sub in_message_context {
    my($name, $InMessageContext) = @_;
    return 1 if ($InMessageContext);
    MD::Syslog::md_syslog('warning', "$name called outside of message context");
    return 0;
}

#***********************************************************************
# %PROCEDURE: in_filter_wrapup
# %ARGUMENTS:
#  name -- a string to syslog if we are in filter wrapup
# %RETURNS:
#  1 if we are not in filter wrapup; 0 otherwise.
#***********************************************************************
sub in_filter_wrapup {
    my($name,$InFilterWrapUp) = @_;
    if ($InFilterWrapUp) {
	    MD::Syslog::md_syslog('warning', "$name called inside filter_wrapup context");
	    return 1;
    }
    return 0;
}

#***********************************************************************
# %PROCEDURE: in_filter_context
# %ARGUMENTS:
#  name -- a string to syslog if we are not in a filter context
# %RETURNS:
#  1 if we are inside filter or filter_multipart, 0 otherwise.
#***********************************************************************
sub in_filter_context {
    my($name,$InFilterContext) = @_;
    return 1 if ($InFilterContext);
    MD::Syslog::md_syslog('warning', "$name called outside of filter context");
    return 0;
}

#***********************************************************************
# %PROCEDURE: in_filter_end
# %ARGUMENTS:
#  name -- a string to syslog if we are not in filter_end
# %RETURNS:
#  1 if we are inside filter_end 0 otherwise.
#***********************************************************************
sub in_filter_end {
    my($name,$InFilterEnd) = @_;
    return 1 if ($InFilterEnd);
    MD::Syslog::md_syslog('warning', "$name called outside of filter_end");
    return 0;
}

1;
