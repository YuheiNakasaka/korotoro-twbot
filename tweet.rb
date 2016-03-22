# coding: utf-8
require 'yaml'
require 'twitter'
require 'docomoru'

class Bot
  attr_accessor :client, :timeline
  def initialize
    env = YAML.load_file('./config.yml')
    timeline = Twitter::Streaming::Client.new do |config|
      config.consumer_key        = env['consumer_key']
      config.consumer_secret     = env['consumer_secret']
      config.access_token        = env['access_token']
      config.access_token_secret = env['access_token_secret']
    end

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = env['consumer_key']
      config.consumer_secret     = env['consumer_secret']
      config.access_token        = env['access_token']
      config.access_token_secret = env['access_token_secret']
    end

    @timeline = timeline
    @client = client
  end

  def post(msg = '', tw_id: nil, status_id: nil)
    if status_id
      rep_msg = "@#{tw_id} #{msg}"
      @client.update(rep_msg, {in_reply_to_status_id: status_id})
      puts "#{rep_msg}"
    else
      @client.update(msg)
      puts "#{msg}"
    end
  end
end

bot = Bot.new
begin
  bot.client.user_timeline('korotoro', {count: 10}).each do |tl|
    tweet = tl.text
    # Not RT and except reply
    if !tweet.index('RT')
      unless tweet.match(/^@/)
        # tweet which is tweeted until 3 hours ago
        # set cron per 3 hours
        if (Time.now - tl.created_at)/(60*60) < 3
          bot.post(tweet)
          break
        end
      end
    end
  end
rescue => e
  puts "#{Time.now}: #{e} from tweet.rb"
end