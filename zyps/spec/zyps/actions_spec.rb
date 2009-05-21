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


shared_examples_for "spawn action" do

	before :each do
		@environment = Environment.new
		@actor = Creature.new
		@target = GameObject.new
		@environment << @actor << @target
	end

	it "spawns prototype object into target's environment" do
		@action.prototypes = [GameObject.new(:name => 'foo')]
		@action.do(@actor, [@target])
		@target.environment.should satisfy {|e| e.objects.any?{|o| o.name == 'Copy of foo'}}
	end
	
	it "can spawn groups of objects at a time" do
		@action.prototypes = [[GameObject.new(:name => 'foo'), GameObject.new(:name => 'bar')]]
		@action.do(@actor, [@target])
		@target.environment.should satisfy {|e| e.objects.any?{|o| o.name == 'Copy of foo'}}
		@target.environment.should satisfy {|e| e.objects.any?{|o| o.name == 'Copy of bar'}}
	end
	
	it "spawns one group at a time" do
	end
	
end


describe ShootAction do

	before :each do
		@action = ShootAction.new
	end

	it_should_behave_like "spawn action"

end