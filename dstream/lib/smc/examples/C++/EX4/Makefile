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
#
# RCS ID
# $Id: Makefile,v 1.6 2006/09/17 16:26:06 cwrapp Exp $
#
# CHANGE LOG
# $Log: Makefile,v $
# Revision 1.6  2006/09/17 16:26:06  cwrapp
# Initial v. 4.3.3 check-in.
#
# Revision 1.5  2005/05/28 13:31:18  cwrapp
# Updated C++ examples.
#
# Revision 1.0  2003/12/14 19:22:09  charlesr
# Initial revision
#

TARGET    = traffic

CXX       = c++
CPPFLAGS  = -g -I../../../lib
SMC       = java -jar ../../../bin/Smc.jar
SMCFLAGS  = -c++ -g

FSMS      = stoplight.sm
SOURCES   = $(FSMS:.sm=_sm.cpp) stoplight.cpp Main.cpp
HEADERS   = $(FSMS:.sm=_sm.h) stoplight.h
OBJECTS   = $(SOURCES:.cpp=.o)

##############

%_sm.h %_sm.cpp : %.sm
		$(SMC) $(SMCFLAGS) $<

all :		$(TARGET) test

$(TARGET) :	$(HEADERS) $(SOURCES)
		$(CXX) $(CPPFLAGS) -o $@ $(SOURCES)

test :		$(TARGET)
		$(TARGET)

clean :
		-rm -f $(TARGET)
		-rm -f $(OBJECTS)
		-rm -f *_sm.h
		-rm -f *_sm.cpp
