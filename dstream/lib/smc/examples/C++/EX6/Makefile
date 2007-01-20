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
# $Id: Makefile,v 1.5 2005/05/28 13:31:18 cwrapp Exp $
#
# CHANGE LOG
# $Log: Makefile,v $
# Revision 1.5  2005/05/28 13:31:18  cwrapp
# Updated C++ examples.
#
# Revision 1.0  2003/12/14 19:39:20  charlesr
# Initial revision
#

CXX       = c++
# CPPFLAGS  = -D_DEBUG -g -I. -I../../../lib/C++
CPPFLAGS  = -g -I. -I../../../lib
SMC       = java -jar ../../../bin/Smc.jar
SMCFLAGS  = -c++ -g

FSMS           = 	TcpConnection.sm

COMMON_SOURCES = 	TcpConnection_sm.cpp \
			Eventloop.cpp \
			TcpSegment.cpp \
			TcpConnection.cpp \
			TcpClient.cpp \
			TcpServer.cpp

SERVER_SOURCES = 	AppServer.cpp \
			AppClient.cpp \
			server.cpp

CLIENT_SOURCES =	AppClient.cpp \
			AppServer.cpp \
			client.cpp

COMMON_OBJECTS =	$(COMMON_SOURCES:.cpp=.o)
SERVER_OBJECTS =	$(SERVER_SOURCES:.cpp=.o)
CLIENT_OBJECTS =	$(CLIENT_SOURCES:.cpp=.o)

##############

%_sm.h %_sm.cpp : %.sm
	$(SMC) $(SMCFLAGS) $<

%.o :	%.cpp
	$(CXX) $(CPPFLAGS) -c $<

all : server client

common : $(COMMON_OBJECTS)

server : common $(SERVER_OBJECTS)
	$(CXX) -g -o $@ $(COMMON_OBJECTS) $(SERVER_OBJECTS)

client : common $(CLIENT_OBJECTS)
	$(CXX) -g -o $@ $(COMMON_OBJECTS) $(CLIENT_OBJECTS)

clean :
	-rm -f server \
                client \
		$(COMMON_OBJECTS) \
		$(SERVER_OBJECTS) \
                $(CLIENT_OBJECTS) \
		*_sm.h \
		*_sm.cpp \
		core
