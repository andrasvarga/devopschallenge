# app.rb

require 'aws-sdk'
require 'base64'
require 'net/http'
require 'uri'
require 'sinatra'
require 'json'
require './settings'

class ServerControl < Sinatra::Base

	def self_check(id)
		# getting the instance ID for this server
		metadata_endpoint = 'http://169.254.169.254/latest/meta-data/'
		self_id = Net::HTTP.get( URI.parse( metadata_endpoint + 'instance-id' ) )
		if id == self_id
		        return "Error: Could not control the Master node itself. Please select an agent instance."		      
		end
	end

	def get_instance(id)
		ec2 = Aws::EC2::Resource.new(region: 'eu-central-1')
		return ec2.instance(id)
	end

	def validate(raw_params)

		defaults = Marshal.load( Marshal.dump($params_config) )
                valid_params = Hash.new

		
		defaults.each do |key,param|
			if param[:type] == 'novalidate'
				next
			else
				# check if required
				if param[:required]
					if raw_params[key].nil? || raw_params[key].empty?
			                        valid_params['ERROR'] = true
                        			valid_params['ERROR_MESSAGE'] = "#{key} is required!"
			                        return
			                end
				end

				# assign default value if nil
				if raw_params[key].nil? || raw_params[key].empty?
                                                valid_params[key] = param[:default].to_s
                                else
					# validate based on type
					case param[:type]
					when "string"
						l = raw_params[key].length
						if l < param[:min]
							valid_params['ERROR'] = true
	                                                valid_params['ERROR_MESSAGE'] = "#{key} is too short! Minimum length is #{param[:min]}"
        	                                        return
						end
						
						if l > param[:max]
							valid_params['ERROR'] = true
                                                        valid_params['ERROR_MESSAGE'] = "#{key} is too long! Maximum length is #{param[:max]}"
                                                        return
						end

						unless param[:pattern].nil?
							pattern = Regexp.new(param[:pattern]).freeze
							unless raw_params[key] =~ pattern
								valid_params['ERROR'] = true
	                                                        valid_params['ERROR_MESSAGE'] = "#{key} does not match the pattern!"
								return
							end
						end
					when "integer"
						if raw_params[key] < param[:min]
                                                        valid_params['ERROR'] = true
                                                        valid_params['ERROR_MESSAGE'] = "#{key} is too small! Minimum is #{param[:min]}"
                                                        return
                                                elsif  raw_params[key] > param[:max]
                                                        valid_params['ERROR'] = true
                                                        valid_params['ERROR_MESSAGE'] = "#{key} is too big! Maximum is #{param[:max]}"
                                                        return
                                                else
							valid_params[key] = raw_params[key]
						end
					when "list"
						# multiple params
					when "option"
						unless param[:allowed].include? raw_params[key]
							valid_params['ERROR'] = true
                                                        valid_params['ERROR_MESSAGE'] = "#{key} is not an option! Allowed values are: #{param[:allowed]}"
                                                        return
						else
							valid_params[key] = raw_params[key]
						end
					else
						valid_params['ERROR'] = true
                                                valid_params['ERROR_MESSAGE'] = "Unknown parameter type: #{param[:type]}"
						return
					end
				end
			end
		end
	end

	before do
		request.body.rewind
		@request_payload = JSON.parse request.body.read
	end

	# Launching a stack
	post '/stack' do
		
		params = validate(@request_payload)

		if params['ERROR']
			status 400
			body params['ERROR_MESSAGE']
		end

		cloudformation = Aws::CloudFormation::Client.new(
			region: $aws_region
		)

		template = File.open(File.dirname(__FILE__)+'/files/template.json').read

		creation = cloudformation.create_stack({
			stack_name: params['stackName'],
			template_body: template,
			parameters: [
			  { parameter_key: "VpcId", 		 parameter_value: params['VpcId'] },
			  { parameter_key: "Subnets", 		 parameter_value: params['Subnets'] },
			  { parameter_key: "AZs",		 parameter_value: params['AZs'] },
			  { parameter_key: "KeyName",	 	 parameter_value: params['KeyName'] },
			  { parameter_key: "SSHLocation",	 parameter_value: params['SSHLocation'] },
			  { parameter_key: "InstanceType",	 parameter_value: params['InstanceType'] },
			  { parameter_key: "InstanceCount",	 parameter_value: params['InstanceCount'] },
			  { parameter_key: "DBName",		 parameter_value: params['DBName'] },
			  { parameter_key: "DBUser",		 parameter_value: params['DBUser'] },
			  { parameter_key: "DBPassword",         parameter_value: params['DBPassword'] },
			  { parameter_key: "DBAllocatedStorage", parameter_value: params['DBAllocatedStorage'] },
			  { parameter_key: "DBInstanceClass",    parameter_value: params['DBInstanceClass'] },
			  { parameter_key: "MultiAZDatabase",	 parameter_value: params['MultiAZDatabase'] },
			  { parameter_key: "DrupalUser",	 parameter_value: params['DrupalUser'] },
			  { parameter_key: "DrupalPassword",	 parameter_value: params['DrupalPassword'] }
			],
			capabilities: ["CAPABILITY_IAM"],
			on_failure: "ROLLBACK"
		})



		return
	end
	
	# Starting an EC2 instance
	patch '/instance/:id/start' do
		self_check( params[:id] )
		i = get_instance( params[:id] )
		if i.exists?
		    case i.state.code
		        when 0  # pending
	        	    return "Agent is pending, so it will be running in a bit"
		        when 16  # started
		            return "Agent is already started"
	        	when 48  # terminated
		            return "Agent is terminated, so you cannot start it"
		    else
	        	i.start
			return "Agent is started"
		    end
		end
	end

	# Stopping and EC2 instance
	patch '/instance/:id/stop' do
		self_check( params[:id] )
		i = get_instance( params[:id] )
		if i.exists?
		    case i.state.code
		        when 48  # terminated
	        	    return "Agent is terminated, so you cannot stop it"
		        when 64  # stopping
		            return "Agent is stopping, so it will be stopped in a bit"
		        when 89  # stopped
		            return "Agent is already stopped"
		    else
        	    i.stop
	            return "Agent is stopped"
		    end
		else
			return 404
		end
	end

	# Rebooting the agent node
	patch '/instance/:id/reboot' do
	    self_check( params[:id] )
	    i = get_instance( params[:id] )
	    if i.exists?
		    case i.state.code
	        	when 48  # terminated
		            return "Agent is terminated, so you cannot reboot it"
		    	else
			    i.reboot
		            return "Agent is rebooting"
		    end
	    else
		return 404
	    end
	end

	# Terminate
#	delete '/instance/:id' do
#		self_check( params[:id] )
#		i = get_instance( params[:id] )
#		if i.exists?
#		case i.state.code
#			when 48  # terminated
#				puts "#{id} is already terminated"
#			else
#				i.terminate
#			end
#		end
#	end

	# Testing the Drupal site availability on agent node
	get '/test/:id' do
		self_check( params[:id] )
		i = get_instance( params[:id] )
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
	end

	# Getting info about the API
	get '/info' do
		return "Hello World".to_json
	end

# class ServerControl end
end