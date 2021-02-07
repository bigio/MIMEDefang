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

package MD::Syslog;

use strict;
use warnings;

# Reworked detection/usage of Sys::Syslog or Unix::Syslog as
# appropriate is mostly borrowed from Log::Syslog::Abstract, to which
# I'd love to convert at some point.
my $_syslogsub = undef;
my $_openlogsub = undef;
my $_fac_map   = undef;

#***********************************************************************
# %PROCEDURE: md_openlog
# %ARGUMENTS:
#  tag -- syslog tag ("mimedefang.pl")
#  facility -- Syslog facility as a string
# %RETURNS:
#  Nothing
# %DESCRIPTION:
#  Opens a log using either Unix::Syslog or Sys::Syslog
#***********************************************************************
sub md_openlog
{
  my ($tag, $facility) = @_;

  if( ! defined $_openlogsub ) {
    # Try Unix::Syslog first, then Sys::Syslog
    eval qq{use Unix::Syslog qw( :macros ); };
    if(!$@) {
      ($_openlogsub, $_syslogsub) = _wrap_for_unix_syslog();
    } else {
      eval qq{use Sys::Syslog ();};
      if(!$@) {
        ($_openlogsub, $_syslogsub) = _wrap_for_sys_syslog();
      } else {
        die q{Unable to detect either Unix::Syslog or Sys::Syslog};
      }
    }
  }

  return $_openlogsub->($tag, 'pid,ndelay', $facility);
}

#***********************************************************************
# %PROCEDURE: md_syslog
# %ARGUMENTS:
#  facility -- Syslog facility as a string
#  msg -- message to log
# %RETURNS:
#  Nothing
# %DESCRIPTION:
#  Calls syslog, either in Sys::Syslog or Unix::Syslog package
#***********************************************************************
sub md_syslog
{
  my ($facility, $msg) = @_;

  if(!$_syslogsub) {
    md_openlog('mimedefang.pl', $SyslogFacility);
  }

  if (defined $MsgID && $MsgID ne 'NOQUEUE') {
    return $_syslogsub->($facility, '%s', $MsgID . ': ' . $msg);
  } else {
    return $_syslogsub->($facility, '%s', $msg);
  }
}

sub _wrap_for_unix_syslog
{

  my $openlog = sub {
    my ($id, $flags, $facility) = @_;

    die q{first argument must be an identifier string} unless defined $id;
    die q{second argument must be flag string} unless defined $flags;
    die q{third argument must be a facility string} unless defined $facility;

    return Unix::Syslog::openlog( $id, _convert_flags( $flags ), _convert_facility( $facility ) );
  };

  my $syslog = sub {
    my $facility = shift;
    return Unix::Syslog::syslog( _convert_facility( $facility ), @_);
  };

  return ($openlog, $syslog);
}

sub _wrap_for_sys_syslog
{

  my $openlog  = sub {
    # Debian Stretch version is 0.33_01...dammit!
    my $ver = $Sys::Syslog::VERSION;
    $ver =~ s/_.*//;
    if( $ver < 0.16 ) {
      # Older Sys::Syslog versions still need
      # setlogsock().  RHEL5 still ships with 0.13 :(
      Sys::Syslog::setlogsock([ 'unix', 'tcp', 'udp' ]);
    }
    return Sys::Syslog::openlog(@_);
  };
  my $syslog   = sub {
    return Sys::Syslog::syslog(@_);
  };

  return ($openlog, $syslog);
}

sub _convert_flags
{
  my($flags) = @_;

  my $flag_map = {
    pid     => Unix::Syslog::LOG_PID(),
    ndelay  => Unix::Syslog::LOG_NDELAY(),
  };

  my $num = 0;
  foreach my $thing (split(/,/, $flags)) {
    next unless exists $flag_map->{$thing};
    $num |= $flag_map->{$thing};
  }
  return $num;
}


sub _convert_facility
{
  my($facility) = @_;

  my $num = 0;
  foreach my $thing (split(/\|/, $facility)) {
    if (!defined($_fac_map) ||
        !exists($_fac_map->{$thing})) {
      $_fac_map->{$thing} = _fac_to_num($thing);
    }
    next unless defined $_fac_map->{$thing};
    $num |= $_fac_map->{$thing};
  }
  return $num;
}

1;
