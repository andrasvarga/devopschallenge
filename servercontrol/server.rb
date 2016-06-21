#!/usr/bin/env ruby

require 'aws-sdk'
require 'net/http'
require 'uri'

# Sinatra for future REST API features
# require 'sinatra'

if ARGV[1] == 'i-0cafe358c771f98b2'
	puts "Could not control the Master node itself. Please select an agent instance."
	Kernel.exit
end

# AWS IAM security credentials
Aws.config.update({
	credentials: Aws::Credentials.new('AKIAIQ3FADWZRSFA4IHA', 'XyPswPyQU2bUr3Biw2ISh2x6LRngXhPBmfLiPMEY')
})

# EC2 object based on the region, where the Agent and the Master instances are
ec2 = Aws::EC2::Resource.new(region: 'us-west-2')

# ID of the Puppet Agent instance
i = ec2.instance(ARGV[1])

case ARGV[0]

# Starting the agent node
when "start"
	if i.exists?
	    case i.state.code
	        when 0  # pending
	            puts "Agent is pending, so it will be running in a bit"
	        when 16  # started
	            puts "Agent is already started"
	        when 48  # terminated
	            puts "Agent is terminated, so you cannot start it"
	    else
	        i.start
            puts "Agent is started"
	    end
	end

# Stopping the agent node
when "stop"
	if i.exists?
	    case i.state.code
	        when 48  # terminated
	            puts "Agent is terminated, so you cannot stop it"
	        when 64  # stopping
	            puts "Agent is stopping, so it will be stopped in a bit"
	        when 89  # stopped
	            puts "Agent is already stopped"
	    else
            i.stop
            puts "Agent is stopped"
	    end
	end

# Rebooting the agent node
when "reboot"
    if i.exists?
	    case i.state.code
	        when 48  # terminated
	            puts "Agent is terminated, so you cannot reboot it"
	    else
	        i.reboot
            puts "Agent is rebooting"
	    end
    end

# Testing the Drupal site availability on agent node
when "test"

	uri_temp = "http://" + i.public_dns_name + "/?q=test"

	puts ""		
	puts "Starting drupal test on:"
	puts uri_temp

	uri = URI.parse(uri_temp)

	http = Net::HTTP.new(uri.host, 80)
	request = Net::HTTP::Get.new(uri.to_s)
	response = http.request(request)

	response_lines = response.body.lines.map(&:chomp)

	# output

	puts ""
	puts "Status code: #{response.code}"
	puts ""
	puts "Content (first 10 lines):"
	puts ""
	for i in 0..9
		puts response_lines[i]
	end
	puts ""

else
# Usage info for new users
	puts <<-EOF
Please provide correct command name

Usage:
        server.rb start		- starts the agent node
        server.rb stop		- stops the agent node
        server.rb reboot	- reboots the agent node
        server.rb test		- tests the drupal availability on the agent node
EOF
end
