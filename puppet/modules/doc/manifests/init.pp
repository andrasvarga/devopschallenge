# DevOps Challenge alias DOC class with the site name parameter
class doc ( $sitename = undef, ) {

        # GIT installation and setting for Andras
	class gitinstall {
	        class { 'git': } ->
	        git::config { 'color.ui':
        	        value => 'true',
	        } ->
	        git::config { 'user.name':
        	        value => 'andrasvarga',
	        } ->
	        git::config { 'user.email':
        	        value => 'andras.varga.90@gmail.com',
	        }
	}

        # Ruby installation with Sass
	class rubyinstall {
	        package { 'ruby-full':
        	        ensure => installed,
	        } ->
	        package { 'sass':
	                ensure  => installed,
	                provider => gem,
	                require => Package['ruby-full'],
	        }
	}

        # Drupal site installation, configuring Apache and MySQL
        class drupalinstall {
                require lamp
		
		exec { 'service apache2 stop':
		    # stop apache to avoid conflicts
                    command => '/usr/bin/service apache2 stop',
                } ->
                drupal::site { $doc::sitename:
                    core_version        => '7.44',
                    modules             => {
                        'ctools'        => '1.9',
                        'token'         => '1.6',
                        'pathauto'      => '1.3',
                        'views'         => '3.14',
                    },
                    themes      => {
                        'omega' => '4.4',
                    },
                } ->
                apache::vhost { $doc::sitename:
                            ensure  => present,
                            port    => '80',
                            docroot => "/var/www/${doc::sitename}",
                } ->
                exec { 'service apache2 start':
		    # start apache
                    command => '/usr/bin/service apache2 start',
                } ->
                mysql::db { 'doc':
                    user         => 'drupal',
                    password => 'testPassword01toChange',
                    host         => 'localhost',
                    grant        => ['ALL'],
                }
         }

	# LAMP-stack Installation from other custom modules and declare the defined classes
	# runs only if the site name is not undefined!
	if $sitename != undef {
		include lamp
		include gitinstall
		include rubyinstall
		include drupalinstall
	}
}

