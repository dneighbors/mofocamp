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


describe Accelerator do

	before(:each) do
		@environment = Environment.new
		@creature = Creature.new
		@accelerator = Accelerator.new
		@environment << @creature << @accelerator
		@accelerator.clock.stub!(:elapsed_time).and_return(0.1)
	end

	it "should alter target's Vector" do
		@creature.vector = Vector.new(0, 0)
		@accelerator.vector = Vector.new(1, 270)
		@accelerator.act(@environment)
		@creature.vector.speed.should == 0.1
		@creature.vector.pitch.should == 270
	end
	
	it "should slow target if it's moving in opposite direction" do
		@creature.vector = Vector.new(1, 90)
		@accelerator.vector = Vector.new(1, 270)
		@accelerator.act(@environment)
		@creature.vector.speed.should == 0.9
		@creature.vector.pitch.should == 90
	end

end


describe Friction do

	before(:each) do
		@environment = Environment.new
		@creature = Creature.new
		@friction = Friction.new
		@environment << @creature << @friction
		@friction.clock.stub!(:elapsed_time).and_return(0.1)
	end

	it "should slow target" do
		@creature.vector = Vector.new(1, 90)
		@friction.force = 1
		@friction.act(@environment)
		@creature.vector.speed.should == 0.9
		@creature.vector.pitch.should == 90
	end

	it "should have a cumulative effect" do
		@creature.vector = Vector.new(1, 90)
		@friction.force = 1
		@friction.act(@environment)
		@creature.vector.speed.should == 0.9
		@friction.act(@environment)
		@creature.vector.speed.should == 0.8
	end
	
	it "should not reverse Vector of target" do
		@creature.vector = Vector.new(0, 0)
		@friction.force = 1
		@friction.act(@environment)
		@creature.vector.speed.should == 0
		@creature.vector.pitch.should == 0
	end

end