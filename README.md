# netx

Network utilities extending Odin's core:net - IP/CIDR operations, MAC address handling, DNS utilities, and more.

Inspired by Go's [`net/netip`](https://pkg.go.dev/net/netip) package, providing type-safe, allocation-efficient network address handling.

## Features

### Core IP/CIDR Operations (`ip.odin`)
- **CIDR Parsing**: Parse and format CIDR notation (`192.168.1.0/24`, `2001:db8::/32`)
- **IP Classification**: Identify private, loopback, multicast, link-local, global unicast addresses
- **Network Operations**: Contains, overlaps, and comparison operations
- **IP Range types** (`IP4_Range`/`IP6_Range`): Structured address ranges with start/end fields
  - Network and usable host ranges
  - Range containment and overlap checking
  - Range size calculation and string formatting
- **Address:Port types** (`IP4_Addr_Port`/`IP6_Addr_Port`): Combined address and port handling
  - Parse and format address:port strings (`192.168.1.1:8080`, `[::1]:443`)
  - Essential for network service configuration
- **IPv4-Mapped IPv6**: Convert between IPv4 and IPv6 address spaces
  - Embed IPv4 addresses in IPv6 format (`::ffff:192.0.2.1`)
  - Extract IPv4 from mapped IPv6 addresses
  - Detect and handle dual-stack scenarios
- **Subnet Operations**: Subnet splitting and address iteration
- **Network Navigation**: Network prefix operations (next/previous network, parent network, subnet relationships)
- **Bitwise Operations**: AND, OR, XOR, NOT for custom masking and manipulation
- **Full IPv4/IPv6 Support**: Complete implementation for both protocols
- **Random IP Generation**: Generate random IPs within specific CIDR blocks
  - Network-aware random generation
  - Uniform distribution using Odin's crypto-quality RNG
  - Handles all network sizes from tiny (/30) to massive (/8) IPv4 networks
  - Efficient IPv6 random generation for huge spaces
  - Use cases: Testing, load balancing, simulation, test data generation

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
- **VLSM (Variable Length Subnet Masking)**: Optimally split networks based on host requirements
  - Automatically allocates smallest sufficient subnets for each requirement
  - Minimizes address space fragmentation by allocating largest subnets first
  - Returns subnets in original requirement order for easy mapping

### IP Set Data Structure (`ipset.odin`)
- **Radix Tree Implementation**: Efficient O(log n) IP prefix lookups
- **Fast Membership Testing**: Check if an address is in any stored network
- **Longest Prefix Matching**: Find most specific network containing an address
- **Network Management**: Insert and remove networks dynamically
- **Memory Efficient**: Stores prefixes, not individual addresses
- **Use Cases**: Firewalls, routing tables, ACLs, rate limiting, geolocation

## Installation

Clone into your project directory:

```bash
cd your_project
git clone https://github.com/alexferl/netx
```

Then import (adjust the path based on your project structure):

```odin
import "netx"  // If netx is in the same directory as your project
// or
import "./netx"  // If netx is a subdirectory
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

    // Work with IP ranges
    range := netx.network_range4(network)
    fmt.println(netx.range_to_string4(range))   // 192.168.1.0-192.168.1.255
    fmt.println(netx.range_contains4(range, addr))  // true

    // Address:port handling
    server, _ := netx.parse_addr_port4("192.168.1.1:8080")
    fmt.println(server.port)  // 8080
    fmt.println(netx.addr_port_to_string4(server))  // 192.168.1.1:8080

    // IPv4-mapped IPv6 (dual-stack)
    ipv4 := net.IP4_Address{192, 0, 2, 1}
    mapped := netx.ipv4_to_ipv6_mapped(ipv4)
    fmt.println(netx.addr_to_string6(mapped))  // ::ffff:c000:201
    fmt.println(netx.is_ipv4_mapped6(mapped))  // true

    // Navigate network space
    next, _ := netx.next_network4(network)
    fmt.println(netx.network_to_string4(next))  // 192.168.2.0/24

    // Bitwise operations
    mask := net.IP4_Address{255, 255, 255, 128}
    broadcast := netx.ip4_or(network.address, netx.ip4_not(mask))
    fmt.println(netx.addr_to_string4(broadcast))  // Custom broadcast calc

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

    // VLSM: Split network optimally for different department sizes
    company := netx.must_parse_cidr4("192.168.0.0/24")
    requirements := []netx.VLSM_Requirement{
        {hosts = 100, name = "Engineering"},
        {hosts = 50, name = "Sales"},
        {hosts = 20, name = "HR"},
    }
    vlsm_subnets, vlsm_ok := netx.split_network_vlsm4(company, requirements)
    if vlsm_ok {
        fmt.println(netx.network_to_string4(vlsm_subnets[0]))  // 192.168.0.0/25
    }

    // IP Sets: Fast prefix matching with radix trees
    set := netx.set_init4()
    defer netx.set_destroy4(&set)

    netx.set_insert4(&set, netx.must_parse_cidr4("10.0.0.0/8"))
    netx.set_insert4(&set, netx.must_parse_cidr4("192.168.0.0/16"))

    fmt.println(netx.set_contains4(&set, net.IP4_Address{10, 1, 2, 3}))  // true

    // Longest prefix match (like routing table lookup)
    match, _ := netx.set_longest_match4(&set, net.IP4_Address{10, 5, 5, 5})
    fmt.println(netx.network_to_string4(match))  // 10.0.0.0/8

    // Random IP generation for testing or load balancing
    test_net := netx.must_parse_cidr4("192.0.2.0/24")  // TEST-NET-1
    random_ip := netx.random_ip4_in_network(test_net)
    fmt.println(netx.addr_to_string4(random_ip))  // Random IP in 192.0.2.0/24
}
```

## Examples

See the [examples](examples/) directory for complete working examples:

- `ip/` - IPv4/IPv6 operations, address:port, IPv4-mapped IPv6, random IP generation
- `ipam/` - IPAM features (aggregation, pools, exclusion, subnet discovery, VLSM)
- `ipset/` - IP set radix trees for fast lookups, firewalls, routing, ACLs
- `mac/` - MAC address parsing, formatting, and conversion
- `dns/` - Reverse DNS PTR record generation and parsing

## Requirements

- [Odin](https://odin-lang.org/) programming language
- Optional: [pre-commit](https://pre-commit.com/) for development

## Development

```bash
# Run tests
make test

# Check code style and syntax
make check

# Run pre-commit hooks
make pre-commit
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
