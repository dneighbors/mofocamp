== Synopsis

Zyps - An AI library for building games.


== Description

Zyps are small creatures with minds of their own.  You can create dozens of Zyps, then decide how each will act.  (Will it run away from the others?  Follow them?  Eat them for lunch?)  You can combine rules and actions to create very complex behaviors.


== Requirements

* Ruby: http://www.ruby-lang.org
* wxRuby (for the GUI): http://wxruby.rubyforge.org
* Rake (to build from source): http://rake.rubyforge.org


== Installation

Make sure you have administrative privileges, then type the following at a command line:

	gem install zyps

Ensure wxRuby is installed and working:

	gem install wxruby


== Usage

At a command line, type:

	zyps


== Development

Source code and documentation are available via the project site (http://jay.mcgavren.com/zyps).

Once downloaded, change into the project directory.  For a list of targets, run:

	rake -T

To build a gem:

	rake

To see the demo:
	
	rake demo

To create a "doc" subdirectory with API documentation:

	rake rdoc

Also see "bin/zyps_demo" and the "spec" subfolder in the project directory for sample code.


== Thanks

Glen Franta, Scott McGinty, and so many other math, science, and computer science teachers whose names I've forgotten.  Nothing I do today would be possible without your efforts so long ago.

Alex Fenton and Mario Steele for wxRuby advice.

My lovely wife, Diana, for patience and usability testing.


== Author

Copyright 2007-2008 Zyps Contributors


== License

Zyps is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
