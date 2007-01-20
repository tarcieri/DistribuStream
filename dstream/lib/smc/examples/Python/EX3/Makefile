#
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
#
# The Original Code is State Machine Compiler (SMC).
#
# The Initial Developer of the Original Code is Charles W. Rapp.
# Portions created by Charles W. Rapp are
# Copyright (C) 2000 Charles W. Rapp.
# All Rights Reserved.
#
# Contributor(s):
#       Port to Python by Francois Perrad, francois.perrad@gadz.org
#
# RCS ID
# $Id: Makefile,v 1.1 2005/05/28 17:48:29 cwrapp Exp $
#
# CHANGE LOG
# $Log: Makefile,v $
# Revision 1.1  2005/05/28 17:48:29  cwrapp
# Added Python examples 1 - 4 and 7.
#
#

SM_SOURCES=     AppClass.sm
SOURCES=        $(SM_SOURCES:%.sm=%_sm.py)

SMC=            java -jar ../../../bin/Smc.jar
SMC_FLAGS=      -python -g

all :           checkstring

%_sm.py : %.sm
		$(SMC) $(SMC_FLAGS) $<

checkstring :   $(SOURCES)

clean :
		-rm *_sm.py
		-rm *.pyc

test:
		-python checkstring.py ""
		-python checkstring.py 00
		-python checkstring.py 1c
		-python checkstring.py c0
		-python checkstring.py abcba
		-python checkstring.py 110010c010011
		-python checkstring.py 110010c110010
