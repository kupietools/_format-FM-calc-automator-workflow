#!/usr/bin/perl
#
# calculation_formatter.pl
#
# PURPOSE: "Calculation formatter" (a.k.a. pretty printer a.k.a. auto-indenter) for
#           FileMaker Pro 7.0+ calculation expressions
#
# Copyright 2008 Debi Fuchs, debi@aptworks.com
# Debugged, modified, updated, and repackaged 
#  as a service by Michael Kupietz 
#  <consulting-fmsvc@kupietz.com> 
#  http://www.kupietz.com 
#
# LICENSE:
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# INSTRUCTIONS:
#
# - Use BBEdit, available at www.barebones.com, or other Perl friendly environment.
#
# - Install in ~/Library/Application Support/BBEdit/Unix Support/Unix Filters/
#
# - Highlight your VALID FileMaker Pro 7+ calculation (or custom function definition)
#   and choose this Perl file from the "#!-->Unix Filters" menu in BBEdit
#
# - See http://www.aptworks.com/tools for the latest version of this document,
#   and for a codeless language module for "syntax coloring" your calculations.
#
# CHANGE HISTORY (Please record your changes here and share with others.):
#  -------------------- RELEASE NOTES -----------------
#
# Version 1.0 01/27/2003   Debi Fuchs: (first release; private CGI function on www.aptworks.com)
# Version 2.0 07/06/2004   Debi Fuchs: (added FileMaker Pro 7 support)
# Version 2.1 07/27/2005   Debi Fuchs: (fixed bug in locating end of quoted string if contains quoted quotes)
# Version 2.2 07/28/2005   Debi Fuchs: (fixed bug if empty indentwidth; changed defaults/interface so more friendly and indentation is not counted in line length by default; removed "0" indentwidth for now because buggy)
# Version 2.3 12/07/2005   Debi Fuchs: (added some comments; made some parameter and variable names more clear; minor web page whitespace changes to match static page; changed versions to 7/8 instead of just 7)
# Version 2.4 01/18/2007   Debi Fuchs: (fixed bug where a quotation mark preceded by an escaped backslash migth be mistaken for an escaped quotation mark; added some comments; fixed some typos in comments; added 8.5 in comments as acceptible version; updated copyright year)
# Version 2.5 02/02/2008   Debi Fuchs: (updated for hosting on rimuhosting: changed tools to /html/tools; updated copyright year; chagned fmp version from 7.0/8.0/8.5 to 7.0+; note had to chmod to 715 to work on rimuhosting)
# Version 3.0 08/19/2008   Debi Fuchs: (Created non-CGI version for public release under Creative Commons License)
# Version 3.1 08/21/2008   Debi Fuchs: (Removed comma as separator character (for international use); Made mindepthtoaccommodate a calc; removed filemaker6 code; improved perl indentation; fixed typos in comments )
# Version 3.5 2013-2016  Michael Kupietz: Repackaged to run an Automator text service so can be used directly in FileMaker calc dialogs, go through the section with a million regexs and add comments documenting what they do so humans can understand, minor formatting tweaks to betterize output morely.
# Version 4 05/13/2017   Michael Kupietz: Numerous small output formatting improvements, improved indentation, added debugging output (see code), minor tweaks for more recent versions of FileMaker. 
# ------------------------ END ------------------------
#
#
# NOTE: This script was written in 2003 as I was learning Perl for the first
# time. Please excuse the code; It is pretty atrocious. It was also
# modified as quickly as possible to handle FileMaker 7.0 calculations
# when FileMaker 7.0 was first released, and should use spiffy regular
# expressions for handling quoted strings and comments, like thse:
#   strings: (?>"(?s:\\.|[^"])*?(?:"|$))
#   quotes: (/\*[^*]*\*+([^/*][^*]*\*+)*/)|(//.*$)
# but it doesn't right now.
#
# NOTE: User is prohibited from using % or ? or double spaces in field names.
# Calculation must be valid in FileMaker Pro 7.0+.
#
# CAVEAT 1: The FileMaker Pro calculation window uses a variable width font. Thus, it is
# necessary to use a fixed width indent in this calculation formatting tool. That is,
# something like the following...
#
#   substitute(string1,
#              string2,
#              substitute(string3, 
#                         string4,
#                         substitute(string5, string6, string7)
#              )
#   )
#
# would be misaligned in the FileMaker Pro calculation window.  Instead, we format the
# calculation as follows:
#
#   substitute(
#      string1,
#      string2,
#      substitute(
#         string3,
#         string4, 
#         substitute(string5, string6, string7)
#      )
#   )
#
# CAVEAT 2: FileMaker Pro's calculation window can be resized by the user.  Thus, we
# don't know where the calculation will wrap.  Independently, the user may want, for
# reasons of readability, the "non white space" of a given line (e.g. the space used for
# the calculation text itself, not the indentation) not to exceed a given number of
# characters.  Furthermore, the user may require a fixed wrap length for the purpose
# of including the calculation in an email.  Finally, the user may want a simple
# calculation to wrap differently than a more complex one. To satisfy all these needs, we
# set parameters for 1) indentation width, 2) a "wrap length", and 3) a "wraplenghtoption"
# for whether or not to include any indentation in the wrap length. Some common choices would
# probably be:
#
#        Email:  $indentwidth: 3; $wraplength: 70; $wraplengthoption: "including"
#        FileMaker: $indentwidth: 4; $wraplength: 70; $wraplengthoption: "excluding"
#
# Note that if the user uses very long "tokens" such as quoted strings
# and variable names, the wrap length may be exceeded
#
# CHANGE THESE PARAMETERS AS DESIRED:
#
$indentwidth = 5; #default: 3, was 8 forever
$wraplength = 60; #default: 70
$wraplengthoption = 'excluding'; #default: 'excluding'; alternative: 'including'
#
# Enjoy!!!
#
#
##################
# BEGIN CODE HERE#
##################

$calc="";
my $i = 0;
while(<>)
{
    $i++;
    $calc= $calc . $_;
}

#If the user wants to exclude indentation from the wraplength, then wraplength including indentation is actually "unlimited"; using a high value here, for that case.
$wraplength_includingindentation = ((($wraplengthoption cmp "including")==0) ? $wraplength : 1000000);

# Specify default, maximum and minimum values for each parameter. Note that
#  we "fake" any "unlimited" values by simply using large numbers. That
#  is, a wrap length of "unlimited" translates to a very large, but
#  still finite wrap length

$minindentwidth=0;
$maxindentwidth=8;
$defaultindentwidth=3;

$minwraplength_includingindentation=65;
$maxwraplength_includingindentation=1000000;
$defaultwraplength_includingindentation=1000000;

$minwraplength=12;
$maxwraplength=1000000;
$defaultwraplength=70; 

# Next, we adjust the user's specified parameters, if necessary,
# such that they conform to our specifications.  (The interface, e.g.
# a web form) can also do part of the work of preventing the
# user from specifying bad parameters.

$wraplength_includingindentation = ($wraplength_includingindentation ? $wraplength_includingindentation : $defaultwraplength_includingindentation);
$wraplength_includingindentation = min($wraplength_includingindentation, $maxwraplength_includingindentation);
$wraplength_includingindentation = max($wraplength_includingindentation, $minwraplength_includingindentation);

$indentwidth = ($indentwidth ? $indentwidth : $defaultindentwidth);
$indentwidth = min($indentwidth, $maxindentwidth);
$indentwidth = max($indentwidth, $minindentwidth);

$wraplength = ($wraplength ? $wraplength : $defaultwraplength);
$wraplength = min($wraplength, $maxwraplength);
$wraplength = max($wraplength, $minwraplength);

# We need to specify at what indent level to "wrap around" if the
# user has specified a calculation which simply can not fit
# into a "mold" based on the parameters specified by the user.
# For example, if the user has specified a wrap length of 65,
# but we encounter a 20-letter field name at an indent
# level of 9 and an indent width of 6, we can either a) ignore
# the wrap length specified by the user (thus creating a line
# of length 9*6+20 = 74), or b) start the indents over again,
# thus not exceeding the wrap length, but creating a less
# readable result.  Here, we specify the minimum number of
# indents to accommodate, even if it means exceeding the user's
# wrap length.  At or above that value, we wrap around if necessary.
$reasonable_length = 15;
$mindepthtoaccommodate=int(($wraplength-$reasonable_length)/$indentwidth);


# Because it would not make sense for the "non whitespace" length to be
# greater than the "wrap length", we set a total clause length here based on the minimum of those two

$maxpotentialclauselength=min($wraplength_includingindentation, $wraplength); 

# We determine here the maximum number of indent levels our result calc will
#  need to accommodate. We ensure this is at least the number of indent levels
#  specified in "$mindepthtoaccommodate" above, and if possible, more.
$maxpotentialindents = max (int (($wraplength_includingindentation-$maxpotentialclauselength)/$indentwidth), $mindepthtoaccommodate);


# Here is everything our script does. It formats the calculation; then it
#  writes the result.

&formatcalc;
&writeresult;


# Here is the entire formatting operation. Each subroutine is explained below.
sub formatcalc {
    if ($stringsuccess = &removestrings) {
        &prepstring;
        &parsecalc;
        &combineparens;
        &indent;
        &replacestrings;
        &returntostring;
    } else {
        &restorespecialchars;
    }
}


sub prepstring {

    &restorespecialchars;

    # Replace all newlines with spaces
    $calc =~ s/\r/ /g;

    # Surround the string with newline characters
    $calc = "\r$calc\r";    
    
}


sub restorespecialchars {
    # Turn all "!=" operators, which the form changed from a user's 
    # original "≠" character, into "<>".
    $calc =~ s/\!\=/\<\>/g;
}

sub mk_dodoubleindent {
 foreach (@calc) {
        $toreplace = $_;
        
      
          $toreplace =~ s/([\+\-\&\*\^\<\>\=]|[^*]\/| and| or| not)$/$1NEXTGETSSPACES/gi; #if it ends with an operator, indent the following line 2 spaces because it's wrapping in the middle of something. EXCEPT if the next line is outermost level & not indented at all. Just looked weird until I added that exception. Also, had to specify [^*]\/ because was considering the end of comments to be a simple / (division sign) and indenting the next line two spaces no matter what.
     $toreplace =~ s/^( *([\+\-\&\*\^\<\>\=]|\/[^*]|\/\*|and |or |not ))/THISGETSSPACES$1/gi;
    
    
    # also if it STARTS with an operator, which can happen if there are comments in the middle of expressions like: long_expression /* comment */ or long_expression or /*comment*/ long_expression. Should prolly also indent +2 spaces for lines that start with a "/*", EXCEPT if they follow an operator that already causes them to indent. And also indent +2 spaces on lines after a comment that start with an operator. 
  

        
         $calc[$i]=$toreplace; }

}

sub replacestrings {
# Replace any quoted strings or comments which were previously stored on a
# "stack"
$debug="";
    $i=0;
    foreach (@calc) {
        $toreplace = $_;
        
     
     
     #In May 2022 I commented out the next two lines starting with ## because the double indents didn't nest properly, they caused closing parens to be one depth level less than they should be (I think). I think down around line 646 I can probably deal with this properly but right now it jusst seems easier to deal this way
     
      
      ##    $toreplace =~ s/([\+\-\&\*\^\<\>\=]|[^*]\/| and| or| not)$/$1NEXTGETSSPACES/gi; #if it ends with an operator, indent the following line 2 spaces because it's wrapping in the middle of something. EXCEPT if the next line is outermost level & not indented at all. Just looked weird until I added that exception. Also, had to specify [^*]\/ because was considering the end of comments to be a simple / (division sign) and indenting the next line two spaces no matter what.
   ##  $toreplace =~ s/^( *([\+\-\&\*\^\<\>\=]|\/[^*]|and |or |not ))/THISGETSSPACES$1/gi;
    # also if it STARTS with an operator, which can happen if there are comments in the middle of expressions like: long_expression /* comment */ or long_expression or /*comment*/ long_expression. Should prolly also indent +2 spaces for lines that start with a "/*", EXCEPT if they follow an operator that already causes them to indent. And also indent +2 spaces on lines after a comment that start with an operator. 
  

        
         $calc[$i]=$toreplace; 
        
        $startposition=-1;
   $debug = $debug . $i."√" . $toreplace . "√\r";
       while (($startposition2 = min_but_not_blank(
         min_but_not_blank((index $toreplace, "\"", $startposition),
         (index $toreplace, "\?", $startposition)),(index $toreplace, "\%", $startposition)))>=0) {
           $startposition=$startposition2;
           $replacementstring = shift @stringstack;
             $debug = $debug . $i."◊" . $toreplace . "◊\r";
           $toreplace = ((substr $toreplace, 0, $startposition) . $replacementstring . (substr $toreplace, ($startposition+(length $replacementstring)), length $toreplace));
  $toreplace =~ s/\r/%BREAKHERE%/g;
             $debug = $debug . $i."ππ" . $toreplace . "ππ\r";
                    

           $calc[$i]=$toreplace;
           
            
           $startposition = $startposition + (length $replacementstring);
           $j=$j+1;
       }
    $i=$i+1;
    }
}


sub removestrings {
# Remove quoted strings, cplus comments, and c comments,
# substituting them with placeholders and
# pushing each original onto a "stack"
# Return FALSE if parenthesis or comment tags don't match
$calc =~ s/\r *(\/\*)/ $1/gi;
$calc =~ s/(\*\/) *\r/$1 /gi;

    $calc2=$calc;
    $calc3=$calc;
    $leftpos=-1;

    # Find the next potential "left" quote or c or c++ comment, whichever comes first
    while (($leftpos = min_but_not_blank(min_but_not_blank((index $calc2, 
        "\"", $leftpos+1),(index $calc2, "\/\/", $leftpos+1)),
        (index $calc2, "\/\*", $leftpos+1)))>-1) {

        $rightpos = $leftpos;

        # Find the next potential "right" tag, ignoring any 
        # escaped quotes in between
        
                   
        # If we're dealing with a left quotation mark, find the right one.
        # To do this, find the next quotation mark that's not escaped
        if (((substr $calc2, $leftpos,1) cmp "\"")==0) {
                
             # Get rid of any double backslashes within the quotes so we
             # don't mistake an escaped quotation mark for a quotation
             # mark following an escaped backslash
             $mypos = $leftpos + 1;
             while ((index $calc2, "\\\\", 0)>=0) {
                 $doublebackslash_pos = (index $calc2, "\\\\", 0);
                 $calc2 = (substr $calc2, 0, $doublebackslash_pos) . "aa" . (substr $calc2, $doublebackslash_pos + 2, length $calc2);
             }
                 
             
            # Now find a right quote which is not preceded immediately
            # by a backslash.
            $nextpos = $rightpos;
            while((($nextpos = (index $calc2, "\"", $nextpos+1))>=0) && 
             ((substr $calc2, $nextpos-1,1) cmp "\\")==0) {
                $rightpos = $nextpos;
                $nextpos = ($nextpos + 1);
            }
            $rightpos = (index $calc2, "\"", $rightpos+1);
        }
        
        
        # If we're dealing with a slash and apostrophe, find the
        #   end of the comment, which is an apostrophy and then a slash
        elsif(((substr $calc2, $leftpos,2) cmp "\/\*")==0) {
            $rightpos = (index $calc2, "\*\/", $rightpos+2);
        }

        # If we're dealing with two slashes, find the end of the line
        elsif(((substr $calc2, $leftpos,2) cmp "\/\/")==0) {
            $rightpos = (index $calc2, "\r", $rightpos+1); 
#\r used to be \r, but this made the script sometimes break on // lines

            if ($rightpos == -1)
            {$rightpos = length $calc2;}
    
        }
        else
        {
            #this should not happen
            return 0;
        }

        # If there isn't such a right quote or comment tag, 
        # return FALSE; otherwise push 
        # the string between the tags onto a stack and replace it with
        # a string of q's
        if ($rightpos == -1) {
            return 0;
        } elsif(((substr $calc2, $leftpos,1) cmp "\"")==0) {

            push @stringstack, substr $calc3, $leftpos,
                $rightpos-$leftpos+1;
            $calc2 = (substr $calc2, 0, $leftpos) . "\"" . ("q" x ($rightpos-$leftpos-1)) . "\"" . (substr $calc2, $rightpos+1, length $calc2);   
            $leftpos=$rightpos;
        }
        
        elsif(((substr $calc2, $leftpos,2) cmp "\/\*")==0) {
            push @stringstack, substr $calc3, $leftpos, $rightpos-$leftpos+2;
            $calc2 = (substr $calc2, 0, $leftpos) . "%" . ("r" x ($rightpos-$leftpos)) . "%" . (substr $calc2, $rightpos+2, length $calc2);   
            $leftpos=$rightpos+1;
        }

        elsif(((substr $calc2, $leftpos,2) cmp "\/\/")==0) {
            push @stringstack, substr $calc3, $leftpos, $rightpos-$leftpos;
            $calc2 = (substr $calc2, 0, $leftpos) . "?" . ("s" x ($rightpos-$leftpos-2)) . "?" . (substr $calc2, $rightpos, length $calc2);   
            $leftpos=$rightpos;
    
        }
    }

    $calc = $calc2;
    return 1;
}

sub parsecalc {
# Parse calculation string into one where all "tokens" are on a separate line

    # replace wierd space with normal one
    $calc =~ s/ / /g;
    
    $calc =~ s/,/;/g; # quotes have already been removed so replace all commas with ; to reduce what parsecalc has to deal with - MKupietz June 2017
    # Parse into tokens based on symbols
   
    $calc =~ s/\"([^\"]*)\"/\r\"$1\"\r/g; #move quoted phrases onto separate lines
    $calc =~ s/\?([^\?]*)\?/\r\?$1\?\r/g; #phrases surrounded by ?...? (even multiline... maybe shouldn't be.)
    $calc =~ s/\%([^\%]*)\%/\r\%$1\%\r/g; # %....%

    $calc =~ s/\/\*(((\*(?!\/))*([^\*])*)*)\*\//\r\/\*$1\*\/\r/g; # /*....*/

    $calc =~ s/\/\/([^\r]*)\r/\r\/\/$1\r/g;     # //...\r. Might need to change to \r?

#   $calc =~ s/\s*([\^\*\/\+\-\<\>\=\&\,\)\]\;])\s*/\r$1\r/g; removed comma in 3.1
    $calc =~ s/\s*([\^\*\/\+\-\<\>\=\&\)\]\;])\s*/\r$1\r/g; # single ^*/+_<>&)];
    $calc =~ s/\s*([\<\>\=])\s*([\<\>\=])\s*/\r$1$2\r/g; # <>= followed by optional space/return followed by <>=
    $calc =~ s/\(\s*/\(\r/g; # (
    $calc =~ s/\[\s*/\[\r/g; # [ 
    $calc =~ s/\s+not\s+\(/\rnot\r\(/g; # not 
    $calc =~ s/\s+\(/\r\(/g;  #(
    $calc =~ s/\s+\[/\r\[/g;  #[
#   $calc =~ s/([^\^\*\/\+\-\<\>\=\&\;\,\(\)\"\[\]])\s+\(/$1\(/g; removed comma in 3.1
#   $calc =~ s/([^\^\*\/\+\-\<\>\=\&\;\,\(\)\"\[\]])\s+\[/$1\[/g; removed comma in 3.1
    $calc =~ s/([^\^\*\/\+\-\<\>\=\&\;\(\)\"\[\]])\s+\(/$1\(/g; # remove space/return between non-punctuation and (
    $calc =~ s/([^\^\*\/\+\-\<\>\=\&\;\(\)\"\[\]])\s+\[/$1\[/g; # remove space/return between non-punctuation and [
    $calc =~ s/\s+(and|or|xor)\(/\r$1\r\(\r/gi; #and|or|xor( to \r\1\r(\r
    $calc =~ s/\s+(and|or|xor)\s+/\r$1\r/gi; #remove spaces/returns and add returns around and|or|xor

    # Deal specifically with unary plusses and minuses
    $calc =~ s/([\-\+])\s*(?=\-)/$1/g; #remove space/return between - and unary -
    $calc =~ s/([\-\+])\s*(?=\+)/$1/g; #remove space/return between - and unary +
#   $calc =~ s/([\,\[\;\(])(\s*)([\-\+]+)\s+/$1$2$3/g; removed comma in 3.1
    $calc =~ s/([\[\;\(])(\s*)([\-\+]+)\s+/$1$2$3/g;  #remove space from after unary - or + after one of [;(
#   $calc =~ s/\[^\,\[\;\(]\s+([\-\+])([\-\+]+)/\r$1\r$2/g; removed comma in 3.1
    $calc =~ s/\[^\[\;\(]\s+([\-\+])([\-\+]+)/\r$1\r$2/g; #...this appears to be a bug. 

#   $calc =~ s/([^\,\[\;\(]\s+[\^\*\/\+\-\<\>\=\&]|and|not|xor|or)\s*([\+\-]+)\s*/$1\r$2/g; removed comma in 3.1
    $calc =~ s/([^\[\;\(]\s+[\^\*\/\+\-\<\>\=\&]|and|not|xor|or)\s*([\+\-]+)\s*/$1\r$2/g; # Anything besides [;) plus space/return plus one of ^*+-<>=&/ OR a boolean operator, followed by +-, gets \r before +-
    $calc =~ s/^\s+([\-\+]+)\s+/\r$1/g; #for any line starting with +- surrounded by spaces/returns, strip spaces/returns

    # Move separators back to previous line
#   $calc =~ s/([^\%\?])\s+\,/$1\,/g; removed comma in 3.1
    $calc =~ s/([^\%\?])\s+\;/$1 \; /g; # make sure anything but %, followed by a break then a ; are on the same line
    $calc =~ s/([\(\)\[\]])/ $1 /g; #MK - try to add space around ( and ) and [ and ]

    # Get rid of extraneous spaces and line feeds
    $calc =~ s/ +/ /g;
    $calc =~ s/\s\s+/\r/g; #this haas to be a space followed by \r or vice versa, since the last line got rid of all spaces following spaces


}


sub combineparens {
# Combine into lines, if they fit, any clauses

    $leftpos=-1;

    # Get position of next relevant left paren; see if its clause fits
    # on one line
    while (($leftpos = min_but_not_blank((index $calc, "(", $leftpos+1),(index $calc, "[", $leftpos+1)))>=0) {
        $rightpos = $leftpos;
        $lefttext = substr $calc, 0, $leftpos;
        $templeftpos = rindex $lefttext, "\r", $leftpos;
        $lefttext = substr $calc, 0, $templeftpos+1;
        $_=$lefttext;
        $depth1=scalar s/\(//g;
        $_=$lefttext;
        $depth2=scalar s/\[//g;
        $_=$lefttext;
        $depth3=scalar s/\)//g;
        $_=$lefttext;
        $depth4=scalar s/\]//g;
        $depth = $depth1 + $depth2 - $depth3 - $depth4;

    
    
        # Get position of next relevant right paren; see if it is a
        # match for the current left paren, and whether the whole clause
        # will fit on one line
        while (($rightpos = min_but_not_blank((index $calc, ")", $rightpos+1),(index $calc, "]", $rightpos+1)))>=0) {

            # Figure out how far the clause will have to be indented;
            # no clause will be indented longer than half of the wraplength
            $substring = (substr $calc, $leftpos, ($rightpos-$leftpos+1));
            $indents = mod ($indentwidth * $depth, $maxpotentialindents * $indentwidth);
    
            # If the clause won't fit on one line, including a following comma
            # or argument,  skip to next left paren
            if (((length $substring) > ($maxpotentialclauselength - 4)) || ((length $substring) > ($wraplength_includingindentation - 4 - $indents))) {
                last;
            }
    
            # If the clause contains a comment, skip to next left paren
            if (((index $substring, "\?", 0) > 0) || ((index $substring, "\%", 0) > 0)) {
                last;
            }
    
            # If the clause is a full clause, e.g. parens match,
            # put it with the previous line; and go on to the next left
            # paren after the end of the clause; otherwise go on to next
            # right paren
    
            $_=$substring;
            $depth1=scalar s/\(//g;    
            $_=$substring;
            $depth2=scalar s/\[//g;
            $_=$substring;
            $depth3=scalar s/\)//g;
            $_=$substring;
            $depth4=scalar s/\]//g;
            $depth2 = $depth1 + $depth2 - $depth3 - $depth4;
    
            if ($depth2 == 0) {
                $substring =~ s/\r/ /g;
                $calc =  (substr $calc, 0, $leftpos) .  $substring . (substr $calc, $rightpos+1, length $calc);
                $leftpos = $rightpos;
                last;
            }
        }
    }

    # Move all ops to the end of the previous line
    $calc =~ s/([^\?\%])\s+([\^\*\/\+\-\<\>\=\&]|\<\+|\>\+|\<\>|and|not|xor|or)\r/$1 $2\r/g; #anything but ?% then spaces or returns then operator then \r to... uh.... same thing, but with only 1 space.  Bug?
    #^^ pretty sure \<\+ and \>\+ are typose, should be = not +

#Enable these to save to file for debugging:
#open(my $fh, '>', '/Users/[homefolder]/library/logs/FMcalcFormatter.log');
#print $fh "$calc\n";
#close $fh;


}


sub indent {
# Indent an array according to parenthesis depth


    # For ease, split the string into an array: one line per array element
    @calc = split /\r/, $calc;
    shift @calc;

    # Initialize variables
    $spacesneeded=0;
    $i=1;
    $_= $calc[0];
    $depth1=scalar s/\(//g;
    $_= $calc[0];
    $depth2=scalar s/\[//g;
    $_= $calc[0];
    $depth3=scalar s/\)//g;
    $_= $calc[0];
    $depth4=scalar s/\]//g;
    $depth = $depth1 + $depth2 - $depth3 - $depth4;


    # For each line, figure out whether it should be a continuation of
    # the previous one, or
    # should start a new line
    while ($i < scalar @calc) {
        $thistext = $calc[$i];
        $priortext = $calc[$i-1];
    
        $_ = $priortext;
        s/ //g;
        $ptspacesremoved = $_;
        $ptfirstrealchar=substr $ptspacesremoved, 0, 1;
        $ptendsclause = (($ptfirstrealchar cmp "\)")==0) || (($ptfirstrealchar cmp "\]")==0);
    
        $_ = $thistext;
        $tthasparen = m/[\(\)\[\]]/g;
    
        $_ = $thistext;
        $ttiscomment = m/[\?\%]/g;
    
        $_ = $priortext;
        $ptiscomment = m/[\?\%]/g;
    
        $ptlength=length $priortext;
        $ttlength=length $thistext;    
    
        $ptfirstchar=substr $priortext,0,1; #added by mk april 11 2017
        $ttfirstchar=substr $thistext,0,1;
        $ptlastchar=substr $priortext, $ptlength-1,1;
        $ttlastchar=substr $thistext, $ttlength-1,1;
        $ptiscloseparen = (($ptfirstchar cmp "\)")==0 );  #added by mk april 11 2017
    
        $ttiscloseparen = (($ttfirstchar cmp "\)")==0 || ($ttfirstchar cmp "\]")==0);
        $ptbeginsclause = (($ptlastchar cmp "\(")==0 || ($ptlastchar cmp "\[")==0);
#       $ptendsarg = ((($ptlastchar cmp "\,")==0) || (($ptlastchar cmp "\;")==0)) ; removed comma in 3.1
        $ptendsarg = (($ptlastchar cmp "\;")==0);
        $ttbeginsclause = (($ttlastchar cmp "\(")==0 || ($ttlastchar cmp "\[")==0);
        $ttistoolong = ((($ptlength + 1 + $ttlength) > $wraplength_includingindentation) || (($ptlength - $spacesneeded + 1 + $ttlength) > $maxpotentialclauselength));
    
        # If the clause should start a new line, determine how many
        # spaces are needed before it, and place those spaces before 
        # the rest of the text
        if($ttiscomment || $ptiscomment || $ttiscloseparen || $ptiscloseparen || $ptbeginsclause || $ptendsarg || $ttbeginsclause || $ttistoolong || ($ptendsclause && $tthasparen) ) {
            # The number of indents needed depends on the depth at the end 
            # of the previous line; if the current line is a close paren, 
            # then it needs one less indent
         $relevantdepth = $depth + ($ttiscloseparen? -1 : 0);  #commended out by mk april 11 2017 to make it keep closing paren indented 1 more than opening function #then uncommented may 2022 because I don't want that anymore. Don't know why I ever did. (Note: at some point while this was commented out, tt was changed to pt. Had to change back to tt when uncommenting to make this work. 
          #  $relevantdepth = $depth + (($ptiscloseparen || ($ttfirstchar cmp "\]")==0 )? -1 : 0);  #added by mk april 11 2017 to make it keep closing paren indented 1 more than opening function (so lines up closer to opening paren than opening function start), but NOT closing bracket so brackets in Let statements stay at same indent.# And, recommented in May 2022 when uncommenting prior line. 
            $spacesneeded = mod ($indentwidth*$relevantdepth,$maxpotentialindents * $indentwidth);
            $spaces = " " x $spacesneeded;
          #  if ($spacesneeded != $lastSpacesNeeded) {$spaces = "\r" . $spaces ; $lastSpacesNeeded = $spacesneeded;} #MK- separate different indentation depths by a blank line #NAH doesn't quite work... uncomment and see
    
            $thistext = $spaces . $thistext;
    
            $calc[$i] = $thistext;
            $i = $i + 1;
    
            $_ = $thistext;
            $depth1=scalar s/\(//g;
            $_ = $thistext;
            $depth2=scalar s/\[//g;
            $_ = $thistext;
            $depth3=scalar s/\)//g;
            $_ = $thistext;
            $depth4=scalar s/\]//g;
            $depth = $depth + $depth1 + $depth2 - $depth3 - $depth4;


        # Otherwise, the current array element and previous one are
        # spliced into one element (line).
        } else {
            splice @calc, $i-1, 2, $priortext . " " . $thistext;
        }
    }
}



sub returntostring {
# Turn the array we have been working with back into a string
# there's probably a one-liner for this, but I don't know it

    $calc="";
    foreach (@calc) { $calc = $calc . $_ . "\r";}
    
    $calc= substr $calc, 0, (length $calc)-1;

$calc =~ s/(\*\/)\r( *\/\*)/$1%BREAKHERE%$2/g; #put all consecutive comments on one line
   $calc =~ s/(\r)( *\/\*.*?\*\/\rTHISGETSSPACES)/\rTHISGETSSPACES$2/g; #If THISGETSSPACES follows comment-only line, add it to comment line. #This isn't working for some reason. Don't know why.
$calc =~ s/(NEXTGETSSPACES\r *\/\*.*?\*\/)(\r)/$1NEXTGETSSPACES\r/g; #If NEXTGETSPACES followed by comment-only line, add it to that line.

   $calc =~ s/(NEXTGETSSPACES\rTHISGETSSPACES)/\r    /g;
      $calc =~ s/NEXTGETSSPACES\r/\r    /g;
         $calc =~ s/\rTHISGETSSPACES/\r    /g; # add those extra 2 spaces to any line that matched any of above criteria, without adding too many if it matched more than one.
  $calc =~    s/NEXTGETSSPACES|THISGETSSPACES//g; #just in case - remove trailing
$calc =~ s/%BREAKHERE%/\r/g;
}


sub writeresult {
    if (not $stringsuccess) {
        print "Unmatched quotes or comments. Please be sure to enter a calculation which validates in FileMaker Pro.\<BR\>\r";
    }
    $theCredit = "/* Formatted with _mkCalcFormatter. Service based on Calculation_formatter.pl © 2008 by Debi Fuchs <debi@aptworks.com> and released under the GNU license. Debugged, modified, updated, and repackaged as a service by Michael Kupietz <fmform@kupietz.com> https://kupietz.com. Updated again at tremendous risk and great personal expense for nicer formatting in 2017. Released under GNU license, see source code for details. Be excellent to each other. */";
     $calc =~ s/\r *\Q$theCredit//gi; # \Q quotes meta characters in the variable value so they're not interpreted as regex codes.
    print $calc . "\r" . $theCredit . "\r" ; # . $debug;
# Don't remove the above credit. No, seriously. Don't be a dick.
}


sub mod {
    $result = $_[0]-$_[1]*int($_[0]/$_[1]);
    return $result;
}

sub min {
    return ($_[0] <= $_[1] ? $_[0] : $_[1]);
}

sub min_but_not_blank {
    if ($_[0] >= 0) {
        if ($_[1] >=0) {return ($_[0] <= $_[1] ? $_[0] : $_[1]);}
        else {return $_[0];}
    }
    else {return $_[1];} 
}

sub max {
    return ($_[0] >= $_[1] ? $_[0] : $_[1]);
}









