# app.rb

require 'base64'
require 'json'
require 'net/http'
	require 'open-uri'
require 'sinatra'
require 'uri'
require './settings'
require './helpers'
require './controllers'

class ServerControl < Sinatra::Base

	helpers do
		def protected!
			return if authorized?
			headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
			halt 401, "Not authorized\n"
		end

		def authorized?
			@auth ||=  Rack::Auth::Basic::Request.new(request.env)
			@auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [$api_creds['username'], $api_creds['password']]
		end
	end

	# Auth and parameter validation for new stack creation. Criterias and default values are configured in settings.rb.
	before do
		protected!
		content_type 'application/json'
		r = request.body
		unless r.read.to_s.length < 2
			begin
				r.rewind
				@request_payload = JSON.parse r.read
			rescue JSON::ParserError => e
				error = { "error" => e.message }
	            halt 400, {'Content-Type' => 'application/json'}, error.to_json
			end
		end
	end

	# Create stack
	post '/stack' do
	
		begin	
			params = ServerHelpers.validate(@request_payload)
		rescue ArgumentError => e
			error = { "error" => e.message }
			status 400
			body error.to_json
			return
		end

		begin
			stack_details = ServerControllers.create_stack(params)
		rescue StandardError => e
			error = { "error" => e.message }
			status 500
			body error.to_json
			return
		end

		if stack_details['status_message'] == "CREATE_IN_PROGRESS"
			results = {
				"success" => {
					"StackId"		 => stack_details['stack_id'],
					"Status"         => stack_details['status_message'],
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
			status_message = ServerControllers.delete_stack(params[:name])
		rescue StandardError => e
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
        	status_message = client.describe_stacks({ stack_name: stack }).stacks[0].stack_status
		rescue StandardError => e
        	error = { "error" => e.message }
        	status 500
        	body error.to_json
        	return
        end
		success = { "status" => status_message }
        status 200
        body success.to_json
        return
    end

	# Stopping and EC2 instance / Will terminate if instance is in AutoScale group
	patch '/instance/:id/stop' do
		progress = ServerControllers.stop_instance(params[:id])
		status progress["status"]
		body progress["msg"].to_json
		return
	end

# class ServerControl end
end
