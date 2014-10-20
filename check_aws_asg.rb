#!/usr/bin/env ruby
require 'rubygems'
require 'aws-sdk'
require 'optparse'

EXIT_CODES = {
  :unknown => 3,
  :critical => 2,
  :warning => 1,
  :ok => 0
}

options =
{
  :debug => false,
  :groups => [],
  :stack => '',
  :tags => []
}

config = { :region => 'us-west-2' }

opt_parser = OptionParser.new do |opt|

  opt.on("--groups group[,group]","which ASG do you wish to report on?") do |groups|
    options[:groups] = groups.split(',')
  end

  opt.on("--stack stack","which stack do you wish to report on?") do |stack|
    options[:stack] = stack
  end

  opt.on("--tags tag,[tag]","which tag(s) do you wish to report on?") do |tags|
    options[:tags] = tags.split(',')
  end

  opt.on("-k","--key key","specify your AWS key ID") do |key|
    (config[:access_key_id] = key) unless key.empty?
  end

  opt.on("-s","--secret secret","specify your AWS secret") do |secret|
    (config[:secret_access_key] = secret) unless secret.empty?
  end
  
  opt.on("--debug","enable debug mode") do
    options[:debug] = true
  end

  opt.on("--region region","which region do you wish to report on?") do |region|
    config[:region] = region
  end

  opt.on("-h","--help","help") do
    puts opt_parser
    exit
  end
end

opt_parser.parse!

raise OptionParser::MissingArgument, 'Missing "--stack" or "--tags"' if (options[:stack].empty? ^ !options[:tags].empty?)
raise OptionParser::MissingArgument, 'Missing "--stack" & "--tags", or "--groups"' if ((options[:stack].empty?) and (options[:groups].empty?))
raise OptionParser::MissingArgument, 'Missing "--secret" or "--key"' if (options[:key] ^ !options[:secret])

if (options[:debug])
  puts 'Options: '+options.inspect
  puts 'Config: '+config.inspect
end

AWS.config(config)
suspended = []

begin
  as = AWS::AutoScaling.new
  stacks = AWS::CloudFormation.new.stacks
  AWS.memoize do
    options[:tags].each do |tag_name|
      options[:groups] << stacks[options[:stack]].resources[tag_name].physical_resource_id
    end
    as.groups.each do |group|
      if (group.suspended_processes['ReplaceUnhealthy'] and options[:groups].include? group.name)
        suspended << group.name
      end
    end
    if (!suspended.empty?)
      puts 'CRIT: ' + suspended.join(',') + ' suspended.'
      exit EXIT_CODES[:critical] unless options[:debug]
    end
  end
rescue SystemExit
  raise
rescue Exception => e  
  puts 'CRIT: Unexpected error: ' + e.message + ' <' + e.backtrace[0] + '>'
  exit EXIT_CODES[:critical]
end  


puts 'OK: The specified ASGs are active.'
exit EXIT_CODES[:ok]
