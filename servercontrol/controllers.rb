# controllers.rb

require 'aws-sdk'

class ServerControllers

    def self.create_stack(params)
        	client = Aws::CloudFormation::Client.new( region: $aws_region )
			template = File.open(File.dirname(__FILE__)+'/files/template.json').read
			creation = client.create_stack({
				stack_name: params['stackName'],
				template_body: template,
				parameters: [
				  { parameter_key: "SiteName",           parameter_value: params['SiteName'] },
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
				  { parameter_key: "DrupalPassword",	 parameter_value: params['DrupalPassword'] },
				  { parameter_key: "DrupalSalt",         parameter_value: params['DrupalSalt'] }
				],
				capabilities: ["CAPABILITY_IAM"],
				on_failure: "ROLLBACK"
			})
			stack_description = client.describe_stacks({ stack_name: creation.stack_id })
			status_message = stack_description.stacks[0].stack_status

			stack_details = {
				'status_message' => status_message,
				'stack_id'		 => creation.stack_id 
			}

            return stack_details
    end

    def read
    end

    def self.delete_stack(stack)
		client = Aws::CloudFormation::Client.new( region: $aws_region )
		deletion = client.delete_stack({ stack_name: stack })
		status_message = client.describe_stacks({ stack_name: stack }).stacks[0].stack_status
		return status_message
    end

	def self.stop_instance(id)
		self_check( id )
		i = get_instance( id )
		if i.exists?
		    case i.state.code
		        when 48  # terminated
	        		progress = {
						'msg'	 => { "error" => "Agent is terminated, so you cannot stop it" },
						'status' => 400
					}
		        when 64  # stopping
		        	progress = {
						'msg'	 => { "error" => "Agent is stopping, so it will be stopped in a bit" },
						'status' => 400
					}
		        when 89  # stopped
		        	progress = {
						'msg'	 => { "error" =>  "Agent is already stopped" },
		        		'status' => 400
					}
		    else
        	    i.stop
				ec2 = Aws::EC2::Resource.new(region: $aws_region)
				ec2.client.wait_until(:instance_stopped, {instance_ids: [i.id]})
        	    if i.state.code == 32 || i.state.code == 64
					progress = {
						'msg'	 => { "success" => "Agent is stopping" },
						'status' => 200
					}
				else
					progress = {
						'msg'	 => { "error" => "Instance state code: #{i.state.code}" },
						'status' => 500
					}
				end
		    end
		else	
			progress = {
				'msg'	 => { "error" => "Instance not found" },
				'status' => 404
			}
		end
		return progress
	end

end