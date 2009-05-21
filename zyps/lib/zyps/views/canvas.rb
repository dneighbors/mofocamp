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


require 'zyps'
require 'zyps/shapes'


module Zyps


#Parent class for GUI framework-specific Canvas objects.
#Assign an instance to a View, and the drawing_area will be updated whenever the View is.
class Canvas


	#Dimensions of the drawing area.
	#Control should normally be left to the owner View object.
	attr_reader :width, :height


	def initialize(width = 1, height = 1)
	
		#Will be resized later.
		@width, @height = width, height

		#Arrays of shapes that will be painted when render() is called.
		@rectangle_queue = []
		@line_queue = []
		
	end


	#Takes a hash with these keys and defaults:
	#	:color => nil
	#	:border_width => 1
	#	:filled => true
	#	:x => nil
	#	:y => nil
	#	:width => nil
	#	:height => nil
	def draw_rectangle(options = {})
		options = {
			:filled => true,
			:border_width => 1
		}.merge(options)
		@rectangle_queue << options
	end
	
	
	#Takes a hash with these keys and defaults:
	#	:color => nil
	#	:width => nil
	#	:x1 => nil
	#	:y1 => nil
	#	:x2 => nil
	#	:y2 => nil
	def draw_line(options = {})
		@line_queue << options
	end
		
	
end


end #module Zyps