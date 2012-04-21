#!/usr/bin/env ruby

require 'sinatra'
require 'yaml'
require 'haml'

get '/' do
  hosts = []
  timestamp = []
  $/ = "\n\n"
  File.open('socket.yaml', 'r').each_with_index do |object, i|
    (i == 0 ? timestamp : hosts)  << YAML::load(object)
  end
  nhosts = {}
  hosts.each do |host|
    nhosts[host.ivars['name']] = host.ivars['current_user']
  end
  haml :index, :locals => {:hosts => nhosts, :timestamp => timestamp[0].strftime('%Y/%m/%d @ %H:%M')}
end
