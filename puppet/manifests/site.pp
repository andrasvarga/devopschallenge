node default {}

node 'doc-agent.localdomain' {
    class { 'doc':
        sitename => "agentnode.us-west-2.compute.amazonaws.com",
    }
}

node 'doc-test.localdomain' {
    class { 'doc':
        sitename => "testnode.us-west-2.compute.amazonaws.com",
    }
}
