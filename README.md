# netx

Network utilities extending Odin's core:net - IP/CIDR operations, MAC address handling, DNS utilities, and more.

Inspired by Go's [`net/netip`](https://pkg.go.dev/net/netip) package, providing type-safe, allocation-efficient network address handling.

## Features

### Core IP/CIDR Operations (`ip.odin`)
- Parse and format CIDR notation (`192.168.1.0/24`, `2001:db8::/32`)
- IP classification (private, loopback, multicast, link-local, global unicast)
- Network operations (contains, overlaps, comparison)
- Network ranges and host counting
- Subnet splitting and address iteration
- Network prefix operations (next/previous network, parent network, subnet relationships)
- Full IPv4 and IPv6 support

### MAC Address Operations (`mac.odin`)
- **Parsing**: Multiple formats (colon, hyphen, raw hex)
- **Formatting**: Flexible output with uppercase/lowercase options
- **EUI-64 Conversion**: MAC ↔ EUI-64 bidirectional conversion
- **IPv6 Integration**: Generate link-local addresses from MAC (SLAAC)
- **Properties**: Unicast/multicast, locally administered, OUI extraction
- **Comparison**: Full ordering and equality support

### DNS Operations (`dns.odin`)
- **PTR Record Generation**: Convert IP addresses to reverse DNS format
- **IPv4**: Standard in-addr.arpa zones and classless delegation (RFC 2317)
- **IPv6**: Full nibble expansion for ip6.arpa zones
- **Bidirectional**: Parse PTR records back to IP addresses
- **Zone Delegation**: Generate proper zone names for networks
- **Validation**: Check PTR record format validity

### Advanced IPAM Features (`ipam.odin`)
- **CIDR Aggregation**: Merge adjacent networks automatically
- **Range to CIDR**: Convert IP ranges to optimal CIDR blocks
- **Address Pool Allocation**: IPAM-style IP address management
- **Supernet Calculation**: Find common parent networks
- **Network Exclusion**: Subtract networks from each other
- **Subnet Discovery**: Find available subnets of specific sizes
- **Free Block Analysis**: Locate largest contiguous free space
- **Utilization Metrics**: Calculate network usage percentages

## Installation

Clone into your project directory:

```bash
cd your_project
git clone https://github.com/alexferl/netx
```

Then import:

```odin
import "netx"
```

## Quick Start

### Basic Usage

```odin
package main

import "core:fmt"
import "core:net"
import "netx"

main :: proc() {
    // Parse and work with networks
    network := netx.must_parse_cidr4("192.168.1.0/24")
    addr := net.IP4_Address{192, 168, 1, 100}

    fmt.println(netx.contains4(network, addr))  // true
    fmt.println(netx.host_count4(network))      // 254

    // Navigate network space
    next, _ := netx.next_network4(network)
    fmt.println(netx.network_to_string4(next))  // 192.168.2.0/24

    // MAC address handling
    mac, _ := netx.parse_mac("00:1A:2B:3C:4D:5E")
    link_local := netx.mac_to_ipv6_link_local(mac)
    fmt.println(netx.addr_to_string6(link_local))  // fe80::21a:2bff:fe3c:4d5e

    // DNS PTR records
    ptr := netx.addr4_to_ptr(addr)
    fmt.println(ptr)  // 100.1.168.192.in-addr.arpa

    // Find free subnets
    parent := netx.must_parse_cidr4("10.0.0.0/16")
    used := []netx.IP4_Network{netx.must_parse_cidr4("10.0.1.0/24")}
    free := netx.find_free_subnets4(parent, used, 24)
    fmt.println(len(free))  // 255 available /24 subnets
}
```

## Examples

See the [examples](examples/) directory for complete working examples:

- `ip.odin` - IPv4/IPv6 address and CIDR operations
- `ipam.odin` - IPAM features (aggregation, pools, exclusion, subnet discovery)
- `mac.odin` - MAC address parsing, formatting, and conversion
- `dns.odin` - Reverse DNS PTR record generation and parsing
