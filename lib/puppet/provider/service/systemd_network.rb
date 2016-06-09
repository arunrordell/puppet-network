# Manage Red Hat network service
# Certain issues with network service can cause issues that need to be handled specially for centos/rhel 7
# we clean up the dhclients for our interfaces if there's a client that exists after stopping/before starting the service
# dhclients will be "orphaned" if network.service failed to start completely but some interfaces still came up anyway.
# After that point, network.service will no longer "manage" those dhclients and they must be killed manually.
# This can happen when network.service fails to start due to an ifcfg file existing for a nonexistent interface
# at the time network service is started on boot of the vm, before puppet has a chance to clear those files.
Puppet::Type.type(:service).provide :systemd_network, :parent => :systemd do

  confine :osfamily => "RedHat"
  confine :operatingsystemmajrelease => "7"

  # Override how restart is done, so we can ensure the start/stop method is called, which will clean up our dhclients
  def restart
    self.stop
    self.start
  end

  def stop
    super
    execute("pkill dhclient", :failonfail => false)
  end

  def start
    execute("pkill dhclient", :failonfail => false)
    super
  end
end
