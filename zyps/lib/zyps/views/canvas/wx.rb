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


require 'wx'
require 'zyps/views/canvas'


module Zyps


#Called by View objects for use in wxRuby applications.
#Assign an instance to a View, and the drawing_area will be updated whenever the View is.
class WxCanvas < Canvas


	#A Wx::Bitmap that will be painted on.
	attr_reader :buffer
	
	def initialize(width = 1, height = 1)

		super

		#Set buffer to match current width and height.
		resize
	
		#Hash of Wx::Pens used to draw in various colors and widths.
		@pens = Hash.new {|h, k| h[k] = Hash.new}
		#Hash of Wx::Brushes for various colors.
		@brushes = Hash.new
		
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
		buffer.draw do |surface|
			#Draw all queued rectangles.
			render_rectangles(surface)
			#Draw all queued lines.
			render_lines(surface)
		end
	end
				
	
	#The Wx::Bitmap to draw to.
	def buffer
		@buffer ||= Wx::Bitmap.new(@width, @height)
	end

	
	private

	
		#Converts a Zyps Color to the toolkit's color class.
		def convert_color(color)
			Wx::Colour.new(
				(color.red * 255).floor,
				(color.green * 255).floor,
				(color.blue * 255).floor
			)
		end
	
	
		#Resize buffer and drawing area.
		def resize
			@buffer = nil #Causes buffer to reset its size next time it's accessed.
		end

		
		#Draw all queued rectangles to the given GC.
		def render_rectangles(surface)
			while options = @rectangle_queue.shift do
				surface.pen = get_pen(options[:color], options[:border_width]) #Used for border.
				if options[:filled]
					surface.brush = get_brush(options[:color])
				else
					surface.brush = Wx::TRANSPARENT_BRUSH
				end
				surface.draw_rectangle(
					options[:x], options[:y],
					options[:width], options[:height]
				)
			end
		end

			
		#Draw all queued lines to the given GC.
		def render_lines(surface)
			surface.pen.cap = Wx::CAP_ROUND
			while options = @line_queue.shift do
				surface.pen = get_pen(options[:color], options[:width])
				surface.draw_line(
					options[:x1].floor, options[:y1].floor,
					options[:x2].floor, options[:y2].floor
				)
			end
		end
		
		
		def get_pen(color, width)
			@pens[[color.red, color.green, color.blue]][width] ||= Wx::Pen.new(convert_color(color), width.ceil)
		end


		def get_brush(color)
			@brushes[[color.red, color.green, color.blue]] ||= Wx::Brush.new(convert_color(color), Wx::SOLID)
		end

		
end


end #module Zyps