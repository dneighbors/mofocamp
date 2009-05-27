$: << (File.dirname(__FILE__) + '/../lib')

gems_loaded = false
begin
	require 'logger'
	require 'wx'
	require 'yaml'
	require 'zyps'
	require 'zyps/actions'
	require 'zyps/conditions'
	require 'zyps/environmental_factors'
	require 'zyps/remote'
	require 'zyps/serializer'
	require 'zyps/views/trails'
	require 'zyps/views/canvas/wx'
	require 'zomgobjs'
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


LOG_HANDLE = STDOUT
LOG_LEVEL = Logger::DEBUG


class Asteroid < Creature
  def initialize(options = {})
    super({
      :size => 500,
      :vector => Vector.new(rand(10), rand(360)),
      :color => Color.green
    }.merge(options))
  end
end

class BigAsteroid < Asteroid
  def initialize(options = {})
    super({:size => 500}.merge(options))
    add_behavior(SplitBehavior.new(:prototypes => [MediumAsteroid.new, MediumAsteroid.new]))
  end
end
class MediumAsteroid < Asteroid
  def initialize(options = {})
    super({:size => 250}.merge(options))
    add_behavior(SplitBehavior.new(:prototypes => [SmallAsteroid.new, SmallAsteroid.new]))
  end
end
class SmallAsteroid < Asteroid
  def initialize(options = {})
    super({:size => 100}.merge(options))
  end
end

class Bullet < Creature
  def initialize(options = {})
    super({
      :behaviors => [BulletBehavior.new],
      :color => Color.red,
      :vector => Vector.new(100, 0)
    }.merge(options))
  end
end

class Ship < Creature
  def initialize(options = {})
    super({
      :color => Color.blue
    }.merge(options))
  end
end

class SplitBehavior < Behavior
  def initialize(options = {})
    super({
      :conditions => [CollisionCondition.new, ClassCondition.new(Bullet)]
    }.merge(options))
    prototypes = options[:prototypes]
  end
  def prototypes=(objects)
    self.actions = [ExplodeAction.new(objects)]
  end
end

class BulletBehavior < Behavior
  def initialize(options = {})
    super({
      :actions => [DestroyAction.new],
      :conditions => [CollisionCondition.new, ClassCondition.new(Asteroid)]
    }.merge(options))
  end
end

class FireAction < SpawnAction
	attr_accessor :prototypes
	def initialize(*arguments)
		super
		@prototype_index = 0
	end
	#Copies next prototype into environment.
	def do(actor, targets)
		targets.first.environment.add_object(generate_child(actor, prototypes[@prototype_index]))
	end
	#Calls super method.
	#Also makes child angle match parent angle.
	def generate_child(actor, prototype)
		child = super(actor, prototype)
		child.vector.pitch = actor.vector.pitch
		child
	end
end
