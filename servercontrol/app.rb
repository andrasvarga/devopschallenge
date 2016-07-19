# app.rb

require 'aws-sdk'
require 'base64'
require 'net/http'
require 'uri'
require 'sinatra'
require 'json'
require './settings'

class ValidationError < StandardError
end

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
		ec2 = Aws::EC2::Resource.new(region: $aws_region)
		return ec2.instance(id)
	end

	# Parameter validation for new stack creation. Criterias and default values are configured in settings.rb.
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
                        			valid_params['ERROR'] = "#{key} is required!"
			                        return valid_params
			                end
				end

				# assign default value if nil
				if raw_params[key].nil? || raw_params[key].empty?
					if param[:default].kind_of?(Array)
	                                	valid_params[key] = param[:default].join(", ")
					else
						valid_params[key] = param[:default].to_s
					end
                                else
					# validate based on type
					case param[:type]
					when "string"
						l = raw_params[key].length
						if l < param[:min]
	                                                valid_params['ERROR'] = "#{key} : #{raw_params[key]} is too short! Minimum length is #{param[:min]}"
        	                                        return valid_params
						elsif l > param[:max]
                                                        valid_params['ERROR'] = "#{key} : #{raw_params[key]} is too long! Maximum length is #{param[:max]}"
                                                        return valid_params
						end
						unless param[:pattern].nil?
							pattern = Regexp.new(param[:pattern]).freeze
							unless raw_params[key] =~ pattern
	                                                        valid_params['ERROR'] = "#{key} : #{raw_params[key]} does not match the pattern: #{param[:pattern]}"
								return valid_params
							end
						end
						valid_params[key] = raw_params[key]
					when "integer"
						i = raw_params[key].to_i
						unless i
                                                        valid_params['ERROR'] = "#{key} : #{raw_params[key]} is not integer!"
                                                        return valid_params
						end

						if i < param[:min]
                                                        valid_params['ERROR'] = "#{key} : #{raw_params[key]} is too small! Minimum is #{param[:min]}"
                                                        return valid_params
                                                elsif  i > param[:max]
                                                        valid_params['ERROR'] = "#{key} : #{raw_params[key]} is too big! Maximum is #{param[:max]}"
                                                        return valid_params
                                                else
							valid_params[key] = raw_params[key]
						end
					when "list"
						raw_params[key].each do |item|
							unless param[:allowed].include? item
								valid_params['ERROR'] = "#{key} : #{j} is not an allowed! Allowed values are: #{param[:allowed]}"
	                                                        return valid_params
							end
						end
						valid_params[key] = raw_params[key].join(", ")
					when "option"
						unless param[:allowed].include? raw_params[key]
                                                        valid_params['ERROR'] = "#{key} : #{raw_params[key]} is not an option! Allowed values are: #{param[:allowed]}"
                                                        return valid_params
						else
							valid_params[key] = raw_params[key]
						end
					else
                                                valid_params['ERROR'] = "Unknown parameter type: #{param[:type]}"
						return valid_params
					end
				end
			end
		end
		return valid_params
	end

	before do
		r = request.body
		unless r.read.to_s.length < 2
			r.rewind
			@request_payload = JSON.parse r.read
		end
	end

	# Create stack
	post '/stack' do
		
		params = validate(@request_payload)

		unless params['ERROR'].nil?
			error = { "error" => params['ERROR'] }
			status 400
			body error.to_json
			return
		end

		begin
			client = Aws::CloudFormation::Client.new( region: $aws_region )

			template = File.open(File.dirname(__FILE__)+'/files/template.json').read

			creation = client.create_stack({
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

			stack_description = client.describe_stacks({ stack_name: creation.stack_id })

			status_message = stack_description.stacks[0].stack_status

		rescue RuntimeError => e
			error = { "error" => e.message }
			status 500
			body error.to_json
			return
		end

		if status_message == "CREATE_IN_PROGRESS"
			results = {
				"success" => {
					"StackId"	 => creation.stack_id,
					"Status"         => status_message,
					"DrupalUsername" => params['DrupalUser'],
					"DrupalPassword" => params['DrupalPassword']
				}
			}
			status 200
			body results.to_json
			return
		else
			error = { "error" => status_message }
			status 500
			body error.to_json
			return
		end
	end

	# Detele stack
	delete '/stack/:name' do
		if params[:name].nil?
			status 400
			body "No stack name given"
			return
		end
		
		begin
			stack = params[:name]
			client = Aws::CloudFormation::Client.new( region: $aws_region )
			deletion = client.delete_stack({ stack_name: stack })
			stack_description = client.describe_stacks({ stack_name: stack })
                        status_message = stack_description.stacks[0].stack_status
		rescue RuntimeError => e
			error = { "error" => e.message }
			status 500
			body error.to_json
			return
		end
		
		if status_message == "DELETE_IN_PROGRESS"
			results = { "success" => status_message }
			status 200
			body results.to_json
			return
		else
			error = { "error" => status_message }
			status 500
			body error.to_json
			return
		end
	end

	# Get Stack status
	get '/stack/:name' do
		if params[:name].nil?
                        status 400
                        body "No stack name given"
                        return
                end

                begin
                        stack = params[:name]
                        client = Aws::CloudFormation::Client.new( region: $aws_region )
                        stack_description = client.describe_stacks({ stack_name: stack })
                rescue RuntimeError => e
                        error = { "error" => e.message }
                        status 500
                        body error.to_json
                        return
                end
                status 200
                body stack_description.stack[0].to_json
                return
        end
	
	# Starting EC2 instance
	patch '/instance/:id/start' do
		self_check( params[:id] )
		i = get_instance( params[:id] )
		if i.exists?
		    case i.state.code
		        when 0  # pending
				msg = { "error" => "Agent is pending, so it will be running in a bit" }
				status 400
		        when 16  # started
				msg = { "error" => "Agent is already started" }
				status 400
	        	when 48  # terminated
				msg = { "error" => "Agent is terminated, so you cannot start it" }
	        		status 400	
		        else
	        		i.start
				if i.state.code == 16
					msg = { "success" => "Instance is started" }
		        		status 200
				else
					msg = { "error" => "Instance state code: #{i.state.code}" }
					status 500
				end
		    end
		else
			msg = { "error" => "Instance not found" }
			status 404
		end
		body msg.to_json
		return
	end

	# Stopping and EC2 instance
	patch '/instance/:id/stop' do
		self_check( params[:id] )
		i = get_instance( params[:id] )
		if i.exists?
		    case i.state.code
		        when 48  # terminated
	        		msg = { "error" => "Agent is terminated, so you cannot stop it" }
				status 400
		        when 64  # stopping
		        	msg = { "error" => "Agent is stopping, so it will be stopped in a bit" }
				status 400
		        when 89  # stopped
		        	msg = { "error" =>  "Agent is already stopped" }
		        	status 400
		    	else
        	    		i.stop
        	    		if i.state.code == 64
					msg = { "success" => "Agent is stopping" }
					status 200
				else
					msg = { "error" => "Instance state code: #{i.state.code}" }
					status 500
				end
		    end
		else	
			msg = { "error" => "Instance not found" }
			status 404
		end
		body msg.to_json
		return
	end

	# Testing the Drupal site availability on agent node
 	get '/stack/:name/test' do
		if params[:name].nil?
                        status 400
                        body "No stack name given"
                        return
                end

                begin
                        stack = params[:name]
                        client = Aws::CloudFormation::Client.new( region: $aws_region )
                        stack_description = client.describe_stacks({ stack_name: stack })
			uri_temp = stack_description.stacks[0].outputs[0].output_value
                rescue RuntimeError => e
                        error = { "error" => e.message }
                        status 500
                        body error.to_json
                        return
                end
 
 		uri = URI.parse(uri_temp)

		if uri 
	 		http = Net::HTTP.new(uri.host, 80)
 			request = Net::HTTP::Get.new(uri.to_s)
 			response = http.request(request)
	 		response_lines = response.body.lines.map(&:chomp)

	 		msg = { "content" => response_lines[0..9] }
			status response.code
		else
			msg = { "error" => "Output URI isn ot valid" }
			status 500
		end
		body msg.to_json
		return
 	end

# class ServerControl end
end
