package main

import "core:fmt"
import "core:net"
import netx "../.."

main :: proc() {
	// ========================================================================
	// IPv4 EXAMPLES
	// ========================================================================

	fmt.println("--- IPv4: Parsing CIDR ---")
	network, ok := netx.parse_cidr4("192.168.1.0/24")
	if ok {
		fmt.printf("Parsed: %s\n", netx.network_to_string4(network))
	}

	network2 := netx.must_parse_cidr4("10.0.0.0/8")
	fmt.printf("Must parsed: %s\n", netx.network_to_string4(network2))

	fmt.println("\n--- IPv4: Accessors ---")
	fmt.printf("Network address: %s\n", netx.addr_to_string4(netx.network_addr4(network)))
	fmt.printf("Prefix length: %d\n", netx.network_bits4(network))

	fmt.println("\n--- IPv4: Raw Constructor ---")
	dirty := netx.network_from4(net.IP4_Address{192, 168, 1, 100}, 24)
	fmt.printf("Raw network: %s (host bits not masked)\n", netx.network_to_string4(dirty))
	clean := netx.masked4(dirty)
	fmt.printf("Masked network: %s\n", netx.network_to_string4(clean))

	fmt.println("\n--- IPv4: Classification ---")
	private_ip := net.IP4_Address{192, 168, 1, 1}
	public_ip := net.IP4_Address{8, 8, 8, 8}
	loopback := net.IP4_Address{127, 0, 0, 1}
	multicast := net.IP4_Address{224, 0, 0, 1}
	link_local := net.IP4_Address{169, 254, 1, 1}

	fmt.printf("%s is private: %v\n", netx.addr_to_string4(private_ip), netx.is_private4(private_ip))
	fmt.printf("%s is private: %v\n", netx.addr_to_string4(public_ip), netx.is_private4(public_ip))
	fmt.printf("%s is loopback: %v\n", netx.addr_to_string4(loopback), netx.is_loopback4(loopback))
	fmt.printf("%s is multicast: %v\n", netx.addr_to_string4(multicast), netx.is_multicast4(multicast))
	fmt.printf("%s is link-local: %v\n", netx.addr_to_string4(link_local), netx.is_link_local4(link_local))
	fmt.printf("%s is global unicast: %v\n", netx.addr_to_string4(public_ip), netx.is_global_unicast4(public_ip))

	fmt.println("\n--- IPv4: Well-Known Addresses ---")
	fmt.printf("IPv4 unspecified: %s\n", netx.addr_to_string4(netx.ipv4_unspecified()))
	fmt.printf("IPv4 loopback: %s\n", netx.addr_to_string4(netx.ipv4_loopback()))
	fmt.printf("IPv4 broadcast: %s\n", netx.addr_to_string4(netx.ipv4_broadcast()))

	fmt.println("\n--- IPv4: Network Membership ---")
	addr := net.IP4_Address{192, 168, 1, 100}
	fmt.printf("Does %s contain %s? %v\n",
	netx.network_to_string4(network), netx.addr_to_string4(addr), netx.contains4(network, addr))

	outside_addr := net.IP4_Address{192, 168, 2, 100}
	fmt.printf("Does %s contain %s? %v\n",
	netx.network_to_string4(network), netx.addr_to_string4(outside_addr), netx.contains4(network, outside_addr))

	fmt.println("\n--- IPv4: Network Ranges ---")
	range := netx.network_range4(network)
	fmt.printf("Range: %s - %s\n", netx.addr_to_string4(range.start), netx.addr_to_string4(range.end))

	usable_range, usable_ok := netx.usable_host_range4(network)
	if usable_ok {
		fmt.printf("Usable hosts: %s - %s\n", netx.addr_to_string4(usable_range.start), netx.addr_to_string4(usable_range.end))
	}
	fmt.printf("Host count: %d\n", netx.host_count4(network))

	fmt.println("\n--- IPv4: Subnetting ---")
	subnets, subnet_ok := netx.subnets4(network, 26)
	if subnet_ok {
		fmt.printf("Splitting %s into /%d subnets:\n", netx.network_to_string4(network), 26)
		for subnet in subnets {
			fmt.printf("  %s\n", netx.network_to_string4(subnet))
		}
	}

	fmt.println("\n--- IPv4: Comparison ---")
	net_a := netx.must_parse_cidr4("10.0.0.0/8")
	net_b := netx.must_parse_cidr4("192.168.0.0/16")
	cmp := netx.compare_network4(net_a, net_b)
	fmt.printf("Compare %s vs %s: %d\n",
	netx.network_to_string4(net_a),
	netx.network_to_string4(net_b),
	cmp)

	fmt.println("\n--- IPv4: IP Iteration ---")
	start_ip := net.IP4_Address{192, 168, 1, 1}
	fmt.printf("Starting from: %s\n", netx.addr_to_string4(start_ip))
	next_ip, next_ok := netx.next_ip4(start_ip)
	if next_ok {
		fmt.printf("Next IP: %s\n", netx.addr_to_string4(next_ip))
	}
	prev_ip, prev_ok := netx.prev_ip4(start_ip)
	if prev_ok {
		fmt.printf("Previous IP: %s\n", netx.addr_to_string4(prev_ip))
	}

	fmt.println("\n--- IPv4: Network Navigation ---")
	base_net := netx.must_parse_cidr4("192.168.1.0/24")
	fmt.printf("Base network: %s\n", netx.network_to_string4(base_net))

	next_net, next_net_ok := netx.next_network4(base_net)
	if next_net_ok {
		fmt.printf("Next network: %s\n", netx.network_to_string4(next_net))
	}

	prev_net, prev_net_ok := netx.prev_network4(base_net)
	if prev_net_ok {
		fmt.printf("Previous network: %s\n", netx.network_to_string4(prev_net))
	}

	parent_net, parent_net_ok := netx.parent_network4(base_net)
	if parent_net_ok {
		fmt.printf("Parent network (one bit less specific): %s\n", netx.network_to_string4(parent_net))
	}

	fmt.println("\n--- IPv4: Subnet Relationships ---")
	parent := netx.must_parse_cidr4("10.0.0.0/8")
	subnet1 := netx.must_parse_cidr4("10.1.0.0/16")
	subnet2 := netx.must_parse_cidr4("10.1.1.0/24")
	outside := netx.must_parse_cidr4("192.168.1.0/24")

	fmt.printf("Is %s a subnet of %s? %v\n",
	netx.network_to_string4(subnet1),
	netx.network_to_string4(parent),
	netx.is_subnet_of4(subnet1, parent))

	fmt.printf("Is %s a subnet of %s? %v\n",
	netx.network_to_string4(subnet2),
	netx.network_to_string4(parent),
	netx.is_subnet_of4(subnet2, parent))

	fmt.printf("Is %s a subnet of %s? %v\n",
	netx.network_to_string4(outside),
	netx.network_to_string4(parent),
	netx.is_subnet_of4(outside, parent))

	// Navigating through adjacent networks
	fmt.println("\nNavigating through /28 networks:")
	current := netx.must_parse_cidr4("192.168.1.0/28")
	for i := 0; i < 3; i += 1 {
		fmt.printf("  %s\n", netx.network_to_string4(current))
		next, ok_next := netx.next_network4(current)
		if !ok_next {
			break
		}
		current = next
	}

	fmt.println("\n--- IPv4: Bitwise Operations ---")

	ip := net.IP4_Address{192, 168, 1, 130}
	mask := net.IP4_Address{255, 255, 255, 128}
	network_addr := netx.ip4_and(ip, mask)
	fmt.printf("AND: %s & %s = %s\n", netx.addr_to_string4(ip), netx.addr_to_string4(mask), netx.addr_to_string4(network_addr))

	net_addr := net.IP4_Address{192, 168, 1, 0}
	wildcard := netx.ip4_not(mask)
	broadcast := netx.ip4_or(net_addr, wildcard)
	fmt.printf("OR: %s | %s = %s\n", netx.addr_to_string4(net_addr), netx.addr_to_string4(wildcard), netx.addr_to_string4(broadcast))

	original := net.IP4_Address{192, 168, 1, 1}
	key := net.IP4_Address{0xDE, 0xAD, 0xBE, 0xEF}
	encrypted := netx.ip4_xor(original, key)
	decrypted := netx.ip4_xor(encrypted, key)
	fmt.printf("XOR: %s ^ %s = %s (decrypt: %s)\n",
	netx.addr_to_string4(original), netx.addr_to_string4(key),
	netx.addr_to_string4(encrypted), netx.addr_to_string4(decrypted))

	subnet_mask := net.IP4_Address{255, 255, 255, 0}
	host_mask := netx.ip4_not(subnet_mask)
	fmt.printf("NOT: ~%s = %s\n", netx.addr_to_string4(subnet_mask), netx.addr_to_string4(host_mask))

	// ========================================================================
	// IPv6 EXAMPLES
	// ========================================================================

	fmt.println("\n\n=== IPv6 Examples ===\n")

	fmt.println("--- IPv6: Parsing CIDR ---")
	network6, ok6 := netx.parse_cidr6("2001:db8::/32")
	if ok6 {
		fmt.printf("Parsed: %s\n", netx.network_to_string6(network6))
	}

	fmt.println("\n--- IPv6: Well-Known Addresses ---")
	fmt.printf("IPv6 unspecified: %s\n", netx.addr_to_string6(netx.ipv6_unspecified()))
	fmt.printf("IPv6 loopback: %s\n", netx.addr_to_string6(netx.ipv6_loopback()))
	fmt.printf("IPv6 link-local all nodes: %s\n", netx.addr_to_string6(netx.ipv6_link_local_all_nodes()))
	fmt.printf("IPv6 link-local all routers: %s\n", netx.addr_to_string6(netx.ipv6_link_local_all_routers()))

	fmt.println("\n--- IPv6: Classification ---")
	loopback6 := netx.ipv6_loopback()
	unspec6 := netx.ipv6_unspecified()

	link_local6: net.IP6_Address
	ll_segments := cast([8]u16be)link_local6
	ll_segments[0] = 0xFE80
	ll_segments[7] = 0x0001
	link_local6 = cast(net.IP6_Address)ll_segments

	private6: net.IP6_Address
	priv_segments := cast([8]u16be)private6
	priv_segments[0] = 0xFC00
	priv_segments[7] = 0x0001
	private6 = cast(net.IP6_Address)priv_segments

	multicast6: net.IP6_Address
	mc_segments := cast([8]u16be)multicast6
	mc_segments[0] = 0xFF02
	mc_segments[7] = 0x0001
	multicast6 = cast(net.IP6_Address)mc_segments

	fmt.printf("%s is loopback: %v\n", netx.addr_to_string6(loopback6), netx.is_loopback6(loopback6))
	fmt.printf("%s is unspecified: %v\n", netx.addr_to_string6(unspec6), netx.is_unspecified6(unspec6))
	fmt.printf("%s is link-local: %v\n", netx.addr_to_string6(link_local6), netx.is_link_local6(link_local6))
	fmt.printf("%s is private: %v\n", netx.addr_to_string6(private6), netx.is_private6(private6))
	fmt.printf("%s is multicast: %v\n", netx.addr_to_string6(multicast6), netx.is_multicast6(multicast6))

	fmt.println("\n--- IPv6: Network Membership ---")
	test_addr6: net.IP6_Address
	test_segments := cast([8]u16be)test_addr6
	test_segments[0] = 0x2001
	test_segments[1] = 0x0DB8
	test_segments[7] = 0x0001
	test_addr6 = cast(net.IP6_Address)test_segments

	fmt.printf("Does %s contain %s? %v\n",
	netx.network_to_string6(network6), netx.addr_to_string6(test_addr6), netx.contains6(network6, test_addr6))

	fmt.println("\n--- IPv6: Network Ranges ---")
	range6 := netx.network_range6(network6)
	fmt.printf("First address: %s\n", netx.addr_to_string6(range6.start))
	fmt.printf("Last address: %s\n", netx.addr_to_string6(range6.end))

	fmt.println("\n--- IPv6: Accessors ---")
	fmt.printf("Network address: %s\n", netx.addr_to_string6(netx.network_addr6(network6)))
	fmt.printf("Prefix length: %d\n", netx.network_bits6(network6))

	fmt.println("\n--- IPv6: IP Iteration ---")
	start_ip6 := netx.ipv6_loopback()
	fmt.printf("Starting from: %s\n", netx.addr_to_string6(start_ip6))
	next_ip6, next_ok6 := netx.next_ip6(start_ip6)
	if next_ok6 {
		fmt.printf("Next IP: %s\n", netx.addr_to_string6(next_ip6))
	}
	prev_ip6, prev_ok6 := netx.prev_ip6(next_ip6)
	if prev_ok6 {
		fmt.printf("Previous IP: %s\n", netx.addr_to_string6(prev_ip6))
	}

	fmt.println("\n--- IPv6: Comparison ---")
	net6_a := netx.must_parse_cidr6("2001:db8::/32")
	net6_b := netx.must_parse_cidr6("2001:db8:1::/48")
	cmp6 := netx.compare_network6(net6_a, net6_b)
	fmt.printf("Compare %s vs %s: %d\n",
	netx.network_to_string6(net6_a),
	netx.network_to_string6(net6_b),
	cmp6)

	fmt.println("\n--- IPv6: Network Overlap ---")
	fmt.printf("Do %s and %s overlap? %v\n",
	netx.network_to_string6(net6_a),
	netx.network_to_string6(net6_b),
	netx.overlaps6(net6_a, net6_b))

	fmt.println("\n--- IPv6: Network Navigation ---")
	base_net6 := netx.must_parse_cidr6("2001:db8::/64")
	fmt.printf("Base network: %s\n", netx.network_to_string6(base_net6))

	next_net6, next_net6_ok := netx.next_network6(base_net6)
	if next_net6_ok {
		fmt.printf("Next network: %s\n", netx.network_to_string6(next_net6))
	}

	prev_net6, prev_net6_ok := netx.prev_network6(base_net6)
	if prev_net6_ok {
		fmt.printf("Previous network: %s\n", netx.network_to_string6(prev_net6))
	}

	parent_net6, parent_net6_ok := netx.parent_network6(base_net6)
	if parent_net6_ok {
		fmt.printf("Parent network (one bit less specific): %s\n", netx.network_to_string6(parent_net6))
	}

	fmt.println("\n--- IPv6: Subnet Relationships ---")
	parent6 := netx.must_parse_cidr6("2001:db8::/32")
	subnet6_1 := netx.must_parse_cidr6("2001:db8:1::/48")
	subnet6_2 := netx.must_parse_cidr6("2001:db8:1:2::/64")
	outside6 := netx.must_parse_cidr6("2001:db9::/32")

	fmt.printf("Is %s a subnet of %s? %v\n",
	netx.network_to_string6(subnet6_1),
	netx.network_to_string6(parent6),
	netx.is_subnet_of6(subnet6_1, parent6))

	fmt.printf("Is %s a subnet of %s? %v\n",
	netx.network_to_string6(subnet6_2),
	netx.network_to_string6(parent6),
	netx.is_subnet_of6(subnet6_2, parent6))

	fmt.printf("Is %s a subnet of %s? %v\n",
	netx.network_to_string6(outside6),
	netx.network_to_string6(parent6),
	netx.is_subnet_of6(outside6, parent6))

	fmt.println("\n--- IPv6: Bitwise Operations ---")

	segments_addr: [8]u16be = {0x2001, 0x0DB8, 0, 0, 0, 0, 0, 0x1234}
	ipv6_addr := cast(net.IP6_Address)segments_addr
	segments_mask: [8]u16be = {0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0, 0, 0, 0}
	ipv6_mask := cast(net.IP6_Address)segments_mask
	ipv6_network := netx.ip6_and(ipv6_addr, ipv6_mask)
	fmt.printf("AND: %s & /64 = %s\n", netx.addr_to_string6(ipv6_addr), netx.addr_to_string6(ipv6_network))

	segments_a: [8]u16be = {0x2001, 0, 0, 0, 0, 0, 0, 0}
	ipv6_a := cast(net.IP6_Address)segments_a
	segments_b: [8]u16be = {0, 0, 0, 0, 0, 0, 0, 0x0001}
	ipv6_b := cast(net.IP6_Address)segments_b
	ipv6_combined := netx.ip6_or(ipv6_a, ipv6_b)
	fmt.printf("OR: %s | %s = %s\n", netx.addr_to_string6(ipv6_a), netx.addr_to_string6(ipv6_b), netx.addr_to_string6(ipv6_combined))

	segments_original: [8]u16be = {0x2001, 0x0DB8, 0, 0, 0, 0, 0, 0x0001}
	ipv6_original := cast(net.IP6_Address)segments_original
	segments_key: [8]u16be = {0, 0, 0, 0, 0, 0, 0, 0xDEAD}
	ipv6_key := cast(net.IP6_Address)segments_key
	ipv6_encrypted := netx.ip6_xor(ipv6_original, ipv6_key)
	ipv6_decrypted := netx.ip6_xor(ipv6_encrypted, ipv6_key)
	fmt.printf("XOR: %s ^ %s = %s (decrypt: %s)\n",
	netx.addr_to_string6(ipv6_original), netx.addr_to_string6(ipv6_key),
	netx.addr_to_string6(ipv6_encrypted), netx.addr_to_string6(ipv6_decrypted))

	segments_test: [8]u16be = {0xFFFF, 0, 0, 0, 0, 0, 0, 0}
	ipv6_test := cast(net.IP6_Address)segments_test
	ipv6_inverted := netx.ip6_not(ipv6_test)
	fmt.printf("NOT: ~%s = %s\n", netx.addr_to_string6(ipv6_test), netx.addr_to_string6(ipv6_inverted))

	fmt.println("\n\n=== Address:Port Operations ===\n")

	fmt.println("--- IPv4 Address:Port ---")
	// Parse IPv4:port
	addr_port4, ok4 := netx.parse_addr_port4("192.168.1.100:8080")
	if ok4 {
		fmt.printf("Parsed: %s\n", netx.addr_port_to_string4(addr_port4))
		fmt.printf("  Address: %s\n", netx.addr_to_string4(addr_port4.addr))
		fmt.printf("  Port: %d\n", addr_port4.port)
	}

	// Common service ports
	http_server := netx.must_parse_addr_port4("0.0.0.0:80")
	https_server := netx.must_parse_addr_port4("0.0.0.0:443")
	fmt.printf("HTTP server: %s\n", netx.addr_port_to_string4(http_server))
	fmt.printf("HTTPS server: %s\n", netx.addr_port_to_string4(https_server))

	fmt.println("\n--- IPv6 Address:Port ---")
	// Parse [IPv6]:port (note the brackets!)
	addr_port6, ok_ap6 := netx.parse_addr_port6("[2001:db8::1]:8080")
	if ok_ap6 {
		fmt.printf("Parsed: %s\n", netx.addr_port_to_string6(addr_port6))
		fmt.printf("  Address: %s\n", netx.addr_to_string6(addr_port6.addr))
		fmt.printf("  Port: %d\n", addr_port6.port)
	}

	// IPv6 loopback with port
	loopback_server := netx.must_parse_addr_port6("[::1]:3000")
	fmt.printf("Loopback server: %s\n", netx.addr_port_to_string6(loopback_server))

	fmt.println("\n\n=== IPv4-Mapped IPv6 Addresses ===\n")

	fmt.println("--- Converting IPv4 to IPv4-Mapped IPv6 ---")
	ipv4_addr := net.IP4_Address{192, 0, 2, 1}
	mapped := netx.ipv4_to_ipv6_mapped(ipv4_addr)
	fmt.printf("IPv4: %s\n", netx.addr_to_string4(ipv4_addr))
	fmt.printf("IPv4-mapped IPv6: %s\n", netx.addr_to_string6(mapped))
	fmt.printf("Is IPv4-mapped? %v\n", netx.is_ipv4_mapped6(mapped))

	fmt.println("\n--- Extracting IPv4 from Mapped Address ---")
	if extracted, ok_extract := netx.ipv6_to_ipv4_mapped(mapped); ok_extract {
		fmt.printf("Extracted IPv4: %s\n", netx.addr_to_string4(extracted))
		fmt.printf("Matches original? %v\n", extracted == ipv4_addr)
	}

	fmt.println("\n--- Dual-Stack Server Example ---")
	// Simulating what you might see in network logs when IPv4 clients
	// connect to an IPv6 socket
	ipv4_clients := []net.IP4_Address{
		{10, 0, 1, 100},
		{192, 168, 1, 50},
		{172, 16, 0, 25},
	}

	fmt.println("Connections from IPv4 clients (as seen by IPv6 socket):")
	for client in ipv4_clients {
		mapped_client := netx.ipv4_to_ipv6_mapped(client)
		fmt.printf("  Client %s appears as %s\n",
			netx.addr_to_string4(client),
			netx.addr_to_string6(mapped_client))
	}

	fmt.println("\n--- Checking Various IPv6 Addresses ---")
	test_addrs := []struct{addr: net.IP6_Address, name: string}{
		{netx.ipv4_to_ipv6_mapped(net.IP4_Address{127, 0, 0, 1}), "Mapped loopback"},
		{netx.ipv6_loopback(), "Native ::1"},
		{netx.ipv6_unspecified(), "Unspecified ::"},
		{netx.must_parse_cidr6("2001:db8::1/128").address, "Regular IPv6"},
	}

	for test in test_addrs {
		is_mapped := netx.is_ipv4_mapped6(test.addr)
		fmt.printf("%20s (%s): IPv4-mapped? %v\n",
			test.name,
			netx.addr_to_string6(test.addr),
			is_mapped)
	}

	// ========================================================================
	// RANDOM IP GENERATION
	// ========================================================================

	fmt.println("\n========================================")
	fmt.println("RANDOM IP GENERATION")
	fmt.println("========================================")

	fmt.println("\n--- Random IPv4 Addresses in Network ---")
	test_network := netx.must_parse_cidr4("192.168.1.0/24")
	fmt.printf("Generating random IPs in %s:\n", netx.network_to_string4(test_network))
	for i in 0 ..< 5 {
		random_ip := netx.random_ip4_in_network(test_network)
		fmt.printf("  Random IP %d: %s\n", i+1, netx.addr_to_string4(random_ip))
		// Verify it's actually in the network
		if !netx.contains4(test_network, random_ip) {
			fmt.println("    ERROR: IP not in network!")
		}
	}


	// ========================================================================
	// IPv6 ZONE ID EXAMPLES (Scoped Addresses)
	// ========================================================================

	fmt.println("\n========================================")
	fmt.println("IPv6 ZONE ID EXAMPLES")
	fmt.println("========================================")

	fmt.println("\n--- IPv6 Addresses with Zone IDs ---")
	// Parse IPv6 addresses with interface identifiers (zone IDs)
	link_local_addr := netx.must_parse_addr_zone6("fe80::1%eth0")
	fmt.printf("Parsed link-local with zone: %s (zone: %s)\n",
		netx.addr_to_string6(link_local_addr.addr), link_local_addr.zone)
	fmt.printf("Is this a link-local address? %v\n", netx.is_link_local6(link_local_addr.addr))

	// Round-trip conversion
	addr_with_zone := netx.IP6_Addr_Zone{link_local_addr.addr, "ens33"}
	str_with_zone := netx.addr_zone_to_string6(addr_with_zone, context.temp_allocator)
	fmt.printf("Address with zone ID: %s\n", str_with_zone)

	// Parse IPv6 address without zone (also works)
	no_zone_addr, ok_no_zone := netx.parse_addr_zone6("2001:db8::1")
	if ok_no_zone {
		fmt.printf("Parsed without zone: %s (zone: '%s')\n",
			netx.addr_to_string6(no_zone_addr.addr), no_zone_addr.zone)
	}
	// ========================================================================
	// MASK CANONICAL FORM EXAMPLES
	// ========================================================================

	fmt.println("\n========================================")
	fmt.println("MASK CANONICAL FORM EXAMPLES")
	fmt.println("========================================")

	fmt.println("\n--- Checking if Networks are Canonical ---")
	// Canonical networks have all host bits set to zero
	canonical_net1 := netx.must_parse_cidr4("192.168.1.0/24")
	fmt.printf("Network %s is canonical: %v\n",
		netx.network_to_string4(canonical_net1), netx.is_canonical4(canonical_net1))

	canonical_net2 := netx.must_parse_cidr4("10.0.0.0/8")
	fmt.printf("Network %s is canonical: %v\n",
		netx.network_to_string4(canonical_net2), netx.is_canonical4(canonical_net2))

	// Non-canonical network (host bits are not zero)
	non_canonical := netx.network_from4(net.IP4_Address{192, 168, 1, 100}, 24)
	fmt.printf("Raw network %s is canonical: %v\n",
		netx.network_to_string4(non_canonical), netx.is_canonical4(non_canonical))

	// Fix by applying mask
	fixed := netx.masked4(non_canonical)
	fmt.printf("After masking: %s is canonical: %v\n",
		netx.network_to_string4(fixed), netx.is_canonical4(fixed))

	fmt.println("\n--- IPv6 Network Canonical Checks ---")
	ipv6_canonical := netx.must_parse_cidr6("2001:db8::/32")
	fmt.printf("IPv6 %s is canonical: %v\n",
		netx.network_to_string6(ipv6_canonical), netx.is_canonical6(ipv6_canonical))

	// Create non-canonical IPv6 network
	non_canonical6 := netx.network_from6(netx.ipv6_loopback(), 32)
	fmt.printf("Raw IPv6 %s is canonical: %v\n",
		netx.network_to_string6(non_canonical6), netx.is_canonical6(non_canonical6))

	fixed6 := netx.masked6(non_canonical6)
	fmt.printf("After masking: %s is canonical: %v\n",
		netx.network_to_string6(fixed6), netx.is_canonical6(fixed6))

	// ========================================================================
	// ADDRESS FAMILY HELPER EXAMPLES
	// ========================================================================

	fmt.println("\n========================================")
	fmt.println("ADDRESS FAMILY HELPER EXAMPLES")
	fmt.println("========================================")

	fmt.println("\n--- Detecting IPv4-Mapped IPv6 Addresses ---")
	regular_ipv4 := net.IP4_Address{192, 168, 1, 100}
	mapped_addr := netx.ipv4_to_ipv6_mapped(regular_ipv4)
	fmt.printf("IPv4 %s mapped to %s\n", netx.addr_to_string4(regular_ipv4), netx.addr_to_string6(mapped_addr))
	fmt.printf("Is IPv4-mapped? %v\n", netx.is_ipv4_mapped6(mapped))

	regular_ipv6 := netx.must_parse_cidr6("2001:db8::1/128").address
	fmt.printf("Native IPv6 %s\n", netx.addr_to_string6(regular_ipv6))
	fmt.printf("Is IPv4-mapped? %v\n", netx.is_ipv4_mapped6(regular_ipv6))

	fmt.println("\n--- Detecting 6to4 Addresses ---")
	// 6to4 addresses have a 2002::/16 prefix
	example6to4 := netx.must_parse_cidr6("2002::192.0.2.1/48")
	fmt.printf("Example 6to4 address: %s\n", netx.addr_to_string6(example6to4.address))
	fmt.printf("Is 6to4? %v (prefix matches 2002::/16)\n", netx.is_6to4(example6to4.address))

	fmt.printf("Loopback ::1 is 6to4? %v\n", netx.is_6to4(netx.ipv6_loopback()))
	regular_ipv6_2 := netx.must_parse_cidr6("2001:db8::1/128").address
	fmt.printf("Regular %s is 6to4? %v\n", netx.addr_to_string6(regular_ipv6_2), netx.is_6to4(regular_ipv6_2))

	fmt.println("\n--- Detecting Teredo Addresses ---")
	// Teredo addresses have a 2001::/32 prefix with special format
	teredo_addr := netx.must_parse_cidr6("2001::beef/32").address
	fmt.printf("Example Teredo-like address: %s\n", netx.addr_to_string6(teredo_addr))
	fmt.printf("Is Teredo? %v\n", netx.is_teredo(teredo_addr))

	fmt.printf("Loopback ::1 is Teredo? %v\n", netx.is_teredo(netx.ipv6_loopback()))
	fmt.printf("Regular %s is Teredo? %v\n", netx.addr_to_string6(regular_ipv6_2), netx.is_teredo(regular_ipv6_2))

	// ========================================================================
	// IANA SPECIAL NETWORKS CONSTANTS EXAMPLES
	// ========================================================================

	fmt.println("\n========================================")
	fmt.println("IANA SPECIAL NETWORKS CONSTANTS")
	fmt.println("========================================")

	fmt.println("\n--- Documentation and Testing Networks ---")
	// TEST-NET-1, 2, 3: RFC 5737 documentation ranges
	test_net1 := netx.TEST_NET_1()
	fmt.printf("TEST-NET-1 (192.0.2.0/24): %s\n", netx.network_to_string4(test_net1))

	test_ip1 := net.IP4_Address{192, 0, 2, 42}
	fmt.printf("  Is %s in TEST-NET-1? %v\n", netx.addr_to_string4(test_ip1), netx.test_net_1_addr4(test_ip1))

	test_net2 := netx.TEST_NET_2()
	fmt.printf("TEST-NET-2 (198.51.100.0/24): %s\n", netx.network_to_string4(test_net2))

	test_net3 := netx.TEST_NET_3()
	fmt.printf("TEST-NET-3 (203.0.113.0/24): %s\n", netx.network_to_string4(test_net3))

	fmt.println("\n--- Benchmarking Networks ---")
	// 198.18.0.0/15: RFC 2544 benchmarking
	benchmark_net := netx.BENCHMARK_NET()
	fmt.printf("Benchmark Network (RFC 2544): %s\n", netx.network_to_string4(benchmark_net))

	bench_ip1 := net.IP4_Address{198, 18, 0, 100}
	bench_ip2 := net.IP4_Address{198, 19, 255, 200}
	fmt.printf("  Is %s in benchmark range? %v\n", netx.addr_to_string4(bench_ip1), netx.benchmark_addr4(bench_ip1))
	fmt.printf("  Is %s in benchmark range? %v\n", netx.addr_to_string4(bench_ip2), netx.benchmark_addr4(bench_ip2))

	fmt.println("\n--- Carrier-Grade NAT (CGNAT) Network ---")
	// 100.64.0.0/10: RFC 6598 Shared Address Space
	cgnat_net := netx.CARRIER_GRADE_NAT_NET()
	fmt.printf("CGNAT Network (RFC 6598): %s\n", netx.network_to_string4(cgnat_net))

	cgnat_test_ips := []net.IP4_Address{
		{100, 64, 0, 1},        // First in range
		{100, 100, 50, 25},     // Middle of range
		{100, 127, 255, 255},   // Last in range
		{100, 63, 255, 255},    // Just before range
		{100, 128, 0, 0},       // Just after range
	}

	for test_ip in cgnat_test_ips {
		in_range := netx.is_carrier_grade_nat_addr4(test_ip)
		status := "is"
		if !in_range {
			status = "is NOT"
		}
		fmt.printf("  %s %s in CGNAT range\n",
			netx.addr_to_string4(test_ip),
			status)
	}
}
