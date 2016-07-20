node default {
    class { 'doc':
        sitename => $::sitename,
	username => "ubuntu",
    }
}
