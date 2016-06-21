node default {}

# Configuration for the agent node with LAMP-Drupal-Ruby-SASS-Git configuration
node 'doc-agent.localdomain' {
    class { 'doc':
        sitename => "agentnode.us-west-2.compute.amazonaws.com",
    }
}

# Preparing the same configuration for a new test node
node 'doc-test.localdomain' {
    class { 'doc':
        sitename => "testnode.us-west-2.compute.amazonaws.com",
    }
}
