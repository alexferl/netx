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
