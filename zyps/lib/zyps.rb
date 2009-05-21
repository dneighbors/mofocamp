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


require 'enumerator'
require 'observer'

module Zyps


#A virtual environment.
class Environment

	include Observable
	
	#A Clock used to track time between updates.
	attr_accessor :clock
	
	#Takes a hash with these keys and defaults:
	#	:objects => [], 
	#	:environmental_factors => []
	#	:clock => Clock.new
	def initialize (options = {})
		options = {
			:objects => [], 
			:environmental_factors => [],
			:clock => Clock.new
		}.merge(options)
		@objects = {}
		@environmental_factors = []
		options[:objects].each {|object| self.add_object(object)}
		options[:environmental_factors].each {|environmental_factor| self.add_environmental_factor(environmental_factor)}
		self.clock = options[:clock]
	end

	
	#Add a GameObject to this environment.
	def add_object(object)
		object.environment = self
		@objects[object.identifier] = object
	end
	#Remove a GameObject from this environment.
	def remove_object(identifier)
		raise "Object #{identifier} not found." unless @objects[identifier]
		@objects[identifier].environment = nil
		@objects.delete(identifier)
	end
	#An Enumerable::Enumerator over each GameObject in the environment.
	def objects; Enumerable::Enumerator.new(@objects, :each_value); end
	#Remove all GameObjects from this environment.
	def clear_objects
		@objects.clone.each_key {|identifier| self.remove_object(identifier)}
	end
	#Number of GameObjects in this environment.
	def object_count; @objects.length; end
	#Retrieve a GameObject by ID.
	def get_object(identifier); @objects[identifier]; end
	#Retrieve a GameObject by ID and modify it.
	def update_object(object); @objects[object.identifier] = object; end
	
	
	#Add an EnvironmentalFactor to this environment.
	def add_environmental_factor(environmental_factor)
		environmental_factor.environment = self
		@environmental_factors << environmental_factor
	end
	#Remove an EnvironmentalFactor from this environment.
	def remove_environmental_factor(environmental_factor)
		environmental_factor.environment = nil
		@environmental_factors.delete(environmental_factor)
	end
	#An Enumerable::Enumerator over each EnvironmentalFactor in the environment.
	def environmental_factors; Enumerable::Enumerator.new(@environmental_factors, :each); end
	#Remove all EnvironmentalFactors from this environment.
	def clear_environmental_factors
		@environmental_factors.clone.each {|environmental_factor| self.remove_environmental_factor(environmental_factor)}
	end
	#Number of EnvironmentalFactors in this environment.
	def environmental_factor_count; @environmental_factors.length; end
	
	
	#Make a deep copy.
	def copy
		copy = self.clone #Currently, we overwrite everything anyway, but we may add some clonable attributes later.
		#Make a deep copy of all objects.
		copy.instance_eval {@objects = {}}
		self.objects.each {|object| copy.add_object(object.copy)}
		#Make a deep copy of all environmental_factors.
		copy.clear_environmental_factors
		self.environmental_factors.each {|environmental_factor| copy.add_environmental_factor(environmental_factor)}
		copy
	end

	
	#Allow everything in the environment to interact with each other.
	#Objects are first moved according to their preexisting vectors and the amount of time since the last call.
	#Then, each GameObject with an act() method is allowed to act on the environment.
	#Finally, each EnvironmentalFactor is allowed to act on the Environment.
	def interact
	
		#Get time since last interaction.
		elapsed_time = @clock.elapsed_time
		
		self.objects.each do |object|
		
			#Move each object according to its vector.
			begin
				object.move(elapsed_time)
			#Remove misbehaving objects.
			rescue Exception => exception
				puts exception, exception.backtrace
				self.remove_object(object)
				next
			end
			
			#Have all creatures interact with the environment.
			if object.respond_to?(:act)
				begin
					#Have creature act on all GameObjects other than itself.
					object.act(objects.reject{|target| target.equal?(object)})
				#Remove misbehaving objects.
				rescue Exception => exception
					puts exception, exception.backtrace
					self.remove_object(object)
					next
				end
			end
			
		end
		
		#Have all environmental factors interact with environment.
		self.environmental_factors.each do |factor|
			begin
				factor.act(self)
			#Remove misbehaving environmental factors.
			rescue Exception => exception
				self.remove_environmental_factor(factor)
				puts exception, exception.backtrace
				next
			end
		end
			
		#Mark environment as changed.
		changed

		#Alert observers.
		notify_observers(self)
		
	end
	
	
	#Overloads the << operator to put the new item into the correct list.
	#This allows one to simply call env << <valid_object> instead of 
	#having to choose a specific list, such as objects or environmental factors.
	def <<(item)
		if(item.kind_of? Zyps::GameObject)
			self.add_object(item)
		elsif(item.kind_of? Zyps::EnvironmentalFactor)
			self.add_environmental_factor(item)
		else
			raise "Invalid item: #{item.class}" 
		end
		self
	end
	
	
	def to_s
		[
			"Environment",
			[
				"\tObjects", objects.map{|o| o.to_s.gsub(/^/, "\t\t")},
				"\tEnvironmental Factors", environmental_factors.map{|o| o.to_s.gsub(/^/, "\t\t")}
			].join("\n")
		].join("\n")
	end
	
	
	#True if clock, all objects, and all environmental factors are the same.
	def ==(other)
		return false if self.objects.to_a != other.objects.to_a
		return false if @environmental_factors != other.environmental_factors.to_a
		return false if self.clock != other.clock
		true
	end
	
	
end



#An object in the virtual environment.
class GameObject

	#A universal identifier for the object.
	#Needed for DRb transmission, etc.
	attr_reader :identifier
	#The Environment this object is part of.
	attr_accessor :environment
	#The object's Location in space.
	attr_accessor :location
	#A Color that will be used to draw the object.
	attr_accessor :color
	#Radius of the object.
	attr_accessor :size
	#A Vector with the object's current speed and direction of travel.
	attr_accessor :vector
	#A String with the object's name.
	attr_accessor :name
	#An array of Strings with tags that determine how the object will be treated by Creature and EnvironmentalFactor objects in its environment.
	attr_accessor :tags
	
	#Takes a hash with these keys and defaults:
	#	:name => nil,
	#	:location => Location.new,
	#	:color => Color.new,
	#	:vector => Vector.new,
	#	:age => 0,
	#	:size => 1,
	#	:tags => []
	def initialize (options = {})
		options = {
			:name => nil,
			:location => Location.new,
			:color => Color.new,
			:vector => Vector.new,
			:age => 0,
			:size => 1,
			:tags => []
		}.merge(options)
		self.name, self.location, self.color, self.vector, self.age, self.size, self.tags = options[:name], options[:location], options[:color], options[:vector], options[:age], options[:size], options[:tags]
		@identifier = generate_identifier
	end
	
	#Make a deep copy.
	def copy
		copy = self.clone
		copy.vector = @vector.copy
		copy.color = @color.copy
		copy.location = @location.copy
		copy.tags = @tags.clone
		copy.identifier = generate_identifier
		copy.name = @name ? "Copy of " + @name.to_s : nil
		copy
	end
	
	#Size must be positive.
	def size=(v); v = 0 if v < 0; @size = v; end
	
	#Move according to vector over the given number of seconds.
	def move (elapsed_time)
		@location.x += @vector.x * elapsed_time
		@location.y += @vector.y * elapsed_time
	end
	
	#Time since the object was created, in seconds.
	def age; Time.new.to_f - @birth_time; end
	def age=(age); @birth_time = Time.new.to_f - age; end
	
	#Set identifier.
	#Not part of API; copy() needs this to make copy's ID unique.
	def identifier=(value) #:nodoc:
		@identifier = value
	end
	
	#Overloads the << operator to put the new item into the correct
	#list or assign it to the correct attribute.
	#Assignment is done based on item's class or a parent class of item.
	def <<(item)
		if item.kind_of? Zyps::Location:
			self.location = item
		elsif item.kind_of? Zyps::Color:
			self.color = item
		elsif item.kind_of? Zyps::Vector:
			self.vector = item
		else
			raise "Invalid item: #{item.class}"
		end
		self
	end
	
	def to_s
		[
			name || sprintf("%07X", identifier),
			location,
			vector
		].join(" ")
	end
	
	#True if identifier is the same.
	def ==(other); self.identifier == other.identifier; end
	
	private
	
		#Make a unique GameObject identifier.
		def generate_identifier
			rand(99999999) #TODO: Current setup won't necessarily be unique.
		end
	
end



#A Creature is a GameObject that can sense and respond to other GameObjects (including other Creature objects).
class Creature < GameObject

	#A list of Behavior objects that determine the creature's response to its environment.
	attr_accessor :behaviors
	
	#Identical to the GameObject constructor, except that it also takes a list of Behavior objects.
	#Takes a hash with these keys and defaults:
	#	:behaviors => []
	def initialize (options = {})
		options = {
			:behaviors => []
		}.merge(options)
		super
		@behaviors = []
		options[:behaviors].each {|behavior| self.add_behavior(behavior)}
	end
	
	#Add a Behavior to this creature.
	def add_behavior(behavior)
		behavior.creature = self
		@behaviors << behavior
	end
	#Remove a Behavior from this creature.
	def remove_behavior(behavior)
		behavior.creature = nil
		@behaviors.delete(behavior)
	end
	#An Enumerable::Enumerator over each Behavior this creature has.
	def behaviors; Enumerable::Enumerator.new(@behaviors, :each); end
	#Remove all Behaviors from this creature.
	def clear_behaviors
		@behaviors.clone.each {|behavior| self.remove_behavior(behavior)}
	end
	#Number of Behaviors this creature has.
	def behavior_count; @behaviors.length; end

	#Make a deep copy.
	def copy
		copy = super
		#Make deep copy of each behavior.
		copy.instance_eval {@behaviors = []}
		self.behaviors.each {|behavior| copy.add_behavior(behavior.copy)}
		copy
	end
	
	#Performs all assigned behaviors on the targets.
	def act(targets)
		behaviors.each {|behavior| behavior.perform(self, targets)}
	end
	
	#See GameObject#<<.
	#Adds ability to stream in behaviors as well.
	def <<(item)
		if item.kind_of? Zyps::Behavior
			self.add_behavior item
		else
			super
		end
		self
	end
	
	def to_s
		[
			super,
			behaviors.map{|b| "\t#{b}"}
		].join("\n")
	end
	
end



#Something in the environment that acts on creatures.
#EnvironmentalFactors must implement an act(target) instance method.
class EnvironmentalFactor
	#Environment this EnvironmentalFactor belongs to.
	attr_accessor :environment
	#Make a deep copy.
	def copy; self.clone; end
	#True if classes are equal.
	#Subclasses should extend this method.
	def ==(other); self.class == other.class; end
end



#An action that one Creature takes on another.
class Action

	#Whether the action was previously started.
	attr_reader :started
	#The Behavior this Action belongs to.
	attr_accessor :behavior
	
	def initialize
		@started = false
	end
	
	#Make a deep copy.
	def copy; self.clone; end
	
	#Start the action.
	#Overriding subclasses must either call "super" or set the @started attribute to true.
	def start(actor, target)
		@started = true
	end
	
	def do(actor, targets)
		raise NotImplementedError.new("Action subclasses must implement a do(actor, target) instance method.")
	end
	
	#Stop the action.
	#Overriding subclasses must either call "super" or set the @started attribute to false.
	def stop(actor, targets)
		@started = false
	end
	
	#Synonym for started
	def started?; started; end
	
	#True if class and started status are the same.
	#Subclasses should extend or override this method.
	def ==(other); self.class == other.class and self.started == other.started; end
	
	#Choose a random target from a group.
  def random_target(targets)
    targets[rand(targets.length)]
  end

end



#A condition for one Creature to act on another.
class Condition

	#The Behavior this Condition belongs to.
	attr_accessor :behavior

	#Make a deep copy.
	def copy; self.clone; end
	
	def select(actor, targets)
		raise NotImplementedError.new("Condition subclasses must implement a select(actor, target) instance method.")
	end
	
	#True if class is the same.
	#Subclasses should extend or override this method.
	def ==(other); self.class == other.class; end
	
end



#A behavior that a Creature engages in.
#The target can have its tags or colors changed, it can be "herded", it can be destroyed, or any other action the library user can dream up.
#Likewise, the subject can change its own attributes, it can approach or flee from the target, it can spawn new Creatures or GameObjects (like bullets), or anything else.
class Behavior

	#An array of Condition subclasses.
	#Condition#select(actor, targets) will be called on each.
	attr_accessor :conditions
	#An array of Action subclasses.
	#Action#start(actor, targets) and action.do(actor, targets) will be called on each when all conditions are true.
	#Action#stop(actor, targets) will be called when any condition is false.
	attr_accessor :actions
	#The Creature this behavior belongs to.
	attr_accessor :creature
	#Number of updates before behavior is allowed to select a new group of targets to act on.
	attr_accessor :condition_frequency
	
	#Will be used to distribute condition processing time between all Behaviors with the same condition_frequency.
	@@condition_order = Hash.new {|h, k| h[k] = 0}
	
	#Takes a hash with these keys and defaults:
	#	:actions => []
	#	:conditions => []
	#	:condition_frequency => 1
	def initialize (options = {})
		options = {
			:actions => [],
			:conditions => [],
			:condition_frequency => 1
		}.merge(options)
		@actions = []
		@conditions = []
		options[:actions].each {|action| self.add_action(action)}
		options[:conditions].each {|condition| self.add_condition(condition)}
		self.condition_frequency = options[:condition_frequency]
		#Tracks number of calls to perform() so conditions can be evaluated with appropriate frequency.
		@condition_evaluation_count = 0
		#Targets currently selected to act upon.
		@current_targets = []
	end

	
	#Add an Action to this behavior.
	def add_action(action)
		action.behavior = self
		@actions << action
	end
	#Remove an Action from this behavior.
	def remove_action(action)
		action.behavior = nil
		@actions.delete(action)
	end
	#An Enumerable::Enumerator over each Action.
	def actions; Enumerable::Enumerator.new(@actions, :each); end
	#Remove all Actions from this behavior.
	def clear_actions
		@actions.clone.each {|action| self.remove_action(action)}
	end
	#Number of Actions.
	def action_count; @actions.length; end
	
	
	#Add a Condition to this behavior.
	def add_condition(condition)
		condition.behavior = self
		@conditions << condition
	end
	#Remove a Condition from this behavior.
	def remove_condition(condition)
		condition.behavior = nil
		@conditions.delete(condition)
	end
	#An Enumerable::Enumerator over each Condition.
	def conditions; Enumerable::Enumerator.new(@conditions, :each); end
	#Remove all Conditions from this behavior.
	def clear_conditions
		@conditions.clone.each {|condition| self.remove_condition(condition)}
	end
	#Number of Conditions.
	def condition_count; @conditions.length; end
	
	
	def condition_frequency= (value)
		#Condition frequency must be 1 or more.
		@condition_frequency = (value >= 1 ? value : 1)
		#This will be used to distribute condition evaluation time among all behaviors with this frequency.
		@condition_order = @@condition_order[@condition_frequency]
		@@condition_order[@condition_frequency] += 1
	end

	
	#Make a deep copy.
	def copy
		copy = self.clone #Currently, we overwrite everything anyway, but we may add some clonable attributes later.
		#Make a deep copy of all actions.
		copy.instance_eval {@actions = []}
		self.actions.each {|action| copy.add_action(action.copy)}
		#Make a deep copy of all conditions.
		copy.instance_eval {@conditions = []}
		self.conditions.each {|condition| copy.add_condition(condition.copy)}
		copy
	end
	
	
	#Finds targets that meet all conditions, then acts on them.
	#Calls select(actor, targets) on each Condition, each time discarding targets that fail.
	#Then on each Action, calls Action#start(actor, targets) (if not already started) followed by Action#do(actor, targets).
	#If no matching targets are found, calls Action#stop(actor, targets) on each Action.
	#If there are no conditions, actions will occur regardless of targets.
	def perform(actor, targets)
		
		if condition_evaluation_turn?
			@current_targets = targets.clone
			conditions.each {|condition| @current_targets = condition.select(actor, @current_targets)}
		end
		actions.each do |action|
			if @current_targets.empty? and ! @conditions.empty?
				action.stop(actor, targets) if action.started? #Not @current_targets; that array is empty.
			else
				action.start(actor, @current_targets) unless action.started?
				action.do(actor, @current_targets)
			end
		end
		
	end

	
	#True if all attributes, actions and conditions are the same.
	def ==(other)
		return false if @actions != other.actions.to_a
		return false if @conditions != other.conditions.to_a
		return false if condition_frequency != other.condition_frequency
		true
	end
	
	
	#Overloads the << operator to put the new item into the correct
	#list or assign it to the correct attribute.
	#Assignment is done based on item's class or a parent class of item.
	def <<(item)
		if item.kind_of? Condition
			add_condition(item)
		elsif item.kind_of? Action
			add_action(item)
		else
			raise "Invalid item: #{item.class}"
		end
		self
	end

	
	def to_s
		[
			(@actions + @conditions).map{|o| o.class}.join(", "),
			"[#{@current_targets.map{|o| o.name || sprintf("%07X", o.identifier)}.join(',')}]"
		].join(" ")
	end
	
	
	private
		
		#Return true if it's our turn to choose targets, false otherwise.
		def condition_evaluation_turn?
			#Every condition_frequency turns (plus our turn order within the group), return true.
			our_turn = ((@condition_evaluation_count + @condition_order) % @condition_frequency == 0) ? true : false
			#Track number of calls to perform() for staggering condition evaluation.
			@condition_evaluation_count += 1
			our_turn
		end
	
end



#An object's color.  Has red, green, and blue components, each ranging from 0 to 1.
#* Red: <tt>Color.new(1, 0, 0)</tt>
#* Green: <tt>Color.new(0, 1, 0)</tt>
#* Blue: <tt>Color.new(0, 0, 1)</tt>
#* White: <tt>Color.new(1, 1, 1)</tt>
#* Black: <tt>Color.new(0, 0, 0)</tt>
class Color

	include Comparable
	
	#Components which range from 0 to 1, which combine to form the Color.
	attr_accessor :red, :green, :blue
	
	def initialize (red = 1, green = 1, blue = 1)
		self.red, self.green, self.blue = red, green, blue
	end
	
	#Make a deep copy.
	def copy; self.clone; end
	
	#Automatically constrains value to the range 0 - 1.
	def red=(v); v = 0 if v < 0; v = 1 if v > 1; @red = v; end
	#Automatically constrains value to the range 0 - 1.
	def green=(v); v = 0 if v < 0; v = 1 if v > 1; @green = v; end
	#Automatically constrains value to the range 0 - 1.
	def blue=(v); v = 0 if v < 0; v = 1 if v > 1; @blue = v; end
	
	#Compares this Color with another to see which is brighter.
	#The sum of all components (red + green + blue) for each color determines which is greater.
	def <=>(other)
		@red + @green + @blue <=> other.red + other.green + other.blue
	end
	
	#Averages each component of this Color with the corresponding component of color2, returning a new Color.
	def +(color2)
		Color.new(
			(self.red + color2.red) / 2.0,
			(self.green + color2.green) / 2.0,
			(self.blue + color2.blue) / 2.0
		)
	end
	
	#Pre-defined color value.
	def self.red; Color.new(1, 0, 0); end
	def self.orange; Color.new(1, 0.63, 0); end
	def self.yellow; Color.new(1, 1, 0); end
	def self.green; Color.new(0, 1, 0); end
	def self.blue; Color.new(0, 0, 1); end
	def self.indigo; Color.new(0.4, 0, 1); end
	def self.violet; Color.new(0.9, 0.5, 0.9); end
	def self.white; Color.new(1, 1, 1); end
	def self.black; Color.new(0, 0, 0); end
	def self.grey; Color.new(0.5, 0.5, 0.5); end

	#True if components are the same.
	def ==(other); self.red == other.red and self.green == other.green and self.blue == other.blue; end
	
	def to_s
		[
			super,
			sprintf("r%0.1fg%0.1fb%0.1f", red, green, blue)
		].join(" ")
	end
		
end



#An object's location, with x and y coordinates.
class Location

	#Coordinates can be negative, and don't have to be integers.
	attr_accessor :x, :y
	def x; @x.to_f; end
	def y; @y.to_f; end
	
	def initialize (x = 0, y = 0)
		self.x, self.y = x, y
	end

	#Make a deep copy.
	def copy; self.clone; end
	
	#True if x and y coordinates are the same.
	def ==(other); self.x == other.x and self.y == other.y; end
	
	def to_s
		sprintf("x%+04.1fy%+04.1f", x, y)
	end
	
end



#An object or force's velocity.
#Has speed and angle components.
class Vector

	#The length of the Vector.
	attr_accessor :speed
	
	def initialize (speed = 0, pitch = 0)
		self.speed = speed
		self.pitch = pitch
	end
	
	#Make a deep copy.
	def copy; self.clone; end
	
	#The angle along the X/Y axes.
	def pitch; Utility.to_degrees(@pitch); end
	def pitch=(degrees)
		#Constrain degrees to 0 to 360.
		value = degrees % 360
		#Store as radians internally.
		@pitch = Utility.to_radians(value)
	end
 	
	#The X component.
	def x; @speed.to_f * Math.cos(@pitch); end
	def x=(value)
		@speed, @pitch = Math.sqrt(value ** 2 + y ** 2), Math.atan(y / value)
	end
	#The Y component.
	def y; @speed.to_f * Math.sin(@pitch); end
	def y=(value)
		@speed, @pitch = Math.sqrt(x ** 2 + value ** 2), Math.atan(value / x)
	end
	
	#Add this Vector to vector2, returning a new Vector.
	#This operation is useful when calculating the effect of wind or thrust on an object's current heading.
	def +(vector2)
		#Get the x and y components of the new vector.
		new_x = (self.x + vector2.x)
		new_y = (self.y + vector2.y)
		new_length_squared = new_x ** 2 + new_y ** 2
		new_length = (new_length_squared == 0 ? 0 : Math.sqrt(new_length_squared))
		new_angle = (new_x == 0 ? 0 : Utility.to_degrees(Math.atan2(new_y, new_x)))
		#Calculate speed and angle of new vector with components.
		Vector.new(new_length, new_angle)
	end
	
	#True if speed and pitch are the same.
	def ==(other); self.speed == other.speed and self.pitch == other.pitch; end
	
	def to_s
		sprintf("s%+04.1fp%+04.1f", speed, pitch)
	end
	
end



#A clock to use for timing actions.
class Clock

	#Speed at which this clock operates.
	#Multiplied by global clock speed.
	attr_accessor :speed

	def initialize(speed = 1.0)
		@speed = speed
		reset_elapsed_time
	end
	
	#Make a deep copy, resetting elapsed_time.
	def copy
		copy = self.clone
		copy.reset_elapsed_time
		copy
	end
	
	#Returns the time in (fractional) seconds since this method was last called (or on the first call, time since the Clock was created).
	def elapsed_time
		time = Time.new.to_f
		elapsed_time = time - @last_check_time
		@last_check_time = time
		elapsed_time * @@speed * @speed
	end
	
	def reset_elapsed_time
		@last_check_time = Time.new.to_f
	end
	
	#Speed at which all Clocks are operating.
	@@speed = 1.0
	def Clock.speed; @@speed; end
	#Set speed at which all Clocks will operate.
	#1 is real-time, 2 is double speed, 0 is paused.
	def Clock.speed=(value); @@speed = value; end

	#True if instance speed is equal.
	def ==(other); self.speed == other.speed; end

end



#Various methods for working with Vectors, etc.
module Utility
	
	PI2 = Math::PI * 2.0 #:nodoc:
	
	#Empty cached return values.
	def Utility.clear_caches
		@@angles = Hash.new {|h, k| h[k] = {}}
		@@distances = Hash.new {|h, k| h[k] = {}}
	end
	
	#Initialize caches for return values.
	Utility.clear_caches
	
	#Turn caching of return values on or off.
	@@caching_enabled = false
	def Utility.caching_enabled= (value)
		@@caching_enabled = value
		Utility.clear_caches if ! @@caching_enabled
	end
	
	#Get the angle (in degrees) from one Location to another.
	def Utility.find_angle(origin, target)
		if @@caching_enabled
			#Return cached angle if there is one.
			return @@angles[origin][target] if @@angles[origin][target]
			return @@angles[target][origin] if @@angles[target][origin]
		end
		#Get vector from origin to target.
		x_difference = target.x - origin.x
		y_difference = target.y - origin.y
		#Get vector's angle.
		radians = Math.atan2(y_difference, x_difference)
		#Result will range from negative Pi to Pi, so correct it.
		radians += PI2 if radians < 0
		#Convert to degrees.
		angle = to_degrees(radians)
		#Cache angle if caching enabled.
		if @@caching_enabled
			@@angles[origin][target] = angle
			#angle + 180 = angle from target to origin.
			@@angles[target][origin] = (angle + 180 % 360)
		end
		#Return result.
		angle
	end
	
	#Get the distance from one Location to another.
	def Utility.find_distance(origin, target)
		if @@caching_enabled
			#Return cached distance if there is one.
			return @@distances[origin][target] if @@distances[origin][target]
		end
		#Get vector from origin to target.
		x_difference = origin.x - target.x
		y_difference = origin.y - target.y
		#Get distance.
		distance = Math.sqrt(x_difference ** 2 + y_difference ** 2)
		#Cache distance if caching enabled.
		if @@caching_enabled
			#Origin to target distance = target to origin distance.
			#Cache such that either will be found.
			@@distances[origin][target] = distance
			@@distances[target][origin] = distance
		end
		#Return result.
		distance
	end
	
	#Convert radians to degrees.
	def Utility.to_degrees(radians)
		radians / PI2 * 360
	end
	
	#Convert degrees to radians.
	def Utility.to_radians(degrees)
		radians = degrees / 360.0 * PI2
		radians = radians % PI2
		radians += PI2 if radians < 0
		radians
	end
	
	#Reduce a number to within an allowed maximum (or minimum, if the number is negative).
	def Utility.constrain_value(value, absolute_maximum)
		if (value.abs > absolute_maximum) then
			if value >= 0 then
				value = absolute_maximum
			else
				value = absolute_maximum * -1
			end
		end
		value
	end
	
	#Given a normal and an angle, find the reflection angle.
	def Utility.find_reflection_angle(normal, angle)
		incidence_angle = normal - angle
		reflection_angle = normal + incidence_angle
		reflection_angle %= 360
		reflection_angle
	end

	#Given two GameObjects, determine if the boundary of one crosses the boundary of the other.
	def Utility.collided?(object1, object2)
		object1_radius = Math.sqrt(object1.size / Math::PI)
		object2_radius = Math.sqrt(object2.size / Math::PI)
		return true if find_distance(object1.location, object2.location) < object1_radius + object2_radius
		false
	end
	
end


#Tests whether a Location is within its boundaries.
class AreaOfInterest
end


end #module Zyps
