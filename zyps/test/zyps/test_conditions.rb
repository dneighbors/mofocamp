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
require 'zyps/conditions'
require 'test/unit'


include Zyps


class TestConditions < Test::Unit::TestCase


	def setup
		@actor = Creature.new(:name => 'name', :location => Location.new(1, 1))
		@target = GameObject.new(:name => 'name', :location => Location.new(2, 2))
	end


	def test_tag_condition
		condition = TagCondition.new("tag")
		#Test for falsehood.
		assert(! condition.select(@actor, [@target]).include?(@target))
		#Test for truth.
		@target.tags << "tag"
		assert(condition.select(@actor, [@target]).include?(@target))
	end
	
	
	def test_age_condition
		condition = AgeCondition.new(0.2)
		#Test for falsehood.
		@target.age = 0.1
		assert(! condition.select(@actor, [@target]).include?(@target))
		#Test for truth.
		@target.age = 0.2
		assert(condition.select(@actor, [@target]).include?(@target))
		@target.age = 0.3
		assert(condition.select(@actor, [@target]).include?(@target))
	end
	
	
	def test_proximity_condition
		condition = ProximityCondition.new(1)
		#Test for falsehood.
		assert(! condition.select(@actor, [@target]).include?(@target))
		#Test for truth.
		@target.location = Location.new(0.5, 0.5)
		assert(condition.select(@actor, [@target]).include?(@target))
	end
	
	
	def test_collision_condition
		condition = CollisionCondition.new
		#Test for falsehood.
		@actor.size, @target.size = 0.196, 0.196 #Radius = 0.25
		assert(! condition.select(@actor, [@target]).include?(@target))
		#Test for truth.
		@actor.size, @target.size = 1.766, 1.766 #Radius = 0.75
		assert(condition.select(@actor, [@target]).include?(@target))
	end
	
	
	def test_strength_condition
		condition = StrengthCondition.new
		#For now, "strength" is based merely on size.
		#Test for falsehood.
		@actor.size = 1
		@target.size = 2
		assert(! condition.select(@actor, [@target]).include?(@target))
		#Test for truth.
		#Equally strong objects cause the condition to return true.
		@actor.size = 2
		@target.size = 2
		assert(condition.select(@actor, [@target]).include?(@target))
		#As will cases where the actor is stronger, of course.
		@actor.size = 3
		@target.size = 2
		assert(condition.select(@actor, [@target]).include?(@target))
	end
	
	
# 	def test_elapsed_time_condition
# 		condition = ElapsedTimeCondition.new
# 		condition.interval = 0.2
# 		#Test for falsehood.
# 		#On first pass, its clock will only be at 0.1 seconds.
# 		assert(! condition.select(@actor, [@target]).include?(@target))
# 		#Test for truth.
# 		#On first pass, its clock will be at 0.2 seconds, the assigned interval.
# 		assert(condition.select(@actor, [@target]).include?(@target))
# 	end
	
	
	#ActiveLessThanConditions deselect targets when their assigned action has been active too long.
	#This limits the time a behavior continues for.
	def test_active_less_than_condition
		condition = ActiveLessThanCondition.new(0.15)
		#Test for truth.
		#On the first pass, the condition's clock will only be at 0.1 seconds.
		assert(condition.select(@actor, [@target]).include?(@target))
		#Test for falsehood.
		#On the second pass, the condition's clock will be at 0.2 seconds.
		assert(! condition.select(@actor, [@target]).include?(@target))
		#On the third pass, the condition's clock will have reset because it was false before.
		#It will now be at 0.1 seconds.
		assert(condition.select(@actor, [@target]).include?(@target))
	end
	
	#InactiveLongerThanConditions deselect targets until the given duration has elapsed.
	#This delays a behavior.
	def test_inactive_longer_than_condition
		condition = InactiveLongerThanCondition.new(0.15)
		#Test for falsehood.
		#On the first pass, the condition's clock will only be at 0.1 seconds.
		assert(! condition.select(@actor, [@target]).include?(@target))
		#Test for truth.
		#On the second pass, the condition's clock will be at 0.2 seconds.
		assert(condition.select(@actor, [@target]).include?(@target))
		#On the third pass, the condition's clock will have reset and will only be at 0.1 seconds.
		assert(! condition.select(@actor, [@target]).include?(@target))
	end

end
