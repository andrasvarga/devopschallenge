### devopschallenge

DevOps Challenge: Puppet Master
===============================

This guide describes how to create a production-ready Drupal installation on a LAMP-stack server node (agent), configured and maintained by this Puppet master node.
The master node is equipped with a Ruby CLI script (server.rb) to control the agent (start, stop, reboot) and check the availability of a Drupal test page (if /?q=test page exists).
For further development, the Ruby CLI is prepared to be used as a REST API with Sinatra.
The Master node is already installed on

	ec2-52-10-88-206.us-west-2.compute.amazonaws.com

Agent: Setup
------------

1. Create a new Ubuntu 14.04 HVM EC2 instance on AWS, in the same security group as the Master node (doc).
2. Connect to the instance via SSH with the AWS key file. Use the username 'ubuntu' in the host name.

	```
	ubuntu@public-dns.us-west2.compute.amadonaws.com
	```
3. Open the hostname file to edit

	```
	$ sudo nano /etc/hostname
	```
4. Modify the hostname file and set the hostname

	```	
	doc-test
	```
5. Save and exit with Ctrl+X, Y, Enter
6. Open the hosts file to edit

	```
	$ sudo nano /etc/hosts
	```
7. Modify the localhost, add the IP and FQDN entries for the agent itself and the master node (doc-master). Use the internal (or private) IP and DNS, because the public ones will regenerate when the instance stops/starts.

	```
	127.0.0.1 doc-test.localdomain doc-test localhost localhost.localdomain
	
	# use the Puppet master public IP and DNS with an alias (doc-master)
	172.31.40.93 doc-master.us-west-2.compute.internal doc-master
	
	# use the actual server private (local) IP address
	172.31.35.77 doc-test.localdomain                             
	```
8. Save and exit with Ctrl+X, Y, Enter
9. Reboot the virtual server

	```
	$ sudo reboot now
	```
10. Wait for reboot and connect again with SSH.
11. Run the following commands line to install Puppet agent:

	```
	$ sudo apt-get update && sudo apt-get upgrade && cd ~ && wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb && sudo dpkg -i puppetlabs-release-trusty.deb && sudo apt-get update && sudo apt-get install puppet && puppet help | tail -n 1
	```
12. Wait for the execution (Press: Y, Enter when prompted)
13. When the script ends, it returns the installed Puppet version. This version will be used later, so should be remembered. It looks like this:

	```
	Puppet v3.8.7
	```
14. Create the Puppet preferences and edit (you create a new file)

	```
	$ sudo nano /etc/apt/preferences.d/00-puppet.pref
	```
15. Add the following lines to lock the puppet and puppet-common packages to the actual version (change this to match our installed version):

	```
	# /etc/apt/preferences.d/00-puppet.pref
	Package: puppet puppet-common
	Pin: version 3.8*
	Pin-Priority: 501
	```
16. Save and exit with Ctrl+X, Y, Enter
17. Open the puppet configuration to edit

	```
	$ sudo nano /etc/default/puppet
	```
18. Set the line START value to yes

	```
	START=yes
	```
19. Save and exit with Ctrl+X, Y, Enter
20. Agent node is ready to configure!

Agent: Configure
----------------

1. Open the Puppet puppet.conf to edit

	```
	$ sudo nano /etc/puppet/puppet.conf
	```
2. Delete 'templatedir' line and the [master] section
3. Create an [agent] session as the following:

	```
	[agent]
	server = doc-master     # the alias from the hosts file!
	```
4. The file should look like this:

	```
	[main]
	logdir=/var/log/puppet
	vardir=/var/lib/puppet
	ssldir=/var/lib/puppet/ssl
	rundir=/var/run/puppet
	factpath=$vardir/lib/facter
		
	[agent]
	server = doc-master
	```
5. Save and exit with Ctrl+X, Y, Enter
6. Run Puppet agent

	```
	$ sudo service puppet start
	```
7. Test the agent by running the following command:

	```
	$ sudo puppet agent --test
	```
8. You should see something like this. This is not a problem, only the certificate needs to be signed on the master node.

	```
	Exiting; no certificate found and waitforcert is disabled
	```

Master: Sign Cert & Add Node
----------------------------

1. Sign in to the doc-master via SSH.
2. To get a list of pending certificates, run:

	```
	$ sudo puppet cert list
	```
3. To sign the certificate, use its name from the list and run:

	```
	$ sudo puppet cert sign doc-test.localdomain    # use the name listed in the cert list!
	```
4. Open the main manifest file to edit

	```
	$ sudo nano /etc/puppet/manifests/site.pp
	```
5. Add your new agent node to the manifest file and use the 'doc' configuration class with the desired site name as parameter

	```
	node 'doc-test.localdomain' {
		class { 'doc':
			sitename => "testnode.us-west-2.compute.amazonaws.com",
		}
	}
	```
6. Save and exit with Ctrl+X, Y, Enter

Agent: Retrieve configuration
-----------------------------

1. Now, you should try again to retrieve the configuration

	```
	$ sudo puppet agent --test
	```
2. If everything goes well, Your Drupal installation on the LAMP-stack is ready! (Ruby with Sass is installed too)

You can visit your Drupal site (install.php) on the public DNS of the instance.
The following database credentials are created for the drupal installation (you wil have to use these in the configuration):

	Database: doc
	Username: drupal
	Password: testPassword01toChange
	
Do not forget to create a test page (/?q=test) to use the Ruby CLI testing tool!

Master: Ruby CLI
----------------

The server-controlling Ruby CLI script is located in the /home/ubuntu folder and named 'server.rb'. To run the CLI, use:

	$ sudo ruby /etc/servercontrol/server.rb [action] [instance-id]

Action:

	start		Starts an EC2 instance
	stop		Stops an EC2 instance
	reboot		Reboots an EC2 instance
	test		Test the '/?q=test' Drupal page on the EC2 instance

Instance id can be the ID of any EC2 instance within the security group (doc) except for the Master node itself.

Example Instance
----------------

You can see a Drupal installation working on http://ec2-52-40-121-103.us-west-2.compute.amazonaws.com/

Workflow
--------

See my workflow on this project at ...
