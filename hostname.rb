#!/usr/bin/env ruby
#A basic ruby script to show how to use/test ERB templates
require 'erb'

instance_name = "svdlatlwiki_001"
instance_name.delete! '_'
p instance_name

template = " hostname: <%= instance_name %>"

renderer =ERB.new(template)
puts output = renderer.result()
