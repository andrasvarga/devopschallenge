# DevOps Challenge alias DOC class with the site name parameter
class doc (
	$sitename = "example.com",
	$username = "ubuntu",
) {
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

        class drupalsetup {
		exec { 'service apache2 stop':
                        command         => '/usr/bin/service apache2 stop',
                } ->
		file { "/var/${doc::sitename}":
                        ensure		=> directory,
			owner		=> $doc::username,
		} ->
		class { 'composer':
			download_method => 'wget',
			composer_home   => "/home/${doc::username}",
			suhosin_enabled => false,
		} ->
		apache::vhost { $doc::sitename:
                	ensure		=> present,
                	port		=> '80',
                	docroot		=> "/var/${doc::sitename}/core",
			docroot_owner	=> $doc::username,
			override	=> 'All',
                } ->
                exec { 'service apache2 start':
                	command		=> '/usr/bin/service apache2 start',
                } ->
                file { "/var/${doc::sitename}/composer.json" :
			ensure		=> present,
			source		=> "puppet:///modules/doc/composer.json",
			owner		=> $doc::username,
		} ->
		composer::exec { 'install':
			cmd			=> 'install',
			cwd			=> "/var/${doc::sitename}",
			dry_run			=> false,
			custom_installers	=> true,
			timeout			=> 400,
			interaction		=> false,
			user			=> $doc::username,
                } ->
		file { "/var/${doc::sitename}/core/sites/default/settings.php" :
                        ensure  => present,
                	content => template('doc/settings.php.erb'),
                } ->
		file { "/var/${doc::sitename}/core/profiles/awsprofile" :
			source  => "puppet:///modules/doc/awsprofile",
			recurse	=> true,
		} ->
		drush::run { 'site-install':
			arguments  => "--site-name=${doc::sitename} --root='/var/${doc::sitename}/core' --account-name=${::drupalusr} --account-pass=${::drupalpsw}",
		} ->
		exec { "chown /var/${doc::sitename}":
                        # Modify project directory permissions to be writable by the application
                        command         => "/bin/chown -R www-data /var/${doc::sitename}",
                } ->
		exec { "chmod install.php":
			command		=> "/bin/chmod -R 777 /var/${doc::sitename}/core/install.php",
		}
        }

	# LAMP-stack Installation from other custom modules and declare the defined classes runs only if the site name is not undefined!
	if $sitename != undef {
		class { 'lamp': } ->
		class { 'gitinstall': } ->
		class { 'drush': } ->
		class { 'drupalsetup': }
	}
}
