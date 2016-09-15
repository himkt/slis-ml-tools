# -*- coding: utf-8 -*-

require 'rss'
require 'open-uri'
require 'nokogiri'
require 'date'

require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

BASE_URL = 'http://localhost:4000/'
RSS_URL = BASE_URL + 'feed.xml'
TIMEZONE = 'Asia/Tokyo'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
# APPLICATION_NAME =  # 個人依存
CLIENT_SECRETS_PATH = 'client_secret.json' # 個人依存
CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                             "calendar-ruby-quickstart.yaml")
SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY
CALENDAR_ID = 'かれんだーのURL'

def authorize
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(
    client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(
      base_url: OOB_URI)
    puts "Open the following URL in the browser and enter the " +
         "resulting code after authorization"
    puts url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI)
  end
  credentials
end


# Initialize the API
service = Google::Apis::CalendarV3::CalendarService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

now = DateTime.now


# check?
reserved_dates = service.list_events(CALENDAR_ID,
                               max_results: 10,
                               single_events: true,
                               order_by: 'startTime',
                               time_min: Time.now.iso8601)

update_candidates = {} if results.items.empty?

reserved_dates.items.each do |event|
  puts event.summary
  puts event.start.date_time
end


response = open(url)
rss = Nokogiri::XML(response)
rss.search('item').each do |item|
  start_datetime = DateTime.parse(item.xpath('pubDate').text.gsub('+0000', '+0900'))
  break if now > start_datetime

  event = {start: {}, end: {}}
  event[:start][:date_time] = start_datetime.rfc3339
  event[:start][:timezone] = TIMEZONE

  event[:end][:date_time] = (start_datetime-(1.0/24.0)).rfc3339
  event[:end][:timezone] = TIMEZONE

  event[:summary] =  item.xpath('title').text
  event[:location] = item.xpath('locate').text
  event[:description] = BASE_URL + item.xpath('link').text

  event = Google::Apis::CalendarV3::Event.new(event)
  service.insert_event(CALENDAR_ID, event)
end