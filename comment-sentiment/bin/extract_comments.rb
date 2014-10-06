#!/usr/bin/env ruby

require 'mongo'
require 'ghtorrent'

class ExtractComments < GHTorrent::Command

  include GHTorrent::Persister
  include GHTorrent::Settings

  CURSE = %w(fuck shit bitch bollocks bastard dick)

  def prepare_options(options)

  end

  def validate
    super
  end

  def logger
    @ght.logger
  end

  def db
    @db ||= @ght.get_db
    @db
  end

  def mongo
    @mongo ||= connect(:mongo, settings)
    @mongo
  end


  def ght
    @ght ||= GHTorrent::Mirror.new(settings)
  end

  def go

    processed = found = 0

    mongo.get_underlying_connection[:issues].find({}, {:batch_size => 1000,
                                                       :timeout => false}) do |cursor|
      cursor.each do |i|
        processed += 1

        comments = mongo.get_underlying_connection[:issue_comments].find({
                                         'owner' => i['owner'],
                                         'repo' => i['repo'],
                                         'issue_id' => i['number']},
                                        {:batch_size => 1000}).to_a.sort_by!{|x| x['created_at']}

        found_idx = comments.find_index do |ic|
          comment = ic['body']

          if CURSE.find { |word| comment.downcase.include? word }
            true
          else
            false
          end
        end

        unless found_idx.nil?
          found += 1

          text = comments[0..found_idx].reduce([]) do |acc, ic|
            comment = ic['body'].lines.select { |x|
              not x.start_with? '^'
            }.join(' ')

            comment.gsub!(/\n/, ' ')
            comment.gsub!(/\r/, ' ')
            comment.gsub!(/\t/, ' ')
            comment = "##{ic['id']}##{comment}"
            acc << comment
          end

          print i['owner'], ',', i['repo'], ',', i['number'], ',', text.join('#-#'), "\n"
        end

        STDERR.write "\r #{processed} issues, #{found} curse word comments"
      end
    end
  end

end

ExtractComments.run
