module Labmapper
  class Host

    attr_accessor :name, :user, :nossh, :uptime
    @@suffix = '.cs.ucsb.edu' # TODO grab from labrc
    @@invalid_users = ['(unknown)', 'root'] # TODO fix

    def initialize(name)
      @name = name
      @nossh = false
      @user = @uptime = nil
    end

    # TODO improve this -- place ssh keys before polling
    def send_key
      options  = '-o ConnectTimeout=5 ' # in seconds
      # doesn't check RSA fingerprint
      options += '-o UserKnownHostsFile=/dev/null '
      options += '-o StrictHostKeyChecking=no '
      res = `ssh-copy-id #{options}-i ~/.ssh/id_rsa.pub #{@name}#{@@suffix}`
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
            @user = user unless @@invalid_users.index(user)
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
      options  = '-o ConnectTimeout=5 ' # in seconds
      # doesn't check RSA fingerprint
      options += '-o UserKnownHostsFile=/dev/null '
      options += '-o StrictHostKeyChecking=no '
      out = `ssh -q #{options}#{@name}#{@@suffix} '#{cmds.join(' ; ')}'`
      # if ssh returned with non-0 exit status
      $?.success? ? out : nil
    end

  end
end
