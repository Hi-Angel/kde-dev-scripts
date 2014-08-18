#!/usr/bin/perl -w

# Laurent Montel <montel@kde.org> (2014)
# KFileDialog::getOpenFileName(...) => QFileDialog::getOpenFileName(...)
# find -iname "*.cpp" -o -iname "*.h" |xargs kde-dev-scripts/kf5/convert-kfiledialog.pl
# TODO need to improve it.
use strict;
use File::Basename;
use lib dirname($0);
use functionUtilkde;

foreach my $file (@ARGV) {

    my $modified;
    open(my $FILE, "<", $file) or warn "We can't open file $file:$!\n";
    my %varname = ();
    my $needQFileDialog;
    my @l = map {
        my $orig = $_;

        #const QString fileName = KFileDialog::getOpenFileName( KUrl(), QString(), d->wParent, i18n("Attach File" ) );

        my $regexp = qr/
           ^(\s*)                        # (1) Indentation, possibly "Classname *" (the ? means non-greedy)
           (.*?)                         # (2) Possibly "Classname *" (the ? means non-greedy)
           (\w+)                         # (3) variable name
           \s*=\s*                       #   assignment
           KFileDialog::getOpenFileName\s*\((.*)\)  # (4)  new KPushButton(...,...,...,...);
           (.*)$                         # (5) afterreg
           /x; # /x Enables extended whitespace mode
        if (my ($indent, $left, $var, $argument, $afterreg) = $_ =~ $regexp) {
           warn "QFileDialog::getOpenFileName found\n";
           my $constructor_regexp = qr/
                                 ^([^,]*)         # Url
                                 (?:,\s*([^,]*))?        # filter
                                 (?:,\s*([^,]*))?        # parent
                                 (?:,\s*([^,]*))?        # caption
                                 (.*)$              # after
                                 /x;
           my ($url, $filter, $parent, $caption, $after);
           if ( ($url, $filter, $parent, $caption, $after) = $argument =~  $constructor_regexp ) {
              $_ = $indent . $left . $var . " = QFileDialog::getOpenFileName(";
              if (defined $parent) {
                 $_ .= "$parent";
              } else {
                 $_ .= "0";
              }
              if (defined $caption) {
                 $_ .= ", $caption";
              } else {
                 $_ .= ", QString()";
              }
              if (defined $url) {
                 if ($url eq "KUrl()") {
                    $_ .= ", QString()";
                 } else {
                    $_ .= ", $url";
                 }
              } else {
                 $_ .= ", QString()";
              }
              if (defined $filter) {
                 $_ .= ", $filter);\n";
              } else {
                 $_ .= "QString());\n";
              }
              $needQFileDialog = 1;
           }
        }

       
        my $regexgetExistingDirectory = qr/
           ^(\s*)                        # (1) Indentation
           (.*?)                         # (2) Possibly "Classname *" (the ? means non-greedy)
           (\w+)                         # (3) variable name
           \s*=\s*                       #   assignment
           KFileDialog::getExistingDirectory\s*\((.*)\)  # (4)  KFileDialog::getExistingDirectory(...)
           (.*)$                         # (5) afterreg
           /x; # /x Enables extended whitespace mode
        if (my ($indent, $left, $var, $argument, $afterreg) = $_ =~ $regexgetExistingDirectory) {
           warn "QFileDialog::getExistingDirectory found\n";
           my $constructor_regexp = qr/
                                 ^([^,]*)           # (1) Url
                                 (?:,\s*([^,]*))?   # (2) parent
                                 (?:,\s*([^,]*))?   # (3) caption
                                 (.*)$              # (4) after
                                 /x;
           my ($url, $parent, $caption, $after);
           if ( ($url, $parent, $caption, $after) = $argument =~  $constructor_regexp ) {
              $_ = $indent . $left . $var . " = QFileDialog::getExistingDirectory(";
              if (defined $parent) {
                 $_ .= "$parent";
              } else {
                 $_ .= "0";
              }
              if (defined $caption) {
                 $_ .= ", $caption";
              } else {
                 $_ .= ", QString()";
              }
              if (defined $url) {
                 if ($url eq "KUrl()" || $url eq "QUrl()" || $url eq "") {
                    $_ .= ");\n";
                 } else {
                    $_ .= ", $url);\n";
                 }
              } else {
                 $_ .= ")\n";
              }
              $needQFileDialog = 1;
           }
        }

        my $regexgetSaveFileName = qr/
           ^(\s*)                        # (1) Indentation
           (.*?)                         # (2) Possibly "Classname *" (the ? means non-greedy)
           (\w+)                         # (3) variable name
           \s*=\s*                       #   assignment
           KFileDialog::getSaveFileName\s*\((.*)\)  # (4)  KFileDialog::getSaveFileName(...)
           (.*)$                         # (5) afterreg
           /x; # /x Enables extended whitespace mode
        if (my ($indent, $left, $var, $argument, $afterreg) = $_ =~ $regexgetSaveFileName) {
           warn "QFileDialog::getSaveFileName found\n";
           my $constructor_regexp = qr/
                                 ^([^,]*)           # (1) startUrl
                                 (?:,\s*([^,]*))?   # (2) filter
                                 (?:,\s*([^,]*))?   # (3) parent
                                 (?:,\s*([^,]*))?   # (4) caption
                                 (?:,\s*([^,]*))?   # (5) option
                                 (.*)$              # (6) after
                                 /x;
           my ($starturl, $filter, $parent, $caption, $option, $after);
           if ( ($starturl, $filter, $parent, $caption, $option, $after) = $argument =~  $constructor_regexp ) {
              $_ = $indent . $left . $var . " = QFileDialog::getSaveFileName(";

              #QWidget * parent = 0, const QString & caption = QString(), const QString & dir = QString(), const QString & filter = QString(), QString * selectedFilter = 0, Options options = 0
              if (defined $parent) {
                 $_ .= "$parent";
              } else {
                 $_ .= "0";
              }
              if (defined $caption) {
                 $_ .= ", $caption";
              } else {
                 $_ .= ", QString()";
              }
              if (defined $starturl) {
                 $_ .= ", $starturl";
              } else {
                 $_ .= ", QString()";
              }
              if (defined $filter) {
                 $_ .= ", $filter";
              } else {
                 $_ .= ", QString()";
              }
              if (defined $option) {
                 $option =~ s, ,,;
                 if ($option =~ /KFileDialog::ConfirmOverwrite/) {
                    $_ .=");\n"
                 } else {
                   warn "$file : QFileDialog::getSaveFileName : fix me option \'$option\'\n";
                   $_ .= ", 0, $option);\n"; # TODO fix option
                 }
              } else {
                 warn "$file : QFileDialog::getSaveFileName : fix me option \'$option\'\n";
                 $_ .= ", 0, $option);\n"; # TODO fix option
              }



           }
        }



        $modified ||= $orig ne $_;
        $_;
    } <$FILE>;

    if ($modified) {
        open (my $OUT, ">", $file);
        print $OUT @l;
        close ($OUT);
        if ($needQFileDialog) {
           functionUtilkde::addIncludeInFile($file, "QFileDialog");
        }
    }
}

functionUtilkde::diffFile( "@ARGV" );
