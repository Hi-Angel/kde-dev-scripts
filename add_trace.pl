## add_trace.pl
## Script to add a kDebug() call as the first line of each method
## including as many parameters as possible (i.e. those supported by kDebug)
## Very useful for tracing.
##
## Usage: perl -i add_trace.pl myfile.cpp
##
## Generates all statement with kDebug(0) so that it is very easy
## to remove them afterwards :
## perl -pi -e 'if (/kDebug\(0\)/) { $_ = ""; }' myfile.cpp
##
## Copyright 2000, 2002 David Faure <faure@kde.org>
## Copyright 2005-2006, 2008 Thorsten Staerk <kde@staerk.de>
## Copyright 2006 Laurent Montel <montel@kde.org>
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions
## are met:
##
## 1. Redistributions of source code must retain the above copyright
##    notice, this list of conditions and the following disclaimer.
## 2. Redistributions in binary form must reproduce the above copyright
##    notice, this list of conditions and the following disclaimer in the
##    documentation and/or other materials provided with the distribution.
##
## THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
## IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
## OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
## IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
## INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
## NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
## DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
## THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
## (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
## THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

if (scalar (@ARGV) == 0)
{
  print "This program puts in debugging output into a program. At the beginning of every function, there is ";
  print "a line inserted saying which function starts at the moment.";
  exit(0);
}

my $line="";
$insignature=0;
while (<>)
{
  if ( $insignature )
    {
      $statement .= $_;
      chop;
      $oneline .= $_;
    }
  elsif ( /^\/\/.*/)
    {
      # comment
      # do nothing
      $insignature = 0;
    }
  # [^\s]+ means, one ore more characters that are no spaces
  elsif ( /^[^\s]+\s*[^\s]+::[^\s]+.*\}/ && !/typedef\s/ && !/^\s*class\s/ )
    {
      # declaration and implementation in one line
      # do nothing
      $insignature = 0;
    }
  elsif ( /^[^\s]+\s*[^\s]+::[^\s]+/ && !/typedef\s/ && !/^\s*class\s/ )
    {
      $insignature = 1;
      $statement = $_;
      chop;
      $oneline = $_;
    }

  if ( $insignature )
    {
      if ( /\{/ ) # End of signature
	{
	  $insignature = 0;
	  $_ = $oneline;
	  #print STDERR "Signature : $_\n";
	  print $statement;
	  $line = "kDebug(0)";
	  if ( m/([^\*\s]+::[^\s]+)\(/ )
	  {
	    $line = $line . " << \"Entering function\"";
	  }
	  ## Ok now extract args
	  s/^.*\([\s]*//; # Remove everything before first '('
	  s/\s*\)\s*:\s+.*$/,/; # Remove any ") : blah", replace with a ','
	  s/\s*\).*\{\s*$/,/; # Remove anything after ')', replace with a ','
          s/ const / /g; # Replace every "const" by a space
	  #print STDERR "Args list : $_\n";
	  @args = split( ",", $_ );
	  foreach (@args)
	    {
	      s/^\s*//;
	      s/\s*$//;
	      #print STDERR "Argument: $_\n";
	      ## Pointer ?
	      if ( m/[a-zA-Z0-9_\s]+\*\s*([a-zA-Z0-9_]+)/ ) {
		$line = $line . " << \" $1=\" << " . $1;
	      }
	      ## int, long ?
	      elsif ( m/^int\s+([a-zA-Z0-9_]+)/ || m/^long\s*([a-zA-Z0-9_]+)/ ) {
		$line = $line . " << \" $1=\" << " . $1;
	      }
	      ## bool
	      elsif ( m/^bool\s+([a-zA-Z0-9_]+)/ ) {
		$line = $line . " << \" $1=\" << (" . $1 . " ? \"true\" : \"false\" )";
	      }
	      ## QString and friends
	      elsif ( m/QString[\&\s]+([a-zA-Z0-9_]+)/ || m/QCString[\&\s]*([a-zA-Z0-9_]+)/ ) {
		$line = $line . " << \" $1=\" << " . $1;
	      }
	      ## KUrl
	      elsif ( m/KUrl[\&\s]+([a-zA-Z0-9_]+)/ ) {
		$line = $line . " << \" $1=\" << " . $1 . ".url()";
	      }
	    }
	  $line = $line . " << endl;\n";
	  #print STDERR "Debug call added : $line\n";
	}
    }
  else
    {
        $readline=$_;
        if ( $line ) # there is something to insert
        {
	  if (/( *).*/) { $line=$1.$line; } # indent
          if ($readline eq $line) 
	  {
	    $line="";
          }
	  else
	  {
	    print $line;
	    $line="";
          }
	}
        # Normal line
        print $readline;
    }
}
if ( $insignature )
{
   print STDERR "Warning, unterminated method signature !! Check the file !\n";
   print $statement;
}
