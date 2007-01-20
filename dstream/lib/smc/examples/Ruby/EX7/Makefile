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
#       Port to Ruby by Francois Perrad, francois.perrad@gadz.org
#
# RCS ID
# $Id: Makefile,v 1.1 2005/06/16 17:52:04 fperrad Exp $
#
# CHANGE LOG
# $Log: Makefile,v $
# Revision 1.1  2005/06/16 17:52:04  fperrad
# Added Ruby examples 1 - 4 and 7.
#
#

SM_SOURCES=     Telephone.sm
SOURCES=        $(SM_SOURCES:%.sm=%_sm.rb)

SMC=            java -jar ../../../bin/Smc.jar
SMC_FLAGS=      -ruby -g

all :           telephone

%_sm.rb : %.sm
		$(SMC) $(SMC_FLAGS) $<

telephone :   $(SOURCES)

clean :
		-rm *_sm.rb

