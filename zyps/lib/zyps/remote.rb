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


require 'logger'
require 'socket'
require 'zyps'
require 'zyps/serializer'


LOG_HANDLE = STDOUT
LOG_LEVEL = Logger::DEBUG


module Zyps


#Holds requests from a remote system.
module Request
	#Descendents of this class should be re-sent until acknowledged.
	class GuaranteedRequest
		attr_accessor :guarantee_id
		def initialize(*args); @guarantee_id = rand(99999999); end
		def ==(other); self.guarantee_id == other.guarantee_id rescue false; end
	end
	#A request to observe an Environment.
	class Join < GuaranteedRequest
		#The port the host will be listening on.
		attr_accessor :listen_port
		def initialize(listen_port = nil); @listen_port = listen_port; end
	end
	#A request to update the object IDs already in the host's Environment.
	class SetObjectIDs
		#A list of GameObject identifiers.
		attr_accessor :ids
		def initialize(ids = nil); @ids = ids; end
	end
	#A request to update the locations and vectors of specified objects.
	class UpdateObjectMovement
		#A hash with GameObject identifiers as keys and arrays with x coordinate, y coordinate, speed, and pitch as values.
		attr_accessor :movement_data
		def initialize(movement_data = {}); @movement_data = movement_data; end
		def ==(other); self.movement_data == other.movement_data rescue false; end
		def to_s; [self.class, self.movement_data.inspect].join(' '); end
	end
	#A request for all objects and environmental factors within an Environment.
	class Environment < GuaranteedRequest; end
	#A request to add a specified object to an Environment.
	class AddObject < GuaranteedRequest
		#The object to add.
		attr_accessor :object
		def initialize(object = nil); super; @object = object; end
		def to_s; [self.class, self.guarantee_id, self.object].join(' '); end
	end
	#A request for a complete copy of a specified GameObject.
	class GetObject < GuaranteedRequest
		#Identifier of the object being requested.
		attr_accessor :identifier
		def initialize(identifier = nil); super; @identifier = identifier; end
	end
	#A request to update all attributes of a specified GameObject.
	class ModifyObject < GuaranteedRequest
		#The object to update.
		attr_accessor :object
		def initialize(object = nil); super; @object = object; end
	end
	#A request to remove a specified GameObject.
	class RemoveObject < GuaranteedRequest
		#Identifier of the object being removed.
		attr_accessor :identifier
		def initialize(identifier = nil); super; @identifier = identifier; end
	end
end
#Holds acknowledgements of requests from a remote system.
module Response
	#When a descendent of this class is received, re-sending of the corresponding request should be halted.
	class GuaranteedResponse
		attr_accessor :response_id
		def ==(other); self.response_id == other.response_id rescue false; end
	end
	class Join < GuaranteedResponse; end
	class Environment < GuaranteedResponse
		attr_accessor :objects, :environmental_factors
		def initialize(objects = [], environmental_factors = []); @objects, @environmental_factors = objects, environmental_factors; end
		def ==(other); self.objects == other.objects and self.environmental_factors == other.environmental_factors rescue false; end
	end
	class AddObject < GuaranteedResponse
		#Identifier of the object that was added.
		attr_accessor :identifier
		def initialize(identifier = nil); @identifier = identifier; end
	end
	class GetObject < GuaranteedResponse
		#The requested object.
		attr_accessor :object
		def initialize(object = nil); @object = object; end
		def ==(other); self.object == other.object rescue false; end
	end
	class ModifyObject < GuaranteedResponse; end
	class RemoveObject < GuaranteedResponse
		#Identifier of the object that was removed.
		attr_accessor :identifier
		def initialize(identifier = nil); @identifier = identifier; end
	end
end
class RemoteException < Exception
	attr_accessor :response_id
	attr_accessor :cause
end
class BannedError < Exception; end
class ObjectNotFoundError < Exception
	attr_accessor :identifier
	def initialize(identifier); @identifier = identifier; end
	def ==(other); self.identifier == other.identifier rescue false; end
end
class DuplicateObjectError < Exception
	attr_accessor :identifier
	def initialize(identifier); @identifier = identifier; end
	def ==(other); self.identifier == other.identifier rescue false; end
end


class EnvironmentTransmitter

	
	#A list with the IPs of banned hosts.
	attr_accessor :banned_hosts
	#A hash with the IPs of allowed hosts as keys, and their listen ports as values.
	attr_accessor :allowed_hosts
	#A hash with the host IPs as keys, and lists of objects known to be in their environments as values.
	attr_accessor :known_objects
	#The port number to listen for transmissions on.
	attr_accessor :listen_port
	#The environment to maintain.
	attr_accessor :environment

	#Takes the environment to serve.
	def initialize(environment)
		@log = Logger.new(LOG_HANDLE)
		@log.level = LOG_LEVEL
		@log.progname = self
		@environment = environment
		@banned_hosts = []
		@allowed_hosts = {}
		@known_objects = Hash.new {|h, k| h[k] = []}
		@unanswered_requests = Hash.new {|h, k| h[k] = {}}
		@queued_transmissions = Hash.new {|h, k| h[k] = []}
	end
	
	#The maximum allowed transmission size.
	MAX_PACKET_SIZE = 65535

	
	#Binds the given port.
	def open_socket
		@log.debug "Binding port #{@options[:listen_port]}."
		@socket = UDPSocket.open
		@socket.bind(nil, @options[:listen_port])
	end
	
	
	#Listen for an incoming packet, and process it.
	def listen
		@log.debug "Waiting for packet on port #{@socket.addr[1]}."
		data, sender_info = @socket.recvfrom(MAX_PACKET_SIZE)
		@log.debug "Got #{data} from #{sender_info.join('/')}."
		receive(data, sender_info[3])
	end
	
	
	#Closes connection port.
	def close_socket
		@log.debug "Closing @{socket}."
		@socket.close
	end

	
	#True if host is on allowed list.
	def allowed?(host)
		raise BannedError.new if banned?(host)
		allowed_hosts.include?(host)
	end
	#Add host and port to allowed list.
	def allow(host, port)
		allowed_hosts[host] = port
	end
	#Get listen port for host.
	def port(host)
		allowed_hosts[host]
	end
	
	
	#True if address is on banned list.
	def banned?(host)
		banned_hosts.include?(host)
	end
	#Add host to banned list.
	def ban(host)
		ip_address = (host =~ /^[\d\.]+$/ ? host : IPSocket.getaddress(host))
		banned_hosts << ip_address
	end
	
	
	#Compare environment state to previous state and send updates to listeners.
	def update
	
		movement_data = {}
	
		#For each area of interest for the environment:
		areas_of_interest.each do |area|

			#If it is not this area's turn to be evaluated, skip to the next.
			next unless evaluation_turn?(area)
			
			#For each object in the area:
			objects(area).each do |object|
				@log.debug "Processing #{object}."
				#If transmitter has movement authority over object:
				if movable?(object)
					@log.debug "Adding to movement update."
					#Get its location and vector for inclusion in movement update.
					movement_data[object.identifier] = [
						object.location.x,
						object.location.y,
						object.vector.speed,
						object.vector.pitch
					]
				end
			end
			
		end
		
		#Objects that have been removed since previous update should be removed from remote environments.
		object_ids = environment.objects.map{|o| o.identifier}
		objects_to_remove = []
		if defined?(@prior_update_object_ids)
			objects_to_remove = (@prior_update_object_ids - object_ids)
			@log.debug "Objects missing since prior update: #{objects_to_remove}"
			objects_to_remove = objects_to_remove.find_all{|o| destructible?(o)}
		end
		
		#For each host:
		allowed_hosts.keys.each do |host|
			#Update objects.
			@log.debug "Excluding #{known_objects[host]} from transmission to #{host}."
			objects_to_send = environment.objects.reject{|o| known_objects[host].include?(o.identifier)}
			objects_to_send.each {|object| queue(Request::AddObject.new(object), host)}
			@log.debug "Objects to remove from remote environments: #{objects_to_remove}"
			objects_to_remove.each {|id| queue(Request::RemoveObject.new(id), host)}
			#Queue movement data.
			#This should be done AFTER adding objects so reference objects exist in target environment.
			queue(Request::UpdateObjectMovement.new(movement_data), host)
			#Send queued data.
			flush_queue(host)
		end
		
		#Note object IDs so we can see if any are missing next update.
		@prior_update_object_ids = object_ids
		
	end
	
	
	#Re-send requests for which no response has been received.
	def resend_requests
		@log.debug "Unanswered requests: #{@unanswered_requests}"
		@unanswered_requests.each do |host, transmissions|
			transmissions.values.each {|transmission| queue(transmission, host)}
			flush_queue(host)
		end
	end
		
	
	#Sends data.
	def send(data, host)
		#If data needs guaranteed delivery, save it for re-sending if no response received.
		@unanswered_requests[host][data.guarantee_id] = data if data.respond_to?(:guarantee_id)
		#Convert data to string.
		string = Serializer.instance.serialize(data.respond_to?(:each) ? data : [data])
		raise "#{string.length} is over maximum packet size of #{MAX_PACKET_SIZE}." if string.length > MAX_PACKET_SIZE
		#Send string to host.
		@log.debug "Sending '#{string}' to #{host} on #{port(host)}."
		UDPSocket.open.send(string, 0, host, port(host))
	end
	
	
	#Queues data for later sending.
	def queue(data, host)
		@log.debug "Queueing #{data} for sending to #{host}."
		@queued_transmissions[host] << data
	end
	
	#Sends all queued transmissions for host and removes them from queue.
	def flush_queue(host)
		transmissions = @queued_transmissions.delete(host) or return
		transmissions.each do |data|
			#If data needs guaranteed delivery, save it for re-sending if no response received.
			@unanswered_requests[host][data.guarantee_id] = data if data.respond_to?(:guarantee_id)
		end
		send(transmissions, host)
	end
		
		
	private
		
		
		#Parses incoming data.
		def receive(data, sender)
			begin
				#Reject data unless sender has already joined server (or wants to join).
				if allowed?(sender)
					#Deserialize and process data.
					Serializer.instance.deserialize(data).each {|object| process(object, sender)}
				#If sender wants to join, process request.
				else
					@log.debug "#{sender} not currently allowed."
					object = Serializer.instance.deserialize(data).last
					if object.instance_of?(Request::Join)
						process(object, sender)
					else
						raise "#{sender} has not joined game but is transmitting data."
					end
				end
			#Send remote errors back to sender.
			rescue RemoteException => exception
				send(exception, sender)
			end
		end
		
		
		#Determines what to do with a received object.
		def process(transmission, sender)
			@log.debug "Processing #{transmission} from #{sender}."
			begin
				if transmission.kind_of?(RemoteException)
					@log.warn [transmission.cause.message, transmission.cause.backtrace].join("\n")
					@log.debug "Deleting #{transmission.response_id} from #{@unanswered_requests[sender].keys}."
					@unanswered_requests[sender].delete(transmission.response_id)
					raise transmission.cause
				end
			rescue DuplicateObjectError => exception
				known_objects[sender] << exception.identifier
				raise
			end
			begin
				#If this is a response to a guaranteed request, stop re-sending request.
				if transmission.respond_to?(:response_id)
					@unanswered_requests[sender].delete(transmission.response_id)
					@log.debug "Unanswered requests for #{sender}: #{@unanswered_requests[sender]}"
				end
				case transmission
				when Request::Join
					process_join_request(transmission, sender)
				when Response::Join
					#TODO
				when Request::SetObjectIDs
					known_objects[sender] += transmission.ids
				when Request::UpdateObjectMovement
					transmission.movement_data.each do |id, data|
						object = @environment.get_object(id)
						object.location.x, object.location.y = data[0], data[1]
						object.vector.speed, object.vector.pitch = data[2], data[3]
					end
				when Request::Environment
					@log.debug "Found objects #{@environment.objects.map{|o| o.identifier}.join(', ')}, omitting #{known_objects[sender].join(', ')}."
					response = Response::Environment.new(
						@environment.objects.reject{|o| known_objects[sender].include?(o.identifier)},
						@environment.environmental_factors.to_a
					)
					response.response_id = transmission.guarantee_id
					send(response, sender)
				when Response::Environment
					@log.debug "Adding #{transmission.objects} to environment."
					transmission.objects.each {|o| @environment << o}
					transmission.environmental_factors.each {|o| @environment << o}
				when Request::AddObject
					known_objects[sender] << transmission.object.identifier
					if @environment.objects.any?{|o| o.identifier == transmission.object.identifier}
						@log.warn "Duplicate for #{transmission.object} exists in #{@environment}."
						raise DuplicateObjectError.new(transmission.object.identifier)
					end
					@log.debug "Adding #{transmission.object} to #{@environment}."
					@environment << transmission.object
					response = Response::AddObject.new(transmission.object.identifier)
					response.response_id = transmission.guarantee_id
					send(response, sender)
				when Response::AddObject
					known_objects[sender] << transmission.identifier
				when Request::GetObject
					object = @environment.get_object(transmission.identifier)
					raise ObjectNotFoundError.new(transmission.identifier) unless object
					response = Response::GetObject.new(object)
					response.response_id = transmission.guarantee_id
					send(response, sender)
				when Response::GetObject
					@log.debug "Adding #{transmission.object} to environment."
					@environment << transmission.object
				when Request::ModifyObject
					old_object = @environment.get_object(transmission.object.identifier)
					raise ObjectNotFoundError.new(transmission.object.identifier) unless old_object
					@log.debug "Changing #{old_object} to #{transmission.object}."
					@environment.update_object(transmission.object)
					response = Response::ModifyObject.new
					response.response_id = transmission.guarantee_id
					send(response, sender)
				when Response::ModifyObject
				when Request::RemoveObject
					@log.debug "Removing #{@environment.get_object(transmission.identifier)} from environment."
					begin
						@environment.remove_object(transmission.identifier)
					rescue RuntimeError => exception
						@log.warn exception
						raise ObjectNotFoundError.new(transmission.identifier)
					end
					response = Response::RemoveObject.new
					response.response_id = transmission.guarantee_id
					send(response, sender)
				when Response::RemoveObject
					known_objects[sender].delete(transmission.identifier)
				else
					raise RuntimeError.new("Could not process #{transmission}.")
				end
			rescue Exception => exception
				@log.warn [exception.message, exception.backtrace].join("\n")
				remote_exception = RemoteException.new
				remote_exception.cause = exception
				remote_exception.response_id = transmission.guarantee_id if transmission.respond_to?(:guarantee_id)
				raise remote_exception
			end
		end
		
		
		#TODO: Implement.
		def evaluation_turn?(dummy); true; end
		
		#TODO: Implement.
		def areas_of_interest; ["dummy"]; end
		
		#TODO: Implement.
		def objects(area); environment.objects; end
		def movable?(object); true; end
		def sendable?(object); true; end
		def destructible?(object); true; end
		
			
end


#Updates remote EnvironmentClients.
class EnvironmentServer < EnvironmentTransmitter
	
	
	#Takes the environment to serve, and the following options:
	#	:listen_port => 9977
	def initialize(environment, options = {})
		super(environment)
		@options = {
			:listen_port => 9977
		}.merge(options)
		@log.debug "Hosting Environment #{@environment.object_id} with #{@options.inspect}."
	end

	
	#Add sender to client list and acknowledge.
	def process_join_request(request, sender)
		raise BannedError.new if banned?(sender)
		@log.debug "Adding #{sender} to client list with port #{request.listen_port}."
		allow(sender, request.listen_port)
		send(Response::Join.new, sender)
	end


end


#Updates local Environment based on instructions from EnvironmentServer.
class EnvironmentClient < EnvironmentTransmitter


	#The address of the host to connect to.
	attr_accessor :host
	#The port to connect to on the host.
	attr_accessor :host_port

	
	#Takes a hash with the following keys and defaults:
	#	:host => nil,
	#	:host_port => 9977,
	#	:listen_port => nil,
	def initialize(environment, options = {})
		super(environment)
		@options = {
			:host => nil,
			:host_port => 9977,
			:listen_port => nil
		}.merge(options)
		#All transmissions to server should go to server's listen port.
		@options[:host] = IPSocket.getaddress(@options[:host])
		allowed_hosts[@options[:host]] = @options[:host_port]
	end

	
	#Connect to specified server.
	def connect
		@log.debug "Sending join request to #{@options[:host]}."
		send(Request::Join.new(@options[:listen_port]), @options[:host])
	end


	private
	

		#TODO: Implement.
		def movable?(object); false; end

	
end


end #module Zyps
