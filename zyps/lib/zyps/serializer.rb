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

require 'yaml'
require 'zyps'
require 'singleton'


module Zyps

YAML_DOMAIN = "jay.mcgavren.com,2008-03-15"


#Define attributes that should not be serialized.

class Action
	def to_yaml_properties
		instance_variables.reject{|v| v == "@behavior"}
	end
end
class Behavior
	def to_yaml_properties
		instance_variables.reject{|v| v == "@creature" or v == "@current_targets"}
	end
end
class Clock
	def to_yaml_properties
		instance_variables.reject{|v| v == "@last_check_time"}
	end
end
class Condition
	def to_yaml_properties
		instance_variables.reject{|v| v == "@behavior"}
	end
end
class Environment
	#Environment should exclude any observers.
	def to_yaml_properties
		instance_variables.reject{|v| v == "@observer_peers"}
	end
end
class EnvironmentalFactor
	def to_yaml_properties
		instance_variables.reject{|v| v == "@environment"}
	end
end
class GameObject
	def to_yaml_properties
		instance_variables.reject{|v| v == "@environment"}
	end
end


#Restore environment attribute of any member GameObjects, EnvironmentalFactors.
YAML.add_ruby_type("object:Zyps::Environment") do |type, value|
	environment = YAML.object_maker(Zyps::Environment, value)
	environment.objects.each {|o| o.environment = environment}
	environment.environmental_factors.each {|f| f.environment = environment}
	environment
end
#Restore behavior attribute of any member Actions and Conditions.
#Set current targets to empty array.
YAML.add_ruby_type("object:Zyps::Behavior") do |type, value|
	behavior = YAML.object_maker(Zyps::Behavior, value)
	behavior.actions.each {|a| a.behavior = behavior}
	behavior.conditions.each {|a| a.behavior = behavior}
	behavior.instance_eval {@current_targets = []}
	behavior
end
#Restore creature attribute of any member Behaviors.
YAML.add_ruby_type("object:Zyps::Creature") do |type, value|
	creature = YAML.object_maker(Zyps::Creature, value)
	creature.behaviors.each {|o| o.creature = creature}
	creature
end
#Reset elapsed time for any clocks.
YAML.add_ruby_type("object:Zyps::Clock") do |type, value|
	clock = YAML.object_maker(Zyps::Clock, value)
	clock.reset_elapsed_time
	clock
end



class Serializer

	include Singleton
	
	#Return serialized representation of object.
	def serialize(object)
		YAML.dump(object)
	end

	#Return object from serialized representation.
	def deserialize(string)
		YAML.load(string)
	end
	
end


end #module Zyps