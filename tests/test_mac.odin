package test_netx

import "core:net"
import "core:testing"
import netx ".."

// ============================================================================
// PARSING TESTS
// ============================================================================

@(test)
test_parse_mac :: proc(t: ^testing.T) {
	// Valid colon-separated format
	mac1, ok1 := netx.parse_mac("00:1A:2B:3C:4D:5E")
	testing.expect(t, ok1, "Should parse colon-separated MAC")
	testing.expect_value(t, mac1.bytes, [6]u8{0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E})

	// Hyphen-separated format
	mac2, ok2 := netx.parse_mac("00-1a-2b-3c-4d-5e")
	testing.expect(t, ok2, "Should parse hyphen-separated MAC")
	testing.expect_value(t, mac2.bytes, [6]u8{0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E})

	// Raw hex format
	mac4, ok4 := netx.parse_mac("001a2b3c4d5e")
	testing.expect(t, ok4, "Should parse raw hex MAC")
	testing.expect_value(t, mac4.bytes, [6]u8{0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E})
}

@(test)
test_parse_mac_invalid :: proc(t: ^testing.T) {
	// Too short
	_, ok1 := netx.parse_mac("00:1A:2B:3C:4D")
	testing.expect(t, !ok1, "Should fail with too few bytes")

	// Too long
	_, ok2 := netx.parse_mac("00:1A:2B:3C:4D:5E:7F")
	testing.expect(t, !ok2, "Should fail with too many bytes")

	// Invalid hex
	_, ok3 := netx.parse_mac("ZZ:1A:2B:3C:4D:5E")
	testing.expect(t, !ok3, "Should fail with invalid hex")

	// Empty
	_, ok4 := netx.parse_mac("")
	testing.expect(t, !ok4, "Should fail with empty string")
}

@(test)
test_parse_eui64 :: proc(t: ^testing.T) {
	// Valid colon-separated EUI-64
	eui1, ok1 := netx.parse_eui64("02:1A:2B:FF:FE:3C:4D:5E")
	testing.expect(t, ok1, "Should parse colon-separated EUI-64")
	testing.expect_value(t, eui1.bytes, [8]u8{0x02, 0x1A, 0x2B, 0xFF, 0xFE, 0x3C, 0x4D, 0x5E})

	// Hyphen-separated format
	eui2, ok2 := netx.parse_eui64("02-1a-2b-ff-fe-3c-4d-5e")
	testing.expect(t, ok2, "Should parse hyphen-separated EUI-64")
	testing.expect_value(t, eui2.bytes, [8]u8{0x02, 0x1A, 0x2B, 0xFF, 0xFE, 0x3C, 0x4D, 0x5E})

	// Raw hex format
	eui4, ok4 := netx.parse_eui64("021a2bfffe3c4d5e")
	testing.expect(t, ok4, "Should parse raw hex EUI-64")
	testing.expect_value(t, eui4.bytes, [8]u8{0x02, 0x1A, 0x2B, 0xFF, 0xFE, 0x3C, 0x4D, 0x5E})
}

@(test)
test_parse_eui64_invalid :: proc(t: ^testing.T) {
	// Too short
	_, ok1 := netx.parse_eui64("02:1A:2B:FF:FE:3C:4D")
	testing.expect(t, !ok1, "Should fail with too few bytes")

	// Too long
	_, ok2 := netx.parse_eui64("02:1A:2B:FF:FE:3C:4D:5E:00")
	testing.expect(t, !ok2, "Should fail with too many bytes")

	// Invalid hex
	_, ok3 := netx.parse_eui64("ZZ:1A:2B:FF:FE:3C:4D:5E")
	testing.expect(t, !ok3, "Should fail with invalid hex")

	// Empty
	_, ok4 := netx.parse_mac("")
	testing.expect(t, !ok4, "Should fail with empty string")
}

// ============================================================================
// FORMATTING TESTS
// ============================================================================

@(test)
test_mac_to_string_colon :: proc(t: ^testing.T) {
	mac := netx.MAC_Address{bytes = {0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E}}

	// Uppercase
	s1 := netx.mac_to_string_colon(mac, true, context.temp_allocator)
	testing.expect_value(t, s1, "00:1A:2B:3C:4D:5E")

	// Lowercase
	s2 := netx.mac_to_string_colon(mac, false, context.temp_allocator)
	testing.expect_value(t, s2, "00:1a:2b:3c:4d:5e")
}

@(test)
test_mac_to_string_hyphen :: proc(t: ^testing.T) {
	mac := netx.MAC_Address{bytes = {0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF}}
	s := netx.mac_to_string_hyphen(mac, true, context.temp_allocator)
	testing.expect_value(t, s, "AA-BB-CC-DD-EE-FF")
}

@(test)
test_mac_to_string_raw :: proc(t: ^testing.T) {
	mac := netx.MAC_Address{bytes = {0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E}}
	s := netx.mac_to_string_raw(mac, true, context.temp_allocator)
	testing.expect_value(t, s, "001A2B3C4D5E")
}

@(test)
test_eui64_to_string :: proc(t: ^testing.T) {
	eui := netx.EUI64_Address{bytes = {0x02, 0x1A, 0x2B, 0xFF, 0xFE, 0x3C, 0x4D, 0x5E}}

	s1 := netx.eui64_to_string(eui, ":", true, context.temp_allocator)
	testing.expect_value(t, s1, "02:1A:2B:FF:FE:3C:4D:5E")

	s2 := netx.eui64_to_string(eui, "-", false, context.temp_allocator)
	testing.expect_value(t, s2, "02-1a-2b-ff-fe-3c-4d-5e")
}

// ============================================================================
// EUI-64 CONVERSION TESTS
// ============================================================================

@(test)
test_mac_to_eui64 :: proc(t: ^testing.T) {
	// MAC: 00:1A:2B:3C:4D:5E
	// EUI-64 should be: 02:1A:2B:FF:FE:3C:4D:5E (bit flip on first byte)
	mac := netx.MAC_Address{bytes = {0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E}}
	eui := netx.mac_to_eui64(mac)

	testing.expect_value(t, eui.bytes[0], u8(0x02)) // Bit flipped
	testing.expect_value(t, eui.bytes[1], u8(0x1A))
	testing.expect_value(t, eui.bytes[2], u8(0x2B))
	testing.expect_value(t, eui.bytes[3], u8(0xFF)) // Inserted
	testing.expect_value(t, eui.bytes[4], u8(0xFE)) // Inserted
	testing.expect_value(t, eui.bytes[5], u8(0x3C))
	testing.expect_value(t, eui.bytes[6], u8(0x4D))
	testing.expect_value(t, eui.bytes[7], u8(0x5E))
}

@(test)
test_mac_to_eui64_locally_administered :: proc(t: ^testing.T) {
	// MAC with locally administered bit already set: 02:00:00:AA:BB:CC
	// EUI-64 should flip it back: 00:00:00:FF:FE:AA:BB:CC
	mac := netx.MAC_Address{bytes = {0x02, 0x00, 0x00, 0xAA, 0xBB, 0xCC}}
	eui := netx.mac_to_eui64(mac)

	testing.expect_value(t, eui.bytes[0], u8(0x00)) // 0x02 XOR 0x02 = 0x00
	testing.expect_value(t, eui.bytes[3], u8(0xFF))
	testing.expect_value(t, eui.bytes[4], u8(0xFE))
}

@(test)
test_eui64_to_mac :: proc(t: ^testing.T) {
	// EUI-64: 02:1A:2B:FF:FE:3C:4D:5E
	// MAC should be: 00:1A:2B:3C:4D:5E
	eui := netx.EUI64_Address{bytes = {0x02, 0x1A, 0x2B, 0xFF, 0xFE, 0x3C, 0x4D, 0x5E}}
	mac, ok := netx.eui64_to_mac(eui)

	testing.expect(t, ok, "Should extract MAC from EUI-64")
	testing.expect_value(t, mac.bytes, [6]u8{0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E})
}

@(test)
test_eui64_to_mac_roundtrip :: proc(t: ^testing.T) {
	// Test roundtrip conversion
	original := netx.MAC_Address{bytes = {0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E}}
	eui := netx.mac_to_eui64(original)
	recovered, ok := netx.eui64_to_mac(eui)

	testing.expect(t, ok, "Should successfully roundtrip")
	testing.expect_value(t, recovered.bytes, original.bytes)
}

@(test)
test_eui64_to_mac_invalid :: proc(t: ^testing.T) {
	// EUI-64 without FF:FE in middle
	eui := netx.EUI64_Address{bytes = {0x02, 0x1A, 0x2B, 0x00, 0x00, 0x3C, 0x4D, 0x5E}}
	_, ok := netx.eui64_to_mac(eui)

	testing.expect(t, !ok, "Should fail for non-MAC-derived EUI-64")
}

// ============================================================================
// IPv6 LINK-LOCAL ADDRESS GENERATION TESTS
// ============================================================================

@(test)
test_mac_to_ipv6_link_local :: proc(t: ^testing.T) {
	// MAC: 00:1A:2B:3C:4D:5E
	// Link-local should be: fe80::21a:2bff:fe3c:4d5e
	mac := netx.MAC_Address{bytes = {0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E}}
	addr := netx.mac_to_ipv6_link_local(mac)

	segments := cast([8]u16be)addr
	testing.expect_value(t, u16(segments[0]), u16(0xFE80))
	testing.expect_value(t, u16(segments[1]), u16(0))
	testing.expect_value(t, u16(segments[2]), u16(0))
	testing.expect_value(t, u16(segments[3]), u16(0))

	// Interface ID from EUI-64
	testing.expect_value(t, u16(segments[4]), u16(0x021A))
	testing.expect_value(t, u16(segments[5]), u16(0x2BFF))
	testing.expect_value(t, u16(segments[6]), u16(0xFE3C))
	testing.expect_value(t, u16(segments[7]), u16(0x4D5E))
}

@(test)
test_eui64_to_ipv6_interface_id :: proc(t: ^testing.T) {
	// EUI-64: 02:1A:2B:FF:FE:3C:4D:5E
	eui := netx.EUI64_Address{bytes = {0x02, 0x1A, 0x2B, 0xFF, 0xFE, 0x3C, 0x4D, 0x5E}}
	segments := netx.eui64_to_ipv6_interface_id(eui)

	testing.expect_value(t, u16(segments[0]), u16(0x021A))
	testing.expect_value(t, u16(segments[1]), u16(0x2BFF))
	testing.expect_value(t, u16(segments[2]), u16(0xFE3C))
	testing.expect_value(t, u16(segments[3]), u16(0x4D5E))
}

@(test)
test_ipv6_to_eui64 :: proc(t: ^testing.T) {
	// Create link-local address with EUI-64
	mac := netx.MAC_Address{bytes = {0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E}}
	addr := netx.mac_to_ipv6_link_local(mac)

	// Extract EUI-64
	eui, ok := netx.ipv6_to_eui64(addr)
	testing.expect(t, ok, "Should extract EUI-64 from link-local address")
	testing.expect_value(t, eui.bytes, [8]u8{0x02, 0x1A, 0x2B, 0xFF, 0xFE, 0x3C, 0x4D, 0x5E})
}

@(test)
test_ipv6_to_eui64_non_slaac :: proc(t: ^testing.T) {
	// Address without FF:FE pattern
	segments: [8]u16be
	segments[0] = 0xFE80
	segments[7] = 0x0001
	addr := cast(net.IP6_Address)segments

	_, ok := netx.ipv6_to_eui64(addr)
	testing.expect(t, !ok, "Should fail for non-SLAAC address")
}

@(test)
test_ipv6_to_mac :: proc(t: ^testing.T) {
// Full roundtrip: MAC -> link-local -> MAC
	original := netx.MAC_Address{bytes = {0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E}}
	addr := netx.mac_to_ipv6_link_local(original)
	recovered, ok := netx.ipv6_to_mac(addr)

	testing.expect(t, ok, "Should extract MAC from SLAAC address")
	testing.expect_value(t, recovered.bytes, original.bytes)
}

// ============================================================================
// MAC ADDRESS PROPERTIES TESTS
// ============================================================================

@(test)
test_is_unicast_mac :: proc(t: ^testing.T) {
	// Unicast MAC (LSB of first byte is 0)
	mac_unicast := netx.MAC_Address{bytes = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55}}
	testing.expect(t, netx.is_unicast_mac(mac_unicast), "0x00 should be unicast")

	// Multicast MAC (LSB of first byte is 1)
	mac_multicast := netx.MAC_Address{bytes = {0x01, 0x00, 0x5E, 0x00, 0x00, 0xFB}}
	testing.expect(t, !netx.is_unicast_mac(mac_multicast), "0x01 should not be unicast")
}

@(test)
test_is_multicast_mac :: proc(t: ^testing.T) {
	mac_multicast := netx.MAC_Address{bytes = {0x01, 0x00, 0x5E, 0x00, 0x00, 0xFB}}
	testing.expect(t, netx.is_multicast_mac(mac_multicast), "0x01 should be multicast")

	mac_unicast := netx.MAC_Address{bytes = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55}}
	testing.expect(t, !netx.is_multicast_mac(mac_unicast), "0x00 should not be multicast")
}

@(test)
test_is_locally_administered :: proc(t: ^testing.T) {
	// Locally administered (bit 1 of first byte is 1)
	mac_local := netx.MAC_Address{bytes = {0x02, 0x11, 0x22, 0x33, 0x44, 0x55}}
	testing.expect(t, netx.is_locally_administered(mac_local), "0x02 should be locally administered")

	// Globally unique (bit 1 of first byte is 0)
	mac_global := netx.MAC_Address{bytes = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55}}
	testing.expect(t, !netx.is_locally_administered(mac_global), "0x00 should not be locally administered")
}

@(test)
test_is_globally_unique :: proc(t: ^testing.T) {
	mac_global := netx.MAC_Address{bytes = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55}}
	testing.expect(t, netx.is_globally_unique(mac_global), "0x00 should be globally unique")

	mac_local := netx.MAC_Address{bytes = {0x02, 0x11, 0x22, 0x33, 0x44, 0x55}}
	testing.expect(t, !netx.is_globally_unique(mac_local), "0x02 should not be globally unique")
}

@(test)
test_is_broadcast_mac :: proc(t: ^testing.T) {
	mac_broadcast := netx.mac_broadcast()
	testing.expect(t, netx.is_broadcast_mac(mac_broadcast), "FF:FF:FF:FF:FF:FF is broadcast")

	mac_normal := netx.MAC_Address{bytes = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE}}
	testing.expect(t, !netx.is_broadcast_mac(mac_normal), "Almost broadcast is not broadcast")
}

@(test)
test_is_null_mac :: proc(t: ^testing.T) {
	mac_null := netx.mac_null()
	testing.expect(t, netx.is_null_mac(mac_null), "00:00:00:00:00:00 is null")

	mac_normal := netx.MAC_Address{bytes = {0x00, 0x00, 0x00, 0x00, 0x00, 0x01}}
	testing.expect(t, !netx.is_null_mac(mac_normal), "Almost null is not null")
}

// ============================================================================
// OUI TESTS
// ============================================================================

@(test)
test_get_oui :: proc(t: ^testing.T) {
	mac := netx.MAC_Address{bytes = {0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E}}
	oui := netx.get_oui(mac)
	testing.expect_value(t, oui, [3]u8{0x00, 0x1A, 0x2B})
}

@(test)
test_get_nic_specific :: proc(t: ^testing.T) {
	mac := netx.MAC_Address{bytes = {0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E}}
	nic := netx.get_nic_specific(mac)
	testing.expect_value(t, nic, [3]u8{0x3C, 0x4D, 0x5E})
}

// ============================================================================
// COMPARISON TESTS
// ============================================================================

@(test)
test_compare_mac :: proc(t: ^testing.T) {
	mac1 := netx.MAC_Address{bytes = {0x00, 0x1A, 0x2B, 0x00, 0x00, 0x01}}
	mac2 := netx.MAC_Address{bytes = {0x00, 0x1A, 0x2B, 0x00, 0x00, 0x02}}
	mac3 := netx.MAC_Address{bytes = {0x00, 0x1A, 0x2B, 0x00, 0x00, 0x02}}

	testing.expect_value(t, netx.compare_mac(mac1, mac2), -1)
	testing.expect_value(t, netx.compare_mac(mac2, mac1), 1)
	testing.expect_value(t, netx.compare_mac(mac2, mac3), 0)
}

@(test)
test_less_mac :: proc(t: ^testing.T) {
	mac1 := netx.MAC_Address{bytes = {0x00, 0x1A, 0x2B, 0x00, 0x00, 0x01}}
	mac2 := netx.MAC_Address{bytes = {0x00, 0x1A, 0x2B, 0x00, 0x00, 0x02}}

	testing.expect(t, netx.less_mac(mac1, mac2), "mac1 < mac2")
	testing.expect(t, !netx.less_mac(mac2, mac1), "mac2 not < mac1")
	testing.expect(t, !netx.less_mac(mac1, mac1), "mac1 not < mac1")
}

// ============================================================================
// VALIDATION TESTS
// ============================================================================

@(test)
test_is_valid_mac :: proc(t: ^testing.T) {
	mac_null := netx.mac_null()
	testing.expect(t, !netx.is_valid_mac(mac_null), "Null MAC is not valid")

	mac_normal := netx.MAC_Address{bytes = {0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E}}
	testing.expect(t, netx.is_valid_mac(mac_normal), "Normal MAC is valid")
}

// ============================================================================
// WELL-KNOWN MAC ADDRESS TESTS
// ============================================================================

@(test)
test_mac_broadcast :: proc(t: ^testing.T) {
	mac := netx.mac_broadcast()
	testing.expect_value(t, mac.bytes, [6]u8{0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF})
	testing.expect(t, netx.is_broadcast_mac(mac), "Should be broadcast")
}

@(test)
test_mac_null :: proc(t: ^testing.T) {
	mac := netx.mac_null()
	testing.expect_value(t, mac.bytes, [6]u8{0x00, 0x00, 0x00, 0x00, 0x00, 0x00})
	testing.expect(t, netx.is_null_mac(mac), "Should be null")
}

// ============================================================================
// CONSTRUCTOR TESTS
// ============================================================================

@(test)
test_mac_from_bytes :: proc(t: ^testing.T) {
	bytes := [6]u8{0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E}
	mac := netx.mac_from_bytes(bytes)
	testing.expect_value(t, mac.bytes, bytes)
}

@(test)
test_eui64_from_bytes :: proc(t: ^testing.T) {
	bytes := [8]u8{0x02, 0x1A, 0x2B, 0xFF, 0xFE, 0x3C, 0x4D, 0x5E}
	eui := netx.eui64_from_bytes(bytes)
	testing.expect_value(t, eui.bytes, bytes)
}

// ============================================================================
// MUST PARSE TESTS
// ============================================================================

@(test)
test_must_parse_mac :: proc(t: ^testing.T) {
	mac := netx.must_parse_mac("00:1A:2B:3C:4D:5E")
	testing.expect_value(t, mac.bytes, [6]u8{0x00, 0x1A, 0x2B, 0x3C, 0x4D, 0x5E})
}

@(test)
test_must_parse_eui64 :: proc(t: ^testing.T) {
	eui := netx.must_parse_eui64("02:1A:2B:FF:FE:3C:4D:5E")
	testing.expect_value(t, eui.bytes, [8]u8{0x02, 0x1A, 0x2B, 0xFF, 0xFE, 0x3C, 0x4D, 0x5E})
}
