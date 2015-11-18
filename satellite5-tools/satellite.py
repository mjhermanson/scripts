#!/usr/bin/python

###################################################################
# Author: Matt Hermanson
# Purpose: This can be used to get information out of Satellite
# for reporting purposes new servers. Meant to be run from cron to 
# for daily digests of new servers and any servers removed in the 
# last 24 hours.
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
server_list = '/tmp/servers'

#used to write current systems to system_list
def update_list():
    f = open(server_list, 'w')
    for system in systems:
        system = str(system['name'])+ '\n'
        f.write(system)
    f.close()

#compare current systems to system_list and print report
def build_report():
    #check if we have a list of systems and store in a list, else create it 
    if os.path.exists(server_list):
        old_list=[]
        file = open(server_list)
        old_list = [line.strip() for line in open(server_list)] 
        file.close()
    else:
   	update_list()
 
    new_list=[]
    for entry in systems:
       new_list.append(entry['name'])
    if old_list:
        print('New servers added since %s:'%time.ctime(os.path.getmtime(server_list)))
        for diff in set(new_list).difference(old_list):
    	    print diff
        print ('\nServers removed since %s:'%time.ctime(os.path.getmtime(server_list)))
        for diff in set(old_list).difference(new_list):
    	    print diff

# if option is passed and we've logged in
if opts.report and key:
    systems = client.system.listUserSystems(key)
    build_report()
    #update if older than 24 hours
    if time.time() - os.path.getmtime(server_list) > 86300:
	update_list() 
else:
    parser.print_help()
    sys.exit(-1)

client.auth.logout(key)
