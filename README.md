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


### MAC Address Handling

```odin
// Parse MAC addresses (multiple formats supported)
mac1, _ := netx.parse_mac("00:1A:2B:3C:4D:5E")  // Colon-separated
mac2, _ := netx.parse_mac("00-1a-2b-3c-4d-5e")  // Hyphen-separated
mac3, _ := netx.parse_mac("001a2b3c4d5e")       // Raw hex

// Format output
fmt.println(netx.mac_to_string_colon(mac1, true))   // 00:1A:2B:3C:4D:5E
fmt.println(netx.mac_to_string_hyphen(mac1, false)) // 00-1a-2b-3c-4d-5e

// Check properties
fmt.printf("Is unicast? %v\n", netx.is_unicast_mac(mac1))
fmt.printf("Is multicast? %v\n", netx.is_multicast_mac(mac1))
fmt.printf("Is locally administered? %v\n", netx.is_locally_administered(mac1))

// Extract OUI (Organizationally Unique Identifier)
oui := netx.get_oui(mac1)  // First 3 bytes
fmt.printf("OUI: %02X:%02X:%02X\n", oui, oui, oui)[^1][^2]

// Convert to EUI-64
eui64 := netx.mac_to_eui64(mac1)
fmt.println(netx.eui64_to_string(eui64, ":", true))  // 02:1A:2B:FF:FE:3C:4D:5E

// Generate IPv6 link-local address from MAC (SLAAC)
link_local := netx.mac_to_ipv6_link_local(mac1)
fmt.println(netx.addr_to_string6(link_local))  // fe80::21a:2bff:fe3c:4d5e

// Extract MAC from IPv6 SLAAC address
recovered_mac, ok := netx.ipv6_to_mac(link_local)
if ok {
    fmt.println(netx.mac_to_string_colon(recovered_mac, true))
}
```


### DNS Reverse Lookups (PTR Records)

```odin
// IPv4 PTR generation
addr := net.IP4_Address{192, 168, 1, 100}
ptr := netx.addr4_to_ptr(addr)
fmt.println(ptr)  // 100.1.168.192.in-addr.arpa

// IPv4 network zone delegation
network := netx.must_parse_cidr4("192.168.1.0/24")
zone := netx.network4_to_ptr(network)
fmt.println(zone)  // 1.168.192.in-addr.arpa

// IPv4 classless delegation (RFC 2317) for /25-/31
small_net := netx.must_parse_cidr4("192.168.1.64/26")
classless_zone := netx.network4_to_classless_ptr(small_net)
fmt.println(classless_zone)  // 64/26.1.168.192.in-addr.arpa

// Parse PTR back to address
recovered, ok := netx.ptr_to_addr4("100.1.168.192.in-addr.arpa")
if ok {
    fmt.println(netx.addr_to_string4(recovered))  // 192.168.1.100
}

// IPv6 PTR generation
addr6 := netx.ipv6_loopback()
ptr6 := netx.addr6_to_ptr(addr6)
fmt.println(ptr6)  // 1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa

// IPv6 network zone delegation (nibble boundaries)
net6 := netx.must_parse_cidr6("2001:db8::/32")
zone6 := netx.network6_to_ptr(net6)
fmt.println(zone6)  // 8.b.d.0.1.0.0.2.ip6.arpa

// Validate PTR format
fmt.println(netx.is_valid_ptr4("100.1.168.192.in-addr.arpa"))  // true
fmt.println(netx.is_valid_ptr6("1.0.0.0...ip6.arpa"))  // true
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


## Examples

See the [examples](examples/) directory for complete working examples:

- `dns.odin` - Reverse DNS PTR record generation and parsing
- `ip.odin` - IPv4/IPv6 address and CIDR operations
- `ipam.odin` - IPAM features (aggregation, pools, exclusion)
- `mac.odin` - MAC address parsing, formatting, and conversion
