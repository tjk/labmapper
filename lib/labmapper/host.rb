module Labmapper
  class Host
    attr_accessor :name, :user, :nossh, :uptime

    SUFFIX = '.cs.ucsb.edu' # TODO grab from labrc
    INVALID_USERS = ['(unknown)', 'root'] # TODO fix
    SSH_OPTIONS = {
      'ConnectTimeout' => 5, # in seconds
      'UserKnownHostsFile' => '/dev/null',
      'StrictHostKeyChecking' => 'no', # don't check RSA fingerprint
    }

    def initialize(name, key='~/.ssh/id_rsa.pub')
      @name = name
      @nossh = false
      @user = @uptime = nil
      @key = key
    end

    # TODO improve this -- place ssh keys before polling
    def send_key
      ssh_options = SSH_OPTIONS.map { |k,v| "-o #{k}=#{v}" }.join(' ')
      res = `ssh-copy-id #{ssh_options} -i #{@key} #{@name}#{SUFFIX}`
      puts "Could not send key to #{@name}" unless $?.success?
    end

    def poll
      res = ssh(['uptime', 'who'])
      if res.nil?
        @nossh = true
      else
        @uptime, *whos = res.split("\n")
        whos.each do |who|
          user, tty, date, time, ip = who.split
          if ip.nil? || ip.size < 6 # TODO no magic number please
            @user = user unless INVALID_USERS.index(user)
          end
        end
      end
      debug # TODO if $DEBUG ?
    end

    def debug
      # TODO let's use log4r
      puts "#{@name}: #{@user}"
    end

    def to_json(*a)
      {name: @name, nossh: @nossh, user: @user}.to_json(*a)
    end

    private

    def ssh(cmds=['who'])
      ssh_options = SSH_OPTIONS.map { |k,v| "-o #{k}=#{v}" }.join(' ')
      out = `ssh -q #{ssh_options} #{@name}#{SUFFIX} '#{cmds.join(' ; ')}'`
      # if ssh returned with non-0 exit status
      $?.success? ? out : nil
    end
  end
end
