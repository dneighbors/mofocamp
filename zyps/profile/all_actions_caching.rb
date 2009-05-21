require 'logger'
require 'rubygems'
require 'ruby-prof'
require 'zyps'
require 'zyps/actions'
require 'zyps/conditions'
require 'zyps/environmental_factors'

include Zyps


LOOP_COUNT = 500


def main
	environment = Environment.new
	environment << Enclosure.new(
		:left => 0,
		:bottom => 0,
		:top => 600,
		:right => 400
	)
	environment << SpeedLimit.new(100)
	environment << PopulationLimit.new(50)
	generator = CreatureGenerator.new(:environment => environment)
	prototype_creature = generator.create_creature(
		:turn => true,
		:approach => true,
		:flee => true,
		:push => true,
		:pull => true,
		:breed => true,
		:eat => true
	)
	populate(environment, prototype_creature)
	Utility.caching_enabled = true
	LOOP_COUNT.times do
		environment.interact
		Utility.clear_caches
		GC.start
	end
end

def populate(environment, creature, count = 50)
	count.times do |i|
		copy = creature.copy
		copy.location = Location.new(i, i)
		copy.vector = Vector.new(i, i)
		environment << creature
	end
end


#Creates Creature objects.
class CreatureGenerator


	#Environment creatures will be placed in.
	attr_accessor :environment
	#Default size of new creatures.
	attr_accessor :default_size
	#Default required proximity for actions.
	attr_accessor :default_proximity
	#Rate of new TurnActions.
	attr_accessor :turn_rate
	#Acceleration rate of new ApproachActions.
	attr_accessor :approach_rate
	#Acceleration rate of new FleeActions.
	attr_accessor :flee_rate
	#Strength of new PullActions.
	attr_accessor :pull_strength
	#Strength of new PushActions.
	attr_accessor :push_strength

	
	#Takes a hash with these keys and defaults:
	#	:default_size => 5
	#	:default_proximity => 200
	#	:approach_rate => 200
	#	:flee_rate => :approach_rate
	#	:push_strength => :approach_rate * 2
	#	:pull_strength => :push_strength * 0.75
	#	:turn_rate => :approach_rate * 1.1
	#	:turn_angle => 90
	#	:breed_rate => 10
	def initialize(options = {})
	
		options = {
			:default_size => 5,
			:default_proximity => 200,
			:approach_rate => 200,
			:turn_angle => 90,
			:breed_rate => 10,
		}.merge(options)
		
		@default_size = options[:default_size]
		@default_proximity = options[:default_proximity]
		@approach_rate = options[:approach_rate]
		@turn_angle = options[:turn_angle]
		@breed_rate = options[:breed_rate]
		@flee_rate = options[:flee_rate] || @approach_rate * 2
		@push_strength = options [:push_strength] || @approach_rate * 2
		@pull_strength = options[:pull_strength] || @push_strength * 0.75
		@turn_rate = options[:turn_rate] || @approach_rate * 1.1
		
	end
	
	
	#Create a creature with the given attributes and behaviors.
	#Takes a hash with these keys and defaults:
	#	:x => 0,
	#	:y => 0,
	#	:speed => 1,
	#	:pitch => 0,
	#	:size => @default_size,
	#	:action_proximity => @default_proximity,
	#	:turn => false,
	#	:approach => false,
	#	:flee => false,
	#	:push => false,
	#	:pull => false,
	#	:breed => false,
	#	:eat => false,
	def create_creature(options = {})
	
		options = {
			:x => 0,
			:y => 0,
			:speed => 1,
			:pitch => 0,
			:size => @default_size,
			:action_proximity => @default_proximity,
			:turn => false,
			:approach => false,
			:flee => false,
			:push => false,
			:pull => false,
			:breed => false,
			:eat => false,
		}.merge(options)
		
		#Create a creature.
		creature = Creature.new(
			:location => Location.new(options[:x], options[:y]),
			:vector => Vector.new(options[:speed], options[:pitch]),
			:size => options[:size]
		)
		
		#Set up actions and merge colors according to selected behaviors.
		color = Color.new(0.5, 0.5, 0.5)
		if options[:turn]
			color.blue += 1
			creature << Behavior.new(
				:actions => [TurnAction.new(@turn_rate, @turn_angle)],
				:conditions => [ProximityCondition.new(options[:action_proximity] * 2)]
			)
		end
		if options[:approach]
			color.red += 1
			creature << Behavior.new(
				:actions => [ApproachAction.new(@approach_rate)],
				:conditions => [ProximityCondition.new(options[:action_proximity])]
			)
		end
		if options[:flee]
			color.red += 0.5; color.green += 0.5 #Yellow.
			creature << Behavior.new(
				:actions => [FleeAction.new(@flee_rate)],
				:conditions => [ProximityCondition.new(options[:action_proximity] * 0.5)]
			)
		end
		if options[:push]
			color.red += 0.5; color.blue += 0.5 #Purple.
			creature << Behavior.new(
				:actions => [PushAction.new(@push_strength)],
				:conditions => [ProximityCondition.new(options[:action_proximity] * 0.25)]
			)
		end
		if options[:pull]
			color.blue += 0.75; color.green += 0.75 #Aqua.
			creature << Behavior.new(
				:actions => [PullAction.new(@pull_strength)],
				:conditions => [ProximityCondition.new(options[:action_proximity] * 0.75)]
			)
		end
		if options[:breed]
			color.green -= 0.1 #Make a bit redder.
			color.blue -= 0.1
			creature << Behavior.new(
				:actions => [BreedAction.new],
				:conditions => [
					CollisionCondition.new, #The default ProximityCondition won't do.
					InactiveLongerThanCondition.new(@breed_rate) #Avoids instant population explosion.
				]
			)
		end
		if options[:eat]
			color.green += 1
			creature << Behavior.new(
				:actions => [EatAction.new],
				:conditions => [
					CollisionCondition.new, #The default ProximityCondition won't do.
					StrengthCondition.new #The eater should be as strong or stronger than its dinner.
				] 
			)
		end
		
		creature.color = color
		
		creature
		
	end
	
	
end


main