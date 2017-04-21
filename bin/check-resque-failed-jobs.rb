#! /usr/bin/env ruby
require 'sensu-plugin/check/cli'
require 'uri'
require 'net/https'
require 'json'

class CheckResqueFailedJobs < Sensu::Plugin::Check::CLI

  check_name 'check_resque_failed_jobs'

  option :url,
         short: '-u URL',
         long: '--url URL',
         description: 'Resque URL',
         required: true

  option :host_header,
         short: '-H HOST',
         long: '--http-header HOST',
         description: 'Resque URL HTTP Host header',
         required: false

  option :threshold,
         short: '-t THRESHOLD',
         long: '--threshold THRESHOLD',
         description: 'Threshold',
         default: 0

  option :user,
         short: '-U USER',
         long: '--user USER',
         description: 'Basic Auth user'

  option :password,
         short: '-p PASSWORD',
         long: '--password PASSWORD',
         description: 'Basic Auth password'

  def run
    response = get_response
    raise RuntimeError, "#{response.class}" unless response.is_a?(Net::HTTPSuccess)

    json = JSON.parse(response.body)
    errors = json.select { |_,v| v.to_i > config[:threshold] }

    (errors.empty? ? ok : warning(errors_to_string(errors)))
  end

  def errors_to_string(errors)
    errors.map { |k,v| "#{k}: #{v}" }.join(', ')
  end

  def get_response
    uri = URI(config[:url])

    req = Net::HTTP::Get.new(uri).tap do |r|
      r['Host'] = config[:host_header] if config[:host_header]
      r.basic_auth config[:user], config[:password] if config[:user] && config[:password]
    end

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
      http.request(req)
    end
  end
end
