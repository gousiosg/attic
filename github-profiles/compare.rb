#!/usr/bin/env ruby

require 'mysql2'
require 'digest'

client = Mysql2::Client.new(:host => "127.0.0.1",
                            :username => "root",
                            :password => "george",
                            :database => "ghtorrent")

predictions = File.open(ARGV[0]).readlines
actual = File.open(ARGV[1]).readlines.reduce(Hash.new) do |acc, x|
  (id, dev_hash) = x.split(/,/)
  acc.merge({id => dev_hash})
end

matched = 0
examined = 0
predictions.each do |x|
  examined += 1
  fields = x.split(/,/)
  id = fields[0]

  fields[1..-1].each do |dev|
    q = client.query("select email from users where login='#{dev}'")
    email = q.each(:symbolize_keys => true, :as=>:array){|row| row[0]}
    if email.nil? or email[0].nil?
      next
    end
    md5 = Digest::MD5.hexdigest(email[0][0])
    if md5 == actual[id].strip
      matched += 1
      puts 'matched!'
    end
  end

end

puts "Matched #{matched} out of #{examined} predictions"