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


module Zyps


#Base class of shapes in Zyps.
class Shape

	#A Location object for the Shape.
	attr_accessor :location
	#A Color object for the Shape.
	attr_accessor :color

	#Takes a hash with the following keys and defaults:
	def initialize(options = {})
		options = {
			:location => Location.new,
			:color => Color.new
		}.merge(options)
		self.location = options[:location]
		self.color = options[:color]
	end
	
end


#A rectanglular shape.
class Rectangle < Shape

	#The shape's width.
	attr_accessor :width
	#The shape's height.
	attr_accessor :height
	
	#Takes a hash with the following keys and defaults, in addition to those for Shape:
	#	:width => 1,
	#	:height => 1
	def initialize(options = {})
		options = {
			:width => 1,
			:height => 1
		}.merge(options)
		super
		self.width = options[:width]
		self.height = options[:height]
	end
	
	#Renders self to given Canvas.
	def draw(canvas)
		canvas.draw_rectangle(
			:color => self.color,
			:x => self.location.x,
			:y => self.location.y,
			:width => self.width,
			:height => self.height
		)
	end

end


#A circular shape.
class Circle < Shape
end


#Acts like a circle, but has a segmented, intangible tail.
class Zyp < Circle
end


end #module Zyps
