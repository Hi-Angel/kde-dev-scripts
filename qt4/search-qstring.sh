#!/bin/sh
egrep -rl 'findRev|local8Bit|utf8' * |grep -v "\.svn" |grep -v "\.libs" | grep -v "\.o" | grep -v Makefile | grep -v Makefile.in  | grep -v "\.moc" | grep -v "\.lo" | grep -v "\.la" |grep -v "\.Ulo" |grep -v "\.kidl" | grep -v "\.desktop"
