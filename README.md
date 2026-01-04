# netx

Network utilities extending Odin's core:net - IP/CIDR operations, address management, and more.

Inspired by Go's [`net/netip`](https://pkg.go.dev/net/netip) package, providing type-safe, allocation-efficient IP address handling.

## Features

### Core IP/CIDR Operations (`ip.odin`)
- Parse and format CIDR notation (`192.168.1.0/24`, `2001:db8::/32`)
- IP classification (private, loopback, multicast, link-local, global unicast)
- Network operations (contains, overlaps, comparison)
- Network ranges and host counting
- Subnet splitting and address iteration
- Full IPv4 and IPv6 support

### Advanced IPAM Features (`ipam.odin`)
- **CIDR Aggregation**: Merge adjacent networks automatically
- **Range to CIDR**: Convert IP ranges to optimal CIDR blocks
- **Address Pool Allocation**: IPAM-style IP address management
- **Supernet Calculation**: Find common parent networks
- **Network Exclusion**: Subtract networks from each other

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
    // Parse CIDR
    network, ok := netx.parse_cidr4("192.168.1.0/24")
    if !ok do return

    fmt.printf("Network: %s\n", netx.network_to_string4(network))

    // Check membership
    addr := net.IP4_Address{192, 168, 1, 100}
    fmt.printf("Contains %s? %v\n",
               netx.addr_to_string4(addr),
               netx.contains4(network, addr))

    // Get ranges
    first, last := netx.network_range4(network)
    fmt.printf("Range: %s - %s\n",
               netx.addr_to_string4(first),
               netx.addr_to_string4(last))

    // Host count
    count := netx.host_count4(network)
    fmt.printf("Usable hosts: %d\n", count)

    // Split into subnets
    subnets, _ := netx.subnets4(network, 26, context.temp_allocator)
    fmt.println("Subnets:")
    for subnet in subnets {
        fmt.printf("  %s\n", netx.network_to_string4(subnet))
    }

    // Classify IPs
    fmt.printf("Is private? %v\n", netx.is_private4(addr))
    fmt.printf("Is global? %v\n", netx.is_global_unicast4(addr))
}
```

### IPv6 Support

```odin
// Parse IPv6 CIDR
net6, _ := netx.parse_cidr6("2001:db8::/32")
fmt.println(netx.network_to_string6(net6))  // 2001:db8::/32

// Well-known IPv6 addresses
fmt.println(netx.addr_to_string6(netx.ipv6_loopback()))  // ::1
fmt.println(netx.addr_to_string6(netx.ipv6_link_local_all_nodes()))  // ff02::1

// IPv6 classification
addr6, _ := net.parse_ip6_address("fe80::1")
fmt.printf("Is link-local? %v\n", netx.is_link_local6(addr6))
```

## Advanced Features (IPAM)

### CIDR Aggregation

Automatically merge adjacent networks:

```odin
networks := []netx.IP4_Network{
    netx.must_parse_cidr4("192.168.1.0/25"),
    netx.must_parse_cidr4("192.168.1.128/25"),
}

// Merges into 192.168.1.0/24
merged := netx.aggregate_networks4(networks, context.temp_allocator)
for net in merged {
    fmt.println(netx.network_to_string4(net))
}
```

### Range to CIDR Conversion

Convert arbitrary IP ranges to CIDR blocks:

```odin
start := net.IP4_Address{192, 168, 1, 10}
end := net.IP4_Address{192, 168, 1, 50}

cidrs := netx.range_to_cidrs4(start, end, context.temp_allocator)
for cidr in cidrs {
    fmt.println(netx.network_to_string4(cidr))
}
// Output: 192.168.1.10/31, 192.168.1.12/30, ...
```

### Address Pool Allocation

IPAM-style IP address management:

```odin
// Create a pool from a network
network := netx.must_parse_cidr4("10.0.1.0/24")
pool := netx.pool4_init(network)
defer netx.pool4_destroy(&pool)

// Allocate addresses
ip1, ok := netx.pool4_allocate(&pool)  // 10.0.1.1
ip2, ok := netx.pool4_allocate(&pool)  // 10.0.1.2

// Check availability
available := netx.pool4_available(&pool)
fmt.printf("Available IPs: %d\n", available)

// Free an address
netx.pool4_free(&pool, ip1)

// Check if allocated
is_used := netx.pool4_is_allocated(&pool, ip2)
```

### Supernet Calculation

Find the common parent network:

```odin
net_a := netx.must_parse_cidr4("192.168.0.0/24")
net_b := netx.must_parse_cidr4("192.168.1.0/24")

super := netx.supernet4(net_a, net_b)
fmt.println(netx.network_to_string4(super))  // 192.168.0.0/23
```

### Network Exclusion

Subtract one network from another:

```odin
from := netx.must_parse_cidr4("192.168.1.0/24")
exclude := netx.must_parse_cidr4("192.168.1.128/25")

remaining := netx.exclude4(from, exclude, context.temp_allocator)
for net in remaining {
    fmt.println(netx.network_to_string4(net))
}
// Output: 192.168.1.0/25 (the non-excluded portion)
```
