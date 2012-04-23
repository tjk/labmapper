#!/usr/bin/env ruby

require 'sinatra'
require 'yaml'
require 'haml'

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
      tokens[m[:re]] = {:id => id, :dir => dir, :classes => classes}
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
          sub_tokens[token] = vcopy.merge({:id => token})
        end
        tokens = sub_tokens.merge!(tokens)
        tokens[' '] = nil # empty block -- TODO handle better
      end
    end
  end
  lines2haml(tokens, lines, valids)
end

def lines2haml(tokens, lines, valids)
  haml = "- status = lambda {|n| hosts[n] ? ' occupied' : ' available'}\n"
  haml += "%table{:cellpadding => 0}\n"
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
          haml += "    %td{:id => \"#{tokens[t][:id]}\", :class => \"#{tokens[t][:classes].join(' ')}\#{status.call(:'#{tokens[t][:id]}')} #{tokens[t][:dir]}\"}\n"
        else
          haml += "    %td\n"
        end
      end
    end
  end
  haml
end

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
  table = Haml::Engine.new(parserc).render(Object.new, :hosts => nhosts)
  haml :index, :locals => {:table => table, :timestamp => timestamp[0].strftime('%Y/%m/%d @ %H:%M')}
end
