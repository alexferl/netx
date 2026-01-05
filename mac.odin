package netx

import "core:fmt"
import "core:net"
import "core:strconv"
import "core:strings"

MAC_Address :: struct {
	bytes: [6]u8,
}

EUI64_Address :: struct {
	bytes: [8]u8,
}

// ============================================================================
// PARSING
// ============================================================================

parse_mac :: proc(s: string) -> (mac: MAC_Address, ok: bool) {
	// Remove common separators and normalize
	cleaned := strings.to_upper(s, context.temp_allocator)
	cleaned, _ = strings.replace_all(cleaned, ":", "", context.temp_allocator)
	cleaned, _ = strings.replace_all(cleaned, "-", "", context.temp_allocator)

	// Should have exactly 12 hex characters
	if len(cleaned) != 12 {
		return {}, false
	}

	// Parse each pair of hex digits
	for i in 0..<6 {
		hex_pair := cleaned[i*2:(i*2)+2]
		val, parse_ok := strconv.parse_u64_of_base(hex_pair, 16)
		if !parse_ok || val > 255 {
			return {}, false
		}
		mac.bytes[i] = u8(val)
	}

	return mac, true
}

parse_eui64 :: proc(s: string) -> (eui: EUI64_Address, ok: bool) {
	cleaned := strings.to_upper(s, context.temp_allocator)
	cleaned, _ = strings.replace_all(cleaned, ":", "", context.temp_allocator)
	cleaned, _ = strings.replace_all(cleaned, "-", "", context.temp_allocator)

	if len(cleaned) != 16 {
		return {}, false
	}

	for i in 0..<8 {
		hex_pair := cleaned[i*2:(i*2)+2]
		val, parse_ok := strconv.parse_u64_of_base(hex_pair, 16)
		if !parse_ok || val > 255 {
			return {}, false
		}
		eui.bytes[i] = u8(val)
	}

	return eui, true
}

// ============================================================================
// FORMATTING
// ============================================================================

mac_to_string :: proc(mac: MAC_Address, separator := ":", uppercase := true, allocator := context.allocator) -> string {
	format := "%02x" if !uppercase else "%02X"

	builder := strings.builder_make(allocator)
	for byte, i in mac.bytes {
		if i > 0 {
			strings.write_string(&builder, separator)
		}
		fmt.sbprintf(&builder, format, byte)
	}

	return strings.to_string(builder)
}

mac_to_string_colon :: proc(mac: MAC_Address, uppercase := true, allocator := context.allocator) -> string {
	return mac_to_string(mac, ":", uppercase, allocator)
}

mac_to_string_hyphen :: proc(mac: MAC_Address, uppercase := true, allocator := context.allocator) -> string {
	return mac_to_string(mac, "-", uppercase, allocator)
}

mac_to_string_raw :: proc(mac: MAC_Address, uppercase := true, allocator := context.allocator) -> string {
	format := "%02x%02x%02x%02x%02x%02x" if !uppercase else "%02X%02X%02X%02X%02X%02X"
	return fmt.aprintf(format,
	mac.bytes[0], mac.bytes[1], mac.bytes[2],
	mac.bytes[3], mac.bytes[4], mac.bytes[5],
	allocator = allocator)
}

eui64_to_string :: proc(eui: EUI64_Address, separator := ":", uppercase := true, allocator := context.allocator) -> string {
	format := "%02x" if !uppercase else "%02X"

	builder := strings.builder_make(allocator)
	for byte, i in eui.bytes {
		if i > 0 {
			strings.write_string(&builder, separator)
		}
		fmt.sbprintf(&builder, format, byte)
	}

	return strings.to_string(builder)
}

// ============================================================================
// EUI-64 CONVERSION FOR IPv6 SLAAC
// ============================================================================

mac_to_eui64 :: proc(mac: MAC_Address) -> EUI64_Address {
	eui: EUI64_Address

	// Copy first 3 bytes (OUI)
	eui.bytes[0] = mac.bytes[0]
	eui.bytes[1] = mac.bytes[1]
	eui.bytes[2] = mac.bytes[2]

	// Insert 0xFF 0xFE in the middle
	eui.bytes[3] = 0xFF
	eui.bytes[4] = 0xFE

	// Copy last 3 bytes
	eui.bytes[5] = mac.bytes[3]
	eui.bytes[6] = mac.bytes[4]
	eui.bytes[7] = mac.bytes[5]

	// Flip the universal/local bit (7th bit of first byte)
	eui.bytes[0] ~= 0x02

	return eui
}

eui64_to_mac :: proc(eui: EUI64_Address) -> (mac: MAC_Address, ok: bool) {
	// Check if it's a valid EUI-64 derived from MAC (has FF FE in middle)
	if eui.bytes[3] != 0xFF || eui.bytes[4] != 0xFE {
		return {}, false
	}

	// Extract OUI (flip the bit back)
	mac.bytes[0] = eui.bytes[0] ~ 0x02
	mac.bytes[1] = eui.bytes[1]
	mac.bytes[2] = eui.bytes[2]

	// Extract NIC specific part
	mac.bytes[3] = eui.bytes[5]
	mac.bytes[4] = eui.bytes[6]
	mac.bytes[5] = eui.bytes[7]

	return mac, true
}

// ============================================================================
// IPv6 LINK-LOCAL ADDRESS GENERATION
// ============================================================================

mac_to_ipv6_link_local :: proc(mac: MAC_Address) -> net.IP6_Address {
	eui := mac_to_eui64(mac)

	// Link-local prefix is fe80::/64
	segments: [8]u16be
	segments[0] = 0xFE80  // fe80
	segments[1] = 0x0000  // 0000
	segments[2] = 0x0000  // 0000
	segments[3] = 0x0000  // 0000

	// Add EUI-64 as interface identifier
	segments[4] = u16be((u16(eui.bytes[0]) << 8) | u16(eui.bytes[1]))
	segments[5] = u16be((u16(eui.bytes[2]) << 8) | u16(eui.bytes[3]))
	segments[6] = u16be((u16(eui.bytes[4]) << 8) | u16(eui.bytes[5]))
	segments[7] = u16be((u16(eui.bytes[6]) << 8) | u16(eui.bytes[7]))

	return cast(net.IP6_Address)segments
}

eui64_to_ipv6_interface_id :: proc(eui: EUI64_Address) -> [4]u16be {
	segments: [4]u16be
	segments[0] = u16be((u16(eui.bytes[0]) << 8) | u16(eui.bytes[1]))
	segments[1] = u16be((u16(eui.bytes[2]) << 8) | u16(eui.bytes[3]))
	segments[2] = u16be((u16(eui.bytes[4]) << 8) | u16(eui.bytes[5]))
	segments[3] = u16be((u16(eui.bytes[6]) << 8) | u16(eui.bytes[7]))
	return segments
}

ipv6_to_eui64 :: proc(addr: net.IP6_Address) -> (eui: EUI64_Address, ok: bool) {
	segments := cast([8]u16be)addr

	// Extract last 64 bits (interface identifier)
	eui.bytes[0] = u8(segments[4] >> 8)
	eui.bytes[1] = u8(segments[4] & 0xFF)
	eui.bytes[2] = u8(segments[5] >> 8)
	eui.bytes[3] = u8(segments[5] & 0xFF)
	eui.bytes[4] = u8(segments[6] >> 8)
	eui.bytes[5] = u8(segments[6] & 0xFF)
	eui.bytes[6] = u8(segments[7] >> 8)
	eui.bytes[7] = u8(segments[7] & 0xFF)

	// Check if it looks like an EUI-64 (has FF FE)
	if eui.bytes[3] == 0xFF && eui.bytes[4] == 0xFE {
		return eui, true
	}

	return eui, false
}

ipv6_to_mac :: proc(addr: net.IP6_Address) -> (mac: MAC_Address, ok: bool) {
	eui, eui_ok := ipv6_to_eui64(addr)
	if !eui_ok {
		return {}, false
	}

	return eui64_to_mac(eui)
}

// ============================================================================
// MAC ADDRESS PROPERTIES
// ============================================================================

is_unicast_mac :: proc(mac: MAC_Address) -> bool {
	// Check if least significant bit of first byte is 0
	return (mac.bytes[0] & 0x01) == 0
}

is_multicast_mac :: proc(mac: MAC_Address) -> bool {
	// Check if least significant bit of first byte is 1
	return (mac.bytes[0] & 0x01) == 1
}

is_locally_administered :: proc(mac: MAC_Address) -> bool {
	// Check if second least significant bit of first byte is 1
	return (mac.bytes[0] & 0x02) == 0x02
}

is_globally_unique :: proc(mac: MAC_Address) -> bool {
	// Check if second least significant bit of first byte is 0
	return (mac.bytes[0] & 0x02) == 0
}

is_broadcast_mac :: proc(mac: MAC_Address) -> bool {
	// Check if all bytes are 0xFF
	for byte in mac.bytes {
		if byte != 0xFF {
			return false
		}
	}
	return true
}

is_null_mac :: proc(mac: MAC_Address) -> bool {
	// Check if all bytes are 0x00
	for byte in mac.bytes {
		if byte != 0x00 {
			return false
		}
	}
	return true
}

// ============================================================================
// OUI (ORGANIZATIONALLY UNIQUE IDENTIFIER)
// ============================================================================

get_oui :: proc(mac: MAC_Address) -> [3]u8 {
	return [3]u8{mac.bytes[0], mac.bytes[1], mac.bytes[2]}
}

get_nic_specific :: proc(mac: MAC_Address) -> [3]u8 {
	return [3]u8{mac.bytes[3], mac.bytes[4], mac.bytes[5]}
}

// ============================================================================
// COMPARISON
// ============================================================================

compare_mac :: proc(a, b: MAC_Address) -> int {
	for i in 0..<6 {
		if a.bytes[i] < b.bytes[i] {
			return -1
		}
		if a.bytes[i] > b.bytes[i] {
			return 1
		}
	}
	return 0
}

less_mac :: proc(a, b: MAC_Address) -> bool {
	return compare_mac(a, b) < 0
}

// ============================================================================
// VALIDATION
// ============================================================================

is_valid_mac :: proc(mac: MAC_Address) -> bool {
	return !is_null_mac(mac)
}

// ============================================================================
// WELL-KNOWN MAC ADDRESSES
// ============================================================================

mac_broadcast :: proc() -> MAC_Address {
	return MAC_Address{bytes = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF}}
}

mac_null :: proc() -> MAC_Address {
	return MAC_Address{bytes = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00}}
}

// ============================================================================
// CONSTRUCTOR
// ============================================================================

mac_from_bytes :: proc(bytes: [6]u8) -> MAC_Address {
	return MAC_Address{bytes = bytes}
}

eui64_from_bytes :: proc(bytes: [8]u8) -> EUI64_Address {
	return EUI64_Address{bytes = bytes}
}

// ============================================================================
// MUST PARSE
// ============================================================================

must_parse_mac :: proc(s: string, loc := #caller_location) -> MAC_Address {
	mac, ok := parse_mac(s)
	if !ok {
		panic("invalid MAC address", loc)
	}
	return mac
}

must_parse_eui64 :: proc(s: string, loc := #caller_location) -> EUI64_Address {
	eui, ok := parse_eui64(s)
	if !ok {
		panic("invalid EUI-64 address", loc)
	}
	return eui
}
