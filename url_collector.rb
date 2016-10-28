#!/usr/bin/ruby
# require './db_test.rb'
require 'link_thumbnailer'
require 'slack-ruby-client'
require 'uri'
require 'pg'
require 'active_record'
require './config.rb'
# connect to database
ActiveRecord::Base.establish_connection(:adapter=>CONFIG_INFO::INFO['adapter'],
  :host => CONFIG_INFO::INFO['host'],
  :username => CONFIG_INFO::INFO['username'],
  :password => CONFIG_INFO::INFO['password'],
  :database => CONFIG_INFO::INFO['database'])

# create url class for talking to the db
class Url < ActiveRecord::Base
end
# configure slack client
Slack.configure do |config|
  config.token = CONFIG_INFO::INFO['token']

end
client = Slack::RealTime::Client.new
web_client = Slack::Web::Client.new

# successfully connected
client.on :hello do
  puts "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."
end
# i=0
# web_client.channels_info(channel: 'C2SAJSQBT').each do |channel|
#   if i == 1
#     channel_name = channel[1]["name"]
#   end
#   i += 1
# end
# puts channel_name

# handle message
client.on :message do |data|
  urls = URI.extract(data.text, ['http', 'https'])
  puts urls
  urls.each do |url|
    object = LinkThumbnailer.generate(url)
    # remove '/' in the beginning of image path
    object.favicon[0] = ''
    # get the channel name
    i=0
    channel_name = ""
    begin
      web_client.channels_info(channel: data.channel).each do |channel|
        if i == 1
          channel_name = channel[1]["name"]
        end
        i += 1
      end
      puts channel_name
    rescue Slack::Web::Api::Error
      channel_name = 'direct message'
    end

    Url.create(url: url, channel: channel_name, channel_id: data.channel,title: object.title,
      description: object.description, image: url+object.favicon,
      shared_at: Time.now.strftime("%Y-%m-%d %H:%M:%S"))
    puts "url stored"
  end
end

# close connection
client.on :close do |_data|
  puts "Client is about to disconnect"
end

client.on :closed do |_data|
  puts "Client has disconnected successfully!"
end

client.start!
