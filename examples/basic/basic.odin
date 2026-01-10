package main

import "core:fmt"
import "core:net"
import netx "../.."

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
}
