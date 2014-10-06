require 'sentiment'

include Sentiment

File.open(ARGV[0]).each do |l|
  dev, loc = l.split(/:/)

  unless Sentiment::user_timezone(dev, loc).nil?
    puts "#{dev} #{loc.strip} #{Sentiment::user_timezone(dev, loc)}"
  end

end
