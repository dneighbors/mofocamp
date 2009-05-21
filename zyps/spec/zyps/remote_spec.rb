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
	require 'zyps/remote'
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


CLIENT_LISTEN_PORT = 8989
LOCAL_HOST_ADDRESS = '127.0.0.1'


describe EnvironmentServer do

	before(:each) do
		@server_environment = Environment.new
		@server = EnvironmentServer.new(@server_environment)
		@client_environment = Environment.new
		@client = EnvironmentClient.new(@client_environment, :host => LOCAL_HOST_ADDRESS, :listen_port => CLIENT_LISTEN_PORT)
	end
	
	after(:each) do
		@server.close_socket
		@client.close_socket
	end
	
	it "allows a client to join" do
		@server.open_socket
		@client.open_socket
		@server.should_receive(:process_join_request).with(
			an_instance_of(Request::Join),
			an_instance_of(String)
		)
		@client.connect
		@server.listen
	end
	
	it "acknowledges when a client has joined" do
		@server.open_socket
		@client.open_socket
		@client.should_receive(:process).with(
			an_instance_of(Response::Join),
			an_instance_of(String)
		)
		@client.connect
		@server.listen
		@client.listen
	end
	
	it "rejects banned clients" do
		@server.open_socket
		@client.open_socket
		@server.ban(LOCAL_HOST_ADDRESS)
		@client.connect
		lambda{@server.listen}.should raise_error(BannedError)
	end
	
	it "does not allow IP address if corresponding hostname is banned"
	it "does not allow hostname if corresponding IP address is banned"
	
	it "sends objects that were already on server when a new client connects" do
		object = GameObject.new
		object2 = GameObject.new
		@server_environment << object << object2
		@server.open_socket
		@client.open_socket
		@client.connect
		@server.listen
		@client.listen
		@server.update
		@client.listen
		@client_environment.should satisfy {|e| e.objects.any?{|o| o.identifier == object.identifier}}
		@client_environment.should satisfy {|e| e.objects.any?{|o| o.identifier == object2.identifier}}
	end
	
	it "sends environmental factors that were already on server when a new client connects"	
	
	it "doesn't send new object to client if a rule tells it not to"

	it "sends an error to banned clients that attempt to join"
	
	it "assigns no AreaOfInterest to a client by default"
	it "updates a client with no AreaOfInterest on all objects"
	it "updates a client on all objects inside its AreaOfInterest"
	it "does not update a client on objects outside its AreaOfInterest"
	it "allows a client to have more than one AreaOfInterest"
	it "allows different clients to have a different AreaOfInterest"

end


describe EnvironmentServer do

	before(:each) do
		@server_environment = Environment.new
		@server = EnvironmentServer.new(@server_environment)
		@client_environment = Environment.new
		@client = EnvironmentClient.new(@client_environment, :host => LOCAL_HOST_ADDRESS, :listen_port => CLIENT_LISTEN_PORT)
		@server.open_socket
		@client.open_socket
		@client.connect
		@server.listen
		@client.listen
	end
	
	after(:each) do
		@server.close_socket
		@client.close_socket
	end

	it "can send movement data for all GameObjects" do
		object = GameObject.new(:location => Location.new(1, 2), :vector => Vector.new(10, 45))
		@server_environment << object
		@server.update
		@client.listen
		@server.listen
		@server.update
		@client.should_receive(:process).with(
			Request::UpdateObjectMovement.new(
				{object.identifier => [1, 2, 10, 45]}
			),
			LOCAL_HOST_ADDRESS
		)
		@client.listen
	end
	
	it "can request full Environment" do
		object = GameObject.new
		environmental_factor = SpeedLimit.new(1)
		@client_environment << object << environmental_factor
		@server.send(Request::Environment.new, LOCAL_HOST_ADDRESS)
		@client.listen
		@server.should_receive(:process).with(
			Response::Environment.new([object], [environmental_factor]),
			LOCAL_HOST_ADDRESS
		)
		@server.listen
	end
	
	it "keeps requesting Environment until remote system responds" do
		@client.stub!(:send) #Prevent client from responding.
		request = Request::Environment.new
		@server.send(request, LOCAL_HOST_ADDRESS)
		@client.listen
		@server.resend_requests
		@client.should_receive(:process).with(request, LOCAL_HOST_ADDRESS)
		@client.listen
	end
	
	it "stops requesting Environment once response is received" do
		request = Request::Environment.new
		@server.send(request, LOCAL_HOST_ADDRESS)
		@client.listen
		@server.listen
		@server.should_not_receive(:send)
		@server.resend_requests
	end
	
	it "stops requesting Environment when exception is received" do
		request = Request::Environment.new
		exception = RemoteException.new
		exception.cause = Exception.new
		exception.response_id = request.guarantee_id
		@client.stub!(:process).and_raise(exception)
		begin
			@server.send(request, LOCAL_HOST_ADDRESS)
			@client.listen
			@server.listen
		#Receiver should throw wrapped Exception; discard it for test.
		rescue Exception
		end
		@server.should_not_receive(:send)
		@server.resend_requests
	end
	
	it "can add GameObject to remote Environment" do
		object = GameObject.new(:location => Location.new(1, 2), :vector => Vector.new(10, 45))
		@server_environment << object
		@server.send(Request::AddObject.new(object), LOCAL_HOST_ADDRESS)
		@client_environment.object_count.should == 0
		@client.listen
		@client_environment.object_count.should == 1
	end
	
	it "keeps sending request to add GameObject until remote system responds" do
		@client.stub!(:send) #Prevent client from responding.
		request = Request::AddObject.new(GameObject.new)
		@server.send(request, LOCAL_HOST_ADDRESS)
		@client.listen
		@server.resend_requests
		@client.should_receive(:process).with(request, LOCAL_HOST_ADDRESS)
		@client.listen
	end
	
	it "stops sending add request once response is received" do
		object = GameObject.new
		@server_environment << object
		@server.send(Request::AddObject.new(object), LOCAL_HOST_ADDRESS)
		@client.listen
		@server.listen
		@server.should_not_receive(:queue).with(an_instance_of(Request::AddObject), LOCAL_HOST_ADDRESS)
		@server.update
	end

	it "stops sending add request when exception is received" do
		object = GameObject.new
		@server_environment << object
		@client_environment << object
		@server.update
		@client.listen
		begin
			@server.listen
		rescue DuplicateObjectError
		end
		@server.should_not_receive(:queue).with(an_instance_of(Request::AddObject), LOCAL_HOST_ADDRESS)
		@server.update
	end
	
	it "returns an exception if added GameObject already exists in local environment" do
		object = GameObject.new
		@server_environment << object
		@client_environment << object
		@client.send(Request::AddObject.new(object), LOCAL_HOST_ADDRESS)
		@server.listen
		lambda{@client.listen}.should raise_error(DuplicateObjectError)
	end
	
	it "modifies remote object instead if add fails because it already exists"
	
	it "does not send back objects that were added by client" do
		object = GameObject.new
		@client_environment << object
		@client.send(Request::AddObject.new(object), LOCAL_HOST_ADDRESS)
		@server.listen
		@server.should_not_receive(:queue).with(an_instance_of(Request::AddObject), LOCAL_HOST_ADDRESS)
		@server.update
	end
	
	it "can request full serialized GameObject" do
		object = GameObject.new
		@client_environment << object
		@server.send(Request::GetObject.new(object.identifier), LOCAL_HOST_ADDRESS)
		@client.listen
		@server.listen
		@server_environment.objects.should include(object)
	end
	
	it "keeps requesting GameObject until remote system responds" do
		object = GameObject.new
		@client_environment << object
		@client.stub!(:send) #Prevent client from responding.
		request = Request::GetObject.new(object.identifier)
		@server.send(request, LOCAL_HOST_ADDRESS)
		@client.listen
		@server.resend_requests
		@client.should_receive(:process).with(request, LOCAL_HOST_ADDRESS)
		@client.listen
	end
	
	it "stops sending object request once response is received" do
		object = GameObject.new
		@client_environment << object
		request = Request::GetObject.new(object.identifier)
		@server.send(request, LOCAL_HOST_ADDRESS)
		@client.listen
		@server.listen
		@server.should_not_receive(:send)
		@server.resend_requests
	end
	
	it "stops sending object request when exception is received" do
		request = Request::GetObject.new(999999)
		begin
			@server.send(request, LOCAL_HOST_ADDRESS)
			@client.listen
			@server.listen
		#Receiver should throw Exception; discard it for test.
		rescue ObjectNotFoundError
		end
		@server.should_not_receive(:send)
		@server.resend_requests
	end
	
	it "returns an exception if requested GameObject does not exist in local environment" do
		@client.send(Request::GetObject.new(1234567), LOCAL_HOST_ADDRESS)
		@server.listen
		lambda {@client.listen}.should raise_error(ObjectNotFoundError)
	end
	
	it "can modify GameObject in remote Environment" do
		server_object = GameObject.new
		@server_environment << server_object
		@server.send(Request::AddObject.new(server_object), LOCAL_HOST_ADDRESS)
		@client.listen
		server_object.size = 21
		server_object.color = Color.blue
		server_object.name = 'Mikey'
		server_object.tags << 'foo'
		client_object = @client_environment.get_object(server_object.identifier)
		client_object.size.should_not == server_object.size
		client_object.color.should_not == server_object.color
		client_object.name.should_not == server_object.name
		client_object.tags.should_not == server_object.tags
		@server.send(Request::ModifyObject.new(server_object), LOCAL_HOST_ADDRESS)
		@client.listen
		client_object = @client_environment.get_object(server_object.identifier)
		client_object.size.should == server_object.size
		client_object.color.should == server_object.color
		client_object.name.should == server_object.name
		client_object.tags.should == server_object.tags
	end
	
	it "keeps sending GameObject modification request until remote system responds" do
		object = GameObject.new
		@server_environment << object
		@client_environment << object
		@client.stub!(:send) #Prevent client from responding.
		request = Request::ModifyObject.new(object)
		@server.send(request, LOCAL_HOST_ADDRESS)
		@client.listen
		@server.resend_requests
		@client.should_receive(:process).with(request, LOCAL_HOST_ADDRESS)
		@client.listen
	end
	
	it "stops sending modification request once response is received" do
		object = GameObject.new
		@client_environment << object
		@server.send(Request::ModifyObject.new(object), LOCAL_HOST_ADDRESS)
		@client.listen
		@server.listen
		@server.should_not_receive(:send)
		@server.resend_requests
	end
	
	it "stops sending modification request when exception is received" do
		begin
			@server.send(Request::ModifyObject.new(GameObject.new), LOCAL_HOST_ADDRESS)
			@client.listen
			@server.listen
		#Receiver should throw Exception; discard it for test.
		rescue ObjectNotFoundError
		end
		@server.should_not_receive(:send)
		@server.resend_requests
	end
	
	it "returns an exception if GameObject to be modified does not exist in local environment" do
		@client.send(Request::ModifyObject.new(GameObject.new), LOCAL_HOST_ADDRESS)
		@server.listen
		lambda{@client.listen}.should raise_error(ObjectNotFoundError)
	end
	
	it "can remove GameObject from remote Environment" do
		object = GameObject.new
		@client_environment << object
		@client_environment.object_count.should == 1
		@server.send(Request::RemoveObject.new(object.identifier), LOCAL_HOST_ADDRESS)
		@client.listen
		@client_environment.object_count.should == 0
	end
	
	it "keeps sending object removal request until remote system responds" do
		object = GameObject.new
		@client_environment << object
		@client.stub!(:send) #Prevent client from responding.
		request = Request::RemoveObject.new(object.identifier)
		@server.send(request, LOCAL_HOST_ADDRESS)
		@client.listen
		@server.resend_requests
		@client.should_receive(:process).with(request, LOCAL_HOST_ADDRESS)
		@client.listen
	end
	
	it "stops sending removal request once response is received" do
		object = GameObject.new
		@client_environment << object
		@server.send(Request::RemoveObject.new(object.identifier), LOCAL_HOST_ADDRESS)
		@client.listen
		@server.listen
		@server.should_not_receive(:send)
		@server.resend_requests
	end
	
	it "stops sending removal request when exception is received" do
		begin
			@server.send(Request::RemoveObject.new(999999), LOCAL_HOST_ADDRESS)
			@client.listen
			@server.listen
		#Receiver should throw Exception; discard it for test.
		rescue ObjectNotFoundError
		end
		@server.should_not_receive(:send)
		@server.resend_requests
	end
	
	it "returns an exception if item for deletion does not exist in local environment" do
		@client.send(Request::RemoveObject.new(6545641), LOCAL_HOST_ADDRESS)
		@server.listen
		lambda{@client.listen}.should raise_error(ObjectNotFoundError)
	end
	
	it "does not send objects known to already be in remote environment" do
		object = GameObject.new
		object2 = GameObject.new
		@server_environment << object << object2
		@client.send(Request::SetObjectIDs.new([object.identifier]), LOCAL_HOST_ADDRESS)
		@server.listen
		@client.send(Request::Environment.new, LOCAL_HOST_ADDRESS)
		@server.listen
		@client.should_receive(:process).with(
			Response::Environment.new([object2], []),
			LOCAL_HOST_ADDRESS
		)
		@client.listen
	end
	
	it "sends new objects as they're added to server" do
		object = GameObject.new
		@server_environment << object
		@server.update
		@client.listen
		@server.listen
		@client_environment.should satisfy {|e| e.objects.any?{|o| o.identifier == object.identifier}}
		object2 = GameObject.new
		@server_environment << object2
		@server.update
		@client.listen
		@client_environment.should satisfy {|e| e.objects.any?{|o| o.identifier == object.identifier}}
		@client_environment.should satisfy {|e| e.objects.any?{|o| o.identifier == object2.identifier}}
	end
	
	it "removes objects from client as they're removed from server" do
		object = GameObject.new
		@server_environment << object
		@server.update
		@client.listen
		@client_environment.should satisfy {|e| e.objects.any?{|o| o.identifier == object.identifier}}
		@server.listen
		@server_environment.remove_object(object.identifier)
		@server.update
		@client.listen
		@client_environment.should_not satisfy {|e| e.objects.any?{|o| o.identifier == object.identifier}}
	end
	
	it "sends new environmental factors as they're added to server"
	it "removes environmental factors from client as they're removed from server"
	
	it "can buffer requests to be sent in a single transmission" do
		@server.queue(Request::Environment.new, LOCAL_HOST_ADDRESS)
		@server.queue(Request::SetObjectIDs.new([1111]), LOCAL_HOST_ADDRESS)
		@server.flush_queue(LOCAL_HOST_ADDRESS)
		@client.should_receive(:process).with(an_instance_of(Request::Environment), LOCAL_HOST_ADDRESS)
		@client.should_receive(:process).with(an_instance_of(Request::SetObjectIDs), LOCAL_HOST_ADDRESS)
		@client.listen
	end
	
	it "has authority on object movement by default"
	it "does not have authority on object movement when assigned to client"
	it "has authority on object removal"
	
# 	it "lets new clients connect and get world if others are already connected" do
# 		object = GameObject.new
# 		@server_environment << object
# 		@server.update
# 		@client.listen
# 		@client_environment.should satisfy {|e| e.objects.any?{|o| o.identifier == object.identifier}}
# 		client2_environment = Environment.new
# 		client2 = EnvironmentClient.new(client2_environment, :host => LOCAL_HOST_ADDRESS, :listen_port => CLIENT_LISTEN_PORT + 1)
# 		client2.open_socket
# 		client2.connect
# 		@server.listen
# 		@server.update
# 		client2.listen
# 		client2_environment.should satisfy {|e| e.objects.any?{|o| o.identifier == object.identifier}}
# 	end

	it "keeps updating other clients if one disconnects"
	it "allows forced disconnection of clients"
	
end
	
describe EnvironmentClient do

	before(:each) do
	end
	
	it "keeps requesting to join server until response is received"
	it "stops join requests once response is received"
	it "stops join requests if banned"
	
	it "should send objects that were already on client when it connects to a server"
	it "should send new objects as they're added to client"
	it "shouldn't send new object to server if a rule tells it not to"
	it "should keep telling server about object creation until server acknowledges it"

	it "assigns no AreaOfInterest to server by default"
	it "updates server with no AreaOfInterest on all objects"
	it "updates a client on all objects inside its AreaOfInterest"
	it "does not update a client on objects outside its AreaOfInterest"
	it "allows a client to have more than one AreaOfInterest"
	it "allows different clients to have a different AreaOfInterest"
	
end
