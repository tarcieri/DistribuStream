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
// Copyright (C) 2004. Charles W. Rapp.
// All Rights Reserved.
// 
// Contributor(s):
//   Eitan Suez contributed examples/Ant.
//   (Name withheld) contributed the C# code generation and
//   examples/C#.
//
// Class
//    AppClass
//
// Description
//    When a state machine executes an action, it is really calling a
//  member function in the context class.
//
// RCS ID
// $Id: AppClass.cs,v 1.2 2005/11/07 19:34:54 cwrapp Exp $
//
// CHANGE LOG
// $Log: AppClass.cs,v $
// Revision 1.2  2005/11/07 19:34:54  cwrapp
// Changes in release 4.3.0:
// New features:
//
// + Added -reflect option for Java, C#, VB.Net and Tcl code
//   generation. When used, allows applications to query a state
//   about its supported transitions. Returns a list of transition
//   names. This feature is useful to GUI developers who want to
//   enable/disable features based on the current state. See
//   Programmer's Manual section 11: On Reflection for more
//   information.
//
// + Updated LICENSE.txt with a missing final paragraph which allows
//   MPL 1.1 covered code to work with the GNU GPL.
//
// + Added a Maven plug-in and an ant task to a new tools directory.
//   Added Eiten Suez's SMC tutorial (in PDF) to a new docs
//   directory.
//
// Fixed the following bugs:
//
// + (GraphViz) DOT file generation did not properly escape
//   double quotes appearing in transition guards. This has been
//   corrected.
//
// + A note: the SMC FAQ incorrectly stated that C/C++ generated
//   code is thread safe. This is wrong. C/C++ generated is
//   certainly *not* thread safe. Multi-threaded C/C++ applications
//   are required to synchronize access to the FSM to allow for
//   correct performance.
//
// + (Java) The generated getState() method is now public.
//
// Revision 1.1  2005/05/28 13:05:17  cwrapp
// Added CSharp examples 1 - 3.
//
// Revision 1.0  2004/09/01 17:34:50  charlesr
// Initial revision
//

using System;

public class AppClass
{
// Member methods.

    public AppClass()
    {
        _fsm = new AppClassContext(this);
        _is_acceptable = false;

        // Uncomment to see debug output.
        // _fsm.Debug = true;
    }

    public bool CheckString(string str)
    {
        int i,
            Length;
      

        for (i = 0, Length = str.Length;
             i < Length;
             ++i)
        {
            switch (str[i])
            {
                case '0':
                    _fsm.Zero();
                    break;

                case '1':
                    _fsm.One();
                    break;

                case 'c':
                case 'C':
                    _fsm.C();
                    break;

                default:
                    _fsm.Unknown();
                    break;
            }
        }

        _fsm.EOS();

        return(_is_acceptable);
    }

    public void Acceptable()
    {
        _is_acceptable = true;
    }

    public void Unacceptable()
    {
        _is_acceptable = false;
    }

// Member data.

    private AppClassContext _fsm;
    private bool _is_acceptable;
}
