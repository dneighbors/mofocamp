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
    vector = Vector.new(rand(10), rand(360))
    behaviors = [SplitBehavior.new]
    size = option[:size]
    color = Color.white
  end
end

class Bullet < Creature
  def initalize(options = {})
    options = {
      :location => Location.new(0, 0),
      :vector => Vector.new(100, rand(360))
    }.merge(options)
    behaviors = [BulletBehavior.new]
    color = Color.red
  end
end

class Ship < Creature
  def initalize
    ship = Creature.new(:color => Color.blue)
  end
end

class SplitBehavior < Behavior
  def initalize
    actions = [ExplodeAction.new([Asteroid.new, Asteroid.new]), DestroyAction.new]
    collisions = [CollisionCondition.new, ClassCondition.new(Bullet)]
  end
end

class BulletBehavior < Behavior
  def initalize
    actions = [DestroyAction.new]
    collisions = [CollisionCondition.new, ClassCondition.new(Asteroid)]
  end
end