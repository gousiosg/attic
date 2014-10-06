#!/usr/bin/env ruby

require 'rubygems'
require 'ghtorrent'
require 'cgi'
require 'open-uri'
require 'json'

require 'sentiment'

class CommentFeatures < GHTorrent::Command

  include GHTorrent::Persister
  include GHTorrent::Settings
  include Sentiment

  def prepare_options(options)
    options.banner <<-BANNER
Extract features for all sentiment across all pull requests

#{command_name} owner repo lang

    BANNER
    options.opt :extract_diffs,
                'Extract file diffs for modified files'
    options.opt :diff_dir,
                'Base directory to store file diffs', :default => "diffs"
  end

  def validate
    super
    Trollop::die "Three arguments required" unless !args[2].nil?
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

    p   'link,owner,project,lang,commenter,time,order,' <<
        'mentions_dev,has_quote' <<
        'emot_smile,emot_lol,emot_frown,emot_dev' <<
        'emoji_plusone,emoji_' <<
        'num_expl_marks,num_full_stops' <<
        'fuck,shit,crap,bitch,bollocks,bastard,dick'

    comments = %w(pull_request_comments issue_comments)
    comments.each do |table|
      db[table].find({},{}).each do |c|
        p link(c),',' <<
          owner(c),','<<
          repo(c),','<<
          lang(c),','<<
          commenter(c),','<<
          timeofday(c),',' <<
          order(c),',' <<
          mentions(c),',' <<
          quotes(c),','
      end
    end
  end

  def link(comment)
    comment['_links']['self']['html']
  end

  def owner(comment)
    comment['url'].split('/')[4]
  end

  def repo(comment)
    comment['url'].split('/')[5]
  end

  def lang(comment)
    q = <<-QUERY
      select p.language as lang
      from projects p, users u
      where u.id = p.owner_id
        and p.name =
        and u.name = #{owner(comment)}
    QUERY
    if_empty(db.fetch(q, repo(comment), owner(comment)).all, :lang)
  end

  def commenter(comment)
    comment['user']['login']
  end

  def timeofday(comment)
    t = Time.at(comment['created_at'])

    q = <<-QUERY
      select p.language as lang
      from projects p, users u
      where u.id = p.owner_id
        and p.name =
        and u.name = #{owner(comment)}
    QUERY
    if_empty(db.fetch(q, repo(comment), owner(comment)).all, :lang)

    tz = user_timezone()
  end

  def order(comment)

  end

  def mentions(comment)

  end

  def quotes(comment)

  end

  def emoji(body)

  end

  private

  def if_empty(result, field)
    if result.nil? or result.empty?
      0
    else
      result[field]
    end
  end




end

CommentFeatures.run
#vim: set filetype=ruby expandtab tabstop=2 shiftwidth=2 autoindent smartindent: