package test_netx

import "core:net"
import "core:testing"
import netx "../"

// ============================================================================
// IP SET TESTS
// ============================================================================

@(test)
test_set_init_destroy4 :: proc(t: ^testing.T) {
	set := netx.set_init4(context.temp_allocator)
	defer netx.set_destroy4(&set)

	testing.expect_value(t, set.root, nil)
}

@(test)
test_set_init_destroy6 :: proc(t: ^testing.T) {
	set := netx.set_init6(context.temp_allocator)
	defer netx.set_destroy6(&set)

	testing.expect_value(t, set.root, nil)
}

@(test)
test_set_insert_contains4 :: proc(t: ^testing.T) {
	set := netx.set_init4(context.temp_allocator)
	defer netx.set_destroy4(&set)

	// Insert some networks
	netx.set_insert4(&set, netx.must_parse_cidr4("192.168.1.0/24"))
	netx.set_insert4(&set, netx.must_parse_cidr4("10.0.0.0/8"))

	// Test containment
	testing.expect(
		t,
		netx.set_contains4(&set, net.IP4_Address{192, 168, 1, 100}),
		"Should contain 192.168.1.100",
	)
	testing.expect(
		t,
		netx.set_contains4(&set, net.IP4_Address{10, 1, 2, 3}),
		"Should contain 10.1.2.3",
	)
	testing.expect(
		t,
		!netx.set_contains4(&set, net.IP4_Address{172, 16, 0, 1}),
		"Should not contain 172.16.0.1",
	)
}

@(test)
test_set_insert_contains6 :: proc(t: ^testing.T) {
	set := netx.set_init6(context.temp_allocator)
	defer netx.set_destroy6(&set)

	netx.set_insert6(&set, netx.must_parse_cidr6("2001:db8::/32"))

	// Address in range
	addr_in := netx.must_parse_cidr6("2001:db8::1/128").address
	testing.expect(t, netx.set_contains6(&set, addr_in), "Should contain 2001:db8::1")

	// Address out of range
	addr_out := netx.must_parse_cidr6("2001:db9::1/128").address
	testing.expect(t, !netx.set_contains6(&set, addr_out), "Should not contain 2001:db9::1")
}

@(test)
test_set_longest_match4 :: proc(t: ^testing.T) {
	set := netx.set_init4(context.temp_allocator)
	defer netx.set_destroy4(&set)

	// Insert overlapping networks
	net1 := netx.must_parse_cidr4("10.0.0.0/8")
	net2 := netx.must_parse_cidr4("10.1.0.0/16")
	net3 := netx.must_parse_cidr4("10.1.1.0/24")

	netx.set_insert4(&set, net1)
	netx.set_insert4(&set, net2)
	netx.set_insert4(&set, net3)

	// Test address in most specific network
	addr := net.IP4_Address{10, 1, 1, 100}
	match, ok := netx.set_longest_match4(&set, addr)
	testing.expect(t, ok, "Should find a match")
	testing.expect_value(t, match, net3)

	// Test address in less specific network
	addr2 := net.IP4_Address{10, 1, 2, 1}
	match2, ok2 := netx.set_longest_match4(&set, addr2)
	testing.expect(t, ok2, "Should find a match")
	testing.expect_value(t, match2, net2)

	// Test address in least specific network
	addr3 := net.IP4_Address{10, 2, 0, 1}
	match3, ok3 := netx.set_longest_match4(&set, addr3)
	testing.expect(t, ok3, "Should find a match")
	testing.expect_value(t, match3, net1)
}

@(test)
test_set_longest_match6 :: proc(t: ^testing.T) {
	set := netx.set_init6(context.temp_allocator)
	defer netx.set_destroy6(&set)

	// Insert overlapping networks
	net1 := netx.must_parse_cidr6("2001:db8::/32")
	net2 := netx.must_parse_cidr6("2001:db8:1::/48")

	netx.set_insert6(&set, net1)
	netx.set_insert6(&set, net2)

	// Address in more specific network
	addr := netx.must_parse_cidr6("2001:db8:1::1/128").address
	match, ok := netx.set_longest_match6(&set, addr)
	testing.expect(t, ok, "Should find a match")
	testing.expect_value(t, match, net2)
}

@(test)
test_set_remove4 :: proc(t: ^testing.T) {
	set := netx.set_init4(context.temp_allocator)
	defer netx.set_destroy4(&set)

	network := netx.must_parse_cidr4("192.168.1.0/24")
	netx.set_insert4(&set, network)

	// Verify it's there
	addr := net.IP4_Address{192, 168, 1, 1}
	testing.expect(t, netx.set_contains4(&set, addr), "Should contain address before removal")

	// Remove it
	removed := netx.set_remove4(&set, network)
	testing.expect(t, removed, "Should successfully remove")

	// Verify it's gone
	testing.expect(t, !netx.set_contains4(&set, addr), "Should not contain address after removal")
}

@(test)
test_set_remove6 :: proc(t: ^testing.T) {
	set := netx.set_init6(context.temp_allocator)
	defer netx.set_destroy6(&set)

	network := netx.must_parse_cidr6("2001:db8::/32")
	netx.set_insert6(&set, network)

	addr := netx.must_parse_cidr6("2001:db8::1/128").address
	testing.expect(t, netx.set_contains6(&set, addr), "Should contain before removal")

	removed := netx.set_remove6(&set, network)
	testing.expect(t, removed, "Should successfully remove")

	testing.expect(t, !netx.set_contains6(&set, addr), "Should not contain after removal")
}

@(test)
test_set_multiple_networks4 :: proc(t: ^testing.T) {
	set := netx.set_init4(context.temp_allocator)
	defer netx.set_destroy4(&set)

	// Insert multiple non-overlapping networks
	networks := []netx.IP4_Network{
		netx.must_parse_cidr4("10.0.0.0/8"),
		netx.must_parse_cidr4("172.16.0.0/12"),
		netx.must_parse_cidr4("192.168.0.0/16"),
	}

	for network in networks {
		netx.set_insert4(&set, network)
	}

	// Test addresses in each network
	testing.expect(
		t,
		netx.set_contains4(&set, net.IP4_Address{10, 1, 1, 1}),
		"Should contain 10.1.1.1",
	)
	testing.expect(
		t,
		netx.set_contains4(&set, net.IP4_Address{172, 16, 1, 1}),
		"Should contain 172.16.1.1",
	)
	testing.expect(
		t,
		netx.set_contains4(&set, net.IP4_Address{192, 168, 1, 1}),
		"Should contain 192.168.1.1",
	)

	// Test address not in any network
	testing.expect(
		t,
		!netx.set_contains4(&set, net.IP4_Address{8, 8, 8, 8}),
		"Should not contain 8.8.8.8",
	)
}

@(test)
test_set_empty4 :: proc(t: ^testing.T) {
	set := netx.set_init4(context.temp_allocator)
	defer netx.set_destroy4(&set)

	// Empty set should not contain anything
	testing.expect(
		t,
		!netx.set_contains4(&set, net.IP4_Address{10, 0, 0, 1}),
		"Empty set should not contain address",
	)

	_, ok := netx.set_longest_match4(&set, net.IP4_Address{10, 0, 0, 1})
	testing.expect(t, !ok, "Empty set should not have longest match")
}

@(test)
test_set_empty6 :: proc(t: ^testing.T) {
	set := netx.set_init6(context.temp_allocator)
	defer netx.set_destroy6(&set)

	addr := netx.must_parse_cidr6("2001:db8::1/128").address
	testing.expect(
		t,
		!netx.set_contains6(&set, addr),
		"Empty set should not contain address",
	)

	_, ok := netx.set_longest_match6(&set, addr)
	testing.expect(t, !ok, "Empty set should not have longest match")
}
