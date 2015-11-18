#!/usr/bin/python

###################################################################
# Author: Matt Hermanson
# Purpose: This can be used to get information out of Satellite 5
# in csv format for reporting purposes. In theory, this can be used 
# to modify objects but that funcationality is not implemented. 
#
###################################################################

import xmlrpclib
import optparse
import getpass
import sys,os, datetime, time

parser = optparse.OptionParser()

parser.add_option('-u', "--username", help='satellite username', dest="username", default=False)
parser.add_option('-p', "--password", help='satellite password', dest='password', default=False)
parser.add_option('-r', "--report", help='generate report', dest='report', default=False, action='store_true')
parser.add_option('-s', "--satellite", help='satellite hostname [%default]', \
    dest='satellite_url', default='https://sppatlsat01.servers.global.prv/rpc/api')
(opts,args) = parser.parse_args()

if not opts.username and not opts.password and opts.report:
    opts.username = 'satuser'
    opts.password = 'r3@d0nly'
if not opts.username:
    opts.username = getpass.getuser()
    print 'Username: ' + opts.username
if not opts.password:
    opts.password = getpass.getpass()

#Define client and login
client = xmlrpclib.Server(opts.satellite_url, verbose=0)
key = client.auth.login(opts.username, opts.password)

#location of 'stale' server lsit
server_list = 'inventory.txt'
inventory_csv = 'inventory.csv'
#dmi_info = {}
csv_info = []
server_details = {}

#used to write current systems to system_list
def loadDmi():
    print "Loading DMI info for all systems in Satellite..."
    for system in systems:
       dmi_info[system['name']] = client.system.getDmi(key,system['id'])
    return dmi_info

def loadDetails():
    for system in systems:
      server_details[system['name']] = client.system.getDetails(key,system['id'])


def parseSystems():
    print "Plucking only the ones I care about"
    f = open(server_list, 'r')
    mylist = [line.strip() for line in open(server_list)]
    f.close()
    for system in systems:
      if system['name'] not in mylist:
	del dmi_info[system['name']]

def convertToUploadFormat():
    inv_item = {}
    for system in systems:
      dmi_info = client.system.getDmi(key,system['id'])
      cpuinfo = client.system.getCpu(key,system['id'])
      inv_item['name'] = system['name']
      inv_item['os'] = 'RedHat ES'
      inv_item['osver'] = server_details[system['name']]['release'][:1]
      if dmi_info:
        if ('vmware' in dmi_info['system'].lower()) or ('kvm' in dmi_info['system'].lower()) or ('virtualbox' in dmi_info['system'].lower()) or ('rhev' in dmi_info['system'].lower()):
  	  inv_item['type'] = 'Virtual'
        else:
          inv_item['type'] = 'Real'
        inv_item['vendor'] = dmi_info['vendor']
        inv_item['hardware'] = dmi_info['product']
        if dmi_info['asset']:
  	  inv_item['serial'] = dmi_info['asset'].split('system:')[1].rstrip(')')
      else:
        inv_item['type'] = 'unknown'
        inv_item['vendor'] = 'unknown'
	inv_item['hardware'] = 'unknown'
        inv_item['serial'] = 'unknown'
      if cpuinfo:
        inv_item['cpu'] = cpuinfo['mhz']
        inv_item['cpucount'] =  cpuinfo['count']
      else:
 	inv_item['cpu'] = 'unknown'
 	inv_item['cpucount'] = 'unknown'
      inv_item['memory'] =  client.system.getMemory(key,system['id'])['ram']
      print ',,' + inv_item['type'] + ',' + inv_item['name'] + ',' + inv_item['os'] + ',' + inv_item['osver'] + ',' + str(inv_item['cpu']) + ',' + str(inv_item['cpucount']) + ',' + str(inv_item['memory']) + ',' + inv_item['hardware'] + ',' + inv_item['vendor'] + ',,,,,,,,' + inv_item['serial'] 
      inv_item.clear()

# if option is passed and we've logged in
if opts.report and key:
    systems = client.system.listUserSystems(key)
    loadDetails()
    convertToUploadFormat()
else:
    parser.print_help()
    sys.exit(-1)

client.auth.logout(key)
