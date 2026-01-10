package main

import "core:fmt"
import "core:net"
import netx "../.."

main :: proc() {
	// ========================================================================
	// IP SET BASICS
	// ========================================================================

	fmt.println("--- IP Set Basics ---")
	fmt.println("IP sets use radix trees for fast O(log n) IP lookups")

	// Create an IPv4 set
	set := netx.set_init4(context.temp_allocator)
	defer netx.set_destroy4(&set)

	// Insert some networks
	fmt.println("\nInserting networks:")
	networks := []netx.IP4_Network{
		netx.must_parse_cidr4("192.168.1.0/24"),
		netx.must_parse_cidr4("10.0.0.0/8"),
		netx.must_parse_cidr4("172.16.0.0/12"),
	}

	for network in networks {
		netx.set_insert4(&set, network)
		fmt.printf("  Added: %s\n", netx.network_to_string4(network))
	}

	// Check if addresses are in the set
	fmt.println("\nChecking address membership:")
	test_addrs := []struct {
		addr:     net.IP4_Address,
		expected: bool,
	}{
		{{192, 168, 1, 100}, true},   // In first network
		{{10, 1, 2, 3}, true},        // In second network
		{{172, 16, 5, 1}, true},      // In third network
		{{8, 8, 8, 8}, false},        // Not in any network
		{{192, 168, 2, 1}, false},    // Not in any network
	}

	for test in test_addrs {
		contains := netx.set_contains4(&set, test.addr)
		status := contains == test.expected ? "✓" : "✗"
		fmt.printf("  %s %s: %v (expected %v)\n",
			status,
			netx.addr_to_string4(test.addr),
			contains,
			test.expected)
	}

	// ========================================================================
	// LONGEST PREFIX MATCHING
	// ========================================================================

	fmt.println("\n--- Longest Prefix Matching ---")
	fmt.println("Find the most specific network containing an address")

	// Create a set with overlapping networks
	routing_set := netx.set_init4(context.temp_allocator)
	defer netx.set_destroy4(&routing_set)

	routes := []netx.IP4_Network{
		netx.must_parse_cidr4("10.0.0.0/8"),      // Broad network
		netx.must_parse_cidr4("10.1.0.0/16"),     // More specific
		netx.must_parse_cidr4("10.1.1.0/24"),     // Most specific
	}

	fmt.println("\nAdding overlapping routes:")
	for route in routes {
		netx.set_insert4(&routing_set, route)
		fmt.printf("  %s\n", netx.network_to_string4(route))
	}

	// Test longest match
	fmt.println("\nFinding longest prefix matches:")
	lookups := []struct {
		addr:     net.IP4_Address,
		expected: string,
	}{
		{{10, 1, 1, 100}, "10.1.1.0/24"},   // Matches most specific
		{{10, 1, 2, 1}, "10.1.0.0/16"},     // Matches middle specificity
		{{10, 2, 0, 1}, "10.0.0.0/8"},      // Matches least specific
		{{192, 168, 1, 1}, "none"},         // No match
	}

	for lookup in lookups {
		match, ok := netx.set_longest_match4(&routing_set, lookup.addr)
		if ok {
			match_str := netx.network_to_string4(match)
			status := match_str == lookup.expected ? "✓" : "✗"
			fmt.printf("  %s %s → %s\n",
				status,
				netx.addr_to_string4(lookup.addr),
				match_str)
		} else {
			status := lookup.expected == "none" ? "✓" : "✗"
			fmt.printf("  %s %s → no match\n",
				status,
				netx.addr_to_string4(lookup.addr))
		}
	}

	// ========================================================================
	// FIREWALL RULES EXAMPLE
	// ========================================================================

	fmt.println("\n--- Firewall Rules Example ---")
	fmt.println("Using IP sets for fast firewall allow/deny checks")

	// Create allowed networks set
	allowed := netx.set_init4(context.temp_allocator)
	defer netx.set_destroy4(&allowed)

	allow_rules := []netx.IP4_Network{
		netx.must_parse_cidr4("10.0.0.0/8"),          // Internal network
		netx.must_parse_cidr4("192.168.0.0/16"),      // Office network
		netx.must_parse_cidr4("203.0.113.0/24"),      // Partner network
	}

	fmt.println("\nAllowed networks:")
	for rule in allow_rules {
		netx.set_insert4(&allowed, rule)
		fmt.printf("  %s\n", netx.network_to_string4(rule))
	}

	// Simulate incoming connections
	fmt.println("\nIncoming connection attempts:")
	connections := []struct {
		addr: net.IP4_Address,
		desc: string,
	}{
		{{10, 0, 1, 50}, "Internal server"},
		{{192, 168, 1, 100}, "Office laptop"},
		{{203, 0, 113, 42}, "Partner API"},
		{{1, 2, 3, 4}, "External attacker"},
		{{8, 8, 8, 8}, "Public DNS"},
	}

	for conn in connections {
		is_allowed := netx.set_contains4(&allowed, conn.addr)
		action := is_allowed ? "ALLOW" : "DENY"
		icon := is_allowed ? "✓" : "✗"
		fmt.printf("  %s [%s] %s (%s)\n",
			icon,
			action,
			netx.addr_to_string4(conn.addr),
			conn.desc)
	}

	// ========================================================================
	// NETWORK REMOVAL
	// ========================================================================

	fmt.println("\n--- Network Removal ---")
	fmt.println("Remove specific networks from the set")

	removal_set := netx.set_init4(context.temp_allocator)
	defer netx.set_destroy4(&removal_set)

	// Add networks
	initial_networks := []netx.IP4_Network{
		netx.must_parse_cidr4("192.168.1.0/24"),
		netx.must_parse_cidr4("192.168.2.0/24"),
		netx.must_parse_cidr4("192.168.3.0/24"),
	}

	fmt.println("\nInitial networks:")
	for network in initial_networks {
		netx.set_insert4(&removal_set, network)
		fmt.printf("  %s\n", netx.network_to_string4(network))
	}

	// Remove one network
	to_remove := netx.must_parse_cidr4("192.168.2.0/24")
	fmt.printf("\nRemoving: %s\n", netx.network_to_string4(to_remove))
	removed := netx.set_remove4(&removal_set, to_remove)
	fmt.printf("Removed successfully: %v\n", removed)

	// Check what's left
	fmt.println("\nVerifying remaining networks:")
	test_removal := []net.IP4_Address{
		{192, 168, 1, 1},  // Should be in set (not removed)
		{192, 168, 2, 1},  // Should NOT be in set (removed)
		{192, 168, 3, 1},  // Should be in set (not removed)
	}

	for addr in test_removal {
		contains := netx.set_contains4(&removal_set, addr)
		fmt.printf("  %s: %s\n",
			netx.addr_to_string4(addr),
			contains ? "present" : "absent")
	}

	// ========================================================================
	// IPv6 IP SETS
	// ========================================================================

	fmt.println("\n--- IPv6 IP Sets ---")

	set6 := netx.set_init6(context.temp_allocator)
	defer netx.set_destroy6(&set6)

	ipv6_networks := []netx.IP6_Network{
		netx.must_parse_cidr6("2001:db8::/32"),
		netx.must_parse_cidr6("2001:db8:1::/48"),
		netx.must_parse_cidr6("fd00::/8"),  // Unique Local Addresses
	}

	fmt.println("\nAdding IPv6 networks:")
	for network in ipv6_networks {
		netx.set_insert6(&set6, network)
		fmt.printf("  %s\n", netx.network_to_string6(network))
	}

	// Test IPv6 lookups
	fmt.println("\nIPv6 address lookups:")
	test_ipv6 := []struct {
		cidr:     string,
		expected: bool,
	}{
		{"2001:db8::1/128", true},          // In first network
		{"2001:db8:1::1/128", true},        // In second network (more specific)
		{"fd00::1/128", true},              // In ULA network
		{"2001:db9::1/128", false},         // Not in any network
	}

	for test in test_ipv6 {
		addr := netx.must_parse_cidr6(test.cidr).address
		contains := netx.set_contains6(&set6, addr)
		status := contains == test.expected ? "✓" : "✗"
		fmt.printf("  %s %s: %v\n",
			status,
			netx.addr_to_string6(addr),
			contains)
	}

	// Longest match for IPv6
	fmt.println("\nIPv6 longest prefix matching:")
	addr_specific := netx.must_parse_cidr6("2001:db8:1::100/128").address
	if match6, ok6 := netx.set_longest_match6(&set6, addr_specific); ok6 {
		fmt.printf("  %s → %s (most specific)\n",
			netx.addr_to_string6(addr_specific),
			netx.network_to_string6(match6))
	}

	// ========================================================================
	// GEOLOCATION/CDN USE CASE
	// ========================================================================

	fmt.println("\n--- CDN/Geolocation Use Case ---")
	fmt.println("Using IP sets to route traffic to nearest datacenter")

	// Different datacenters serve different IP ranges
	us_east := netx.set_init4(context.temp_allocator)
	defer netx.set_destroy4(&us_east)

	us_west := netx.set_init4(context.temp_allocator)
	defer netx.set_destroy4(&us_west)

	europe := netx.set_init4(context.temp_allocator)
	defer netx.set_destroy4(&europe)

	// Simplified regional IP assignments (not real)
	netx.set_insert4(&us_east, netx.must_parse_cidr4("192.0.2.0/24"))    // Example range
	netx.set_insert4(&us_west, netx.must_parse_cidr4("198.51.100.0/24")) // Example range
	netx.set_insert4(&europe, netx.must_parse_cidr4("203.0.113.0/24"))   // Example range

	fmt.println("\nRouting requests to nearest datacenter:")
	requests := []net.IP4_Address{
		{192, 0, 2, 50},
		{198, 51, 100, 42},
		{203, 0, 113, 100},
	}

	for req in requests {
		datacenter := "Unknown"
		if netx.set_contains4(&us_east, req) {
			datacenter = "US-East"
		} else if netx.set_contains4(&us_west, req) {
			datacenter = "US-West"
		} else if netx.set_contains4(&europe, req) {
			datacenter = "Europe"
		}
		fmt.printf("  %s → %s\n", netx.addr_to_string4(req), datacenter)
	}

	// ========================================================================
	// RATE LIMITING USE CASE
	// ========================================================================

	fmt.println("\n--- Rate Limiting Use Case ---")
	fmt.println("Track premium/trusted IP ranges for different rate limits")

	premium_ips := netx.set_init4(context.temp_allocator)
	defer netx.set_destroy4(&premium_ips)

	trusted_ips := netx.set_init4(context.temp_allocator)
	defer netx.set_destroy4(&trusted_ips)

	// Premium customers get higher rate limits
	netx.set_insert4(&premium_ips, netx.must_parse_cidr4("10.100.0.0/16"))
	netx.set_insert4(&trusted_ips, netx.must_parse_cidr4("10.200.0.0/16"))

	fmt.println("\nDetermining rate limits:")
	api_requests := []struct {
		addr:  net.IP4_Address,
		label: string,
	}{
		{{10, 100, 1, 50}, "Premium customer"},
		{{10, 200, 1, 25}, "Trusted partner"},
		{{203, 0, 113, 42}, "Public user"},
	}

	for req in api_requests {
		rate_limit := 100 // default: 100 req/min
		tier := "Standard"

		if netx.set_contains4(&premium_ips, req.addr) {
			rate_limit = 10000
			tier = "Premium"
		} else if netx.set_contains4(&trusted_ips, req.addr) {
			rate_limit = 1000
			tier = "Trusted"
		}

		fmt.printf("  %s (%s): %s tier = %d req/min\n",
			netx.addr_to_string4(req.addr),
			req.label,
			tier,
			rate_limit)
	}

	fmt.println("\n--- Performance Note ---")
	fmt.println("IP sets use radix trees for efficient prefix matching:")
	fmt.println("  • Insertion: O(k) where k is key length (32 or 128 bits)")
	fmt.println("  • Lookup: O(k) - much faster than iterating all networks")
	fmt.println("  • Memory: Only stores prefixes, not individual IPs")
	fmt.println("  • Ideal for: firewalls, routing, ACLs, rate limiting")
}
