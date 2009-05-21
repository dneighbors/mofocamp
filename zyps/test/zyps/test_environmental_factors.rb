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
require 'zyps/environmental_factors'
require 'test/unit'


include Zyps


#Redefine Clock to return a predictable time.
class Clock
	def elapsed_time; 0.1; end
end


class TestEnclosure < Test::Unit::TestCase

	def test_enclosure
	
		creature = Creature.new
		environment = Environment.new(:objects => [creature])
		
		#Create an enclosure.
		enclosure = Enclosure.new(
			:left => 1,
			:top => 3,
			:right => 3,
			:bottom => 1
		)
		
		#Place creature outside the walls, and act on it.
		#Ensure it's moved inside and its heading reflects off the walls.
		creature.location = Location.new(0, 2) #Too far left.
		creature.vector.pitch = 170
		enclosure.act(environment)
		assert_equal(1, creature.location.x)
		assert_equal(2, creature.location.y)
		assert_equal(10, creature.vector.pitch)
		
		creature.location = Location.new(4, 2) #Too far right.
		creature.vector.pitch = 10
		enclosure.act(environment)
		assert_equal(3, creature.location.x)
		assert_equal(2, creature.location.y)
		assert_equal(170, creature.vector.pitch)
		
		creature.location = Location.new(2, 0) #Too far down.
		creature.vector.pitch = 280
		enclosure.act(environment)
		assert_equal(2, creature.location.x)
		assert_equal(1, creature.location.y)
		assert_equal(80, creature.vector.pitch)
		
		creature.location = Location.new(2, 4) #Too far up.
		creature.vector.pitch = 80
		enclosure.act(environment)
		assert_equal(2, creature.location.x)
		assert_equal(3, creature.location.y)
		assert_equal(280, creature.vector.pitch)
		
		#Place creature inside the walls, and ensure it's unaffected.
		creature.location = Location.new(2, 2) #Inside.
		creature.vector.pitch = 45
		enclosure.act(environment)
		assert_equal(2, creature.location.x)
		assert_equal(2, creature.location.y)
		assert_equal(45, creature.vector.pitch)
		
	end
	
end



class TestWrapAround < Test::Unit::TestCase

	def test_wrap_around
	
		creature = Creature.new
		environment = Environment.new(:objects => [creature])
		
		#Create a WrapAround.
		wrapper = WrapAround.new(
			:left => 1,
			:top => 3,
			:right => 3,
			:bottom => 1
		)
		
		#Place creature outside the walls, and act on it.
		#Ensure it's moved inside on opposite side.
		creature.location = Location.new(0, 2) #Too far left.
		wrapper.act(environment)
		assert_equal(3, creature.location.x)
		assert_equal(2, creature.location.y)
		
		creature.location = Location.new(4, 2) #Too far right.
		wrapper.act(environment)
		assert_equal(1, creature.location.x)
		assert_equal(2, creature.location.y)
		
		creature.location = Location.new(2, 0) #Too far down.
		wrapper.act(environment)
		assert_equal(2, creature.location.x)
		assert_equal(3, creature.location.y)
		
		creature.location = Location.new(2, 4) #Too far up.
		wrapper.act(environment)
		assert_equal(2, creature.location.x)
		assert_equal(1, creature.location.y)
		
		#Place creature inside the walls, and ensure it's unaffected.
		creature.location = Location.new(2, 2) #Inside.
		wrapper.act(environment)
		assert_equal(2, creature.location.x)
		assert_equal(2, creature.location.y)
		
	end
	
end



class TestSpeedLimit < Test::Unit::TestCase

	def test_speed_limit
	
		creature = Creature.new
		environment = Environment.new(:objects => [creature])
		
		#Create a speed limit.
		limit = SpeedLimit.new(10)
		
		#Act on a creature going under the limit, and ensure it's unaffected.
		creature.vector.speed = 1
		limit.act(environment)
		assert_equal(1, creature.vector.speed)
		
		#Act on a creature going over the limit, and ensure its speed is reduced.
		creature.vector.speed = 11
		limit.act(environment)
		assert_equal(10, creature.vector.speed)
		
		#Act on a creature going in reverse, and ensure its speed is reduced.
		creature.vector.speed = -11
		limit.act(environment)
		assert_equal(-10, creature.vector.speed)
				
	end
	
end


class TestPopulationLimit < Test::Unit::TestCase
	
	def test_limit
	
		#Create an environment.
		environment = Environment.new
		#Create a population limit for the environment.
		limit = PopulationLimit.new(2)
		
		#Ensure population is not affected when under/at the limit.
		creature_1 = Creature.new
		environment.add_object(creature_1)
		limit.act(environment)
		assert_equal(1, environment.object_count)
		creature_2 = Creature.new
		environment.add_object(creature_2)
		limit.act(environment)
		assert_equal(2, environment.object_count)
		limit.act(environment)
		assert_equal(2, environment.object_count)
		
		#Ensure first creature is removed when limit is exceeded.
		creature_3 = Creature.new
		environment.add_object(creature_3)
		limit.act(environment)
		assert_equal(2, environment.object_count)
		
	end
	
end
