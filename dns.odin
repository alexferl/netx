package netx

import "core:fmt"
import "core:net"
import "core:strconv"
import "core:strings"

// ============================================================================
// REVERSE DNS PTR GENERATION
// ============================================================================

// addr4_to_ptr converts an IPv4 address to a PTR record name.
// Example: 192.168.1.100 -> "100.1.168.192.in-addr.arpa"
addr4_to_ptr :: proc(addr: net.IP4_Address, allocator := context.allocator) -> string {
	return fmt.aprintf("%d.%d.%d.%d.in-addr.arpa",
	addr[3], addr[2], addr[1], addr[0],
	allocator = allocator)
}

// addr6_to_ptr converts an IPv6 address to a PTR record name.
// Example: 2001:db8::1 -> "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa"
addr6_to_ptr :: proc(addr: net.IP6_Address, allocator := context.allocator) -> string {
	// Convert to bytes for easier nibble extraction
	bytes := transmute([16]u8)addr
	builder := strings.builder_make(allocator)

	// Process bytes in reverse order
	for i := 15; i >= 0; i -= 1 {
		b := bytes[i]
		// Low nibble first, then high nibble
		fmt.sbprintf(&builder, "%x.", b & 0xF)
		fmt.sbprintf(&builder, "%x.", (b >> 4) & 0xF)
	}

	// Append ip6.arpa
	strings.write_string(&builder, "ip6.arpa")

	return strings.to_string(builder)
}

// network4_to_ptr converts an IPv4 network to a PTR zone name.
// Example: 192.168.1.0/24 -> "1.168.192.in-addr.arpa"
//          10.0.0.0/8 -> "10.in-addr.arpa"
network4_to_ptr :: proc(network: IP4_Network, allocator := context.allocator) -> string {
	addr := network.address
	prefix := network.prefix_len

	// Standard delegation boundaries: /8, /16, /24
	switch prefix {
	case 8:
		return fmt.aprintf("%d.in-addr.arpa", addr[0], allocator = allocator)
	case 16:
		return fmt.aprintf("%d.%d.in-addr.arpa", addr[1], addr[0], allocator = allocator)
	case 24:
		return fmt.aprintf("%d.%d.%d.in-addr.arpa", addr[2], addr[1], addr[0], allocator = allocator)
	case:
	// For non-standard prefixes, use the network address
	// This may not be a proper delegation zone
		masked := masked4(network)
		return fmt.aprintf("%d.%d.%d.%d.in-addr.arpa",
		masked.address[3], masked.address[2], masked.address[1], masked.address[0],
		allocator = allocator)
	}
}

// network6_to_ptr converts an IPv6 network to a PTR zone name.
// Prefix length should be on a nibble boundary (multiple of 4) for standard delegation.
// Example: 2001:db8::/32 -> "8.b.d.0.1.0.0.2.ip6.arpa"
network6_to_ptr :: proc(network: IP6_Network, allocator := context.allocator) -> string {
	prefix := network.prefix_len
	nibble_count := prefix / 4

	if nibble_count == 0 {
		return "ip6.arpa"
	}

	// Convert to bytes for easier nibble extraction
	bytes := transmute([16]u8)network.address
	builder := strings.builder_make(allocator)

	// Extract nibbles in order (high to low), then we'll reverse
	nibbles: [32]u8
	for i in 0..<16 {
		b := bytes[i]
		nibbles[i*2] = (b >> 4) & 0xF      // High nibble
		nibbles[i*2 + 1] = b & 0xF         // Low nibble
	}

	// Output nibbles in reverse order up to nibble_count
	for i := int(nibble_count) - 1; i >= 0; i -= 1 {
		fmt.sbprintf(&builder, "%x.", nibbles[i])
	}

	// Append ip6.arpa
	strings.write_string(&builder, "ip6.arpa")

	return strings.to_string(builder)
}

// network4_to_classless_ptr generates a classless in-addr.arpa delegation name (RFC 2317).
// This is used for subnets smaller than /24 (i.e., /25 to /31).
// Example: 192.168.1.64/26 -> "64/26.1.168.192.in-addr.arpa"
network4_to_classless_ptr :: proc(network: IP4_Network, allocator := context.allocator) -> string {
	if network.prefix_len < 25 {
	// Not a classless delegation - use standard format
		return network4_to_ptr(network, allocator)
	}

	masked := masked4(network)
	addr := masked.address

	return fmt.aprintf("%d/%d.%d.%d.%d.in-addr.arpa",
	addr[3],
	network.prefix_len,
	addr[2], addr[1], addr[0],
	allocator = allocator)
}


// ptr_to_addr4 parses an IPv4 PTR record name back to an address.
// Example: "100.1.168.192.in-addr.arpa" -> 192.168.1.100
ptr_to_addr4 :: proc(ptr: string) -> (addr: net.IP4_Address, ok: bool) {
	// Check suffix
	if !strings.has_suffix(ptr, ".in-addr.arpa") {
		return {}, false
	}

	// Remove suffix
	without_suffix := strings.trim_suffix(ptr, ".in-addr.arpa")

	// Split into octets
	parts := strings.split(without_suffix, ".", context.temp_allocator)
	if len(parts) != 4 {
		return {}, false
	}

	// Parse octets in reverse order
	octets: [4]u8
	for i in 0..<4 {
		val, parse_ok := strconv.parse_int(parts[i])
		if !parse_ok || val < 0 || val > 255 {
			return {}, false
		}
		octets[3 - i] = u8(val)
	}

	return net.IP4_Address{octets[0], octets[1], octets[2], octets[3]}, true
}

// ptr_to_addr6 parses an IPv6 PTR record name back to an address.
// Example: "1.0.0.0...ip6.arpa" -> 2001:db8::1
ptr_to_addr6 :: proc(ptr: string) -> (addr: net.IP6_Address, ok: bool) {
	// Check suffix
	if !strings.has_suffix(ptr, ".ip6.arpa") {
		return {}, false
	}

	// Remove suffix
	without_suffix := strings.trim_suffix(ptr, ".ip6.arpa")

	// Split into nibbles
	nibble_strs := strings.split(without_suffix, ".", context.temp_allocator)
	if len(nibble_strs) != 32 {
		return {}, false
	}

	// Parse nibbles
	nibbles: [32]u8
	for i in 0..<32 {
		val, parse_ok := strconv.parse_int(nibble_strs[i], 16)
		if !parse_ok || val < 0 || val > 15 {
			return {}, false
		}
		nibbles[i] = u8(val)
	}

	// Nibbles are in reverse order
	// nibble_strs[0] is the low nibble of byte 15
	// nibble_strs[1] is the high nibble of byte 15
	// nibble_strs[2] is the low nibble of byte 14
	// nibble_strs[3] is the high nibble of byte 14, etc.
	bytes: [16]u8
	for i in 0..<16 {
		low := nibbles[i*2]
		high := nibbles[i*2 + 1]
		bytes[15 - i] = (high << 4) | low
	}

	return transmute(net.IP6_Address)bytes, true
}

// is_valid_ptr4 checks if a string is a valid IPv4 PTR record format.
is_valid_ptr4 :: proc(ptr: string) -> bool {
	_, ok := ptr_to_addr4(ptr)
	return ok
}

// is_valid_ptr6 checks if a string is a valid IPv6 PTR record format.
is_valid_ptr6 :: proc(ptr: string) -> bool {
	_, ok := ptr_to_addr6(ptr)
	return ok
}
