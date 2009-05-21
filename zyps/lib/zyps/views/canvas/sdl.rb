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


require 'sdl'
require 'zyps/views/canvas'


module Zyps


#Called by View objects for use in Ruby/SDL applications.
#Assign an instance to a View, and the drawing_area will be updated whenever the View is.
class SDLCanvas < Canvas


	#TODO: Consider making this an attribute.
	SURFACE_FORMAT = 32
	

	#A bitmap that will be painted on.
	attr_reader :buffer
	
	def initialize(width = 1, height = 1)

		super

		#Set buffer to match current width and height.
		resize
	
	end

	def width= (pixels) #:nodoc:
		@width = pixels
		resize
	end
	
	def height= (pixels) #:nodoc:
		@height = pixels
		resize
	end
	
	
	#Draw all objects to the drawing area.
	def render
		buffer.lock
		#Draw all queued rectangles.
		render_rectangles(buffer)
		#Draw all queued lines.
		render_lines(buffer)
		buffer.unlock
	end
				
	
	#The surface to draw to.
	def buffer
		@buffer ||= SDL::Surface.new(SDL::SWSURFACE, @width, @height, SURFACE_FORMAT)
	end

	
	private

	
		#Converts a Zyps Color to the toolkit's color class.
		def convert_color(color)
			[
				(color.red * 255).floor,
				(color.green * 255).floor,
				(color.blue * 255).floor
			]
		end
	
	
		#Resize buffer and drawing area.
		def resize
			@buffer = nil #Causes buffer to reset its size next time it's accessed.
		end

		
		#Draw all queued rectangles to the given GC.
		def render_rectangles(surface)
			while options = @rectangle_queue.shift do
				surface.draw_rect(
					options[:x], options[:y],
					options[:width], options[:height],
					convert_color(options[:color]),
					options[:filled]
				)
			end
		end

			
		#Draw all queued lines to the given GC.
		def render_lines(surface)
			while options = @line_queue.shift do
				x1, y1, x2, y2 = options[:x1].floor, options[:y1].floor, options[:x2].floor, options[:y2].floor
				color = convert_color(options[:color])
				#Round end caps.
				surface.draw_circle(x1, y1, options[:width], color, true)
				surface.draw_circle(x2, y2, options[:width], color, true)
				#Draw line.
				surface.draw_line(x1, x2, y1, y2, color)
			end
		end
		
		
end


end #module Zyps