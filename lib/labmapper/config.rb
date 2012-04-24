module Labmapper
  class Config
    class << self

      def configure_with_options(opts={})
        @configured = @parsed = false
        @ext        = opts[:ext]    || 'labrc'
        @valids     = opts[:valids] || /[0-9a-zA-Z\ ]/
        @dirs       = /[\^v><]/
        @alphabet   = [(0..9), ('a'..'z'), ('A'..'Z')].map(&:to_a).reduce(&:+).join
        @re = /^(?<re>[#{@valids}\-\*]*)\|(?<dir>#{@dirs})?(?<id>#.*)?(?<classes>\..*)*$/
        # TODO handle multiple rc files in same dir?
        @fname = Dir[File.join(File.dirname(__FILE__), "../../*.#{@ext}")][0]
        if @fname.nil?
          raise 'Could not find Labmapper config file in root directory'
        end
        @configured = true
      end

      def readlines(fname)
        @lines = []
        # TODO handle too large of file
        File.open(fname, 'r') do |file|
          @lines = file.read.split("\n")
        end
      end

      def parse(opts={})
        configure_with_options(opts) unless @configured
        readlines(@fname)
        @parsed = false
        @tokens = {}
        @lines.each do |line|
          if m = line.match(/^= (?<title>.*)$/)
            @title = m[:title]
          elsif m = line.match(@re)
            id = m[:id] ? m[:id][1..-1] : m[:re]
            classes = m[:classes] ? m[:classes].split('.')[1..-1] : []
            dir = {'^' => 'up', '>' => 'right', 'v' => 'down', '<' => 'left'}[m[:dir]]
            @tokens[m[:re]] = {id: id, dir: dir, classes: classes}
          end
        end
        @tokens.dup.each do |kcopy, vcopy|
          # for all non-single token, 'pop' them from hash and ...
          # apply them to relevants
          unless kcopy.match(/^#{@valids}$/)
            @tokens.delete(kcopy)
            # let each item in @tokens inherit from @tokens['*']
            if kcopy == '*'
              @tokens.each do |k, v|
                v[:dir] = vcopy[:dir] unless v[:dir]
                v[:classes] |= vcopy[:classes]
              end
            else
              # create new tokens that aren't explicitely named
              sub_tokens = {}
              more_tokens = alphabet.scan(/[#{kcopy}]/)
              more_tokens.each do |token|
                sub_tokens[token] = vcopy.merge(id: token)
              end
              @tokens = sub_tokens.merge(@tokens)
              @tokens[' '] = nil # empty block -- TODO handle better
            end
          end
        end
        @parsed = true
      end

      def title
        parse # unless @parsed
        puts "== #{@title} =="
        @title
      end

      def hosts
        parse # unless @parsed
        @tokens.map {|k,v| v[:id].to_sym if k != v[:id]}.compact
      end

      def to_haml(force=false)
        parse # unless @parsed
        return @haml unless @haml.nil? || force
        haml  = "- availability = lambda {|n| hosts[n] ? (hosts[n]['nossh'] "
        haml += "? ' nossh' : (hosts[n]['user'] "
        haml += "? ' occupied' : ' available')) : nil}\n"
        haml += "- uptime = lambda {|n| hosts[n] && hosts[n]['uptime']}\n"
        haml += "%table{cellpadding: 0}\n"
        @lines.each do |line|
          m = line.match(/^;(#{@valids}*)\|?(\..*)*$/)
          if m
            haml += '  %tr'
            toks, classes = m[1], m[2].split('.')[1..-1]
            haml += '.' + classes.join('.') unless classes.empty?
            haml += "\n"
            toks.chars.each do |t|
              if @tokens[t]
                haml += "    %td{id: \"#{@tokens[t][:id]}\", "
                haml += "class: \"#{@tokens[t][:classes].join(' ')}"
                haml += "\#{availability.call('#{@tokens[t][:id]}')} "
                haml += "#{@tokens[t][:dir]}\"}\n"
                haml += "      %span{class: \"uptime hidden\"}= "
                haml += "\"\#{uptime.call('#{@tokens[t][:id]}')}\"\n"
              else
                haml += "    %td\n"
              end
            end
          end
        end
        @haml = haml # TODO why am i caching?
      end

    end
  end
end
