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
	require 'spec/story'
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

load File.join(File.dirname(__FILE__), 'steps', 'all.rb')

include Zyps

steps_for(:actions) do
end

with_steps_for :actions, :all do
	run File.expand_path(__FILE__).sub(/.rb$/, ".txt")
end
