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

require 'logger'
require 'singleton'


class ObjectManager

	#These accessors store the object(s) referred to by various pronouns.
	attr_accessor :it, :them

	def initialize
		@log = Logger.new(STDOUT)
		@log.level = Logger::WARN
		@log.progname = self
		@the = Hash.new {|h, k| h[k] = []}
		@creators = Hash.new
	end

	#Takes an object name and a block that will be called when an instance of the named object must be created.
	#The block will be passed the given name.
	def on_create(name, &block)
		@log.debug "Assigning creator block for '#{name}'."
		@creators[name] = block
	end

	#Given a name, create an appropriate object and store it for later reference.
	def create(*names)
		objects = []
		names.each do |name|
			if @creators[name]
				@log.debug "Creator block found for '#{name}', calling it."
				object = @creators[name].call(name)
			else
				#By default, assume name is a class name and create an instance of it.
				class_name = name.split(/\s+/).map{|w| w.capitalize}.join('')
				@log.debug "Calling empty constructor for '#{class_name}'."
				object = Object.const_get(class_name).new
			end
			#Add name to 'the' collection so it can be referenced later.
			@log.debug "'the #{name}' is now #{object.to_s}."
			@the[name] << object
			#Add object to return list.
			objects << object
		end
		@log.debug "Created objects: #{objects.map{|o| o.to_s}.join(' ')}"
		objects
	end

	#Create or retrieve objects referenced by a phrase.
	def resolve_objects(phrase)
		case phrase
		#The meaning of pronouns should have been assigned by prior calls.
		when /^it$/i
			objects = @it or fail "Could not determine what 'it' references."
		when /^them$/i
			objects = @them or fail "Could not determine what 'them' references."
		when /^they$/i
			objects = @them or fail "Could not determine what 'they' references."
		#Objects should be created for indefinite articles.
		when /^(?:a|an|another) (.+)$/i
			objects = create($1)
			@it = [objects.first]
			@log.debug "'it' is now #{@it}."
		#Objects should already exist for the definite article.
		when /^the (.+)$/i
			#TODO: Add support for ordinals.
			objects = @the[$1] or fail "Could not find previous reference to '#{$1}'."
		when /^each (.+)$/i
			objects = @the[$1]
			fail "Could not find previous reference to '#{$1}'." if objects.empty?
			@them = objects
			@log.debug "'them' is now #{@them}."
		else
			fail "Could not parse phrase: '#{phrase}'"
		end
		@log.debug "Resolved phrase '#{phrase}': #{objects.inspect}"
		objects
	end

end
