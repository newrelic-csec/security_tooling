require 'json'
require 'maxminddb'
require 'httparty'
require 'timezone'
require 'time'

$NR_ACCOUNT_ID ||= ENV['NR_ACCOUNT_ID']
$OKTA_ENDPOINT ||= ENV['OKTA_ENDPOINT']
$PROD_OKTA_ENDPOINT ||= ENV['PROD_OKTA_ENDPOINT']
$OKTA_API_TOKEN ||= 'SSWS ' + ENV['OKTA_API_TOKEN']
$PROD_OKTA_API_TOKEN ||= 'SSWS ' + ENV['PROD_OKTA_API_TOKEN']


$INSIGHTS_INSERT_URL ||= 'https://insights-collector.newrelic.com/v1/accounts/'+ $NR_ACCOUNT_ID +'/events'
$INSIGHTS_INSERT_KEY ||= ENV['INSIGHTS_INSERT_KEY']

$TIME_RANGE_IN_SECONDS = 300




def init(*)
  puts 'test'
  events = pull_okta_logs($OKTA_ENDPOINT, $OKTA_API_TOKEN)
  prod_events = pull_okta_logs($PROD_OKTA_ENDPOINT, $PROD_OKTA_API_TOKEN)
  insights_events = []

  unless events.empty?
    events.each do |event|
      insights_events << build_insights_hash(event, 'okta-environment') 
    end
  end

  unless prod_events.empty?
    prod_events.each do |event|
      insights_events << build_insights_hash(event, 'okta-prod-environment')
    end
  end

  post_to_insights(insights_events, $INSIGHTS_INSERT_URL, $INSIGHTS_INSERT_KEY)
  puts('done')
end

def pull_okta_logs(endpoint, api_token)
  puts 'Pulling Okta events...'
  # This needs to be like 2013-01-01T12:00:00-07:00
  # However, if UTC (+00:00), you need to replace that with Z. 
  since_date = (Time.now - $TIME_RANGE_IN_SECONDS).iso8601.gsub('+00:00', 'Z')
  puts "... since #{since_date}"
  url = URI.parse("https://#{endpoint}/api/v1/logs?limit=1000&since=#{since_date}")
  response = HTTParty.get(url, headers: { 'accept' => 'application/json',
                                          'content-type' => 'application/json',
                                          'authorization' => api_token,
                                          'cache-control' => 'no-cache' })
  events = JSON.parse(response.body)
  puts "Pulled #{events.length} Okta events."
  events
end

def build_insights_hash(okta_event, domain)
  puts "Parsing Okta Event with ID #{okta_event['uuid']}..."
  insights_hash = {}
  begin
    insights_hash['domain'] = domain
    insights_hash['eventType'] = 'OktaEvents'
    insights_hash['uuid'] = okta_event['uuid']
    insights_hash['timestamp'] = Time.parse(okta_event['published']).localtime.to_i
    insights_hash['message'] = okta_event['displayMessage']
    insights_hash['user'] = okta_event['actor']['alternateId'] unless okta_event['actor']['alternateId'].nil? 
    insights_hash['userAgent'] = okta_event['client']['userAgent']
    insights_hash['srcIP'] = okta_event['client']['ipAddress']
    unless okta_event['client']['geographicalContext'].nil?
      insights_hash['srcCountry'] = okta_event['client']['geographicalContext']['country']
      insights_hash['srcCity'] = okta_event['client']['geographicalContext']['city']
    end
    insights_hash['target'] = okta_event['target'][0]['alternateId'] unless okta_event['target'].nil?
    insights_hash['category'] = okta_event['eventType']
    insights_hash['severity'] = okta_event['severity']
    unless okta_event['outcome'].nil?
      insights_hash['outcome'] = okta_event['outcome']['result']
      insights_hash['outcomeReason'] = okta_event['outcome']['reason']
    end


  rescue StandardError => e
    puts "Error parsing event: #{e}"
  end
  insights_hash
end

def post_to_insights(insights_events, insert_url, insert_key)
  puts "Posting events to #{insert_url}..."
  json_data = JSON.generate(insights_events)
  response = HTTParty.post(insert_url, body: json_data, headers: { 'Content-Type' => 'application/json',
                                                                   'X-Insert-Key' => insert_key })

  puts "Insights returned the response: \"#{response.body}\""
end


init