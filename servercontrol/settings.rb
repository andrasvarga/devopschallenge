# settings.rb
	
	$aws_region = "eu-central-1"
	
	$params_config = {
                'ERROR'              => {
			:type    => "novalidate",
			:default => false
		},
                'ERROR_MESSAGE'      => {
			:type	 => "novalidate",
			:default => nil
		},
                'stackName'          => {
			:type	 => "string",
			:default => "NewStack",
			:min	 => 1,
			:max	 => 16,
			:pattern => "[a-zA-Z0-9]*",
			:required => true
		},
                'VpcId'              => {
			:type    => "string",
			:default => "vpc-4a1a2b23",
			:min	 => 12,
			:max	 => 12,
			:begin	 => {
				:length => 4,
				:string => "vpc-"
			}
		},
                'Subnets'            => {
			:type	 => "list",
			:default => [ "subnet-7a7a6013", "subnet-b72f1fcc" ],
			:min	 => 15,
			:max	 => 15,
			:begin	 => {
				:length => 7,
				:string => "subnet-"
			},
			:allowed => [ "subnet-7a7a6013", "subnet-b72f1fcc" ]
		},
                'AZs'                => {
			:type	 => "list",
			:default => [ "eu-central-1a", "eu-central-1b" ],
			:allowed => [ "eu-central-1a", "eu-central-1b" ]
		},
                'KeyName'            => {
			:type	 => "string",
			:default => "instance-access-key",
			:min	 => 1,
			:max	 => 64
		},
                'SSHLocation'        => {
			:type	 => "string",
			:default => "0.0.0.0/0",
			:min	 => 9,
			:max	 => 18,
			:pattern => "(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})"
		},
                'InstanceType'       => {
			:type	 => "option",
			:default => "t2.micro",
			:allowed => [ "t1.micro", "t2.nano", "t2.micro", "t2.small", "t2.medium", "t2.large", "m1.small", "m1.medium", "m1.large", "m1.xlarge", "m2.xlarge", "m2.2xlarge", "m2.4xlarge", "m3.medium", "m3.large", "m3.xlarge", "m3.2xlarge", "m4.large", "m4.xlarge", "m4.2xlarge", "m4.4xlarge", "m4.10xlarge", "c1.medium", "c1.xlarge", "c3.large", "c3.xlarge", "c3.2xlarge", "c3.4xlarge", "c3.8xlarge", "c4.large", "c4.xlarge", "c4.2xlarge", "c4.4xlarge", "c4.8xlarge", "g2.2xlarge", "g2.8xlarge", "r3.large", "r3.xlarge", "r3.2xlarge", "r3.4xlarge", "r3.8xlarge", "i2.xlarge", "i2.2xlarge", "i2.4xlarge", "i2.8xlarge", "d2.xlarge", "d2.2xlarge", "d2.4xlarge", "d2.8xlarge", "hi1.4xlarge", "hs1.8xlarge", "cr1.8xlarge", "cc2.8xlarge", "cg1.4xlarge" ]
		},
                'InstanceCount'      => {
			:type	 => "integer",
			:default => 2,
			:min	 => 2,
			:max	 => 20
		},
                'DBName'             => {
			:type    => "string",
			:default => 'drupal',
			:min	 => 1,
			:max	 => 64,
			:pattern => "[a-zA-Z][a-zA-Z0-9]*"
		},
                'DBUser'             => {
			:type    => "string",
			:default => 'drupal',
			:min	 => 1,
			:max	 => 16,
			:pattern => "[a-zA-Z][a-zA-Z0-9]*"
		},
                'DBPassword'         => {
			:type    => "string",
			:default => Array.new(8){[*"a".."z", *"0".."9"].sample}.join,
			:min	 => 8,
			:max	 => 41,
			:pattern => "[a-zA-Z0-9]*"
		},
                'DBAllocatedStorage' => {
			:type    => "integer",
			:default => 5,
			:min	 => 5,
			:max	 => 1024
		},
                'DBInstanceClass'    => {
			:type    => "option",
			:default => "db.t2.micro",
			:allowed => [ "db.t1.micro", "db.m1.small", "db.m1.medium", "db.m1.large", "db.m1.xlarge", "db.m2.xlarge", "db.m2.2xlarge", "db.m2.4xlarge", "db.m3.medium", "db.m3.large", "db.m3.xlarge", "db.m3.2xlarge", "db.m4.large", "db.m4.xlarge", "db.m4.2xlarge", "db.m4.4xlarge", "db.m4.10xlarge", "db.r3.large", "db.r3.xlarge", "db.r3.2xlarge", "db.r3.4xlarge", "db.r3.8xlarge", "db.m2.xlarge", "db.m2.2xlarge", "db.m2.4xlarge", "db.cr1.8xlarge", "db.t2.micro", "db.t2.small", "db.t2.medium", "db.t2.large"]
		},
                'MultiAZDatabase'    => {
			:type    => "option",
			:default => "false",
			:allowed => [ "true", "false" ]
		},
                'DrupalUser'         => {
			:type    => "string",
			:default => "admin",
			:min	 => 1,
			:max	 => 16,
			:pattern => "[a-zA-Z][a-zA-Z0-9]*"
		},
        	'DrupalPassword'     => {
			:type    => "string",
			:default => Array.new(8){[*"a".."z", *"0".."9"].sample}.join,
			:min	 => 8,
			:max	 => 41,
			:pattern => "[a-zA-Z0-9]*"
		}
	}
