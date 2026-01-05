package test_netx

import "core:net"
import "core:testing"
import netx ".."

// ============================================================================
// REVERSE DNS PTR GENERATION TESTS
// ============================================================================

@(test)
test_addr4_to_ptr :: proc(t: ^testing.T) {
	// Standard address
	addr1 := net.IP4_Address{192, 168, 1, 100}
	ptr1 := netx.addr4_to_ptr(addr1, context.temp_allocator)
	testing.expect_value(t, ptr1, "100.1.168.192.in-addr.arpa")

	// Loopback
	addr2 := net.IP4_Address{127, 0, 0, 1}
	ptr2 := netx.addr4_to_ptr(addr2, context.temp_allocator)
	testing.expect_value(t, ptr2, "1.0.0.127.in-addr.arpa")

	// Google DNS
	addr3 := net.IP4_Address{8, 8, 8, 8}
	ptr3 := netx.addr4_to_ptr(addr3, context.temp_allocator)
	testing.expect_value(t, ptr3, "8.8.8.8.in-addr.arpa")

	// Zero address
	addr4 := net.IP4_Address{0, 0, 0, 0}
	ptr4 := netx.addr4_to_ptr(addr4, context.temp_allocator)
	testing.expect_value(t, ptr4, "0.0.0.0.in-addr.arpa")
}

@(test)
test_network4_to_ptr :: proc(t: ^testing.T) {
	// /24 network
	net24 := netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 24}
	ptr24 := netx.network4_to_ptr(net24, context.temp_allocator)
	testing.expect_value(t, ptr24, "1.168.192.in-addr.arpa")

	// /16 network
	net16 := netx.IP4_Network{net.IP4_Address{10, 0, 0, 0}, 16}
	ptr16 := netx.network4_to_ptr(net16, context.temp_allocator)
	testing.expect_value(t, ptr16, "0.10.in-addr.arpa")

	// /8 network
	net8 := netx.IP4_Network{net.IP4_Address{172, 0, 0, 0}, 8}
	ptr8 := netx.network4_to_ptr(net8, context.temp_allocator)
	testing.expect_value(t, ptr8, "172.in-addr.arpa")
}

@(test)
test_network4_to_ptr_non_standard :: proc(t: ^testing.T) {
	// /25 network (non-standard boundary)
	net25 := netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 25}
	ptr25 := netx.network4_to_ptr(net25, context.temp_allocator)
	testing.expect_value(t, ptr25, "0.1.168.192.in-addr.arpa")

	// /30 network
	net30 := netx.IP4_Network{net.IP4_Address{192, 168, 1, 4}, 30}
	ptr30 := netx.network4_to_ptr(net30, context.temp_allocator)
	testing.expect_value(t, ptr30, "4.1.168.192.in-addr.arpa")
}

@(test)
test_network4_to_classless_ptr :: proc(t: ^testing.T) {
// /26 network (classless delegation)
	net26 := netx.IP4_Network{net.IP4_Address{192, 168, 1, 64}, 26}
	ptr26 := netx.network4_to_classless_ptr(net26, context.temp_allocator)
	testing.expect_value(t, ptr26, "64/26.1.168.192.in-addr.arpa")

	// /27 network
	net27 := netx.IP4_Network{net.IP4_Address{10, 0, 0, 32}, 27}
	ptr27 := netx.network4_to_classless_ptr(net27, context.temp_allocator)
	testing.expect_value(t, ptr27, "32/27.0.0.10.in-addr.arpa")

	// /30 network
	net30 := netx.IP4_Network{net.IP4_Address{192, 168, 1, 4}, 30}
	ptr30 := netx.network4_to_classless_ptr(net30, context.temp_allocator)
	testing.expect_value(t, ptr30, "4/30.1.168.192.in-addr.arpa")

	// /24 network - should use standard format
	net24 := netx.IP4_Network{net.IP4_Address{192, 168, 1, 0}, 24}
	ptr24 := netx.network4_to_classless_ptr(net24, context.temp_allocator)
	testing.expect_value(t, ptr24, "1.168.192.in-addr.arpa")
}

@(test)
test_ptr_to_addr4 :: proc(t: ^testing.T) {
	// Valid PTR record
	addr1, ok1 := netx.ptr_to_addr4("100.1.168.192.in-addr.arpa")
	testing.expect(t, ok1, "Should parse valid PTR")
	testing.expect_value(t, addr1, net.IP4_Address{192, 168, 1, 100})

	// Loopback
	addr2, ok2 := netx.ptr_to_addr4("1.0.0.127.in-addr.arpa")
	testing.expect(t, ok2, "Should parse loopback PTR")
	testing.expect_value(t, addr2, net.IP4_Address{127, 0, 0, 1})

	// Google DNS
	addr3, ok3 := netx.ptr_to_addr4("8.8.8.8.in-addr.arpa")
	testing.expect(t, ok3, "Should parse Google DNS PTR")
	testing.expect_value(t, addr3, net.IP4_Address{8, 8, 8, 8})
}

@(test)
test_ptr_to_addr4_invalid :: proc(t: ^testing.T) {
	// Missing suffix
	_, ok1 := netx.ptr_to_addr4("100.1.168.192")
	testing.expect(t, !ok1, "Should fail without .in-addr.arpa")

	// Wrong suffix
	_, ok2 := netx.ptr_to_addr4("100.1.168.192.ip6.arpa")
	testing.expect(t, !ok2, "Should fail with wrong suffix")

	// Too few octets
	_, ok3 := netx.ptr_to_addr4("1.168.192.in-addr.arpa")
	testing.expect(t, !ok3, "Should fail with too few octets")

	// Too many octets
	_, ok4 := netx.ptr_to_addr4("1.2.3.4.5.in-addr.arpa")
	testing.expect(t, !ok4, "Should fail with too many octets")

	// Invalid octet value
	_, ok5 := netx.ptr_to_addr4("256.1.168.192.in-addr.arpa")
	testing.expect(t, !ok5, "Should fail with invalid octet")

	// Non-numeric
	_, ok6 := netx.ptr_to_addr4("abc.1.168.192.in-addr.arpa")
	testing.expect(t, !ok6, "Should fail with non-numeric octet")

	// Empty
	_, ok7 := netx.ptr_to_addr4("")
	testing.expect(t, !ok7, "Should fail with empty string")
}

@(test)
test_ptr_to_addr4_roundtrip :: proc(t: ^testing.T) {
	// Test roundtrip conversion
	original := net.IP4_Address{192, 168, 1, 100}
	ptr := netx.addr4_to_ptr(original, context.temp_allocator)
	recovered, ok := netx.ptr_to_addr4(ptr)

	testing.expect(t, ok, "Should successfully roundtrip")
	testing.expect_value(t, recovered, original)
}

@(test)
test_is_valid_ptr4 :: proc(t: ^testing.T) {
	// Valid PTR records
	testing.expect(t, netx.is_valid_ptr4("100.1.168.192.in-addr.arpa"), "Should be valid")
	testing.expect(t, netx.is_valid_ptr4("1.0.0.127.in-addr.arpa"), "Should be valid")
	testing.expect(t, netx.is_valid_ptr4("0.0.0.0.in-addr.arpa"), "Should be valid")

	// Invalid PTR records
	testing.expect(t, !netx.is_valid_ptr4("100.1.168.192"), "Should be invalid")
	testing.expect(t, !netx.is_valid_ptr4("1.168.192.in-addr.arpa"), "Should be invalid")
	testing.expect(t, !netx.is_valid_ptr4("256.1.168.192.in-addr.arpa"), "Should be invalid")
}

@(test)
test_addr6_to_ptr :: proc(t: ^testing.T) {
	// Loopback ::1
	addr1 := netx.ipv6_loopback()
	ptr1 := netx.addr6_to_ptr(addr1, context.temp_allocator)
	testing.expect_value(t, ptr1, "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa")

	// Unspecified ::
	addr2 := netx.ipv6_unspecified()
	ptr2 := netx.addr6_to_ptr(addr2, context.temp_allocator)
	testing.expect_value(t, ptr2, "0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa")

	// 2001:db8::1
	segments3: [8]u16be
	segments3[0] = 0x2001
	segments3[1] = 0x0db8
	segments3[7] = 0x0001
	addr3 := cast(net.IP6_Address)segments3
	ptr3 := netx.addr6_to_ptr(addr3, context.temp_allocator)
	testing.expect_value(t, ptr3, "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa")
}

@(test)
test_network6_to_ptr :: proc(t: ^testing.T) {
	// /32 network - 2001:db8::/32
	segments32: [8]u16be
	segments32[0] = 0x2001
	segments32[1] = 0x0db8
	addr32 := cast(net.IP6_Address)segments32
	net32 := netx.IP6_Network{addr32, 32}
	ptr32 := netx.network6_to_ptr(net32, context.temp_allocator)
	testing.expect_value(t, ptr32, "8.b.d.0.1.0.0.2.ip6.arpa")

	// /48 network
	net48 := netx.IP6_Network{addr32, 48}
	ptr48 := netx.network6_to_ptr(net48, context.temp_allocator)
	testing.expect_value(t, ptr48, "0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa")

	// /64 network
	net64 := netx.IP6_Network{addr32, 64}
	ptr64 := netx.network6_to_ptr(net64, context.temp_allocator)
	testing.expect_value(t, ptr64, "0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa")
}

@(test)
test_network6_to_ptr_nibble_boundary :: proc(t: ^testing.T) {
	// Test various nibble boundaries (multiples of 4)
	segments: [8]u16be
	segments[0] = 0xFE80
	addr := cast(net.IP6_Address)segments

	// /4 - first nibble is F (high nibble of first byte)
	net4 := netx.IP6_Network{addr, 4}
	ptr4 := netx.network6_to_ptr(net4, context.temp_allocator)
	testing.expect_value(t, ptr4, "f.ip6.arpa")  // Changed from "e"

	// /8 - first two nibbles are F and E
	net8 := netx.IP6_Network{addr, 8}
	ptr8 := netx.network6_to_ptr(net8, context.temp_allocator)
	testing.expect_value(t, ptr8, "e.f.ip6.arpa")

	// /16 - all four nibbles of first segment: F, E, 8, 0
	net16 := netx.IP6_Network{addr, 16}
	ptr16 := netx.network6_to_ptr(net16, context.temp_allocator)
	testing.expect_value(t, ptr16, "0.8.e.f.ip6.arpa")
}

@(test)
test_ptr_to_addr6 :: proc(t: ^testing.T) {
	// Loopback
	addr1, ok1 := netx.ptr_to_addr6("1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa")
	testing.expect(t, ok1, "Should parse loopback PTR")
	testing.expect_value(t, addr1, netx.ipv6_loopback())

	// Unspecified
	addr2, ok2 := netx.ptr_to_addr6("0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa")
	testing.expect(t, ok2, "Should parse unspecified PTR")
	testing.expect_value(t, addr2, netx.ipv6_unspecified())
}

@(test)
test_ptr_to_addr6_invalid :: proc(t: ^testing.T) {
	// Missing suffix
	_, ok1 := netx.ptr_to_addr6("1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0")
	testing.expect(t, !ok1, "Should fail without .ip6.arpa")

	// Wrong suffix
	_, ok2 := netx.ptr_to_addr6("1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.in-addr.arpa")
	testing.expect(t, !ok2, "Should fail with wrong suffix")

	// Too few nibbles
	_, ok3 := netx.ptr_to_addr6("1.0.0.0.ip6.arpa")
	testing.expect(t, !ok3, "Should fail with too few nibbles")

	// Too many nibbles
	_, ok4 := netx.ptr_to_addr6("1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa")
	testing.expect(t, !ok4, "Should fail with too many nibbles")

	// Invalid hex nibble
	_, ok5 := netx.ptr_to_addr6("g.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa")
	testing.expect(t, !ok5, "Should fail with invalid hex")

	// Empty
	_, ok6 := netx.ptr_to_addr6("")
	testing.expect(t, !ok6, "Should fail with empty string")
}

@(test)
test_ptr_to_addr6_roundtrip :: proc(t: ^testing.T) {
	// Test roundtrip conversion
	original := netx.ipv6_loopback()
	ptr := netx.addr6_to_ptr(original, context.temp_allocator)
	recovered, ok := netx.ptr_to_addr6(ptr)

	testing.expect(t, ok, "Should successfully roundtrip")
	testing.expect_value(t, recovered, original)

	// Test with 2001:db8::1
	segments: [8]u16be
	segments[0] = 0x2001
	segments[1] = 0x0db8
	segments[7] = 0x0001
	original2 := cast(net.IP6_Address)segments
	ptr2 := netx.addr6_to_ptr(original2, context.temp_allocator)
	recovered2, ok2 := netx.ptr_to_addr6(ptr2)

	testing.expect(t, ok2, "Should successfully roundtrip complex address")
	testing.expect_value(t, recovered2, original2)
}

@(test)
test_is_valid_ptr6 :: proc(t: ^testing.T) {
	// Valid PTR records
	testing.expect(t, netx.is_valid_ptr6("1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa"), "Should be valid")
	testing.expect(t, netx.is_valid_ptr6("0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa"), "Should be valid")

	// Invalid PTR records
	testing.expect(t, !netx.is_valid_ptr6("1.0.0.0.ip6.arpa"), "Should be invalid")
	testing.expect(t, !netx.is_valid_ptr6("1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0"), "Should be invalid")
	testing.expect(t, !netx.is_valid_ptr6("g.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa"), "Should be invalid")
}
