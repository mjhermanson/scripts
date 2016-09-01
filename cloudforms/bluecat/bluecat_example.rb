#!/root/.rbenv/versions/2.3.1/bin/ruby 
#An example script to query basic information from BlueCat Proteus from the SOAP API
# 	- tested on ruby 2.3.1, savon 1.1.0. Does not work with savon 2.x+
#	- debug logging for HTTPI
#TODO: 
#	- create a def to generate request for next available
#	- catch exceptions
#	- create a def to release an IP

#Require an older savon
gem 'savon', '=1.1.0'
require "savon"
require	"httpi"

HTTPI.log_level = :debug
HTTPI.log		= true
HTTPI.adapter	= :net_http

Savon.configure do |config|
  config.log	= true
  config.log_level	= :debug
end

#change this or get from somewhere
servername = 'bluecat.fqdn'
username = "username"
password = "password"

# create WSDL and endpoint objects
client = Savon::Client.new do |wsdl, http, wsse|
  wsdl.document = "https://#{servername}/Services/API?wsdl"
  wsdl.endpoint = "https://#{servername}/Services/API"
  http.auth.ssl.verify_mode = :none
end

#client = Savon.client("http://#{servername}/Services/API?wsdl")
#puts @client

#puts "Namespace:<#{client.wsdl.namespace}> Endpoint:<#{client.wsdl.endpoint}> Actions:<#{client.wsdl.soap_actions}>"

#login
login_response = client.request :login do 
  soap.body = {
	:username => username,
    :password => password,
	:order!	=> [:username, :password],
  }
end
#set cookies
client.http.headers["Cookie"] = login_response.http.headers["Set-Cookie"]

#get to root container. We use this to lookup IP ranges
getEntityByName = client.request :get_entity_by_name do
  soap.body = {
	:parent_id => 0,
	:name	=> 'Elavon',
	:type	=> 'Configuration',
  }
end

# use Savon .to_hash to convert object to hash
getEntityByName_hash = getEntityByName.to_hash[:get_entity_by_name_response][:return]

#extract container info from above hash
container = getEntityByName_hash[:name]
container_id = getEntityByName_hash[:id]

#lookup IP range by gateway inside the previously discovered container
#TODO: make this a def
getIPRangedByIP = client.request :get_ip_ranged_by_ip do
  soap.body	= {
	:container_id	=> container_id,
	:address	=> 'gateway_ip',
	:type	=> 'IP4Network'
  }
end

#convert response to hash, again using Savon .to_hash
getIPRangedByIP_hash = getIPRangedByIP.to_hash[:get_ip_ranged_by_ip_response][:return]
puts "Get IP Ranged By IP Response: #{getIPRangedByIP_hash.inspect}"

#store the numerical ID
ip4network_id = getIPRangedByIP_hash[:id]
puts "IP4Network ID:<#{ip4network_id}>"
#create properties array
properties_array = getIPRangedByIP_hash[:properties].split('|')
#split the array of "key=value" strings into a hash of 'key'=>'value'
properties_hash = Hash[properties_array.map { |prop| prop.split '='}]
cidr = properties_hash['CIDR']
#print what we are doing to stdout
puts properties_hash.inspect
puts "CIDR:<#{cidr}>"

#TODO: def to create a request
