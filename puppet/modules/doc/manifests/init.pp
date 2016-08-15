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

	class server-on {
                exec { 'service apache2 stop':
                        command         => '/usr/bin/service apache2 stop',
                } ->
                apache::vhost { $doc::sitename:
                        ensure          => present,
                        port            => '80',
                        manage_docroot  => false,
                        docroot         => "/var/${doc::sitename}/web",
                        docroot_owner   => $doc::username,
                        override        => 'All',
                } ->
                exec { 'service apache2 start':
                        command         => '/usr/bin/service apache2 start',
                }
        }

        class drupal-make {
                file { "/var/${doc::sitename}" :
                        ensure  => directory,
                } ->
                file { "/var/${doc::sitename}/d7.make.yml" :
                        ensure  => present,
                        source  => 'puppet:///modules/doc/d7.make.yml',
                } ->
                class { 'drush::git::drush' :
                        git_branch => '8.x',
                } ->
		exec { "drush make":
			command => "/usr/bin/drush @none --yes  make /var/${doc::sitename}/d7.make.yml /var/${doc::sitename}/web",
			unless	=> "/usr/bin/test -f /var/${doc::sitename}/web/index.php",
		}
        }

	class drupal-config {
		file { '/tmp/cache':
			ensure 	=> directory,
		}
		file { "/var/${doc::sitename}/web/sites/default/settings.php" :
                        ensure  => present,
                        content => template('doc/settings.php.erb'),
                } ->
                file { "/var/${doc::sitename}/web/profiles/awsprofile" :
                        source  => 'puppet:///modules/doc/awsprofile',
                        recurse => true,
                } -> 
		file { "/var/${doc::sitename}/web/sites/default/files":
			ensure => directory,
		} ->
		exec { "/bin/chown -R www-data /var/${doc::sitename}/web/sites/default/files": } ->
		exec { "/bin/chmod -R 755 /var/${doc::sitename}/web/sites/default/files": }
	}

	class drupal-site-install {
		file { '/var/tmp/db-check.sh' :
                        ensure => present,
                        content => template('doc/db-check.sh.erb'),
                } ->
		exec { '/bin/chmod +x /var/tmp/db-check.sh': } ->
                exec { 'drush site-install':
			cwd	=> "/var/${doc::sitename}/web",
			command => "/usr/bin/drush site-install awsprofile --yes --site-name=${doc::sitename} --account-name=${::drupalusr} --account-pass=${::drupalpsw}",
                	unless	=> "/var/tmp/db-check.sh",
                }
	}

	# LAMP-stack Installation from other custom modules and declare the defined classes runs only if the site name is not undefined!
	if $sitename != undef {
		class { 'lamp': } ->
		class { 'gitinstall': } ->
		class { 'server-on': } ->
		class { 'drupal-make': } ->
                class { 'drupal-config': } ->
                class { 'drupal-site-install': }
	}
}
