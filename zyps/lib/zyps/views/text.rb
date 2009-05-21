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
class TextView < View

	#An object to puts() text to.
	attr_accessor :output

	#Takes a hash with the following keys and defaults:
	#	:output => STDOUT
	def initialize (options = {})
	
		super
		
		options = {
			:output => STDOUT,
		}.merge(options)
		@output = options[:output]
		
	end

	#Takes an Environment, and prints objects to the assigned output.
	def update(environment)
	
		output.puts environment
		
	end
	
	
	private
	
	
		#Do nothing; text views don't need to be cleared.
		def clear_view; end

	
end


end #module Zyps
