# Copyright 2007-2008 Zyps Contributors.
# 
# This file is part of Zyps.
# 
# Zyps is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


gems_loaded = false
begin
	require 'spec'
	require 'zyps'
	require 'zyps/shapes'
	require 'zyps/views/canvas'
rescue LoadError
	if gems_loaded == false
		require 'rubygems'
		gems_loaded = true
		retry
	else
		raise
	end
end


include Zyps


describe Rectangle do

	before(:each) do
		@shape = Rectangle.new
	end

	it "has a default size"	
	it "has a default Color"	
	it "draws itself to Views"	
	it "collides with Locations inside it"	
	it "collides with Locations that have passed through it since the prior frame"
	
end


describe Zyp do

	before(:each) do
		@shape = Zyp.new
	end

	it "has a default size"
	it "draws itself to Views when it has 1 segment"
	it "draws itself to Views when it has 2 segments"	
	it "draws itself to Views when it has 3 segments"
	it "draws itself to Views when it has 100 segments"
	
	it "drops prior segment end locations when over its maximum segment count"
	it "collides with Locations inside it"
	it "collides with Locations that have passed through it since the prior frame"
	it "should report the normal from its surface for a given point of impact"

end