require 'socket'
class Server
  def initialize(ip_v4, port)
    @server = TCPServer.new ip_v4, port
    @connections = Hash.new
  end

  def run
    loop do #runs forever
      puts "waiting for client"
      client = @server.accept
      request = client.gets #client's message (one line string?)
      lines = receive(request) # get Hash of ...
      if (!lines.nil?)
        if (lines.key?("Broadcaster") && !lines["Broadcaster"].nil?)
          @connections[lines["Broadcaster"]] = Hash.new
          Thread.start(client) do |client|
            current_user = lines["Broadcaster"].freeze
            begin
              puts "Current User: #{current_user}-----------"
              loop do
                puts 'Waiting on new data---------'
                song_info = client.readpartial(2048)
                song_info = receive song_info
                if (!song_info.nil?)
                  if (song_info.key?("Song_id") && song_info.key?("Duration") && !song_info["Duration"].nil? && !song_info["Song_id"].nil?)
                    @connections[current_user] = ["Song_id" => song_info["Song_id"], "Duration" => song_info["Duration"]]
                    puts @connections[current_user]
                  elsif (song_info.key?("Action") && !song_info["Action"].nil?)
                    @connections[current_user] = ["Song_id" => -1, "Duration" => song_info["Action"]]
                    #@connections.delete(current_user)
                    puts "sayonara"
                  else
                    puts "Bad Song Data"
                  end
                else
                  puts "No Song Data"
                end
              end
            rescue ECONNRESET => e
              e.message
            ensure
              @connections[current_user] = ["Song_id" => -1, "Duration" => -1]
              puts"--------------ensure--------------"
              puts @connections[current_user]

            end
          end
        else
          puts "Bad Broadcaster Data..."
        end
      else
        puts "Broadcaster Data is null"
      end
    end
  end

  def receive(lines)
    info = Hash.new # dictionary
    lines = reorderLines(lines) #move empty lines
    lines.each_line do |line|
      contents = line.strip!.split(":") # strip doesnt do anything here?
      info[contents[0]] = contents[1] # info[ : ]
    end
    return info
  end

  def reorderLines(lines) # remove empty lines
    new_lines = ""
    lines.each_line do |f| #
      if (f.strip!.length == 0 || f.include?("------")) # if line is nil or "------"
        next
      else
        new_lines += f #append line to return variable
        new_lines += "\n"
      end
    end
    return new_lines
  end

  def get_data(user)
    return @connections[user]
  end

  def exists_key?(user)
    puts "#{user.strip!}, #{user.class}------------1"
    puts "#{@connections[user]}-------------2"
    puts @connections
    puts "vs #{user.gsub(" ", "")}"
    if (!@connections.nil?)
      @connections.key?(user.gsub(" ", "")) || @connections.key(user) || @connections.key(user.strip!) ? true : false
    end
  end
end