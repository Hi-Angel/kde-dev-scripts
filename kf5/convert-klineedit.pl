#!/usr/bin/perl -w

# Laurent Montel <montel@kde.org> (2014)
# KLineEdit => QLineEdit
# find -iname "*.cpp" -o -iname "*.h" -o -iname "*.ui" |xargs kde-dev-scripts/kf5/convert-klineedit.pl

use strict;
use File::Basename;
use lib dirname($0);
use functionUtilkde;

foreach my $file (@ARGV) {

    my $modified;
    open(my $FILE, "<", $file) or warn "We can't open file $file:$!\n";
    my @l = map {
        my $orig = $_;
        s/\bKLineEdit\b/QLineEdit/g;
        s/\<KLineEdit\b\>/\<QLineEdit>/ =~ /#include/ ;
        s/\<klineEdit.h\>/\<QLineEdit>/ =~ /#include/ ;
        s/\bsetClickMessage\b/setPlaceholderText/;
        s/\bsetClearButtonShown\b/setClearButtonEnabled/;
        s/\"clickMessage\"/\"placeholderText\"/;
        s/\"clearButtonShown\"/\"clearButtonEnabled\"/;

        $modified ||= $orig ne $_;
        $_;
    } <$FILE>;

    if ($modified) {
        open (my $OUT, ">", $file);
        print $OUT @l;
        close ($OUT);
    }
}

functionUtilkde::diffFile( "@ARGV" );
