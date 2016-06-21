class lamp {
	# execute 'apt-get update'
	exec { 'apt-update': # exec resource named 'apt-update'
		command => '/usr/bin/apt-get update' # command this resource will run
	}

	# install apache withoud default vhost for custom configuraton
	class apacheinstall {
		class { 'apache':
			mpm_module => 'prefork',
			default_vhost => false,
		}
		include apache::mod::php
	}

	# install mysql-server package and ensure mysql service is running
	class mysqlinstall {
		package { 'mysql-server':
			require => Exec['apt-update'], # require 'apt-update' before installing
			ensure => installed,
		} ->
		service { 'mysql':
			ensure => running,
		}
	}

	# install php5 packages
	class php5 {
		package { [ 'php5', 'libapache2-mod-php5', 'php5-cli', 'php5-mysql', 'php5-curl', 'php5-gd' ]:
			require => Exec['apt-update'], # require 'apt-update' before installing
			ensure => installed,
		}
	}

	# declare the defined classes
	include apacheinstall
	include php5
	include mysqlinstall
}
