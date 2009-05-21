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
	require 'zyps/actions'
	require 'zyps/conditions'
	require 'zyps/environmental_factors'
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


describe Environment do

	before(:each) do
		@environment = Environment.new
	end
	
	it "should accept GameObjects" do
		@environment << GameObject.new << GameObject.new
		@environment.object_count.should equal(2) #Can't use have(); doesn't return array.
	end
	
	it "should accept Creatures" do
		@environment << Creature.new << Creature.new
		@environment.object_count.should equal(2) #Can't use have(); doesn't return array.
	end
	
	it "should accept EnvironmentalFactors" do
		@environment << Gravity.new << Gravity.new
		@environment.environmental_factor_count.should == 2 #Can't use have(); doesn't return array.
	end
	

	it "should allow copies" do
		copy = @environment.copy
		copy.should == @environment
	end

	it "should copy GameObjects when copying self" do
		@environment << GameObject.new << GameObject.new
		@environment.objects.each do |object|
			@environment.copy.object_count.should == 2 #Equal...
			@environment.copy.objects.should_not satisfy {|objects| objects.any?{|o| o.equal?(object)}} #...but not identical.
		end
	end
	
	it "should move all objects on update" do
		object = GameObject.new(:vector => Vector.new(1, 0))
		@environment << object
		clock = Clock.new
		clock.should_receive(:elapsed_time).and_return(1)
		@environment.clock = clock
		@environment.interact
		object.location.should == Location.new(1, 0)
	end
	
	it "should have all objects act on each other" do
		creature_1 = Creature.new
		creature_2 = Creature.new
		@environment << creature_1 << creature_2
		creature_1.should_receive(:act).with([creature_2])
		creature_1.should_not_receive(:act).with([creature_1])
		creature_2.should_receive(:act).with([creature_1])
		creature_2.should_not_receive(:act).with([creature_2])
		@environment.interact
	end
	
	it "should have all EnvironmentalFactors act on environment" do
		gravity_1 = Gravity.new
		gravity_2 = Gravity.new
		@environment << gravity_1 << gravity_2
		gravity_1.should_receive(:act).with(@environment)
		gravity_2.should_receive(:act).with(@environment)
		@environment.interact
	end
	
	it "should remove objects that throw exceptions on update"
	
	it "should have no area of interest by default"
	
	it "should update all game objects if no area of interest is defined"
	
	it "should not move an object outside its area of interest"
	it "should move an object inside its area of interest"
	it "should not have other objects act on an object outside its area of interest"
	it "should have other objects act on an object inside its area of interest"
	it "should not have environmental factors act on an object outside its area of interest"
	it "should have environmental factors act on an object inside its area of interest"
	it "should not allow an object outside its area of interest to act on others"
	it "should allow an object inside its area of interest to act on others"
	
	it "should update multiple areas of interest"
	
end


describe Behavior do

	before(:each) do
		@behavior = Behavior.new
		@condition = TagCondition.new("foo")
		@action = TagAction.new("bar")
		@behavior << @action << @condition
		@actor = Creature.new
		@target = Creature.new
	end

	it "should start and perform all Actions when all Conditions are true" do
		@action.should_receive(:start).with(@actor, [@target])
		@action.should_receive(:do).with(@actor, [@target])
		@target.tags << "foo"
		@behavior.perform(@actor, [@target])
	end
	
	it "should not call Actions unless all Conditions are true" do
		@action.should_not_receive(:start)
		@action.should_not_receive(:do)
		@behavior.perform(@actor, [@target])
	end
	
	it "should not start Actions that are already started" do
		@target.tags << "foo"
		@behavior.perform(@actor, [@target])
		@action.should_not_receive(:start)
		@action.should_receive(:do)
		@behavior.perform(@actor, [@target])
	end
	
	it "should not stop Actions that aren't started" do
		@action.should_not_receive(:start)
		@action.should_not_receive(:do)
		@action.should_not_receive(:stop)
		@behavior.perform(@actor, [@target])
	end
	
	it "should call all Actions when there are no Conditions" do
		@behavior.remove_condition(@condition)
		@action.should_receive(:start).with(@actor, [@target])
		@action.should_receive(:do).with(@actor, [@target])
		@behavior.perform(@actor, [@target])
	end

end


describe GameObject do

	before(:each) do
		@object = GameObject.new
	end
	
	it "should use size of zero when assigned size of less than zero" do
		@object.size = -1
		@object.size.should == 0
	end
	
	it "should copy Vector when copying self" do
		@object.copy.vector.should_not equal(@object.vector)
	end
	it "should share Vector attributes with copy" do
		@object.vector = Vector.new(1, 1)
		@object.copy.vector.x.should == @object.vector.x
		@object.copy.vector.y.should == @object.vector.y
	end
	it "should copy Location when copying self" do
		@object.copy.location.should_not equal(@object.location)
	end
	it "should share Location attributes with copy" do
		@object.location = Location.new(1, 1)
		@object.copy.location.x.should == @object.location.x
		@object.copy.location.y.should == @object.location.y
	end
	it "should copy Color when copying self" do
		@object.copy.color.should_not equal(@object.color)
	end
	it "should share Color attributes with copy" do
		@object.color = Color.new(1, 1, 1)
		@object.copy.color.red.should == @object.color.red
		@object.copy.color.green.should == @object.color.green
		@object.copy.color.blue.should == @object.color.blue
	end
	it "should copy Tags when copying self" do
		@object.copy.tags.should_not equal(@object.tags)
	end
	it "should share Tags attributes with copy" do
		@object.tags = ["1", "2"]
		@object.copy.tags[0].should == @object.tags[0]
		@object.copy.tags[1].should == @object.tags[1]
	end
	
	it "has a default Location of 0, 0" do
		@object.location.should == Location.new(0, 0)
	end
	it "has a default Color of white" do
		@object.color.should == Color.white
	end
	it "has a default speed of 0" do
		@object.vector.speed.should == 0
	end
	it "has a default pitch of 0" do
		@object.vector.pitch.should == 0
	end
	it "has a default name of nil" do
		@object.name.should == nil
	end
	it "has a default size of 1" do
		@object.size.should == 1
	end
	it "has no tags by default" do
		@object.tags.should be_empty
	end
	it "has a unique identifier by default" do
		@object.identifier.should_not == GameObject.new.identifier
	end
	
	it "has no default shape"
	
	it "should pass calls to collided method on to its Shape object"

end


#Tests for constructor.
describe GameObject do
	it "takes a :name key in its constructor" do
		GameObject.new(:name => "foo").name.should == "foo"
	end
	it "takes a :location key in its constructor" do
		GameObject.new(:location => Location.new(1, 1)).location.should == Location.new(1, 1)
	end
	it "takes a :color key in its constructor" do
		GameObject.new(:color => Color.blue).color.should == Color.blue
	end
	it "takes an :age key in its constructor" do
    GameObject.new(:age => 100).age.should be_close(100, 0.1)
	end
	it "takes a :size key in its constructor" do
		GameObject.new(:size => 3).size.should == 3
	end
	it "takes a :tags key in its constructor" do
		GameObject.new(:tags => ["blue team"]).tags.should == ["blue team"]
	end
end


describe Creature do
	
	before(:each) do
		@creature = Creature.new
	end
	
	it "has no behaviors by default" do
		@creature.behavior_count.should == 0
	end
	
	it "should copy Behaviors when copying self" do
		@creature << Behavior.new << Behavior.new
		@creature.behaviors.each do |behavior|
			@creature.copy.behaviors.should include(behavior) #Equal...
			@creature.copy.behaviors.should_not satisfy {|behaviors| behaviors.any?{|b| b.equal?(behavior)}} #...but not identical.
		end
	end
	
	it "should have no area of interest by default"
	it "should act on all objects if no area of interest is defined"
	it "should not act on an object outside its area of interest"
	it "should act on all objects inside its area of interest"
	it "should allow multiple areas of interest"
	
end


#Tests for constructor.
describe Creature do
	it "takes a :behaviors key in its constructor" do
		Creature.new(:behaviors => [Behavior.new]).behaviors.should include(Behavior.new)
	end
end


describe Behavior do

	before(:each) do
		@behavior = Behavior.new
	end
	
	it "should copy Actions when copying self" do
		@behavior << TagAction.new << TagAction.new
		@behavior.actions.each do |action|
			@behavior.copy.actions.should include(action) #Equal...
			@behavior.copy.actions.should_not satisfy {|actions| actions.any?{|a| a.equal?(action)}} #...but not identical.
		end
	end
	
end


describe AreaOfInterest do

	it "should report all GameObjects whose Locations are within its bounds"
	it "should filter out all GameObjects whose Locations are not within its bounds"
	it "should have a default evaluation frequency of 1"
	it "should always report objects if its evaluation frequency is 1"
	it "should report objects every other update if its evaluation frequency is 2"
	it "should report objects every three updates if its evaluation frequency is 3"

end
