#!/usr/bin/env ruby

require 'sinatra'
require 'yaml'
require 'haml'
require 'json'

def parserc
  fname = Dir['./*.labrc'][0]
  lines = File.open(fname, 'r').read.split("\n")
  alphabet = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
  valids, dirs = /[0-9a-zA-Z\ ]/, /[\^v><]/
  rowre = /^(?<re>[#{valids}\-\*]*)\|(?<dir>#{dirs})?(?<id>#.*)?(?<classes>\..*)*$/
  tokens = {}
  lines.each do |line|
    if m = line.match(rowre)
      id = m[:id] ? m[:id][1..-1] : m[:re]
      classes = m[:classes] ? m[:classes].split('.')[1..-1] : []
      dir = {'^' => 'up', '>' => 'right', 'v' => 'down', '<' => 'left'}[m[:dir]]
      tokens[m[:re]] = {id: id, dir: dir, classes: classes}
    end
  end
  tokens.dup.each do |kcopy, vcopy|
    # for all non-single token, 'pop' them from hash and apply them to relevants
    unless kcopy.match(/^#{valids}$/)
      tokens.delete(kcopy)
      # let each item in tokens inherit from tokens['*']
      if kcopy == '*'
        tokens.each do |k, v|
          v[:dir] = vcopy[:dir] unless v[:dir]
          v[:classes] |= vcopy[:classes]
        end
      else
        # create new tokens that aren't explicitely named
        sub_tokens = {}
        more_tokens = alphabet.scan(/[#{kcopy}]/)
        more_tokens.each do |token|
          sub_tokens[token] = vcopy.merge({id: token})
        end
        tokens = sub_tokens.merge!(tokens)
        tokens[' '] = nil # empty block -- TODO handle better
      end
    end
  end
  lines2haml(tokens, lines, valids)
end

def lines2haml(tokens, lines, valids)
  haml = "- availability = lambda {|n| hosts[n] && hosts[n]['user'] ? ' occupied' : ' available'}\n"
  haml += "- uptime = lambda {|n| hosts[n] && hosts[n]['uptime']}\n"
  haml += "%table{cellpadding: 0}\n"
  lines.each do |line|
    m = line.match(/^;(#{valids}*)\|?(\..*)*$/)
    if m
      haml += '  %tr'
      toks, classes = m[1], m[2].split('.')[1..-1]
      haml += '.' + classes.join('.') unless classes.empty?
      haml += "\n"
      # haml += "    - #{toks.chars.collect {|t| tokens[t][:id].to_sym if tokens[t]}.inspect}.each do |host|\n"
      toks.chars.each do |t|
        if tokens[t]
          haml += "    %td{id: \"#{tokens[t][:id]}\", class: \"#{tokens[t][:classes].join(' ')}\#{availability.call('#{tokens[t][:id]}')} #{tokens[t][:dir]}\"}\n"
          haml += "      %span{class: \"uptime hidden\"}= \"\#{uptime.call('#{tokens[t][:id]}')}\"\n"
        else
          haml += "    %td\n"
        end
      end
    end
  end
  haml
end

get '/' do
  input = {}
  File.open('socket.json','r') do |file|
    input = JSON.parse(file.read)
  end

  timestamp = DateTime.parse(input['timestamp'])
  formatted_timestamp = timestamp.strftime('%Y/%m/%d @ %H:%M')

  puts parserc
  table = Haml::Engine.new(parserc).render(Object.new, hosts: input['hosts'])
  haml :index, locals: {table: table, timestamp: formatted_timestamp}
end

# TODO remove this or obfuscate user on host? (privacy issue)
# TODO either way, i propose the route to be /hosts.json
# get '/json' do
#   send_file 'socket.json'
# end
