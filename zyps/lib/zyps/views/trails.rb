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
require 'zyps/views'


module Zyps


#A view of game objects.
class TrailsView < View

	#Number of line segments to draw for each object.
	attr_accessor :trail_length

	#Takes a hash with these keys and defaults, in addition to those defined for the View constructor:
	#	:trail_length => 5
	def initialize (options = {})
	
		super
	
		options = {
			:trail_length => 5,
		}.merge(options)
		@trail_length = options[:trail_length]
		
		#Track a list of locations for each object.
		@locations = Hash.new {|h, k| h[k] = Array.new}
		
	end

	#Takes an Environment, and draws it to the canvas.
	#Tracks the position of each GameObject over time so it can draw a trail behind it.
	#The head will match the object's Color exactly, fading to black at the tail.
	#GameObject.size will be used as the line thickness at the object's head, diminishing to 1 at the tail.
	def update(environment)
	
		#For each GameObject in the environment:
		super do |object|

			object_radius = Math.sqrt(object.size / Math::PI)

			#Add the object's current location to the list.
			@locations[object.identifier] << object.location.copy

			#If the list is larger than the number of tail segments, delete the first position.
			@locations[object.identifier].shift while @locations[object.identifier].length > @trail_length

			#For each location in this object's list:
			@locations[object.identifier].each_with_index do |location, index|
			
				#Skip first location.
				next if index == 0
				
				#Divide the current segment number by trail segment count to get the multiplier to use for brightness and width.
				multiplier = index.to_f / @locations[object.identifier].length.to_f
				
				#Get previous location so we can draw a line from it.
				previous_location = @locations[object.identifier][index - 1]
				
				draw_line(
					:color => Color.new(
						object.color.red * multiplier,
						object.color.green * multiplier,
						object.color.blue * multiplier
					),
					:width => (object_radius * 2 * multiplier).ceil,
					:location_1 => previous_location,
					:location_2 => location
				)
				
			end
			
		end
		
	end

	
end


end #module Zyps
