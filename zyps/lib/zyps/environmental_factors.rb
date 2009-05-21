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


#Keeps all objects within a set of walls.
class Enclosure < EnvironmentalFactor
	
	#X coordinate of left boundary.
	attr_accessor :left
	#Y coordinate of top boundary.
	attr_accessor :top
	#X coordinate of right boundary.
	attr_accessor :right
	#Y coordinate of bottom boundary.
	attr_accessor :bottom
	
	#Takes a hash with these keys and defaults:
	#	:left => 0
	#	:top => 0
	#	:right => 0
	#	:bottom => 0
	def initialize(options = {})
		options = {
			:left => 0,
			:top => 0,
			:right => 0,
			:bottom => 0
		}.merge(options)
		self.left, self.top, self.right, self.bottom = options[:left], options[:top], options[:right], options[:bottom]
	end
	
	#If object is beyond a boundary, set its position equal to the boundary and reflect it.
	def act(environment)
		environment.objects.each do |object|
			if (object.location.x < @left) then
				object.location.x = @left
				object.vector.pitch = Utility.find_reflection_angle(90, object.vector.pitch)
			elsif (object.location.x > @right) then
				object.location.x = @right
				object.vector.pitch = Utility.find_reflection_angle(270, object.vector.pitch)
			end
			if (object.location.y > @top) then
				object.location.y = @top
				object.vector.pitch = Utility.find_reflection_angle(0, object.vector.pitch)
			elsif (object.location.y < @bottom) then
				object.location.y = @bottom
				object.vector.pitch = Utility.find_reflection_angle(180, object.vector.pitch)
			end
		end
	end
	
	#True if boundaries are same.
	def ==(other)
		return false unless super
		self.left == other.left and
			self.right == other.right and
			self.top == other.top and
			self.bottom == other.bottom
	end
	
end


#When an object crosses its boundary, warps object to opposite boundary.
class WrapAround < EnvironmentalFactor
	
	#X coordinate of left boundary.
	attr_accessor :left
	#Y coordinate of top boundary.
	attr_accessor :top
	#X coordinate of right boundary.
	attr_accessor :right
	#Y coordinate of bottom boundary.
	attr_accessor :bottom
	
	#Takes a hash with these keys and defaults:
	#	:left => 0
	#	:top => 0
	#	:right => 0
	#	:bottom => 0
	def initialize(options = {})
		options = {
			:left => 0,
			:top => 0,
			:right => 0,
			:bottom => 0
		}.merge(options)
		self.left, self.top, self.right, self.bottom = options[:left], options[:top], options[:right], options[:bottom]
	end
	
	#If object is beyond a boundary, set its position to that of opposite boundary.
	def act(environment)
		environment.objects.each do |object|
			if (object.location.x < @left) then
				object.location.x = @right
			elsif (object.location.x > @right) then
				object.location.x = @left
			end
			if (object.location.y > @top) then
				object.location.y = @bottom
			elsif (object.location.y < @bottom) then
				object.location.y = @top
			end
		end
	end
	
	#True if boundaries are same.
	def ==(other)
		return false unless super
		self.left == other.left and
			self.right == other.right and
			self.top == other.top and
			self.bottom == other.bottom
	end
	
end


#Keeps all objects at/under the assigned speed.
class SpeedLimit < EnvironmentalFactor
	
	#Maximum allowed speed in units.
	attr_accessor :maximum
	
	def initialize(units = nil)
		self.maximum = units
	end
	
	#If object is over the speed, reduce its speed.
	def act(environment)
		environment.objects.each do |object|
			object.vector.speed = Utility.constrain_value(object.vector.speed, @maximum)
		end
	end
	
	#True if maximum is the same.
	def ==(other)
		return false unless super
		self.maximum == other.maximum
	end
	
end


#A force that pushes on all objects.
class Accelerator < EnvironmentalFactor
	
	#A Clock that tracks time between actions.
	attr_accessor :clock
	#Vector to apply to objects.
	attr_accessor :vector
	
	def initialize(vector = nil)
		self.vector = vector
		@clock = Clock.new
	end

	#Make a deep copy.
	def copy
		copy = super
		#Copies should have their own Clock.
		copy.clock = @clock.copy
		copy
	end
	
	#Add the given vector to each object, but limited by elapsed time.
	def act(environment)
		elapsed_time = @clock.elapsed_time
		environment.objects.each do |object|
			#Push on object.
			object.vector += Vector.new(@vector.speed * elapsed_time, @vector.pitch)
		end
	end

	#True if maximum is the same.
	def ==(other)
		return false unless super
		self.vector == other.vector
	end
	
end


#Gravity pulls all objects downward.
class Gravity < Accelerator

	#Rate of acceleration.
	attr_accessor :force
	
	def initialize(force = 9.8)
		super(Vector.new(force, 90))
		self.force = force
	end
	
	def force= (force)
		@vector.speed = force
	end
	
end


#A force that slows all objects.
class Friction < EnvironmentalFactor
	
	#A Clock that tracks time between actions.
	attr_accessor :clock
	#Rate of slowing.
	attr_accessor :force
	
	def initialize(force = nil)
		self.force = force
		#Track time since last action.
		@clock = Clock.new
	end
	
	#Make a deep copy.
	def copy
		copy = super
		#Copies should have their own Clock.
		copy.clock = @clock.copy
		copy
	end
	
	#Reduce each object's speed at the given rate.
	def act(environment)
		elapsed_time = @clock.elapsed_time
		environment.objects.each do |object|
			#Slow object.
			acceleration = @force * elapsed_time
			speed = object.vector.speed
			if speed > 0
				speed -= acceleration 
				speed = 0 if speed < 0
			elsif speed < 0
				speed += acceleration
				speed = 0 if speed > 0
			end
			object.vector.speed = speed
		end
	end
	
	#True if force is the same.
	def ==(other)
		return false unless super
		self.force == other.force
	end
	
end


class PopulationLimit < EnvironmentalFactor
	
	#Maximum allowed population.
	attr_accessor :count
	
	def initialize(count = nil)
		self.count = count
	end
	
	#Remove objects if there are too many objects in environment.
	def act(environment)
		excess = environment.object_count - @count
		if excess > 0
			objects_for_removal = []
			environment.objects.each do |object|
				objects_for_removal << object
				break if objects_for_removal.length >= excess
			end
			objects_for_removal.each {|object| environment.remove_object(object.identifier)}
		end
	end
	
	#True if count is the same.
	def ==(other)
		return false unless super
		self.count == other.count
	end
	
end


end #module Zyps
