#!/root/.rbenv/versions/2.3.1/bin/ruby

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

servername = 'bluecat.servers.global.prv'
username = "cloud_bcsvc"
password = "Tr@n5@ct10n"

client = Savon::Client.new do |wsdl, http, wsse|
  wsdl.document = "https://#{servername}/Services/API?wsdl"
  wsdl.endpoint = "https://#{servername}/Services/API"
  http.auth.ssl.verify_mode = :none
end

#client = Savon.client("http://#{servername}/Services/API?wsdl")
#puts @client

#puts "Namespace:<#{client.wsdl.namespace}> Endpoint:<#{client.wsdl.endpoint}> Actions:<#{client.wsdl.soap_actions}>"

login_response = client.request :login do 
  soap.body = {
	:username => username,
    :password => password,
	:order!	=> [:username, :password],
  }
end

client.http.headers["Cookie"] = login_response.http.headers["Set-Cookie"]

getEntityByName = client.request :get_entity_by_name do
  soap.body = {
	:parent_id => 0,
	:name	=> 'Elavon',
	:type	=> 'Configuration',
  }
end

getEntityByName_hash = getEntityByName.to_hash[:get_entity_by_name_response][:return]
container = getEntityByName_hash[:name]
container_id = getEntityByName_hash[:id]

getIPRangedByIP = client.request :get_ip_ranged_by_ip do
  soap.body	= {
	:container_id	=> container_id,
	:address	=> '10.167.64.1',
	:type	=> 'IP4Network'
  }
end

getIPRangedByIP_hash = getIPRangedByIP.to_hash[:get_ip_ranged_by_ip_response][:return]
puts "Get IP Ranged By IP Response: #{getIPRangedByIP_hash.inspect}"

ip4network_id = getIPRangedByIP_hash[:id]
puts "IP4Network ID:<#{ip4network_id}>"
properties_array = getIPRangedByIP_hash[:properties].split('|')
properties_hash = Hash[properties_array.map { |prop| prop.split '='}]
puts properties_hash.inspect
cidr = properties_hash['CIDR']
puts "CIDR:<#{cidr}>"

