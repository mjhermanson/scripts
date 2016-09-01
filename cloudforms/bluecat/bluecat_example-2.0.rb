#!/opt/rh/rh-ruby22/root/usr/bin/ruby
#An example script to query basic information from BlueCat Proteus from the SOAP API
# 	- tested on ruby 2.3.1, savon 1.1.0. Does not work with savon 2.x+
#	- debug logging for HTTPI
#TODO: 
#	- create a def to generate request for next available
#	- catch exceptions
#	- create a def to release an IP

#Require an older savon
require "savon"
require	"httpi"


HTTPI.log_level = :debug
HTTPI.log		= true
HTTPI.adapter	= :net_http

#Savon.configure do |config|
#  config.log	= true
#  config.log_level	= :debug
#end

#change this or get from somewhere
servername = 'bluecat.servers.global.prv'
username = "cloud_bcsvc"
password = "Tr@n5@ct10n"
rootcontainer = "Elavon"

# create WSDL and endpoint objects
#client = Savon.client do |wsdl, http, wsse|
#  wsdl "https://#{servername}/Services/API?wsdl"
#  endpoint = "https://#{servername}/Services/API"
#end
WsdlUrl = "https://#{servername}/Services/API?wsdl"

$client = Savon.client(wsdl: WsdlUrl, ssl_verify_mode: :none)
$response = $client.call(:login) do
    message username: username, password: password
end

$auth_cookies = $response.http.cookies
    getEntityByName = $client.call(:get_entity_by_name) do |ctx|
        ctx.cookies $auth_cookies
        ctx.message parentId: 0, name: rootcontainer, type: 'Configuration'
    end
    #Get Entity By Name Response: {:type=>"Configuration", :name=>"MTC", :id=>"5", :properties=>nil}
    getEntityByName_hash = getEntityByName.to_hash[:get_entity_by_name_response][:return]
    puts "Get Entity By Name Response: #{getEntityByName_hash.inspect}"
    puts "Get Entity By Name container id: #{getEntityByName_hash[:id]}"

    #puts $client.operations

def system_info
    print "In system_info\n"
    hash = {}
    begin
      print "Calling get_system_info\n"
      response = $client.call(:get_system_info) do |ctx|
        ctx.cookies $auth_cookies
      end
      print "Called get_system_info\n"
  
      payload = response.body[:get_system_info_response][:return]
      print "Got payload %s\n" % payload
      kvs = unserialize_properties(payload)
      kvs.each do |k,v|
        hash[k.to_sym] = v
      end
      print "--------------------\n"
    rescue Exception => e
      print "Got Exception %s\n" % e.message
    end
    return hash
end

def system_test
    # Check for some operations
    unless client.operations.include? :login
      print "Login method missing from Bluecat Api\n"
    end
    unless client.operations.include? :get_system_info
      print "getSystemInfo method missing from Bluecat Api\n"
    else
      unless ( system_info[:address] =~ /\d{1,4}\.\d{1,4}\.\d{1,4}\.\d{1,4}/ ) == 0
        raise 'Failed system sanity test'
      end
    end
end

def get_configurations
    response = client.call(:get_entities) do |ctx|
      ctx.cookies auth_cookies
      ctx.message parentId: 0, type: 'Configuration', start: 0, count: 10
    end
    items = canonical_items(response.body[:get_entities_response])
end

def get_ip4_blocks(parent_id, start=0, count=1)
    response = client.call(:get_entities) do |ctx|
      ctx.cookies auth_cookies
      ctx.message parentId: parent_id, type: 'IP4Block', start: 0, count: 10
    end
    items = canonical_items(response.body[:get_entities_response])
end

def get_ip4_networks(parent_id, start=0, count=1)
    response = client.call(:get_entities) do |ctx|
      ctx.cookies auth_cookies
      ctx.message parentId: parent_id, type: 'IP4Network', start: 0, count: 10
    end
    items = canonical_items(response.body[:get_entities_response])
end


##get to root container. We use this to lookup IP ranges
#getEntityByName = client.request :get_entity_by_name do
#  soap.body = {
#	:parent_id => 0,
#	:name	=> 'Elavon',
#	:type	=> 'Configuration',
#  }
#end
#
## use Savon .to_hash to convert object to hash
#getEntityByName_hash = getEntityByName.to_hash[:get_entity_by_name_response][:return]
#
##extract container info from above hash
#container = getEntityByName_hash[:name]
#container_id = getEntityByName_hash[:id]
#
##lookup IP range by gateway inside the previously discovered container
##TODO: make this a def
#getIPRangedByIP = client.request :get_ip_ranged_by_ip do
#  soap.body	= {
#	:container_id	=> container_id,
#	:address	=> 'gateway_ip',
#	:type	=> 'IP4Network'
#  }
#end
#
##convert response to hash, again using Savon .to_hash
#getIPRangedByIP_hash = getIPRangedByIP.to_hash[:get_ip_ranged_by_ip_response][:return]
#puts "Get IP Ranged By IP Response: #{getIPRangedByIP_hash.inspect}"
#
##store the numerical ID
#ip4network_id = getIPRangedByIP_hash[:id]
#puts "IP4Network ID:<#{ip4network_id}>"
##create properties array
#properties_array = getIPRangedByIP_hash[:properties].split('|')
##split the array of "key=value" strings into a hash of 'key'=>'value'
#properties_hash = Hash[properties_array.map { |prop| prop.split '='}]
#cidr = properties_hash['CIDR']
##print what we are doing to stdout
#puts properties_hash.inspect
#puts "CIDR:<#{cidr}>"
#
#TODO: def to create a request
