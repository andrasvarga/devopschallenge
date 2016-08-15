# helpers.rb

class ServerHelpers

    def self.self_check(id)
		# getting the instance ID for this server
		metadata_endpoint = 'http://169.254.169.254/latest/meta-data/'
		self_id = Net::HTTP.get( URI.parse( metadata_endpoint + 'instance-id' ) )
		if id == self_id
	        raise ArgumentError.new("Error: Could not control the Master node itself. Please select an agent instance.")		      
		end
	end

	def self.get_instance(id)
		ec2 = Aws::EC2::Resource.new(region: $aws_region)
		return ec2.instance(id)
	end

    def self.validate(raw_params)

		defaults = Marshal.load( Marshal.dump($params_config) )
        valid_params = Hash.new

		defaults.each do |key,param|

			if param[:type] == 'novalidate'
				next
			else
				# check if required
				if param[:required] && raw_params[key].nil?
                    raise ArgumentError.new("#{key} is required!")
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
	                    	raise ArgumentError.new("#{key} : #{raw_params[key]} is too short! Minimum length is #{param[:min]}")
						elsif l > param[:max]
                        	raise ArgumentError.new("#{key} : #{raw_params[key]} is too long! Maximum length is #{param[:max]}")
						end
						unless param[:pattern].nil?
							pattern = Regexp.new(param[:pattern]).freeze
							unless raw_params[key] =~ pattern
	                        	raise ArgumentError.new("#{key} : #{raw_params[key]} does not match the pattern: #{param[:pattern]}")
							end
						end
						valid_params[key] = raw_params[key]
					when "integer"
						i = raw_params[key].to_i
						unless i
                        	raise ArgumentError.new("#{key} : #{raw_params[key]} is not integer!")
						end

						if i < param[:min]
                        	raise ArgumentError.new("#{key} : #{raw_params[key]} is too small! Minimum is #{param[:min]}")
                        elsif  i > param[:max]
                        	raise ArgumentError.new("#{key} : #{raw_params[key]} is too big! Maximum is #{param[:max]}")
                        else
							valid_params[key] = raw_params[key]
						end
					when "list"
						raw_params[key].each do |item|
							unless param[:allowed].include? item
								raise ArgumentError.new("#{key} : #{j} is not an allowed! Allowed values are: #{param[:allowed]}")
							end
						end
						valid_params[key] = raw_params[key].join(", ")
					when "option"
						unless param[:allowed].include? raw_params[key]
                        	raise ArgumentError.new("#{key} : #{raw_params[key]} is not an option! Allowed values are: #{param[:allowed]}")
						else
							valid_params[key] = raw_params[key]
						end
					else
                    	raise ArgumentError.new("Unknown parameter type: #{param[:type]}")
					end
				end
			end
		end
		return valid_params
	end
    
end