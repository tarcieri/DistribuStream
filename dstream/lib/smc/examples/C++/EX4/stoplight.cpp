//
// The contents of this file are subject to the Mozilla Public
// License Version 1.1 (the "License"); you may not use this file
// except in compliance with the License. You may obtain a copy of
// the License at http://www.mozilla.org/MPL/
// 
// Software distributed under the License is distributed on an "AS
// IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
// implied. See the License for the specific language governing
// rights and limitations under the License.
// 
// The Original Code is State Machine Compiler (SMC).
// 
// The Initial Developer of the Original Code is Charles W. Rapp.
// Portions created by Charles W. Rapp are
// Copyright (C) 2000 - 2003 Charles W. Rapp.
// All Rights Reserved.
// 
// Contributor(s): 
//
// Class
//	Stoplight
//
// Member Functions
//	Stoplight()						   - Default constructor.
//	Stoplight(Directions)			   - Set initial direction.
//	TurnLight(StopLights, LightColors) - Change directions.
//	SetTimer(int)					   - Start a timer.
//	Initialize(Directions)			   - Set start state and timer.
//
// RCS ID
// $Id: stoplight.cpp,v 1.6 2005/05/28 13:31:18 cwrapp Exp $
//
// CHANGE LOG
// $Log: stoplight.cpp,v $
// Revision 1.6  2005/05/28 13:31:18  cwrapp
// Updated C++ examples.
//
// Revision 1.0  2003/12/14 19:25:59  charlesr
// Initial revision
//

#ifdef WIN32
#pragma warning(disable: 4355)
#endif

#if (__GNUC__ >= 3 && __GNUC_MINOR__ >= 1)
#include <iostream>
#include <cassert>
#include <cstdio>
#elif defined(WIN32)
#include <windows.h>
#include <winbase.h>
#else
#include <sys/time.h>
#endif
#include <stdlib.h>
#include "stoplight.h"

const static char _rcs_id[] = "$Id: stoplight.cpp,v 1.6 2005/05/28 13:31:18 cwrapp Exp $";

using namespace std;

extern int NSGreenTimer;
extern int EWGreenTimer;
#ifdef WIN32
extern DWORD Gtimeout;
#endif

namespace cpp_ex4
{
    Stoplight::Stoplight()
        : _fsm(*this)
    {
        Initialize(NORTH_SOUTH);

        // Uncomment to see debug messages.
        // _fsm.setDebugFlag(true);
    }

    Stoplight::Stoplight(Directions direction)
        : _fsm(*this)
    {
        Initialize(direction);
    }

    void Stoplight::TurnLight(StopLights light, LightColors color)
    {
        cout << "Turning the ";

        switch(light)
        {
            case EWLIGHT:
                cout << "east-west lights ";
                break;

            case NSLIGHT:
                cout << "north-south lights ";
                break;
        }

        switch(color)
        {
            case GREEN:
                cout << "green." << endl;
                break;

            case YELLOW:
                cout << "yellow." << endl;
                break;

            case RED:
                cout << "red." << endl;
                break;
        }

        return;
    }

    void Stoplight::SetTimer(int seconds)
    {
#ifdef WIN32
        Gtimeout = seconds * 1000;
#else
        itimerval timeout;

        timeout.it_value.tv_sec = seconds;
        timeout.it_value.tv_usec = 0;
        timeout.it_interval.tv_sec = 0;
        timeout.it_interval.tv_usec = 0;

        if (setitimer(ITIMER_REAL, &timeout, (itimerval *) NULL) < 0)
        {
            cerr << "Failed to set timer. Quitting application." << endl;
            exit(1);
        }
#endif

        return;
    }

    void Stoplight::Initialize(Directions direction)
    {
        switch(direction)
        {
            case NORTH_SOUTH:
                cout << "Turning the north-south lights green." << endl;
                _fsm.setState(StopMap::NorthSouthGreen);
                SetTimer(NSGreenTimer);
                break;

            case EAST_WEST:
                cout << "Turning the east-west lights green." << endl;
                _fsm.setState(StopMap::EastWestGreen);
                SetTimer(EWGreenTimer);
                break;
        }
    }
}
