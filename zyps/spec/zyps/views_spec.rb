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
	require 'zyps/views'
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


describe View do

	before(:each) do
		@view = View.new
	end

	it "has no Canvas by default"
	it "has a scale of 1 by default"
	it "has an origin of 0, 0 by default"
	it "erases between frames by default"
	it "has a black background by default"
	
	it "corrects for scale when drawing rectangles to a Canvas" do
		@view.scale = 0.5
		@view.canvas = Canvas.new
		@view.canvas.should_receive(:draw_rectangle).with(
			:x => 0.5,
			:y => 1,
			:width => 2,
			:height => 1,
			:color => Color.white,
			:border_width => 0.5,
			:filled => true
		)
		@view.draw_rectangle(
			:location => Location.new(1, 2),
			:width => 4,
			:height => 2,
			:color => Color.white,
			:border_width => 1
		)
	end
	
	it "corrects for origin when drawing rectangles to a Canvas" do
		@view.origin = Location.new(-2, -3)
		@view.canvas = Canvas.new
		@view.canvas.should_receive(:draw_rectangle).with(
			:x => 5,
			:y => 8,
			:width => 1,
			:height => 3,
			:color => Color.blue,
			:border_width => 2,
			:filled => false
		)
		@view.draw_rectangle(
			:location => Location.new(3, 5),
			:width => 1,
			:height => 3,
			:color => Color.blue,
			:border_width => 2,
			:filled => false
		)
	end
	
	it "corrects for scale when drawing lines to a Canvas" do
		@view.scale = 2
		@view.canvas = Canvas.new
		@view.canvas.should_receive(:draw_line).with(
			:x1 => 2,
			:y1 => 4,
			:x2 => 6,
			:y2 => 8,
			:width => 10,
			:color => Color.orange
		)
		@view.draw_line(
			:location_1 => Location.new(1, 2),
			:location_2 => Location.new(3, 4),
			:width => 5,
			:color => Color.orange
		)
	end
	
	it "corrects for origin when drawing lines to a Canvas" do
		@view.origin = Location.new(10, 10)
		@view.canvas = Canvas.new
		@view.canvas.should_receive(:draw_line).with(
			:x1 => -5,
			:y1 => -4,
			:x2 => -7,
			:y2 => -6,
			:width => 2,
			:color => Color.green
		)
		@view.draw_line(
			:location_1 => Location.new(5, 6),
			:location_2 => Location.new(3, 4),
			:width => 2,
			:color => Color.green
		)
	end
	
end
