#!/usr/bin/env ruby

require 'sinatra'
require 'yaml'

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
  erb :index, :locals => {:hosts => nhosts, :timestamp => timestamp[0].strftime('%Y/%m/%d @ %H:%M')}
end
