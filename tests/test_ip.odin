package test_netx

import "core:net"
import "core:testing"
import netx "../"

// ============================================================================
// PARSING AND FORMATTING TESTS
// ============================================================================

@(test)
test_parse_cidr4 :: proc(t: ^testing.T) {
	// Valid CIDR
	network, ok := netx.parse_cidr4("192.168.1.0/24")
	testing.expect(t, ok, "Should parse valid CIDR")
	testing.expect_value(t, network.address, net.IP4_Address{192, 168, 1, 0})
	testing.expect_value(t, network.prefix_len, u8(24))

	// CIDR with non-zero host bits (should normalize)
	network2, ok2 := netx.parse_cidr4("192.168.1.100/24")
	testing.expect(t, ok2, "Should parse CIDR with host bits")
	testing.expect_value(t, network2.address, net.IP4_Address{192, 168, 1, 0})

	// /32
	network32, ok32 := netx.parse_cidr4("8.8.8.8/32")
	testing.expect(t, ok32, "Should parse /32")
	testing.expect_value(t, network32.prefix_len, u8(32))

	// /0
	network0, ok0 := netx.parse_cidr4("0.0.0.0/0")
	testing.expect(t, ok0, "Should parse /0")
	testing.expect_value(t, network0.prefix_len, u8(0))

	// Invalid cases
	_, bad1 := netx.parse_cidr4("192.168.1.0")
	testing.expect(t, !bad1, "Should fail without prefix")

	_, bad2 := netx.parse_cidr4("192.168.1.0/33")
	testing.expect(t, !bad2, "Should fail with prefix > 32")

	_, bad3 := netx.parse_cidr4("not.an.ip/24")
	testing.expect(t, !bad3, "Should fail with invalid IP")
}

@(test)
test_addr_to_string4 :: proc(t: ^testing.T) {
	// Test standard address
	addr1 := net.IP4_Address{192, 168, 1, 100}
	str1 := netx.addr_to_string4(addr1, context.temp_allocator)
	testing.expect_value(t, str1, "192.168.1.100")

	// Test zeros
	addr2 := net.IP4_Address{0, 0, 0, 0}
	str2 := netx.addr_to_string4(addr2, context.temp_allocator)
	testing.expect_value(t, str2, "0.0.0.0")

	// Test broadcast
	addr3 := net.IP4_Address{255, 255, 255, 255}
	str3 := netx.addr_to_string4(addr3, context.temp_allocator)
	testing.expect_value(t, str3, "255.255.255.255")

	// Test loopback
	addr4 := net.IP4_Address{127, 0, 0, 1}
	str4 := netx.addr_to_string4(addr4, context.temp_allocator)
	testing.expect_value(t, str4, "127.0.0.1")

	// Test public DNS
	addr5 := net.IP4_Address{8, 8, 8, 8}
	str5 := netx.addr_to_string4(addr5, context.temp_allocator)
	testing.expect_value(t, str5, "8.8.8.8")
}


@(test)
test_network_to_string4 :: proc(t: ^testing.T) {
	network := netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 24}
	str := netx.network_to_string4(network, context.temp_allocator)
	testing.expect_value(t, str, "192.168.1.0/24")

	network32 := netx.IP4_Network{net.IP4_Address{8, 8, 8, 8}, 32}
	str32 := netx.network_to_string4(network32, context.temp_allocator)
	testing.expect_value(t, str32, "8.8.8.8/32")
}

@(test)
test_masked4 :: proc(t: ^testing.T) {
	// Network with host bits set
	dirty := netx.IP4_Network{net.IP4_Address{192, 168, 1, 100}, 24}
	clean := netx.masked4(dirty)
	testing.expect_value(t, clean.address, net.IP4_Address{192, 168, 1, 0})
	testing.expect_value(t, clean.prefix_len, u8(24))
}

@(test)
test_parse_cidr6 :: proc(t: ^testing.T) {
	// Valid CIDR
	network, ok := netx.parse_cidr6("2001:db8::/32")
	testing.expect(t, ok, "Should parse valid CIDR")
	testing.expect_value(t, network.prefix_len, u8(32))

	// CIDR with non-zero host bits (should normalize)
	network2, ok2 := netx.parse_cidr6("2001:db8::1/32")
	testing.expect(t, ok2, "Should parse CIDR with host bits")
	testing.expect_value(t, network2.address, network.address)

	// /128
	network128, ok128 := netx.parse_cidr6("::1/128")
	testing.expect(t, ok128, "Should parse /128")
	testing.expect_value(t, network128.prefix_len, u8(128))

	// /0
	network0, ok0 := netx.parse_cidr6("::/0")
	testing.expect(t, ok0, "Should parse /0")
	testing.expect_value(t, network0.prefix_len, u8(0))

	// Invalid cases
	_, bad1 := netx.parse_cidr6("2001:db8::")
	testing.expect(t, !bad1, "Should fail without prefix")

	_, bad2 := netx.parse_cidr6("2001:db8::/129")
	testing.expect(t, !bad2, "Should fail with prefix > 128")

	_, bad3 := netx.parse_cidr6("not.valid/64")
	testing.expect(t, !bad3, "Should fail with invalid IP")
}

@(test)
test_addr_to_string6 :: proc(t: ^testing.T) {
	// Test loopback (::1)
	loopback := netx.ipv6_loopback()
	str_loopback := netx.addr_to_string6(loopback, context.temp_allocator)
	testing.expect_value(t, str_loopback, "::1")

	// Test unspecified (::)
	unspec := netx.ipv6_unspecified()
	str_unspec := netx.addr_to_string6(unspec, context.temp_allocator)
	testing.expect_value(t, str_unspec, "::")

	// Test link-local all nodes (ff02::1)
	all_nodes := netx.ipv6_link_local_all_nodes()
	str_all_nodes := netx.addr_to_string6(all_nodes, context.temp_allocator)
	testing.expect_value(t, str_all_nodes, "ff02::1")

	// Test link-local all routers (ff02::2)
	all_routers := netx.ipv6_link_local_all_routers()
	str_all_routers := netx.addr_to_string6(all_routers, context.temp_allocator)
	testing.expect_value(t, str_all_routers, "ff02::2")

	// Test standard address (2001:db8::1)
	segments: [8]u16be
	segments[0] = 0x2001
	segments[1] = 0x0db8
	segments[7] = 0x0001
	addr := cast(net.IP6_Address)segments
	str_addr := netx.addr_to_string6(addr, context.temp_allocator)
	testing.expect_value(t, str_addr, "2001:db8::1")

	// Test no compression needed (2001:db8:0:1:2:3:4:5)
	segments_full: [8]u16be
	segments_full[0] = 0x2001
	segments_full[1] = 0x0db8
	segments_full[2] = 0x0000
	segments_full[3] = 0x0001
	segments_full[4] = 0x0002
	segments_full[5] = 0x0003
	segments_full[6] = 0x0004
	segments_full[7] = 0x0005
	addr_full := cast(net.IP6_Address)segments_full
	str_full := netx.addr_to_string6(addr_full, context.temp_allocator)
	testing.expect_value(t, str_full, "2001:db8:0:1:2:3:4:5")
}

@(test)
test_network_to_string6 :: proc(t: ^testing.T) {
	segments: [8]u16be
	segments[0] = 0x2001
	segments[1] = 0x0db8
	addr := cast(net.IP6_Address)segments

	network := netx.IP6_Network{addr, 32}
	str := netx.network_to_string6(network, context.temp_allocator)
	testing.expect_value(t, str, "2001:db8::/32")
}

@(test)
test_masked6 :: proc(t: ^testing.T) {
	// Create network with host bits set
	segments: [8]u16be
	segments[0] = 0x2001
	segments[1] = 0x0db8
	segments[7] = 0x0001  // host bit set
	addr := cast(net.IP6_Address)segments

	dirty := netx.IP6_Network{addr, 64}
	clean := netx.masked6(dirty)

	// Host bits should be cleared
	clean_segments := cast([8]u16be)clean.address
	testing.expect_value(t, u16(clean_segments[7]), u16(0))
	testing.expect_value(t, clean.prefix_len, u8(64))
}

// ============================================================================
// MASK CONVERSION TESTS
// ============================================================================

@(test)
test_prefix_to_mask4 :: proc(t: ^testing.T) {
	// Test /24
	mask, ok := netx.prefix_to_mask4(24)
	testing.expect(t, ok, "prefix_to_mask4 should succeed for /24")
	testing.expect_value(t, mask, [4]u8{255, 255, 255, 0})

	// Test /32
	mask32, ok32 := netx.prefix_to_mask4(32)
	testing.expect(t, ok32, "prefix_to_mask4 should succeed for /32")
	testing.expect_value(t, mask32, [4]u8{255, 255, 255, 255})

	// Test /0
	mask0, ok0 := netx.prefix_to_mask4(0)
	testing.expect(t, ok0, "prefix_to_mask4 should succeed for /0")
	testing.expect_value(t, mask0, [4]u8{0, 0, 0, 0})

	// Test /16
	mask16, ok16 := netx.prefix_to_mask4(16)
	testing.expect(t, ok16, "prefix_to_mask4 should succeed for /16")
	testing.expect_value(t, mask16, [4]u8{255, 255, 0, 0})

	// Test /28
	mask28, ok28 := netx.prefix_to_mask4(28)
	testing.expect(t, ok28, "prefix_to_mask4 should succeed for /28")
	testing.expect_value(t, mask28, [4]u8{255, 255, 255, 240})

	// Test invalid prefix
	_, ok_invalid := netx.prefix_to_mask4(33)
	testing.expect(t, !ok_invalid, "prefix_to_mask4 should fail for /33")
}

@(test)
test_mask4_to_prefix :: proc(t: ^testing.T) {
	// Test standard masks
	prefix24, ok24 := netx.mask4_to_prefix([4]u8{255, 255, 255, 0})
	testing.expect(t, ok24, "mask4_to_prefix should succeed")
	testing.expect_value(t, prefix24, u8(24))

	prefix16, ok16 := netx.mask4_to_prefix([4]u8{255, 255, 0, 0})
	testing.expect(t, ok16, "mask4_to_prefix should succeed")
	testing.expect_value(t, prefix16, u8(16))

	prefix8, ok8 := netx.mask4_to_prefix([4]u8{255, 0, 0, 0})
	testing.expect(t, ok8, "mask4_to_prefix should succeed")
	testing.expect_value(t, prefix8, u8(8))
}

@(test)
test_apply_mask4 :: proc(t: ^testing.T) {
	addr := net.IP4_Address{192, 168, 1, 100}
	mask := [4]u8{255, 255, 255, 0}

	result := netx.apply_mask4(addr, mask)
	testing.expect_value(t, result, net.IP4_Address{192, 168, 1, 0})
}

@(test)
test_prefix_to_mask6 :: proc(t: ^testing.T) {
	// Test /64
	mask64 := netx.prefix_to_mask6(64)
	for i in 0..<4 {
		testing.expect_value(t, u16(mask64[i]), u16(0xFFFF))
	}
	for i in 4..<8 {
		testing.expect_value(t, u16(mask64[i]), u16(0x0000))
	}

	// Test /128
	mask128 := netx.prefix_to_mask6(128)
	for i in 0..<8 {
		testing.expect_value(t, u16(mask128[i]), u16(0xFFFF))
	}

	// Test /0
	mask0 := netx.prefix_to_mask6(0)
	for i in 0..<8 {
		testing.expect_value(t, u16(mask0[i]), u16(0x0000))
	}

	// Test /32
	mask32 := netx.prefix_to_mask6(32)
	testing.expect_value(t, u16(mask32[0]), u16(0xFFFF))
	testing.expect_value(t, u16(mask32[1]), u16(0xFFFF))
	for i in 2..<8 {
		testing.expect_value(t, u16(mask32[i]), u16(0x0000))
	}

	// Test /48
	mask48 := netx.prefix_to_mask6(48)
	for i in 0..<3 {
		testing.expect_value(t, u16(mask48[i]), u16(0xFFFF))
	}
	for i in 3..<8 {
		testing.expect_value(t, u16(mask48[i]), u16(0x0000))
	}

	// Test /60 (partial segment)
	mask60 := netx.prefix_to_mask6(60)
	for i in 0..<3 {
		testing.expect_value(t, u16(mask60[i]), u16(0xFFFF))
	}
	testing.expect_value(t, u16(mask60[3]), u16(0xFFF0))
	for i in 4..<8 {
		testing.expect_value(t, u16(mask60[i]), u16(0x0000))
	}
}

@(test)
test_mask6_to_prefix :: proc(t: ^testing.T) {
	// Test /64
	mask64: [8]u16be
	for i in 0..<4 {
		mask64[i] = 0xFFFF
	}
	prefix64, ok64 := netx.mask6_to_prefix(mask64)
	testing.expect(t, ok64, "mask6_to_prefix should succeed")
	testing.expect_value(t, prefix64, u8(64))

	// Test /128
	mask128: [8]u16be
	for i in 0..<8 {
		mask128[i] = 0xFFFF
	}
	prefix128, ok128 := netx.mask6_to_prefix(mask128)
	testing.expect(t, ok128, "mask6_to_prefix should succeed")
	testing.expect_value(t, prefix128, u8(128))

	// Test /0
	mask0: [8]u16be
	prefix0, ok0 := netx.mask6_to_prefix(mask0)
	testing.expect(t, ok0, "mask6_to_prefix should succeed")
	testing.expect_value(t, prefix0, u8(0))

	// Test /32
	mask32: [8]u16be
	mask32[0] = 0xFFFF
	mask32[1] = 0xFFFF
	prefix32, ok32 := netx.mask6_to_prefix(mask32)
	testing.expect(t, ok32, "mask6_to_prefix should succeed")
	testing.expect_value(t, prefix32, u8(32))

	// Test /48
	mask48: [8]u16be
	mask48[0] = 0xFFFF
	mask48[1] = 0xFFFF
	mask48[2] = 0xFFFF
	prefix48, ok48 := netx.mask6_to_prefix(mask48)
	testing.expect(t, ok48, "mask6_to_prefix should succeed")
	testing.expect_value(t, prefix48, u8(48))
}

@(test)
test_apply_mask6 :: proc(t: ^testing.T) {
	// Create address 2001:db8::100
	segments: [8]u16be
	segments[0] = 0x2001
	segments[1] = 0x0db8
	segments[7] = 0x0100
	addr := cast(net.IP6_Address)segments

	// Create /64 mask
	mask: [8]u16be
	for i in 0..<4 {
		mask[i] = 0xFFFF
	}

	result := netx.apply_mask6(addr, mask)
	result_segments := cast([8]u16be)result

	// First 4 segments should match
	testing.expect_value(t, u16(result_segments[0]), u16(0x2001))
	testing.expect_value(t, u16(result_segments[1]), u16(0x0db8))
	testing.expect_value(t, u16(result_segments[2]), u16(0))
	testing.expect_value(t, u16(result_segments[3]), u16(0))

	// Host bits should be cleared
	testing.expect_value(t, u16(result_segments[7]), u16(0))
}

// ============================================================================
// CLASSIFICATION TESTS
// ============================================================================

@(test)
test_is_private4 :: proc(t: ^testing.T) {
	// Private ranges
	testing.expect(t, netx.is_private4(net.IP4_Address{10, 0, 0, 1}), "10/8 is private")
	testing.expect(t, netx.is_private4(net.IP4_Address{172, 16, 0, 1}), "172.16/12 is private")
	testing.expect(t, netx.is_private4(net.IP4_Address{172, 31, 255, 255}), "172.31/12 is private")
	testing.expect(t, netx.is_private4(net.IP4_Address{192, 168, 1, 1}), "192.168/16 is private")

	// Not private
	testing.expect(t, !netx.is_private4(net.IP4_Address{8, 8, 8, 8}), "8.8.8.8 is not private")
	testing.expect(t, !netx.is_private4(net.IP4_Address{172, 15, 0, 1}), "172.15 is not private")
	testing.expect(t, !netx.is_private4(net.IP4_Address{172, 32, 0, 1}), "172.32 is not private")
}

@(test)
test_is_loopback4 :: proc(t: ^testing.T) {
	testing.expect(t, netx.is_loopback4(net.IP4_Address{127, 0, 0, 1}), "127.0.0.1 is loopback")
	testing.expect(t, netx.is_loopback4(net.IP4_Address{127, 255, 255, 255}), "127.255.255.255 is loopback")
	testing.expect(t, !netx.is_loopback4(net.IP4_Address{128, 0, 0, 1}), "128.0.0.1 is not loopback")
}

@(test)
test_is_link_local4 :: proc(t: ^testing.T) {
	testing.expect(t, netx.is_link_local4(net.IP4_Address{169, 254, 0, 1}), "169.254/16 is link-local")
	testing.expect(t, !netx.is_link_local4(net.IP4_Address{169, 253, 0, 1}), "169.253 is not link-local")
}

@(test)
test_is_multicast4 :: proc(t: ^testing.T) {
	testing.expect(t, netx.is_multicast4(net.IP4_Address{224, 0, 0, 1}), "224.0.0.1 is multicast")
	testing.expect(t, netx.is_multicast4(net.IP4_Address{239, 255, 255, 255}), "239.255.255.255 is multicast")
	testing.expect(t, !netx.is_multicast4(net.IP4_Address{223, 0, 0, 1}), "223.0.0.1 is not multicast")
}

@(test)
test_is_unspecified4 :: proc(t: ^testing.T) {
	testing.expect(t, netx.is_unspecified4(net.IP4_Address{0, 0, 0, 0}), "0.0.0.0 is unspecified")
	testing.expect(t, !netx.is_unspecified4(net.IP4_Address{0, 0, 0, 1}), "0.0.0.1 is not unspecified")
}

@(test)
test_is_broadcast4 :: proc(t: ^testing.T) {
	testing.expect(t, netx.is_broadcast4(net.IP4_Address{255, 255, 255, 255}), "255.255.255.255 is broadcast")
	testing.expect(t, !netx.is_broadcast4(net.IP4_Address{255, 255, 255, 254}), "255.255.255.254 is not broadcast")
}

@(test)
test_is_global_unicast4 :: proc(t: ^testing.T) {
	testing.expect(t, netx.is_global_unicast4(net.IP4_Address{8, 8, 8, 8}), "8.8.8.8 is global unicast")
	testing.expect(t, netx.is_global_unicast4(net.IP4_Address{1, 1, 1, 1}), "1.1.1.1 is global unicast")
	testing.expect(t, !netx.is_global_unicast4(net.IP4_Address{192, 168, 1, 1}), "192.168.1.1 is not global")
	testing.expect(t, !netx.is_global_unicast4(net.IP4_Address{127, 0, 0, 1}), "127.0.0.1 is not global")
}

@(test)
test_is_private6 :: proc(t: ^testing.T) {
	// Private/ULA range (fc00::/7)
	segments_private: [8]u16be
	segments_private[0] = 0xfc00
	private_addr := cast(net.IP6_Address)segments_private
	testing.expect(t, netx.is_private6(private_addr), "fc00::/7 is private")

	segments_private2: [8]u16be
	segments_private2[0] = 0xfd00
	private_addr2 := cast(net.IP6_Address)segments_private2
	testing.expect(t, netx.is_private6(private_addr2), "fd00::/7 is private")

	// Public address
	segments_public: [8]u16be
	segments_public[0] = 0x2001
	public_addr := cast(net.IP6_Address)segments_public
	testing.expect(t, !netx.is_private6(public_addr), "2001:: is not private")
}

@(test)
test_is_loopback6 :: proc(t: ^testing.T) {
	// Test loopback (::1)
	loopback := netx.ipv6_loopback()
	testing.expect(t, netx.is_loopback6(loopback), "::1 is loopback")

	// Test not loopback (::2)
	segments_not_loopback: [8]u16be
	segments_not_loopback[7] = 0x0002
	not_loopback := cast(net.IP6_Address)segments_not_loopback
	testing.expect(t, !netx.is_loopback6(not_loopback), "::2 is not loopback")

	// Test unspecified (::)
	unspec := netx.ipv6_unspecified()
	testing.expect(t, !netx.is_loopback6(unspec), ":: is not loopback")

	// Test other address
	segments_other: [8]u16be
	segments_other[0] = 0x2001
	other := cast(net.IP6_Address)segments_other
	testing.expect(t, !netx.is_loopback6(other), "2001:: is not loopback")
}


@(test)
test_is_link_local6 :: proc(t: ^testing.T) {
	// Link-local (fe80::/10)
	segments: [8]u16be
	segments[0] = 0xfe80
	addr := cast(net.IP6_Address)segments
	testing.expect(t, netx.is_link_local6(addr), "fe80::/10 is link-local")

	// Not link-local
	segments2: [8]u16be
	segments2[0] = 0xfe00
	addr2 := cast(net.IP6_Address)segments2
	testing.expect(t, !netx.is_link_local6(addr2), "fe00:: is not link-local")
}

@(test)
test_is_multicast6 :: proc(t: ^testing.T) {
	// Multicast (ff00::/8)
	segments: [8]u16be
	segments[0] = 0xff02
	addr := cast(net.IP6_Address)segments
	testing.expect(t, netx.is_multicast6(addr), "ff02:: is multicast")

	// Not multicast
	segments2: [8]u16be
	segments2[0] = 0xfe80
	addr2 := cast(net.IP6_Address)segments2
	testing.expect(t, !netx.is_multicast6(addr2), "fe80:: is not multicast")
}

@(test)
test_is_unspecified6 :: proc(t: ^testing.T) {
	// Test unspecified (::)
	unspec := netx.ipv6_unspecified()
	testing.expect(t, netx.is_unspecified6(unspec), ":: is unspecified")

	// Test loopback (::1) - not unspecified
	loopback := netx.ipv6_loopback()
	testing.expect(t, !netx.is_unspecified6(loopback), "::1 is not unspecified")

	// Test other address
	segments: [8]u16be
	segments[0] = 0x2001
	addr := cast(net.IP6_Address)segments
	testing.expect(t, !netx.is_unspecified6(addr), "2001:: is not unspecified")

	// Test address with only last segment set
	segments_last: [8]u16be
	segments_last[7] = 0x0001
	addr_last := cast(net.IP6_Address)segments_last
	testing.expect(t, !netx.is_unspecified6(addr_last), "::1 is not unspecified")
}

@(test)
test_is_global_unicast6 :: proc(t: ^testing.T) {
	// Global unicast
	segments: [8]u16be
	segments[0] = 0x2001
	segments[1] = 0x0db8
	addr := cast(net.IP6_Address)segments
	testing.expect(t, netx.is_global_unicast6(addr), "2001:db8:: is global unicast")

	// Not global (link-local)
	segments2: [8]u16be
	segments2[0] = 0xfe80
	addr2 := cast(net.IP6_Address)segments2
	testing.expect(t, !netx.is_global_unicast6(addr2), "fe80:: is not global")

	// Not global (loopback)
	loopback := netx.ipv6_loopback()
	testing.expect(t, !netx.is_global_unicast6(loopback), "::1 is not global")
}

@(test)
test_is_interface_local_multicast6 :: proc(t: ^testing.T) {
	// Test interface-local multicast (ff01::)
	segments_if_local: [8]u16be
	segments_if_local[0] = 0xff01
	if_local := cast(net.IP6_Address)segments_if_local
	testing.expect(t, netx.is_interface_local_multicast6(if_local), "ff01:: is interface-local multicast")

	// Test interface-local all nodes (ff01::1)
	segments_if_local_nodes: [8]u16be
	segments_if_local_nodes[0] = 0xff01
	segments_if_local_nodes[7] = 0x0001
	if_local_nodes := cast(net.IP6_Address)segments_if_local_nodes
	testing.expect(t, netx.is_interface_local_multicast6(if_local_nodes), "ff01::1 is interface-local multicast")

	// Test link-local multicast (ff02::) - not interface-local
	segments_link_local: [8]u16be
	segments_link_local[0] = 0xff02
	link_local := cast(net.IP6_Address)segments_link_local
	testing.expect(t, !netx.is_interface_local_multicast6(link_local), "ff02:: is not interface-local multicast")

	// Test non-multicast
	segments_unicast: [8]u16be
	segments_unicast[0] = 0x2001
	unicast := cast(net.IP6_Address)segments_unicast
	testing.expect(t, !netx.is_interface_local_multicast6(unicast), "2001:: is not interface-local multicast")
}

@(test)
test_is_link_local_multicast6 :: proc(t: ^testing.T) {
	// Test link-local multicast (ff02::)
	segments_link_local: [8]u16be
	segments_link_local[0] = 0xff02
	link_local := cast(net.IP6_Address)segments_link_local
	testing.expect(t, netx.is_link_local_multicast6(link_local), "ff02:: is link-local multicast")

	// Test link-local all nodes (ff02::1)
	all_nodes := netx.ipv6_link_local_all_nodes()
	testing.expect(t, netx.is_link_local_multicast6(all_nodes), "ff02::1 is link-local multicast")

	// Test link-local all routers (ff02::2)
	all_routers := netx.ipv6_link_local_all_routers()
	testing.expect(t, netx.is_link_local_multicast6(all_routers), "ff02::2 is link-local multicast")

	// Test interface-local multicast (ff01::) - not link-local
	segments_if_local: [8]u16be
	segments_if_local[0] = 0xff01
	if_local := cast(net.IP6_Address)segments_if_local
	testing.expect(t, !netx.is_link_local_multicast6(if_local), "ff01:: is not link-local multicast")

	// Test non-multicast
	segments_unicast: [8]u16be
	segments_unicast[0] = 0x2001
	unicast := cast(net.IP6_Address)segments_unicast
	testing.expect(t, !netx.is_link_local_multicast6(unicast), "2001:: is not link-local multicast")
}

// ============================================================================
// NETWORK MEMBERSHIP TESTS
// ============================================================================

@(test)
test_contains4 :: proc(t: ^testing.T) {
	network := netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 24}

	// Test addresses within network
	testing.expect(t, netx.contains4(network, net.IP4_Address{192, 168, 1, 1}), "Should contain 192.168.1.1")
	testing.expect(t, netx.contains4(network, net.IP4_Address{192, 168, 1, 100}), "Should contain 192.168.1.100")
	testing.expect(t, netx.contains4(network, net.IP4_Address{192, 168, 1, 255}), "Should contain 192.168.1.255")

	// Test addresses outside network
	testing.expect(t, !netx.contains4(network, net.IP4_Address{192, 168, 2, 1}), "Should not contain 192.168.2.1")
	testing.expect(t, !netx.contains4(network, net.IP4_Address{192, 168, 0, 255}), "Should not contain 192.168.0.255")
	testing.expect(t, !netx.contains4(network, net.IP4_Address{10, 0, 0, 1}), "Should not contain 10.0.0.1")
}


@(test)
test_overlaps4 :: proc(t: ^testing.T) {
	net_a := netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 24}
	net_b := netx.IP4_Network{net.IP4_Address{192, 168, 1, 128}, 25}
	net_c := netx.IP4_Network{net.IP4_Address{192, 168, 2, 0}, 24}

	testing.expect(t, netx.overlaps4(net_a, net_b), "192.168.1.0/24 overlaps 192.168.1.128/25")
	testing.expect(t, netx.overlaps4(net_b, net_a), "Overlap is symmetric")
	testing.expect(t, !netx.overlaps4(net_a, net_c), "192.168.1.0/24 doesn't overlap 192.168.2.0/24")
}

@(test)
test_contains6 :: proc(t: ^testing.T) {
	// 2001:db8::/32
	segments_net: [8]u16be
	segments_net[0] = 0x2001
	segments_net[1] = 0x0db8
	network_addr := cast(net.IP6_Address)segments_net
	network := netx.IP6_Network{network_addr, 32}

	// Address within network
	segments_in: [8]u16be
	segments_in[0] = 0x2001
	segments_in[1] = 0x0db8
	segments_in[7] = 0x0001
	addr_in := cast(net.IP6_Address)segments_in
	testing.expect(t, netx.contains6(network, addr_in), "Should contain 2001:db8::1")

	// Address outside network
	segments_out: [8]u16be
	segments_out[0] = 0x2001
	segments_out[1] = 0x0db9
	addr_out := cast(net.IP6_Address)segments_out
	testing.expect(t, !netx.contains6(network, addr_out), "Should not contain 2001:db9::")
}

@(test)
test_overlaps6 :: proc(t: ^testing.T) {
	segments_a: [8]u16be
	segments_a[0] = 0x2001
	segments_a[1] = 0x0db8
	addr_a := cast(net.IP6_Address)segments_a

	segments_b: [8]u16be
	segments_b[0] = 0x2001
	segments_b[1] = 0x0db8
	addr_b := cast(net.IP6_Address)segments_b

	net_a := netx.IP6_Network{addr_a, 32}
	net_b := netx.IP6_Network{addr_b, 64}  // Subnet of net_a

	testing.expect(t, netx.overlaps6(net_a, net_b), "Should overlap")
	testing.expect(t, netx.overlaps6(net_b, net_a), "Overlap is symmetric")

	// Non-overlapping
	segments_c: [8]u16be
	segments_c[0] = 0x2001
	segments_c[1] = 0x0db9
	addr_c := cast(net.IP6_Address)segments_c
	net_c := netx.IP6_Network{addr_c, 32}

	testing.expect(t, !netx.overlaps6(net_a, net_c), "Should not overlap")
}

// ============================================================================
// NETWORK RANGE TESTS
// ============================================================================

@(test)
test_network_range4 :: proc(t: ^testing.T) {
	// Test /24
	network24 := netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 24}
	first24, last24 := netx.network_range4(network24)
	testing.expect_value(t, first24, net.IP4_Address{192, 168, 1, 0})
	testing.expect_value(t, last24, net.IP4_Address{192, 168, 1, 255})

	// Test /16
	network16 := netx.IP4_Network{net.IP4_Address{10, 0, 0, 0}, 16}
	first16, last16 := netx.network_range4(network16)
	testing.expect_value(t, first16, net.IP4_Address{10, 0, 0, 0})
	testing.expect_value(t, last16, net.IP4_Address{10, 0, 255, 255})

	// Test /32 (single host)
	network32 := netx.IP4_Network{net.IP4_Address{192, 168, 1, 1}, 32}
	first32, last32 := netx.network_range4(network32)
	testing.expect_value(t, first32, net.IP4_Address{192, 168, 1, 1})
	testing.expect_value(t, last32, net.IP4_Address{192, 168, 1, 1})
}

@(test)
test_host_count4 :: proc(t: ^testing.T) {
	// Test /24 (254 usable hosts)
	network24 := netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 24}
	testing.expect_value(t, netx.host_count4(network24), u32(254))

	// Test /16 (65534 usable hosts)
	network16 := netx.IP4_Network{net.IP4_Address{10, 0, 0, 0}, 16}
	testing.expect_value(t, netx.host_count4(network16), u32(65534))

	// Test /30 (2 usable hosts)
	network30 := netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 30}
	testing.expect_value(t, netx.host_count4(network30), u32(2))

	// Test /31 (0 usable hosts - point-to-point)
	network31 := netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 31}
	testing.expect_value(t, netx.host_count4(network31), u32(0))

	// Test /32 (0 usable hosts - single address)
	network32 := netx.IP4_Network{net.IP4_Address{192, 168, 1, 1}, 32}
	testing.expect_value(t, netx.host_count4(network32), u32(0))
}

@(test)
test_usable_host_range4 :: proc(t: ^testing.T) {
	// /24
	network := netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 24}
	first, last, ok := netx.usable_host_range4(network)
	testing.expect(t, ok, "Should succeed for /24")
	testing.expect_value(t, first, net.IP4_Address{192, 168, 1, 1})
	testing.expect_value(t, last, net.IP4_Address{192, 168, 1, 254})

	// /30
	network30 := netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 30}
	first30, last30, ok30 := netx.usable_host_range4(network30)
	testing.expect(t, ok30, "Should succeed for /30")
	testing.expect_value(t, first30, net.IP4_Address{192, 168, 1, 1})
	testing.expect_value(t, last30, net.IP4_Address{192, 168, 1, 2})

	// /31 (no usable range)
	network31 := netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 31}
	_, _, ok31 := netx.usable_host_range4(network31)
	testing.expect(t, !ok31, "Should fail for /31")

	// /32 (no usable range)
	network32 := netx.IP4_Network{net.IP4_Address{192, 168, 1, 1}, 32}
	_, _, ok32 := netx.usable_host_range4(network32)
	testing.expect(t, !ok32, "Should fail for /32")
}

@(test)
test_network_range6 :: proc(t: ^testing.T) {
	// Test /64
	segments: [8]u16be
	segments[0] = 0x2001
	segments[1] = 0x0db8
	addr := cast(net.IP6_Address)segments
	network := netx.IP6_Network{addr, 64}

	first, last := netx.network_range6(network)

	first_segments := cast([8]u16be)first
	testing.expect_value(t, u16(first_segments[0]), u16(0x2001))
	testing.expect_value(t, u16(first_segments[1]), u16(0x0db8))

	last_segments := cast([8]u16be)last
	testing.expect_value(t, u16(last_segments[7]), u16(0xffff))
}

@(test)
test_host_count6 :: proc(t: ^testing.T) {
	// /64
	network64 := netx.IP6_Network{netx.ipv6_unspecified(), 64}
	count := netx.host_count6(network64)
	testing.expect(t, count > 0, "Should have hosts")

	// /127 (0 usable hosts)
	network127 := netx.IP6_Network{netx.ipv6_unspecified(), 127}
	testing.expect_value(t, netx.host_count6(network127), u128(0))

	// /128 (0 usable hosts)
	network128 := netx.IP6_Network{netx.ipv6_unspecified(), 128}
	testing.expect_value(t, netx.host_count6(network128), u128(0))
}

@(test)
test_usable_host_range6 :: proc(t: ^testing.T) {
	// /64
	network := netx.IP6_Network{netx.ipv6_unspecified(), 64}
	first, _, ok := netx.usable_host_range6(network)
	testing.expect(t, ok, "Should succeed for /64")

	// First should be ::1
	first_segments := cast([8]u16be)first
	testing.expect_value(t, u16(first_segments[7]), u16(1))

	// /127 (no usable range)
	network127 := netx.IP6_Network{netx.ipv6_unspecified(), 127}
	_, _, ok127 := netx.usable_host_range6(network127)
	testing.expect(t, !ok127, "Should fail for /127")

	// /128 (no usable range)
	network128 := netx.IP6_Network{netx.ipv6_unspecified(), 128}
	_, _, ok128 := netx.usable_host_range6(network128)
	testing.expect(t, !ok128, "Should fail for /128")
}

// ============================================================================
// ADDRESS ITERATION TESTS
// ============================================================================

@(test)
test_next_ip4 :: proc(t: ^testing.T) {
	// Test normal increment
	addr := net.IP4_Address{192, 168, 1, 1}
	next, ok := netx.next_ip4(addr)
	testing.expect(t, ok, "next_ip4 should succeed")
	testing.expect_value(t, next, net.IP4_Address{192, 168, 1, 2})

	// Test rollover within octet
	addr_rollover := net.IP4_Address{192, 168, 1, 255}
	next_rollover, ok_rollover := netx.next_ip4(addr_rollover)
	testing.expect(t, ok_rollover, "next_ip4 should succeed on rollover")
	testing.expect_value(t, next_rollover, net.IP4_Address{192, 168, 2, 0})

	// Test overflow at max IP
	addr_max := net.IP4_Address{255, 255, 255, 255}
	_, ok_max := netx.next_ip4(addr_max)
	testing.expect(t, !ok_max, "next_ip4 should fail at max IP")
}

@(test)
test_prev_ip4 :: proc(t: ^testing.T) {
	addr := net.IP4_Address{192, 168, 1, 1}
	prev, ok := netx.prev_ip4(addr)
	testing.expect(t, ok, "Should succeed")
	testing.expect_value(t, prev, net.IP4_Address{192, 168, 1, 0})

	// Rollover
	addr_rollover := net.IP4_Address{192, 168, 1, 0}
	prev_rollover, ok_rollover := netx.prev_ip4(addr_rollover)
	testing.expect(t, ok_rollover, "Should succeed on rollover")
	testing.expect_value(t, prev_rollover, net.IP4_Address{192, 168, 0, 255})

	// Underflow
	addr_min := net.IP4_Address{0, 0, 0, 0}
	_, ok_min := netx.prev_ip4(addr_min)
	testing.expect(t, !ok_min, "Should fail at min IP")
}

@(test)
test_next_ip6 :: proc(t: ^testing.T) {
	// Test normal increment
	segments: [8]u16be
	segments[7] = 0x0001
	addr := cast(net.IP6_Address)segments

	next, ok := netx.next_ip6(addr)
	testing.expect(t, ok, "next_ip6 should succeed")
	next_segments := cast([8]u16be)next
	testing.expect_value(t, u16(next_segments[7]), u16(0x0002))

	// Test rollover within segment
	segments_rollover: [8]u16be
	segments_rollover[7] = 0xFFFF
	addr_rollover := cast(net.IP6_Address)segments_rollover

	next_rollover, ok_rollover := netx.next_ip6(addr_rollover)
	testing.expect(t, ok_rollover, "next_ip6 should succeed on rollover")
	next_rollover_segments := cast([8]u16be)next_rollover
	testing.expect_value(t, u16(next_rollover_segments[6]), u16(0x0001))
	testing.expect_value(t, u16(next_rollover_segments[7]), u16(0x0000))

	// Test overflow at max IP
	segments_max: [8]u16be
	for i in 0..<8 {
		segments_max[i] = 0xFFFF
	}
	addr_max := cast(net.IP6_Address)segments_max
	_, ok_max := netx.next_ip6(addr_max)
	testing.expect(t, !ok_max, "next_ip6 should fail at max IP")
}

@(test)
test_prev_ip6 :: proc(t: ^testing.T) {
	// Test normal decrement
	segments: [8]u16be
	segments[7] = 0x0002
	addr := cast(net.IP6_Address)segments

	prev, ok := netx.prev_ip6(addr)
	testing.expect(t, ok, "prev_ip6 should succeed")
	prev_segments := cast([8]u16be)prev
	testing.expect_value(t, u16(prev_segments[7]), u16(0x0001))

	// Test rollover
	segments_rollover: [8]u16be
	segments_rollover[6] = 0x0001
	segments_rollover[7] = 0x0000
	addr_rollover := cast(net.IP6_Address)segments_rollover

	prev_rollover, ok_rollover := netx.prev_ip6(addr_rollover)
	testing.expect(t, ok_rollover, "prev_ip6 should succeed on rollover")
	prev_rollover_segments := cast([8]u16be)prev_rollover
	testing.expect_value(t, u16(prev_rollover_segments[6]), u16(0x0000))
	testing.expect_value(t, u16(prev_rollover_segments[7]), u16(0xFFFF))

	// Test underflow at min IP
	addr_min := netx.ipv6_unspecified()
	_, ok_min := netx.prev_ip6(addr_min)
	testing.expect(t, !ok_min, "prev_ip6 should fail at min IP")
}

// ============================================================================
// NETWORK COMPARISON TESTS
// ============================================================================

@(test)
test_is_single_ip4 :: proc(t: ^testing.T) {
	network32 := netx.IP4_Network{net.IP4_Address{192, 168, 1, 1}, 32}
	testing.expect(t, netx.is_single_ip4(network32), "/32 is single IP")

	network24 := netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 24}
	testing.expect(t, !netx.is_single_ip4(network24), "/24 is not single IP")
}

@(test)
test_compare_addr4 :: proc(t: ^testing.T) {
	a := net.IP4_Address{10, 0, 0, 1}
	b := net.IP4_Address{10, 0, 0, 2}
	c := net.IP4_Address{10, 0, 0, 1}

	testing.expect_value(t, netx.compare_addr4(a, b), -1)
	testing.expect_value(t, netx.compare_addr4(b, a), 1)
	testing.expect_value(t, netx.compare_addr4(a, c), 0)
}

@(test)
test_compare_network4 :: proc(t: ^testing.T) {
	net_a := netx.IP4_Network{net.IP4_Address{10, 0, 0, 0}, 8}
	net_b := netx.IP4_Network{net.IP4_Address{192, 168, 0, 0}, 16}
	net_c := netx.IP4_Network{net.IP4_Address{10, 0, 0, 0}, 16}

	testing.expect_value(t, netx.compare_network4(net_a, net_b), -1)
	testing.expect_value(t, netx.compare_network4(net_a, net_c), -1)
}

@(test)
test_less_addr4 :: proc(t: ^testing.T) {
	a := net.IP4_Address{10, 0, 0, 1}
	b := net.IP4_Address{10, 0, 0, 2}

	testing.expect(t, netx.less_addr4(a, b))
	testing.expect(t, !netx.less_addr4(b, a))
	testing.expect(t, !netx.less_addr4(a, a))
}

@(test)
test_less_network4 :: proc(t: ^testing.T) {
	net_a := netx.IP4_Network{net.IP4_Address{10, 0, 0, 0}, 8}
	net_b := netx.IP4_Network{net.IP4_Address{192, 168, 0, 0}, 16}
	net_c := netx.IP4_Network{net.IP4_Address{10, 0, 0, 0}, 16}

	testing.expect(t, netx.less_network4(net_a, net_b), "10.0.0.0/8 < 192.168.0.0/16")
	testing.expect(t, netx.less_network4(net_a, net_c), "10.0.0.0/8 < 10.0.0.0/16")
	testing.expect(t, !netx.less_network4(net_b, net_a), "192.168.0.0/16 not < 10.0.0.0/8")
	testing.expect(t, !netx.less_network4(net_a, net_a), "Network not < itself")
}

@(test)
test_is_single_ip6 :: proc(t: ^testing.T) {
	network128 := netx.IP6_Network{netx.ipv6_loopback(), 128}
	testing.expect(t, netx.is_single_ip6(network128), "/128 is single IP")

	network64 := netx.IP6_Network{netx.ipv6_unspecified(), 64}
	testing.expect(t, !netx.is_single_ip6(network64), "/64 is not single IP")
}

@(test)
test_compare_addr6 :: proc(t: ^testing.T) {
	a := netx.ipv6_unspecified()
	b := netx.ipv6_loopback()

	testing.expect_value(t, netx.compare_addr6(a, b), -1)
	testing.expect_value(t, netx.compare_addr6(b, a), 1)
	testing.expect_value(t, netx.compare_addr6(a, a), 0)
}

@(test)
test_compare_network6 :: proc(t: ^testing.T) {
	net_a := netx.IP6_Network{netx.ipv6_unspecified(), 64}
	net_b := netx.IP6_Network{netx.ipv6_loopback(), 128}

	cmp := netx.compare_network6(net_a, net_b)
	testing.expect(t, cmp != 0, "Different networks should compare differently")
}

@(test)
test_less_addr6 :: proc(t: ^testing.T) {
	a := netx.ipv6_unspecified()
	b := netx.ipv6_loopback()

	testing.expect(t, netx.less_addr6(a, b))
	testing.expect(t, !netx.less_addr6(b, a))
	testing.expect(t, !netx.less_addr6(a, a))
}

@(test)
test_less_network6 :: proc(t: ^testing.T) {
	net_a := netx.IP6_Network{netx.ipv6_unspecified(), 64}
	net_b := netx.IP6_Network{netx.ipv6_loopback(), 128}
	net_c := netx.IP6_Network{netx.ipv6_unspecified(), 128}

	testing.expect(t, netx.less_network6(net_a, net_b), "::/64 < ::1/128")
	testing.expect(t, netx.less_network6(net_a, net_c), "::/64 < ::/128")
	testing.expect(t, !netx.less_network6(net_b, net_a), "::1/128 not < ::/64")
	testing.expect(t, !netx.less_network6(net_a, net_a), "Network not < itself")
}

// ============================================================================
// SUBNET OPERATION TESTS
// ============================================================================

@(test)
test_subnets4 :: proc(t: ^testing.T) {
	network := netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 24}

	// Split /24 into /26 (4 subnets)
	subnets, ok := netx.subnets4(network, 26, context.temp_allocator)
	testing.expect(t, ok, "Should succeed")
	testing.expect_value(t, len(subnets), 4)

	testing.expect_value(t, subnets[0].address, net.IP4_Address{192, 168, 1, 0})
	testing.expect_value(t, subnets[1].address, net.IP4_Address{192, 168, 1, 64})
	testing.expect_value(t, subnets[2].address, net.IP4_Address{192, 168, 1, 128})
	testing.expect_value(t, subnets[3].address, net.IP4_Address{192, 168, 1, 192})

	for subnet in subnets {
		testing.expect_value(t, subnet.prefix_len, u8(26))
	}

	// Invalid: new prefix smaller than current
	_, bad1 := netx.subnets4(network, 23, context.temp_allocator)
	testing.expect(t, !bad1, "Should fail if new prefix <= current")
}

@(test)
test_subnets6 :: proc(t: ^testing.T) {
	// Split /64 into /66 (4 subnets)
	network := netx.IP6_Network{netx.ipv6_unspecified(), 64}

	subnets, ok := netx.subnets6(network, 66, context.temp_allocator)
	testing.expect(t, ok, "Should succeed")
	testing.expect_value(t, len(subnets), 4)

	for subnet in subnets {
		testing.expect_value(t, subnet.prefix_len, u8(66))
	}

	// Invalid: new prefix smaller than current
	_, bad := netx.subnets6(network, 63, context.temp_allocator)
	testing.expect(t, !bad, "Should fail if new prefix <= current")
}

// ============================================================================
// VALIDATION TESTS
// ============================================================================

@(test)
test_is_valid4 :: proc(t: ^testing.T) {
	// All IP4_Address values are valid in Odin
	testing.expect(t, netx.is_valid4(net.IP4_Address{192, 168, 1, 1}))
	testing.expect(t, netx.is_valid4(net.IP4_Address{0, 0, 0, 0}))
}

@(test)
test_is_valid_network4 :: proc(t: ^testing.T) {
	testing.expect(t, netx.is_valid_network4(netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 24}))
	testing.expect(t, netx.is_valid_network4(netx.IP4_Network{net.IP4_Address{0, 0, 0, 0}, 0}))
	testing.expect(t, netx.is_valid_network4(netx.IP4_Network{net.IP4_Address{8, 8, 8, 8}, 32}))
	testing.expect(t, !netx.is_valid_network4(netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 33}))
}

@(test)
test_bitlen4 :: proc(t: ^testing.T) {
	addr := net.IP4_Address{192, 168, 1, 1}
	testing.expect_value(t, netx.bitlen4(addr), 32)

	// All IPv4 addresses are 32 bits
	testing.expect_value(t, netx.bitlen4(netx.ipv4_unspecified()), 32)
	testing.expect_value(t, netx.bitlen4(netx.ipv4_loopback()), 32)
	testing.expect_value(t, netx.bitlen4(netx.ipv4_broadcast()), 32)
}

@(test)
test_is_valid6 :: proc(t: ^testing.T) {
	testing.expect(t, netx.is_valid6(netx.ipv6_loopback()))
	testing.expect(t, netx.is_valid6(netx.ipv6_unspecified()))
}

@(test)
test_is_valid_network6 :: proc(t: ^testing.T) {
	testing.expect(t, netx.is_valid_network6(netx.IP6_Network{netx.ipv6_unspecified(), 64}))
	testing.expect(t, netx.is_valid_network6(netx.IP6_Network{netx.ipv6_unspecified(), 0}))
	testing.expect(t, netx.is_valid_network6(netx.IP6_Network{netx.ipv6_loopback(), 128}))
	testing.expect(t, !netx.is_valid_network6(netx.IP6_Network{netx.ipv6_unspecified(), 129}))
}

@(test)
test_bitlen6 :: proc(t: ^testing.T) {
	addr := netx.ipv6_loopback()
	testing.expect_value(t, netx.bitlen6(addr), 128)

	// All IPv6 addresses are 128 bits
	testing.expect_value(t, netx.bitlen6(netx.ipv6_unspecified()), 128)
	testing.expect_value(t, netx.bitlen6(netx.ipv6_link_local_all_nodes()), 128)
	testing.expect_value(t, netx.bitlen6(netx.ipv6_link_local_all_routers()), 128)
}

// ============================================================================
// WELL-KNOWN ADDRESSES TESTS
// ============================================================================

@(test)
test_ipv4_unspecified :: proc(t: ^testing.T) {
	addr := netx.ipv4_unspecified()
	testing.expect_value(t, addr, net.IP4_Address{0, 0, 0, 0})
	testing.expect(t, netx.is_unspecified4(addr), "0.0.0.0 is unspecified")
}

@(test)
test_ipv4_broadcast :: proc(t: ^testing.T) {
	addr := netx.ipv4_broadcast()
	testing.expect_value(t, addr, net.IP4_Address{255, 255, 255, 255})
	testing.expect(t, netx.is_broadcast4(addr), "255.255.255.255 is broadcast")
}

@(test)
test_ipv4_loopback :: proc(t: ^testing.T) {
	addr := netx.ipv4_loopback()
	testing.expect_value(t, addr, net.IP4_Address{127, 0, 0, 1})
	testing.expect(t, netx.is_loopback4(addr), "127.0.0.1 is loopback")
}

@(test)
test_ipv6_unspecified :: proc(t: ^testing.T) {
	addr := netx.ipv6_unspecified()
	testing.expect(t, netx.is_unspecified6(addr), ":: is unspecified")
	segments := cast([8]u16be)addr
	for segment in segments {
		testing.expect_value(t, u16(segment), u16(0))
	}
}

@(test)
test_ipv6_loopback :: proc(t: ^testing.T) {
	addr := netx.ipv6_loopback()
	testing.expect(t, netx.is_loopback6(addr), "::1 is loopback")
	segments := cast([8]u16be)addr
	for i in 0..<7 {
		testing.expect_value(t, u16(segments[i]), u16(0))
	}
	testing.expect_value(t, u16(segments[7]), u16(1))
}

@(test)
test_ipv6_link_local_all_nodes :: proc(t: ^testing.T) {
	addr := netx.ipv6_link_local_all_nodes()
	segments := cast([8]u16be)addr
	testing.expect_value(t, u16(segments[0]), u16(0xFF02))
	testing.expect_value(t, u16(segments[7]), u16(0x0001))
	testing.expect(t, netx.is_link_local_multicast6(addr), "ff02::1 is link-local multicast")
}

@(test)
test_ipv6_link_local_all_routers :: proc(t: ^testing.T) {
	addr := netx.ipv6_link_local_all_routers()
	segments := cast([8]u16be)addr
	testing.expect_value(t, u16(segments[0]), u16(0xFF02))
	testing.expect_value(t, u16(segments[7]), u16(0x0002))
	testing.expect(t, netx.is_link_local_multicast6(addr), "ff02::2 is link-local multicast")
}

// ============================================================================
// ACCESSOR TESTS
// ============================================================================

@(test)
test_network_addr4 :: proc(t: ^testing.T) {
	network := netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 24}
	addr := netx.network_addr4(network)
	testing.expect_value(t, addr, net.IP4_Address{192, 168, 1, 0})
}

@(test)
test_network_bits4 :: proc(t: ^testing.T) {
	network := netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 24}
	bits := netx.network_bits4(network)
	testing.expect_value(t, bits, 24)
}

@(test)
test_network_addr6 :: proc(t: ^testing.T) {
	network := netx.IP6_Network{netx.ipv6_loopback(), 128}
	addr := netx.network_addr6(network)
	testing.expect_value(t, addr, netx.ipv6_loopback())
}

@(test)
test_network_bits6 :: proc(t: ^testing.T) {
	network := netx.IP6_Network{netx.ipv6_unspecified(), 64}
	bits := netx.network_bits6(network)
	testing.expect_value(t, bits, 64)
}

// ============================================================================
// RAW CONSTRUCTOR TESTS
// ============================================================================

@(test)
test_network_from4 :: proc(t: ^testing.T) {
	// Unlike parse_cidr4, this doesn't mask host bits
	addr := net.IP4_Address{192, 168, 1, 100}
	network := netx.network_from4(addr, 24)

	testing.expect_value(t, network.address, net.IP4_Address{192, 168, 1, 100})
	testing.expect_value(t, network.prefix_len, u8(24))

	// To get canonical form, use masked4
	canonical := netx.masked4(network)
	testing.expect_value(t, canonical.address, net.IP4_Address{192, 168, 1, 0})
}

@(test)
test_network_from6 :: proc(t: ^testing.T) {
	addr := net.IP6_Address{}
	network := netx.network_from6(addr, 64)

	testing.expect_value(t, network.address, net.IP6_Address{})
	testing.expect_value(t, network.prefix_len, u8(64))
}

// ============================================================================
// MUST PARSE TESTS
// ============================================================================

@(test)
test_must_parse_cidr4 :: proc(t: ^testing.T) {
	network := netx.must_parse_cidr4("192.168.1.0/24")
	testing.expect_value(t, network.address, net.IP4_Address{192, 168, 1, 0})
	testing.expect_value(t, network.prefix_len, u8(24))
}

@(test)
test_must_parse_cidr6 :: proc(t: ^testing.T) {
	// Simple test with all-zeros
	network := netx.must_parse_cidr6("::/64")
	testing.expect_value(t, network.prefix_len, u8(64))
}

// ============================================================================
// ADDRESS CONVERSION TESTS
// ============================================================================

@(test)
test_addr4_to_u32 :: proc(t: ^testing.T) {
	addr := net.IP4_Address{192, 168, 1, 100}
	addr_u32 := netx.addr4_to_u32(addr)
	testing.expect_value(t, addr_u32, u32(3232235876))

	// Test zero
	zero := net.IP4_Address{0, 0, 0, 0}
	testing.expect_value(t, netx.addr4_to_u32(zero), u32(0))

	// Test max
	max := net.IP4_Address{255, 255, 255, 255}
	testing.expect_value(t, netx.addr4_to_u32(max), u32(4294967295))
}

@(test)
test_u32_to_addr4 :: proc(t: ^testing.T) {
	addr := netx.u32_to_addr4(3232235876)
	testing.expect_value(t, addr, net.IP4_Address{192, 168, 1, 100})

	// Test zero
	zero := netx.u32_to_addr4(0)
	testing.expect_value(t, zero, net.IP4_Address{0, 0, 0, 0})

	// Test max
	max := netx.u32_to_addr4(4294967295)
	testing.expect_value(t, max, net.IP4_Address{255, 255, 255, 255})
}

@(test)
test_addr6_to_u128 :: proc(t: ^testing.T) {
	addr := netx.ipv6_loopback()
	addr_u128 := netx.addr6_to_u128(addr)
	testing.expect_value(t, addr_u128, u128(1))

	// Test zero
	zero := netx.ipv6_unspecified()
	testing.expect_value(t, netx.addr6_to_u128(zero), u128(0))
}

@(test)
test_u128_to_addr6 :: proc(t: ^testing.T) {
	addr := netx.u128_to_addr6(1)
	testing.expect_value(t, addr, netx.ipv6_loopback())

	// Test zero
	zero := netx.u128_to_addr6(0)
	testing.expect_value(t, zero, netx.ipv6_unspecified())
}
