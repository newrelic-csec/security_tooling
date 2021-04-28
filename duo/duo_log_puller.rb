require 'time'
require 'openssl'
require 'json'
require 'httparty'
require 'normalize_country'

$NR_ACCOUNT_ID ||= ENV['NR_ACCOUNT_ID']
$HOST ||= ENV['DUO_HOST']
$IKEY ||= ENV['DUO_IKEY']
$SKEY ||= ENV['DUO_SKEY']

$INSIGHTS_INSERT_URL = 'https://insights-collector.newrelic.com/v1/accounts/' + $NR_ACCOUNT_ID +'/events'
$INSIGHTS_INSERT_KEY ||= ENV['INSIGHTS_INSERT_KEY']

def init(*)
  events = pull_duo_logs
  insights_events = []
  events.each do |event|
    insights_events << build_insights_hash(event)
  end
  post_to_insights(insights_events, $INSIGHTS_INSERT_URL, $INSIGHTS_INSERT_KEY)
end

def pull_duo_logs
  puts 'Pulling Duo events...'
  path = '/admin/v1/logs/authentication'
  params = {mintime: Time.now.to_i - 300}
  url = request_url(path, params)
  current_date, signed = sign('GET', url.host, path, params)
  auth = { :username => $IKEY, :password => signed }

  response = HTTParty.get(url, headers: { 'Date' => current_date }, basic_auth: auth)
  events = response.parsed_response['response']

  puts "Pulled #{events.length} Duo events."
  return events
end

def request_url(path, params = nil)
  u = 'https://' + $HOST + path
  u += '?' + encode_params(params) unless params.nil?
  URI.parse(u)
end

def encode_params(params_hash = nil)
  encode_regex = Regexp.new('[^-_.~a-zA-Z\\d]')
  return '' if params_hash.nil?
  params_hash.sort.map do |k, v|
    key = URI.encode(k.to_s, encode_regex)
    value = URI.encode(v.to_s, encode_regex)
    key + '=' + value
  end.join('&')
end

def sign(method, host, path, params, options = {})
  date, canon = canonicalize(method, host, path, params, date: options[:date])
  [date, OpenSSL::HMAC.hexdigest('sha1', $SKEY, canon)]
end

def canonicalize(method, host, path, params, options = {})
  options[:date] ||= time
  canon = [
    options[:date],
    method.upcase,
    host.downcase,
    path,
    encode_params(params)
  ]
  [options[:date], canon.join("\n")]
end

def time
  Time.now.rfc2822
end

def build_insights_hash(event)
  vpn_event = {}
  vpn_event['eventType'] = 'VPNConnection'
  vpn_event['timestamp'] = event['timestamp']
  vpn_event['source'] = 'duo'
  vpn_event['network'] = 'Production'
  vpn_event['browser'] = event['access_device']['browser']
  vpn_event['browserVersion'] = event['access_device']['browser_version']
  vpn_event['flashVersion'] = event['access_device']['flash_version']
  vpn_event['javaVersion'] = event['access_device']['java_version']
  vpn_event['os'] = event['access_device']['os']
  vpn_event['osVersion'] = event['access_device']['os_version']
  vpn_event['device'] = OpenSSL::HMAC.hexdigest('md5',event['device'],'') unless event['device'].nil?# phone number hash
  vpn_event['factor'] = event['factor']
  vpn_event['integration'] = event['integration']
  vpn_event['srcIP'] = event['ip']
  vpn_event['srcCity'] = event['location']['city']
  vpn_event['srcCountry'] = NormalizeCountry(event['location']['country'])
  vpn_event['newEnrollment'] = event['new_enrollment']
  vpn_event['reason'] = event['reason']
  vpn_event['result'] = event['result']
  vpn_event['user'] = event['username']
  return vpn_event
end

def post_to_insights(insights_events, insert_url, insert_key)
  puts "Posting events to #{insert_url}..."
  json_data = JSON.generate(insights_events)
  response = HTTParty.post(insert_url, body: json_data, headers: { 'Content-Type' => 'application/json',
                                                                   'X-Insert-Key' => insert_key })

  puts "Insights returned the response: \"#{response.body}\""
end

init