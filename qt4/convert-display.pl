#!/usr/bin/perl 

# Laurent Montel <montel@kde.org>
# This function convert qt_xdisplay and qt_rootwin to qt4 function
# it added include too

use lib qw( . );
use functionUtilkde; 

foreach my $file (@ARGV) {
	functionUtilkde::substInFile {
	s!qt_xdisplay\s*\(\s*\)!QX11Info::display()!;
	s!qt_xrootwin\s*\(\s*\)!QX11Info::appRootWindow()!;
	s!qt_x_time!QX11Info::appTime()!;
    } $file;
	functionUtilkde::addIncludeInFile( $file, "QX11Info");
}
functionUtilkde::diffFile( "@ARGV" );
