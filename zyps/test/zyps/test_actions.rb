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
require 'zyps/actions'
require 'test/unit'


include Zyps


#Allowed deviation for assert_in_delta.
REQUIRED_ACCURACY = 0.001


#Redefine Clock to return a predictable time.
class Clock
	def elapsed_time; 0.1 * speed * Clock.speed; end
end


class TestActions < Test::Unit::TestCase


	#Create and populate an environment.
	def setup
		@actor = Creature.new(:name => 'actor', :location => Location.new(0, 0))
		@target1 = Creature.new(:name => 'target1', :location => Location.new(1, 1))
		#Create an environment, and add the objects.
		@environment = Environment.new
		#Order is important - we want to act on target 1 first.
		@environment << @actor << @target1
	end
	
	#Add a new behavior to a creature with the given action.
	def add_action(action, creature)
		behavior = Behavior.new
		behavior.add_action action
		creature.add_behavior behavior
	end


	#A FaceAction turns directly toward the target.
	def test_face_action
		add_action(FaceAction.new, @actor)
		@environment.interact
		assert_in_delta(45, @actor.vector.pitch, REQUIRED_ACCURACY)
	end
	
	
	#An AccelerateAction speeds up the actor at a given rate.
	def test_accelerate_action
		#Accelerate 1 unit per second.
		add_action(AccelerateAction.new(1), @actor)
		@environment.interact
		#Clock always returns 0.1 seconds, so actor should be moving 0.1 unit/second faster.
		assert_in_delta(0.1, @actor.vector.speed, REQUIRED_ACCURACY)
	end
	
	
	#A TurnAction turns the actor at a given rate.
	def test_turn_action
		@actor.vector = Vector.new(1, 0)
		#Turn 45 degrees off-heading at 1 unit/second.
		add_action(TurnAction.new(1, 45), @actor)
		@environment.interact
		#Clock always returns 0.1 seconds, so ensure actor's vector is adjusted accordingly.
		assert_in_delta(3.778, @actor.vector.pitch, REQUIRED_ACCURACY)
		assert_in_delta(1.073, @actor.vector.speed, REQUIRED_ACCURACY)
	end
	
	
	#An ApproachAction pushes the actor toward the target.
	def test_approach_action
	
		#Create an ApproachAction with 1 unit/sec thrust.
		@actor.vector = Vector.new(0, 0)
		add_action(ApproachAction.new(1), @actor)
		#Act.
		@environment.interact
		#Ensure actor's vector is correct after action's thrust is applied for 0.1 seconds.
		assert_in_delta(0.1, @actor.vector.speed, REQUIRED_ACCURACY)
		assert_in_delta(45, @actor.vector.pitch, REQUIRED_ACCURACY)

	end
	
	#A FleeAction pushes the actor away from a target.
	def test_flee_action

		#Create a FleeAction with a 0-degree vector, turn rate of 40 degrees/sec.
		@actor.vector = Vector.new(0, 0)
		action = FleeAction.new(1)
		add_action(action, @actor)
		#Act.
		@environment.interact
		#Ensure actor's resulting vector is correct after 0.1 seconds of thrust.
		assert_in_delta(0.1, @actor.vector.speed, REQUIRED_ACCURACY)
		assert_in_delta(225, @actor.vector.pitch, REQUIRED_ACCURACY)
	end
	
	#A DestroyAction removes the target from the environment.
	def test_destroy_action
		#Create a DestroyAction, linked to the environment.
		add_action(DestroyAction.new, @actor)
		#Act.
		@environment.interact
		#Verify targets are removed from environment.
		assert(! @environment.objects.include?(@target1))
	end
	
	
	#An EatAction is like a DestroyAction, but also makes the actor grow in size.
	def test_eat_action
		#Create an EatAction, linked to the environment.
		add_action(EatAction.new, @actor)
		#Act.
		@actor.size = 1
		@target1.size = 2
		@environment.interact
		#Verify targets are removed from environment.
		assert(! @environment.objects.include?(@target1))
		#Verify creature has grown by the appropriate amount.
		assert_in_delta(3, @actor.size, REQUIRED_ACCURACY)
	end
	
	
	#A TagAction adds a tag to the target.
	def test_tag_action
		#Create a TagAction, and act.
		add_action(TagAction.new("tag"), @actor)
		@environment.interact
		#Verify target has appropriate tag.
		assert(@target1.tags.include?("tag"))
	end
	
	
	#A BlendAction shifts the actor's color toward the given color.
	def test_blend_action_black
		#Create a BlendAction that blends to black.
		add_action(BlendAction.new(1, Color.new(0, 0, 0)), @actor)
		#Set the actor's color.
		@actor.color = Color.new(0.5, 0.5, 0.5)
		#Act (time difference is 0.1 seconds).
		@environment.interact
		#Verify the actor's new color.
		assert_in_delta(0.45, @actor.color.red, REQUIRED_ACCURACY)
		assert_in_delta(0.45, @actor.color.green, REQUIRED_ACCURACY)
		assert_in_delta(0.45, @actor.color.blue, REQUIRED_ACCURACY)
	end
		
	#Test shifting colors toward white.
	def test_blend_action_white
		#Create a BlendAction that blends to white.
		add_action(BlendAction.new(1, Color.new(1, 1, 1)), @actor)
		#Set the actor's color.
		@actor.color = Color.new(0.5, 0.5, 0.5)
		#Act (time difference is 0.1 seconds).
		@environment.interact
		#Verify the actor's new color.
		assert_in_delta(0.55, @actor.color.red, REQUIRED_ACCURACY)
		assert_in_delta(0.55, @actor.color.green, REQUIRED_ACCURACY)
		assert_in_delta(0.55, @actor.color.blue, REQUIRED_ACCURACY)
	end
	
	
	#A PushAction pushes the target away.
	def test_push_action
		#Create a PushAction, and act.
		add_action(PushAction.new(1), @actor)
		@environment.interact
		#Verify target's speed and direction are correct.
		assert_in_delta(0.1, @target1.vector.speed, REQUIRED_ACCURACY, "@target1 should have been pushed away from @actor.")
		assert_in_delta(45.0, @target1.vector.pitch, REQUIRED_ACCURACY, "@target1's angle should be facing away from @actor.")
	end

	
	#A PullAction pulls the target toward the actor.
	def test_pull_action
		#Create a PullAction, and act.
		add_action(PullAction.new(1), @actor)
		@environment.interact
		#Verify target's speed and direction are correct.
		assert_in_delta(0.1, @target1.vector.speed, REQUIRED_ACCURACY, "@target1 should have been pulled toward @actor.")
		assert_in_delta(225.0, @target1.vector.pitch, REQUIRED_ACCURACY, "@target1's angle should be facing toward @actor.")
	end
	
	
	#A BreedAction creates a new Creature by combining the actor's color and behaviors with another creature.
	def test_breed_action
		#Create two creatures with different colors and behaviors.
		@actor.color = Color.new(1, 1, 1)
		@target1.color = Color.new(0, 0, 0)
		add_action(TagAction.new("1"), @actor)
		add_action(TagAction.new("2"), @target1)
		#Set actor's location to a non-standard place.
		@actor.location = Location.new(33, 33)
		#Create a BreedAction using the Environment, and act.
		@actor.add_behavior Behavior.new(
			:actions => [BreedAction.new],
			:conditions => [InactiveLongerThanCondition.new(0.15)] #Act only on second interaction.
		)
		@environment.interact
		@environment.interact #Act twice to trigger action on actor (and only actor).
		#Find children.
		children = @environment.objects.find_all {|o| o.name == "Copy of actor"}
		#One child should have been spawned with target.
		assert_equal(1, children.length)
		#Ensure child's color is a mix of parents'.
		assert_equal(Color.new(0.5, 0.5, 0.5), children[0].color)
		#Ensure child's behaviors combine the parents'.
		assert_equal(3, children[0].behavior_count)
		assert(
			children[0].behaviors.find do |behavior|
				behavior.actions.find {|action| action.respond_to?(:tag) and action.tag == "1"}
			end
		)
		assert(
			children[0].behaviors.find do |behavior|
				behavior.actions.find {|action| action.respond_to?(:tag) and action.tag == "2"}
			end
		)
		#Ensure child appears at actor's location.
		assert_equal(@actor.location, children[0].location)
	end
	
	
	def test_spawn_action
		#Set up prototypes.
		prototypes = [Creature.new(:name => 'creature'), GameObject.new(:name => 'object')]
		prototypes[0].vector = Vector.new(1, 45)
		#Add prototypes to new SpawnAction.
		add_action(SpawnAction.new(prototypes), @actor)
		#Interact.
		@environment.interact
		#All children should be spawned.
		assert_equal(4, @environment.object_count)
		creature_copy = @environment.objects.find{|o| o.name == 'Copy of creature'}
		object_copy = @environment.objects.find{|o| o.name == 'Copy of object'}
		#Childrens' starting location should match actor's.
		assert_equal(object_copy.location, @actor.location)
		#Spawned objects should be copy of originals.
		assert_not_same(prototypes[0], creature_copy)
		#Spawned objects' vectors should be same as originals'.
		assert_equal(prototypes[0].vector, creature_copy.vector)
	end
	
	def test_explode_action
		#Set up prototypes.
		prototypes = [Creature.new(:name => 'creature'), GameObject.new(:name => 'object')]
		prototypes[0].vector = Vector.new(1, 45)
		#Add prototypes to new ExplodeAction.
		add_action(ExplodeAction.new(prototypes), @actor)
		#Interact.
		@environment.interact
		#Actor should be removed from environment.
		assert(! @environment.objects.include?(@actor))
		#All children should be spawned.
		assert_equal(3, @environment.object_count)
		creature_copy = @environment.objects.find{|o| o.name == 'Copy of creature'}
		object_copy = @environment.objects.find{|o| o.name == 'Copy of object'}
		#Spawned objects' vectors should be sum of originals' plus actor's.
		assert_equal(prototypes[1].vector + @actor.vector, object_copy.vector)
	end
	
	def test_shoot_action
		#Set up prototypes.
		prototypes = [[Creature.new(:name => 'creature'), GameObject.new(:name => 'object')], Creature.new(:name => '2')]
		prototypes[0][0].vector.pitch = 5
		#Add prototypes to new ShootAction.
		add_action(ShootAction.new(prototypes), @actor)
		#Interact with target.
		@environment.interact
		#Both objects in first group should have been spawned.
		assert_equal(4, @environment.object_count)
		creature_copy = @environment.objects.find{|o| o.name == 'Copy of creature'}
		object_copy = @environment.objects.find{|o| o.name == 'Copy of object'}
		#First spawned object's vector should match angle to target plus prototype's vector angle.
		assert_equal(45 + 5, creature_copy.vector.pitch)
		#Second spawned object's vector should match angle to target.
		assert_equal(45, object_copy.vector.pitch)
		#Fire second set of bullets.
		@environment.interact
		#Only second set should have been spawned.
		assert_equal(5, @environment.object_count)
		creature_2_copy = @environment.objects.find{|o| o.name == 'Copy of 2'}
		assert_not_nil(creature_2_copy)
		#Spawned object should be aimed at target.
		assert_equal(45, creature_2_copy.vector.pitch)
	end
	
end
