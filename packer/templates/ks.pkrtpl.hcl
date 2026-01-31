### Installs from the first attached CD-ROM/DVD on the system.
cdrom

### Performs the kickstart installation in text mode.
### By default, kickstart installations are performed in graphical mode.
text

### Accepts the End User License Agreement.
eula --agreed

### Sets the language to use during installation and the default language to use on the installed system.
lang ${os_language}

### Sets the default keyboard type for the system.
keyboard ${os_keyboard}

### Configure network information for target system and activate network devices in the installer environment (optional)
### --onboot	  enable device at a boot time
### --device	  device to be activated and / or configured with the network command
### --bootproto	  method to obtain networking configuration for device (default dhcp)
### --noipv6	  disable IPv6 on this device
%{ if ipv4_address != null ~}
network --activate --bootproto=static --device=${device} --gateway=${ipv4_gateway} --ip=${ipv4_address} --nameserver=${join(",", dns)} --netmask=${cidrnetmask("${ipv4_address}/${ipv4_netmask}")} --noipv6 --onboot=yes
%{ else ~}
network --bootproto=dhcp --device=${device}
%{ endif ~}

### Lock the root account.
rootpw --lock

# Configure firewall settings for the system (optional)
# --enabled	reject incoming connections that are not in response to outbound requests
# --ssh		allow sshd service through the firewall
firewall --enabled --ssh

# State of SELinux on the installed system (optional)
# Defaults to enforcing
selinux --enforcing

# Set the system time zone (required)
timezone ${os_timezone}

#region ------ [ Storage Configuration ] ------------------------------------------------------ #
### Sets how the boot loader should be installed.
bootloader --location=mbr

### Initialize any invalid partition tables found on disks.
zerombr

### Removes partitions from the system, prior to creation of new partitions.
### By default, no partitions are removed.
### --all	Erases all partitions from the system
### --initlabel Initializes a disk (or disks) by creating a default disk label for all disks in their respective architecture.
clearpart --all --initlabel

### Modify partition sizes for the virtual machine hardware.
### Create primary system partitions.
%{ for partition in partitions ~}
part
%{~ if partition.volume_group != "" ~}
 pv.${partition.volume_group}
%{~ else ~}
%{~ if partition.format.fstype == "swap" ~}
 swap
%{~ else ~}
 ${partition.mount.path}
%{~ endif ~}
%{~ if partition.format.fstype != "" ~}
 --label=${partition.format.label}
%{~ if partition.format.fstype == "fat32" ~}
 --fstype vfat
%{~ else ~}
 --fstype ${partition.format.fstype}
%{~ endif ~}
%{~ endif ~}
%{~ endif ~}
%{~ if partition.mount.options != "" ~}
  --fsoptions="${partition.mount.options}"
%{~ endif ~}
%{~ if partition.size != -1 ~}
 --size=${partition.size}
%{~ else ~}
 --size=100 --grow
%{ endif ~}

%{ endfor ~}
### Create a logical volume management (LVM) group.
%{ for index, volume_group in lvm ~}
volgroup sysvg pv.${volume_group.name}

### Modify logical volume sizes for the virtual machine hardware.
### Create logical volumes.
%{ for partition in volume_group.partitions ~}
logvol
%{~ if partition.format.fstype == "swap" ~}
 swap
%{~ else ~}
 ${partition.mount.path}
%{~ endif ~}
 --name=${partition.name} --vgname=${volume_group.name} --label=${partition.format.label}
%{~ if partition.format.fstype == "fat32" ~}
 --fstype vfat
%{~ else ~}
 --fstype ${partition.format.fstype}
%{~ endif ~}
%{~ if partition.mount.options != "" ~}
 --fsoptions="${partition.mount.options}"
%{~ endif ~}
%{~ if partition.size != -1 ~}
 --size=${partition.size}
%{~ else ~}
 --size=100 --grow
%{ endif ~}

%{ endfor ~}
%{ endfor ~}

### Do not configure X on the installed system.
skipx

### Install Core Package(s)
%packages --ignoremissing --excludedocs --exclude-weakdeps --inst-langs=en_US
  @^minimal-environment
  -iwl*firmware
  qemu-guest-agent
%end

### Modifies the default set of services that will run under the default runlevel.
services --enabled=NetworkManager,sshd,qemu-guest-agent

### Apply DISA STIG during install via OpenSCAP add‑on
%addon com_redhat_oscap
  content-type = scap-security-guide
  profile = xccdf_org.ssgproject.content_profile_stig
%end

# Create the deploy user
user --name=${deploy_user_name} --plaintext --password=${deploy_user_password} --groups=wheel
sshkey --username=${deploy_user_name} "${deploy_user_key}"

### Post-installation commands.
%post

  # Configure the SSH Service To Allow SSH After System Hardening
  sed -ri 's/^#?PermitRootLogin.*/PermitRootLogin no/'               /etc/ssh/sshd_config
  sed -ri 's/^#?X11Forwarding.*/X11Forwarding no/'                   /etc/ssh/sshd_config
  echo "DisableForwarding yes"                                    >> /etc/ssh/sshd_config
  echo "MaxAuthTries 4"                                           >> /etc/ssh/sshd_config
  echo "LoginGraceTime 60"                                        >> /etc/ssh/sshd_config
  echo "AllowGroups wheel"                                        >> /etc/ssh/sshd_config
  grep -q 'Subsystem[[:space:]]\+sftp' /etc/ssh/sshd_config \
    && sed -i 's#^[#[:space:]]*Subsystem[[:space:]]\+sftp.*#Subsystem sftp /usr/libexec/openssh/sftp-server#' /etc/ssh/sshd_config \
    || echo 'Subsystem sftp /usr/libexec/openssh/sftp-server' | tee -a /etc/ssh/sshd_config

  # Configure the deploy user
  chage -m 1 -M 180 -W 14 -d $(date +%F) ${deploy_user_name}

  # Update System
  dnf makecache
  dnf install epel-release -y
  dnf makecache

  # Install Additionally Defined Package(s)
  %{ if additional_packages != "" ~}
    dnf install -y ${additional_packages}
  %{ endif ~}

%end

# Reboot after the installation is complete (optional)
# --eject	attempt to eject CD or DVD media before rebooting
reboot --eject
