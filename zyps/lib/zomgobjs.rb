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
  def initalize(options = {})
    options = {
      :size => 25,
      :location => Location.new(0, 0)
    }.merge(options)
    vector = Vector.new(rand(360), rand(10))
    behaviors = [SplitBehavior.new]
    size = option[:size]
    color = Color.white
  end
end

class Bullet < Creature
  bullet = Creature.new(:color => Color.red)
end

class Ship < Creature
  ship = Creature.new(:color => Color.blue)
end

class SplitBehavior < Behavior
  def initalize
    actions = [ExplodeAction.new([Asteroid.new, Asteroid.new]), DestroyAction.new]
    collisions = [CollisionCondition.new]
  end
end