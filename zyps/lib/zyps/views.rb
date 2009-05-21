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


#Base class of views in Zyps.
class View

	
	#A GUI toolkit-specific drawing area that will be used to render the view.
	#See WxCanvas and GTK2Canvas.
	attr_accessor :canvas
	#Scale of the view, with 1.0 being actual size.
	attr_accessor :scale
	#A Location which objects will be drawn relative to.
	attr_accessor :origin
	#Whether view should be erased before re-drawing.
	attr_accessor :erase_flag
	#Color that background should be drawn with.
	attr_accessor :background_color
	
	
	#Takes a hash with these keys and defaults:
	#	:canvas => nil,
	#	:scale => 1,
	#	:origin => Location.new(0.0),
	#	:erase_flag => true,
	#	:background_color => Color.black
	def initialize(options = {})
	
		options = {
			:canvas => nil,
			:scale => 1,
			:origin => Location.new(0, 0),
			:erase_flag => true,
			:background_color => Color.black
		}.merge(options)
		@canvas = options[:canvas]
		self.scale = options[:scale]
		self.origin = options[:origin]
		self.erase_flag = options[:erase_flag]
		
	end
	
	
	#Draw a rectangle to the canvas, compensating for origin and scale.
	#Takes a hash with these keys and defaults:
	#	:color => nil
	#	:border_width => 1
	#	:filled => true
	#	:location => nil
	#	:width => nil
	#	:height => nil
	def draw_rectangle(options = {})
		options = {
			:filled => true,
			:border_width => 1
		}.merge(options)
		x, y = drawing_coordinates(options[:location])
		self.canvas.draw_rectangle(
			:x => x,
			:y => y,
			:width => drawing_scale(options[:width]),
			:height => drawing_scale(options[:height]),
			:border_width => drawing_scale(options[:border_width]),
			:filled => options[:filled],
			:color => options[:color]
		)
	end
	
	
	#Draw a line to the canvas, compensating for origin and scale.
	#Takes a hash with these keys and defaults:
	#	:color => nil
	#	:width => nil
	#	:location_1 => nil
	#	:location_2 => nil
	def draw_line(options = {})
		x1, y1 = drawing_coordinates(options[:location_1])
		x2, y2 = drawing_coordinates(options[:location_2])
		self.canvas.draw_line(
			:x1 => x1,
			:y1 => y1,
			:x2 => x2,
			:y2 => y2,
			:width => drawing_scale(options[:width]),
			:color => options[:color]
		)
	end
	
	
	#Base update method to be overridden in subclass.
	#This method clears the canvas in preparation of drawing to the canvas.
	#It then iterates over each object in the environment and yields the object.
	#This allows the child class to update each object in its own specific manner,
	# by calling super and passing a block that performs the actual update
	def update(environment)
	
		clear_view if erase_flag
		
		#For each GameObject in the environment:
		#yields this object to the calling block
		environment.objects.each do |object|
			yield object
		end #environment.objects.each
		#render the canvas
		@canvas.render
		
	end #update
	
	
	private


		#Clear view.
		def clear_view
			@canvas.draw_rectangle(
				:color => Color.new(0, 0, 0),
				:filled => true,
				:x => 0, :y => 0,
				:width => @canvas.width, :height => @canvas.height
			)
		end
	
	
		#Convert a Location to x and y drawing coordinates, compensating for view's current scale and origin.
		def drawing_coordinates(location)
			[
				(location.x - origin.x) * scale,
				(location.y - origin.y) * scale
			]
		end
		
		
		#Convert a width to a drawing width, compensating for view's current scale.
		def drawing_scale(units)
			units * scale
		end
	
	
end #View class

end #Zyps module