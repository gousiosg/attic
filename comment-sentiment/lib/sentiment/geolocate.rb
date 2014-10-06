require 'cgi'
require 'open-uri'
require 'json'

module Sentiment

  def user_timezone(login, location)
    @dev_timezones ||= File.open('dev-tz.txt', 'a+').lines.reduce({}) { |acc, l|
      (d, t) = l.split(':')
      acc.merge d => t
    }

    @loc_coords ||= File.open('city-coords.txt', 'a+').lines.reduce({}) { |acc, l|
      (c, lon, lat) = l.split(':')
      acc.merge c => [lon, lat]
    }

    @coord_tz ||= File.open('coord-tz.txt', 'a+').lines.reduce({}) { |acc, l|
      (lon, lat, t) = l.split(':')
      acc.merge [lon, lat] => t
    }

    if location.nil?
      return 0
    end

    unless @dev_timezones.has_key?(login)
      unless @loc_coords.has_key?(location)
        loc = geonames_request("http://api.geonames.org/searchJSON?q=#{CGI.escape(location)}&maxRows=1&username=gousiosg")
        if loc.nil? or loc['geonames'].nil? or loc['geonames'].empty?
          return nil # Cannot geolocate dev location
        end
        city = loc['geonames'][0]
        @loc_coords[location] = [city['lng'], city['lat']]

        File.open('city-coords.txt', 'w') do |file|
          @loc_coords.each do |k, v|
            file.puts "#{k.strip}:#{v[0]}:#{v[1]}"
          end
        end
      end

      coords = @loc_coords[location]

      unless @coord_tz[coords]
        timezone = geonames_request("http://api.geonames.org/timezoneJSON?lat=#{coords[1]}&lng=#{coords[0]}&username=gousiosg")
        if timezone.nil?
          return nil
        end

        @coord_tz[coords] = timezone['rawOffset']

        File.open('coord-tz.txt', 'w') do |file|
          @coord_tz.each do |k, v|
            file.puts "#{k[0]}:#{k[1]}:#{v}"
          end
        end
      end

      @dev_timezones[login] = @coord_tz[@loc_coords[location]]
      File.open('dev-tz.txt', 'w') do |file|
        @dev_timezones.each do |k, v|
          file.puts "#{k}:#{v}"
        end
      end
    end

    @dev_timezones[login]
  end

  def geonames_request(url)

    @req ||= 0
    @hour ||= Time.now.hour

    @req += 1

    if Time.now.hour - @hour > 0
      @req = 0
      @hour = Time.now.hour
    end

    if @req < 2000
      begin
        STDERR.puts "#{url}"
        resp = open(url).read
        json = JSON.parse(resp)
        json
      rescue
        nil
      end
    else
      sleep = 61 - Time.now.min
      @req = 0
      sleep (sleep * 60)
      geonames_request(url)
    end
  end

end

