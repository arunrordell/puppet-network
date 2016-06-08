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

  def ifdown_all
    # On certain RHEL / CentOS 7.0 ISOs some of the interfaces like
    # em1 seem to keep their IP configuration settings after being
    # reconfigured into a bonded interface until the network is
    # restarted a second time. To work-around we ensure all interfaces
    # are down
    Facter["interfaces"].value.split(",").each do |iface|
      execute("ifdown %s" % iface, :failonfail => false) unless iface == "lo"
    end

    # Workaround for case where dhclient gets left running if failures
    # happen halfway through a "service network start" and cannot be
    # managed after that due to those orphan processes.
    execute("pkill dhclient", :failonfail => false)
  end

  def stop
    super
    ifdown_all
  end

  def start
    ifdown_all
    super
  end
end

