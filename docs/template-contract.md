# Template Variable Contract

This document defines the guaranteed variable set that the framework passes to every consumer
install template via `templatefile()`. Consumer templates can use any of these variables.
Changing this contract is a **breaking change** that must follow semantic versioning.

## Credentials

| Variable | Type | Source | Description |
|---|---|---|---|
| `deploy_user_name` | string | `var.deploy_user_name` | Deploy/service account username |
| `deploy_user_password` | string | `var.deploy_user_password` | Deploy account password |
| `deploy_user_public_key` | string | `var.deploy_user_public_key` | SSH public key |

## Locale

| Variable | Type | Default | Description |
|---|---|---|---|
| `os_language` | string | `"en_US"` | OS language/locale |
| `os_keyboard` | string | `"us"` | Keyboard layout |
| `os_timezone` | string | `"UTC"` | System timezone |

## OS Metadata

| Variable | Type | Source | Description |
|---|---|---|---|
| `os_family` | string | `var.packer_image.os_family` | `"linux"` or `"windows"` |
| `os_name` | string | `var.packer_image.os_name` | e.g. `"rocky"`, `"ubuntu"`, `"windows-server"` |
| `os_version` | string | `var.packer_image.os_version` | e.g. `"9"`, `"22.04"`, `"2022"` |

## Network (first adapter, pre-resolved)

| Variable | Type | Description |
|---|---|---|
| `network_device` | string | MAC address or `"link"` (NIC identifier for installer) |
| `network_ipv4_address` | string or null | IPv4 address; null = DHCP |
| `network_ipv4_netmask` | number or null | CIDR prefix length |
| `network_ipv4_gateway` | string or null | Default gateway |
| `network_dns` | list(string) or null | DNS servers |

## Storage

| Variable | Type | Source | Description |
|---|---|---|---|
| `storage_partitions` | list(object) | `var.vm_disk_partitions` | Partition definitions |
| `storage_lvm` | list(object) | `var.vm_disk_lvm` | LVM volume groups |
| `storage_use_swap` | bool | `var.vm_disk_use_swap` | Swap partition flag |

## Build Context

| Variable | Type | Source | Description |
|---|---|---|---|
| `build_bios` | string | normalized | `"ovmf"` or `"seabios"` |
| `build_communicator` | string | normalized | `"ssh"` or `"winrm"` |

## Hardware Summary

| Variable | Type | Source | Description |
|---|---|---|---|
| `hw_cores` | number | normalized | CPU core count |
| `hw_memory` | number | normalized | RAM in MB |
| `hw_disk_size` | string | first disk | Primary disk size (e.g. `"100G"`) |

## Usage in Templates

Kickstart example:

```hcl
network --activate --bootproto=static --ip=${network_ipv4_address} ...
user --name=${deploy_user_name} --plaintext --password=${deploy_user_password}
```

Autounattend example:

```xml
<Value>Windows Server 2022 SERVERDATACENTER</Value>
<Path>D:\viostor\2k22\amd64</Path>
```

OS-specific values such as image names, product keys, and driver versions belong directly
in the consumer's installer template. The framework contract provides the shared variables
above; everything else is owned by the template file itself.
