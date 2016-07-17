### devopschallenge

DevOps Challenge: API
=====================

API endpoint:

        http://ec2-52-28-111-63.eu-central-1.compute.amazonaws.com:9292/

Create new stack
----------------

Request:

	POST
	http://ec2-52-28-111-63.eu-central-1.compute.amazonaws.com:9292/stack
	
	{
		"stackName"		: "" // REQUIRED! The name of the stack to create
		"VpcId"			: "" // AWS Virtual Private Cloud ID
		"Subnets"		: [] // List of AWS subnets
		"AZs"			: [] // List of AZs
		"KeyName"		: ""		 // Key name for SSH access
		"SSHLocation"		: "0.0.0.0/0",	 // SSH access source CIDR
		"InstanceType"		: "t2.micro",	 // Type of EC2 instances in AutoScaling
		"InstanceCount"		: "2",		 // Desired number of working EC2 instances in AutoScaling
		"DBName"		: "drupal",	 // RDS Database name
		"DBUser"		: "drupal",	 // RDS Database username
		"DBPassword"		: "",		 // RDS Database passwod (generated if empty)
		"DBAllocatedStorage"	: "5",		 // RDS instance storage size in GB
		"DBInstanceClass"	: "db.t2.micro", // RDS instance type
		"MultiAZDatabase"	: "false",	 // RDS Multi-AZ mode
		"DrupalUser"		: "admin",	 // Drupal administrator user name
		"DrupalPassword		: ""		 // Drupal administrator password (generated if empty)
	}

Delete stack
------------

Request:

	DELETE
	http://ec2-52-28-111-63.eu-central-1.compute.amazonaws.com:9292/stack/{id}
