#!/usr/bin/env ruby

require 'yaml'
require 'date'
require 'json'

class Host

  attr_accessor :name, :user, :uptime
  @@suffix = '.cs.ucsb.edu' # TODO grab from labrc
  @@invalid_users = ['(unknown)', 'root'] # TODO fix

  def initialize(name)
    @name = name
    @user = @uptime = nil
  end

  def poll
    # TODO check errors here or in ssh()
    @uptime, *whos = ssh(['uptime', 'who']).split("\n")
    whos.each do |who|
      user, tty, date, time, ip = who.split
      if ip.nil? || ip.size < 6 # TODO no magic number please
        @user = user unless @@invalid_users.index(user)
      end
    end
    debug # TODO if $DEBUG ?
  end

  def debug
    # TODO let's use log4r
    puts "#{@name}: #{@user}"
  end

  def to_json(*a)
    {name: @name, user: @user}.to_json(*a)
  end

  private

  def ssh(cmds=['who'])
    # TODO check status (machine may be down)
    `ssh #{@name}#{@@suffix} '#{cmds.join(' ; ')}'`
  end

end

class HostPoller

  # TODO use labrc file
  @@hostnames = [:cartman, :elroy, :dagwood, :calvin]

  @@hosts = []
  @@hostnames.each do |hostname|
    @@hosts << Host.new(hostname)
  end

  def self.poll
    @@hosts.map(&:poll)
  end

  def self.serialize(file)
    File.open(file, 'w') do |f|
      output = {timestamp: DateTime.now, hosts: {}}
      @@hosts.each do |host|
        output[:hosts][host.name] = {user: host.user, uptime: host.uptime}
      end
      f.puts output.to_json
    end
  end

end

if $0 == __FILE__
  HostPoller.poll
  HostPoller.serialize('socket.json')
end
