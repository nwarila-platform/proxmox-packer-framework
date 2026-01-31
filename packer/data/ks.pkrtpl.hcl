# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Rocky Linux 9

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
${network}

### Lock the root account.
rootpw --lock

### Configure firewall settings for the system.
### --enabled	reject incoming connections that are not in response to outbound requests
### --ssh	allow sshd service through the firewall
firewall --enabled --ssh

### Sets up the authentication options for the system.
### The SSSD profile sets sha512 to hash passwords. Passwords are shadowed by default
### See the manual page for authselect-profile for a complete list of possible options.
authselect select sssd

### Sets the state of SELinux on the installed system.
### Defaults to enforcing.
selinux --enforcing

### Sets the system time zone.
timezone ${os_timezone}

### Partitioning
${storage}

### Disable KDump
%addon com_redhat_kdump --disable
%end

### Do not configure X on the installed system.
skipx

### Install Core Package(s)
%packages --ignoremissing --excludedocs
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
  #sed -ri 's/^#?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
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

### Reboot after the installation is complete.
### --eject attempt to eject the media before rebooting.
reboot --eject
