package netx

import "core:fmt"
import "core:net"
import "core:strconv"
import "core:strings"

IP4_Network :: struct {
	address:    net.IP4_Address,
	prefix_len: u8,
}

IP6_Network :: struct {
	address:    net.IP6_Address,
	prefix_len: u8,
}

IP4_Range :: struct {
	start: net.IP4_Address,
	end: net.IP4_Address,
}

IP6_Range :: struct {
	start: net.IP6_Address,
	end: net.IP6_Address,
}

// ============================================================================
// PARSING AND FORMATTING
// ============================================================================

parse_cidr4 :: proc(s: string) -> (network: IP4_Network, ok: bool) {
	parts := strings.split(s, "/", context.temp_allocator)
	if len(parts) != 2 {
		return {}, false
	}

	addr, addr_ok := net.parse_ip4_address(parts[0])
	if !addr_ok {
		return {}, false
	}

	prefix_len, prefix_ok := strconv.parse_u64(parts[1])
	if !prefix_ok || prefix_len > 32 {
		return {}, false
	}

	network.prefix_len = u8(prefix_len)
	mask, mask_ok := prefix_to_mask4(network.prefix_len)
	if !mask_ok {
		return {}, false
	}

	network.address = apply_mask4(addr, mask)
	return network, true
}

parse_cidr6 :: proc(s: string) -> (network: IP6_Network, ok: bool) {
	parts := strings.split(s, "/", context.temp_allocator)
	if len(parts) != 2 {
		return {}, false
	}

	addr, addr_ok := net.parse_ip6_address(parts[0])
	if !addr_ok {
		return {}, false
	}

	prefix_len, prefix_ok := strconv.parse_u64(parts[1])
	if !prefix_ok || prefix_len > 128 {
		return {}, false
	}

	network.prefix_len = u8(prefix_len)
	mask := prefix_to_mask6(network.prefix_len)
	network.address = apply_mask6(addr, mask)
	return network, true
}

addr_to_string4 :: proc(addr: net.IP4_Address, allocator := context.allocator) -> string {
	bytes := cast([4]u8)addr
	return fmt.aprintf("%d.%d.%d.%d", bytes[0], bytes[1], bytes[2], bytes[3], allocator = allocator)
}

addr_to_string6 :: proc(addr: net.IP6_Address, allocator := context.allocator) -> string {
	segments := cast([8]u16be)addr
	segs: [8]u16
	for i in 0..<8 {
		segs[i] = u16(segments[i])
	}

	max_zero_start := -1
	max_zero_len := 0
	curr_zero_start := -1
	curr_zero_len := 0

	for i in 0..<8 {
		if segs[i] == 0 {
			if curr_zero_start == -1 {
				curr_zero_start = i
				curr_zero_len = 1
			} else {
				curr_zero_len += 1
			}
		} else {
			if curr_zero_len > max_zero_len {
				max_zero_start = curr_zero_start
				max_zero_len = curr_zero_len
			}
			curr_zero_start = -1
			curr_zero_len = 0
		}
	}

	if curr_zero_len > max_zero_len {
		max_zero_start = curr_zero_start
		max_zero_len = curr_zero_len
	}

	if max_zero_len < 2 {
		max_zero_start = -1
		max_zero_len = 0
	}

	builder := strings.builder_make(allocator)
	i := 0
	wrote_compression := false

	for i < 8 {
		if i == max_zero_start {
			strings.write_string(&builder, "::")
			i += max_zero_len
			wrote_compression = true
		} else {
			if i > 0 && !wrote_compression {
				strings.write_string(&builder, ":")
			}
			wrote_compression = false
			fmt.sbprintf(&builder, "%x", segs[i])
			i += 1
		}
	}

	return strings.to_string(builder)
}

network_to_string4 :: proc(network: IP4_Network, allocator := context.allocator) -> string {
	addr_bytes := cast([4]u8)network.address
	return fmt.aprintf("%d.%d.%d.%d/%d", addr_bytes[0], addr_bytes[1], addr_bytes[2], addr_bytes[3], network.prefix_len, allocator = allocator)
}

network_to_string6 :: proc(network: IP6_Network, allocator := context.allocator) -> string {
	addr_str := addr_to_string6(network.address, context.temp_allocator)
	return fmt.aprintf("%s/%d", addr_str, network.prefix_len, allocator = allocator)
}

masked4 :: proc(network: IP4_Network) -> IP4_Network {
	result := network
	mask, mask_ok := prefix_to_mask4(network.prefix_len)
	if !mask_ok {
		return network
	}
	result.address = apply_mask4(network.address, mask)
	return result
}

masked6 :: proc(network: IP6_Network) -> IP6_Network {
	result := network
	mask := prefix_to_mask6(network.prefix_len)
	result.address = apply_mask6(network.address, mask)
	return result
}

// ============================================================================
// MASK CONVERSION
// ============================================================================

prefix_to_mask4 :: proc(prefix_len: u8) -> (mask: [4]u8, ok: bool) {
	if prefix_len > 32 {
		return {}, false
	}

	mask_bytes: [4]u8
	full_bytes := prefix_len / 8
	remaining_bits := prefix_len % 8

	for i in 0..<full_bytes {
		mask_bytes[i] = 0xFF
	}

	if remaining_bits > 0 && full_bytes < 4 {
		mask_bytes[full_bytes] = u8(0xFF << (8 - remaining_bits))
	}

	return mask_bytes, true
}

prefix_to_mask6 :: proc(prefix_len: u8) -> [8]u16be {
	mask: [8]u16be
	full_segments := prefix_len / 16
	remaining_bits := prefix_len % 16

	for i in 0..<full_segments {
		mask[i] = 0xFFFF
	}

	if remaining_bits > 0 && full_segments < 8 {
		mask[full_segments] = u16be(0xFFFF << (16 - remaining_bits))
	}

	return mask
}

mask4_to_prefix :: proc(mask: [4]u8) -> (prefix_len: u8, ok: bool) {
	prefix_len = 0

	for mask_byte in mask {
		if mask_byte == 0xFF {
			prefix_len += 8
			continue
		}

		b := mask_byte
		for _ in 0..<8 {
			if (b & 0x80) == 0 {
				break
			}
			prefix_len += 1
			b <<= 1
		}
		break
	}

	return prefix_len, true
}

mask6_to_prefix :: proc(mask: [8]u16be) -> (prefix_len: u8, ok: bool) {
	prefix_len = 0

	for segment in mask {
		seg_val := u16(segment)
		if seg_val == 0xFFFF {
			prefix_len += 16
			continue
		}

		for bit in 0..<16 {
			if (seg_val & (0x8000 >> uint(bit))) == 0 {
				break
			}
			prefix_len += 1
		}
		break
	}

	return prefix_len, true
}

apply_mask4 :: proc(addr: net.IP4_Address, mask: [4]u8) -> net.IP4_Address {
	addr_bytes := cast([4]u8)addr
	result_bytes: [4]u8
	for i in 0..<4 {
		result_bytes[i] = addr_bytes[i] & mask[i]
	}
	return cast(net.IP4_Address)result_bytes
}

apply_mask6 :: proc(addr: net.IP6_Address, mask: [8]u16be) -> net.IP6_Address {
	addr_segments := cast([8]u16be)addr
	result_segments: [8]u16be
	for i in 0..<8 {
		result_segments[i] = addr_segments[i] & mask[i]
	}
	return cast(net.IP6_Address)result_segments
}

// ============================================================================
// CLASSIFICATION
// ============================================================================

is_private4 :: proc(addr: net.IP4_Address) -> bool {
	bytes := cast([4]u8)addr
	if bytes[0] == 10 {
		return true
	}
	if bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31 {
		return true
	}
	if bytes[0] == 192 && bytes[1] == 168 {
		return true
	}
	return false
}

is_private6 :: proc(addr: net.IP6_Address) -> bool {
	segments := cast([8]u16be)addr
	first_byte := u8(segments[0] >> 8)
	return (first_byte & 0xFE) == 0xFC
}

is_loopback4 :: proc(addr: net.IP4_Address) -> bool {
	bytes := cast([4]u8)addr
	return bytes[0] == 127
}

is_loopback6 :: proc(addr: net.IP6_Address) -> bool {
	segments := cast([8]u16be)addr
	for i in 0..<7 {
		if segments[i] != 0 {
			return false
		}
	}
	return u16(segments[7]) == 1
}

is_link_local4 :: proc(addr: net.IP4_Address) -> bool {
	bytes := cast([4]u8)addr
	return bytes[0] == 169 && bytes[1] == 254
}

is_link_local6 :: proc(addr: net.IP6_Address) -> bool {
	segments := cast([8]u16be)addr
	first_segment := u16(segments[0])
	return (first_segment & 0xFFC0) == 0xFE80
}

is_multicast4 :: proc(addr: net.IP4_Address) -> bool {
	bytes := cast([4]u8)addr
	return bytes[0] >= 224 && bytes[0] <= 239
}

is_multicast6 :: proc(addr: net.IP6_Address) -> bool {
	segments := cast([8]u16be)addr
	first_byte := u8(segments[0] >> 8)
	return first_byte == 0xFF
}

is_unspecified4 :: proc(addr: net.IP4_Address) -> bool {
	return addr == net.IP4_Address{0, 0, 0, 0}
}

is_unspecified6 :: proc(addr: net.IP6_Address) -> bool {
	segments := cast([8]u16be)addr
	for segment in segments {
		if segment != 0 {
			return false
		}
	}
	return true
}

is_broadcast4 :: proc(addr: net.IP4_Address) -> bool {
	return addr == net.IP4_Address{255, 255, 255, 255}
}

is_global_unicast4 :: proc(addr: net.IP4_Address) -> bool {
	return !is_private4(addr) && !is_loopback4(addr) && !is_link_local4(addr) &&
	!is_multicast4(addr) && !is_unspecified4(addr) && !is_broadcast4(addr)
}

is_global_unicast6 :: proc(addr: net.IP6_Address) -> bool {
	return !is_private6(addr) && !is_loopback6(addr) && !is_link_local6(addr) &&
	!is_multicast6(addr) && !is_unspecified6(addr)
}

is_interface_local_multicast6 :: proc(addr: net.IP6_Address) -> bool {
	segments := cast([8]u16be)addr
	first_segment := u16(segments[0])
	return (first_segment & 0xFF0F) == 0xFF01
}

is_link_local_multicast6 :: proc(addr: net.IP6_Address) -> bool {
	segments := cast([8]u16be)addr
	first_segment := u16(segments[0])
	return (first_segment & 0xFF0F) == 0xFF02
}

// ============================================================================
// NETWORK MEMBERSHIP
// ============================================================================

contains4 :: proc(network: IP4_Network, addr: net.IP4_Address) -> bool {
	mask, mask_ok := prefix_to_mask4(network.prefix_len)
	if !mask_ok {
		return false
	}
	masked := apply_mask4(addr, mask)
	return masked == network.address
}

overlaps4 :: proc(a, b: IP4_Network) -> bool {
	return contains4(a, b.address) || contains4(b, a.address)
}

contains6 :: proc(network: IP6_Network, addr: net.IP6_Address) -> bool {
	mask := prefix_to_mask6(network.prefix_len)
	masked := apply_mask6(addr, mask)
	return masked == network.address
}

overlaps6 :: proc(a, b: IP6_Network) -> bool {
	return contains6(a, b.address) || contains6(b, a.address)
}

// ============================================================================
// NETWORK RANGE
// ============================================================================

network_range4 :: proc(network: IP4_Network) -> IP4_Range {
	first := network.address
	host_bits := 32 - network.prefix_len
	if host_bits == 0 {
		return IP4_Range{first, first}
	}

	mask, mask_ok := prefix_to_mask4(network.prefix_len)
	if !mask_ok {
		return IP4_Range{first, first}
	}

	first_bytes := cast([4]u8)first
	last_bytes: [4]u8
	for i in 0..<4 {
		last_bytes[i] = first_bytes[i] | ~mask[i]
	}
	last := cast(net.IP4_Address)last_bytes
	return IP4_Range{first, last}
}

network_range6 :: proc(network: IP6_Network) -> IP6_Range {
	first := network.address
	host_bits := 128 - network.prefix_len
	if host_bits == 0 {
		return IP6_Range{first, first}
	}

	mask := prefix_to_mask6(network.prefix_len)
	first_segments := cast([8]u16be)first
	last_segments: [8]u16be
	for i in 0..<8 {
		inv_mask := ~mask[i]
		last_segments[i] = first_segments[i] | inv_mask
	}
	last := cast(net.IP6_Address)last_segments
	return IP6_Range{first, last}
}

host_count4 :: proc(network: IP4_Network) -> u32 {
	host_bits := 32 - network.prefix_len
	if host_bits <= 1 {
		return 0
	}
	return (1 << host_bits) - 2
}

host_count6 :: proc(network: IP6_Network) -> u128 {
	host_bits := 128 - network.prefix_len
	if host_bits <= 1 {
		return 0
	}
	if host_bits >= 64 {
		return max(u128)
	}
	return u128(u128(1) << host_bits) - 2
}

usable_host_range4 :: proc(network: IP4_Network) -> (range: IP4_Range, ok: bool) {
	if network.prefix_len >= 31 { return {}, false }

	full_range := network_range4(network)
	first, first_ok := next_ip4(full_range.start)
	if !first_ok { return {}, false }
	last, last_ok := prev_ip4(full_range.end)
	if !last_ok { return {}, false }

	return IP4_Range{first, last}, true
}

usable_host_range6 :: proc(network: IP6_Network) -> (range: IP6_Range, ok: bool) {
	if network.prefix_len >= 127 { return {}, false }

	full_range := network_range6(network)
	first, first_ok := next_ip6(full_range.start)
	if !first_ok { return {}, false }
	last, last_ok := prev_ip6(full_range.end)
	if !last_ok { return {}, false }

	return IP6_Range{first, last}, true
}

range_contains4 :: proc(range: IP4_Range, addr: net.IP4_Address) -> bool {
	return compare_addr4(addr, range.start) >= 0 && compare_addr4(addr, range.end) <= 0
}

range_contains6 :: proc(range: IP6_Range, addr: net.IP6_Address) -> bool {
	return compare_addr6(addr, range.start) >= 0 && compare_addr6(addr, range.end) <= 0
}

range_overlaps4 :: proc(a, b: IP4_Range) -> bool {
	return compare_addr4(a.start, b.end) <= 0 && compare_addr4(a.end, b.start) >= 0
}

range_overlaps6 :: proc(a, b: IP6_Range) -> bool {
	return compare_addr6(a.start, b.end) <= 0 && compare_addr6(a.end, b.start) >= 0
}

range_size4 :: proc(range: IP4_Range) -> u32 {
	start_u32 := addr4_to_u32(range.start)
	end_u32 := addr4_to_u32(range.end)
	if end_u32 < start_u32 { return 0 }
	return end_u32 - start_u32 + 1
}

range_size6 :: proc(range: IP6_Range) -> u128 {
	start_u128 := addr6_to_u128(range.start)
	end_u128 := addr6_to_u128(range.end)
	if end_u128 < start_u128 { return 0 }
	return end_u128 - start_u128 + 1
}

range_to_string4 :: proc(range: IP4_Range, allocator := context.allocator) -> string {
	return fmt.aprintf("%s-%s",
	addr_to_string4(range.start, context.temp_allocator),
	addr_to_string4(range.end, context.temp_allocator),
	allocator=allocator)
}

range_to_string6 :: proc(range: IP6_Range, allocator := context.allocator) -> string {
	return fmt.aprintf("%s-%s",
	addr_to_string6(range.start, context.temp_allocator),
	addr_to_string6(range.end, context.temp_allocator),
	allocator=allocator)
}

// ============================================================================
// ADDRESS ITERATION
// ============================================================================

next_ip4 :: proc(addr: net.IP4_Address) -> (next: net.IP4_Address, ok: bool) {
	next_bytes := cast([4]u8)addr
	for i := 3; i >= 0; i -= 1 {
		if next_bytes[i] != 255 {
			next_bytes[i] += 1
			return cast(net.IP4_Address)next_bytes, true
		}
		next_bytes[i] = 0
	}
	return {}, false
}

next_ip6 :: proc(addr: net.IP6_Address) -> (next: net.IP6_Address, ok: bool) {
	segments := cast([8]u16be)addr
	next_segments: [8]u16be
	copy(next_segments[:], segments[:])

	for i := 7; i >= 0; i -= 1 {
		val := u16(next_segments[i])
		if val != 0xFFFF {
			next_segments[i] = u16be(val + 1)
			return cast(net.IP6_Address)next_segments, true
		}
		next_segments[i] = 0
	}
	return {}, false
}

prev_ip4 :: proc(addr: net.IP4_Address) -> (prev: net.IP4_Address, ok: bool) {
	prev_bytes := cast([4]u8)addr
	for i := 3; i >= 0; i -= 1 {
		if prev_bytes[i] != 0 {
			prev_bytes[i] -= 1
			return cast(net.IP4_Address)prev_bytes, true
		}
		prev_bytes[i] = 255
	}
	return {}, false
}

prev_ip6 :: proc(addr: net.IP6_Address) -> (prev: net.IP6_Address, ok: bool) {
	segments := cast([8]u16be)addr
	prev_segments: [8]u16be
	copy(prev_segments[:], segments[:])

	for i := 7; i >= 0; i -= 1 {
		val := u16(prev_segments[i])
		if val != 0 {
			prev_segments[i] = u16be(val - 1)
			return cast(net.IP6_Address)prev_segments, true
		}
		prev_segments[i] = 0xFFFF
	}
	return {}, false
}

// ============================================================================
// NETWORK COMPARISON
// ============================================================================

is_single_ip4 :: proc(network: IP4_Network) -> bool {
	return network.prefix_len == 32
}


is_single_ip6 :: proc(network: IP6_Network) -> bool {
	return network.prefix_len == 128
}

compare_addr4 :: proc(a, b: net.IP4_Address) -> int {
	a_bytes := cast([4]u8)a
	b_bytes := cast([4]u8)b
	for i in 0..<4 {
		if a_bytes[i] < b_bytes[i] {
			return -1
		}
		if a_bytes[i] > b_bytes[i] {
			return 1
		}
	}
	return 0
}

compare_addr6 :: proc(a, b: net.IP6_Address) -> int {
	a_segments := cast([8]u16be)a
	b_segments := cast([8]u16be)b
	for i in 0..<8 {
		a_val := u16(a_segments[i])
		b_val := u16(b_segments[i])
		if a_val < b_val {
			return -1
		}
		if a_val > b_val {
			return 1
		}
	}
	return 0
}

compare_network4 :: proc(a, b: IP4_Network) -> int {
	addr_cmp := compare_addr4(a.address, b.address)
	if addr_cmp != 0 {
		return addr_cmp
	}
	if a.prefix_len < b.prefix_len {
		return -1
	}
	if a.prefix_len > b.prefix_len {
		return 1
	}
	return 0
}

compare_network6 :: proc(a, b: IP6_Network) -> int {
	addr_cmp := compare_addr6(a.address, b.address)
	if addr_cmp != 0 {
		return addr_cmp
	}
	if a.prefix_len < b.prefix_len {
		return -1
	}
	if a.prefix_len > b.prefix_len {
		return 1
	}
	return 0
}



less_addr4 :: proc(a, b: net.IP4_Address) -> bool {
	return compare_addr4(a, b) < 0
}

less_addr6 :: proc(a, b: net.IP6_Address) -> bool {
	return compare_addr6(a, b) < 0
}

less_network4 :: proc(a, b: IP4_Network) -> bool {
	return compare_network4(a, b) < 0
}

less_network6 :: proc(a, b: IP6_Network) -> bool {
	return compare_network6(a, b) < 0
}

// ============================================================================
// BITWISE OPERATIONS
// ============================================================================

ip4_and :: proc(a, b: net.IP4_Address) -> net.IP4_Address {
	return net.IP4_Address{
		a[0] & b[0],
		a[1] & b[1],
		a[2] & b[2],
		a[3] & b[3],
	}
}

ip6_and :: proc(a, b: net.IP6_Address) -> net.IP6_Address {
	a_seg := cast([8]u16be)a
	b_seg := cast([8]u16be)b
	result_seg: [8]u16be
	for i in 0..<8 {
		result_seg[i] = a_seg[i] & b_seg[i]
	}
	return cast(net.IP6_Address)result_seg
}

ip4_or :: proc(a, b: net.IP4_Address) -> net.IP4_Address {
	return net.IP4_Address{
		a[0] | b[0],
		a[1] | b[1],
		a[2] | b[2],
		a[3] | b[3],
	}
}

ip6_or :: proc(a, b: net.IP6_Address) -> net.IP6_Address {
	a_seg := cast([8]u16be)a
	b_seg := cast([8]u16be)b
	result_seg: [8]u16be
	for i in 0..<8 {
		result_seg[i] = a_seg[i] | b_seg[i]
	}
	return cast(net.IP6_Address)result_seg
}

ip4_xor :: proc(a, b: net.IP4_Address) -> net.IP4_Address {
	return net.IP4_Address{
		a[0] ~ b[0],
		a[1] ~ b[1],
		a[2] ~ b[2],
		a[3] ~ b[3],
	}
}

ip6_xor :: proc(a, b: net.IP6_Address) -> net.IP6_Address {
	a_seg := cast([8]u16be)a
	b_seg := cast([8]u16be)b
	result_seg: [8]u16be
	for i in 0..<8 {
		result_seg[i] = a_seg[i] ~ b_seg[i]
	}
	return cast(net.IP6_Address)result_seg
}

ip4_not :: proc(a: net.IP4_Address) -> net.IP4_Address {
	return net.IP4_Address{
		~a[0],
		~a[1],
		~a[2],
		~a[3],
	}
}

ip6_not :: proc(a: net.IP6_Address) -> net.IP6_Address {
	a_seg := cast([8]u16be)a
	result_seg: [8]u16be
	for i in 0..<8 {
		result_seg[i] = ~a_seg[i]
	}
	return cast(net.IP6_Address)result_seg
}

ip4_apply_mask :: proc(addr, mask: net.IP4_Address) -> net.IP4_Address {
	return ip4_and(addr, mask)
}

ip6_apply_mask :: proc(addr, mask: net.IP6_Address) -> net.IP6_Address {
	return ip6_and(addr, mask)
}

// ============================================================================
// NETWORK PREFIX OPERATIONS
// ============================================================================

// next_network4 returns the next adjacent network of the same prefix length.
// Example: 192.168.1.0/24 -> 192.168.2.0/24
next_network4 :: proc(network: IP4_Network) -> (next: IP4_Network, ok: bool) {
	// Calculate network size
	if network.prefix_len == 0 {
		return {}, false  // 0.0.0.0/0 has no next network
	}

	network_size := u32(1) << (32 - network.prefix_len)

	current_addr_u32 := addr4_to_u32(network.address)
	next_addr_u32 := current_addr_u32 + network_size

	// Check for overflow
	if next_addr_u32 < current_addr_u32 {
		return {}, false
	}

	next_addr := u32_to_addr4(next_addr_u32)
	return IP4_Network{next_addr, network.prefix_len}, true
}

// next_network6 returns the next adjacent network of the same prefix length.
next_network6 :: proc(network: IP6_Network) -> (next: IP6_Network, ok: bool) {
	if network.prefix_len == 0 {
		return {}, false  // ::/0 has no next network
	}

	// For IPv6, we need to handle u128 arithmetic
	current_addr_u128 := addr6_to_u128(network.address)
	network_size := u128(1) << (128 - network.prefix_len)

	next_addr_u128 := current_addr_u128 + network_size

	// Check for overflow
	if next_addr_u128 < current_addr_u128 {
		return {}, false
	}

	next_addr := u128_to_addr6(next_addr_u128)
	return IP6_Network{next_addr, network.prefix_len}, true
}

// prev_network4 returns the previous adjacent network of the same prefix length.
// Example: 192.168.2.0/24 -> 192.168.1.0/24
prev_network4 :: proc(network: IP4_Network) -> (prev: IP4_Network, ok: bool) {
	// Calculate network size
	if network.prefix_len == 0 {
		return {}, false  // 0.0.0.0/0 has no previous network
	}

	network_size := u32(1) << (32 - network.prefix_len)

	current_addr_u32 := addr4_to_u32(network.address)

	// Check for underflow
	if current_addr_u32 < network_size {
		return {}, false
	}

	prev_addr_u32 := current_addr_u32 - network_size
	prev_addr := u32_to_addr4(prev_addr_u32)

	return IP4_Network{prev_addr, network.prefix_len}, true
}

// prev_network6 returns the previous adjacent network of the same prefix length.
prev_network6 :: proc(network: IP6_Network) -> (prev: IP6_Network, ok: bool) {
	if network.prefix_len == 0 {
		return {}, false  // ::/0 has no previous network
	}

	current_addr_u128 := addr6_to_u128(network.address)
	network_size := u128(1) << (128 - network.prefix_len)

	// Check for underflow
	if current_addr_u128 < network_size {
		return {}, false
	}

	prev_addr_u128 := current_addr_u128 - network_size
	prev_addr := u128_to_addr6(prev_addr_u128)

	return IP6_Network{prev_addr, network.prefix_len}, true
}

// parent_network4 returns the parent network (one bit less specific).
// Example: 192.168.1.0/24 -> 192.168.0.0/23
parent_network4 :: proc(network: IP4_Network) -> (parent: IP4_Network, ok: bool) {
	if network.prefix_len == 0 {
		return {}, false  // 0.0.0.0/0 has no parent
	}

	new_prefix := network.prefix_len - 1
	result := IP4_Network{network.address, new_prefix}

	// Mask to ensure proper network address
	return masked4(result), true
}

// parent_network6 returns the parent network (one bit less specific).
parent_network6 :: proc(network: IP6_Network) -> (parent: IP6_Network, ok: bool) {
	if network.prefix_len == 0 {
		return {}, false  // ::/0 has no parent
	}

	new_prefix := network.prefix_len - 1
	result := IP6_Network{network.address, new_prefix}

	// Mask to ensure proper network address
	return masked6(result), true
}

// is_subnet_of4 checks if subnet is a subnet of parent.
// A network is considered a subnet if it's fully contained within the parent
// and has a longer (more specific) prefix.
is_subnet_of4 :: proc(subnet: IP4_Network, parent: IP4_Network) -> bool {
	// Subnet must have longer or equal prefix
	if subnet.prefix_len < parent.prefix_len {
		return false
	}

	// If prefixes are equal, networks must be identical
	if subnet.prefix_len == parent.prefix_len {
		return subnet.address == parent.address
	}

	// Check if subnet is contained in parent
	return contains4(parent, subnet.address)
}

// is_subnet_of6 checks if subnet is a subnet of parent.
is_subnet_of6 :: proc(subnet: IP6_Network, parent: IP6_Network) -> bool {
// Subnet must have longer or equal prefix
	if subnet.prefix_len < parent.prefix_len {
		return false
	}

	// If prefixes are equal, networks must be identical
	if subnet.prefix_len == parent.prefix_len {
		return subnet.address == parent.address
	}

	// Check if subnet is contained in parent
	return contains6(parent, subnet.address)
}

// ============================================================================
// SUBNET OPERATION
// ============================================================================

subnets4 :: proc(network: IP4_Network, new_prefix: u8, allocator := context.allocator) -> (result: []IP4_Network, ok: bool) {
	if new_prefix <= network.prefix_len || new_prefix > 32 {
		return nil, false
	}

	subnet_bits := new_prefix - network.prefix_len
	num_subnets := 1 << subnet_bits
	result = make([]IP4_Network, num_subnets, allocator)

	host_bits := 32 - new_prefix
	increment := u32(1) << host_bits

	addr_bytes := cast([4]u8)network.address
	addr_u32 := (u32(addr_bytes[0]) << 24) | (u32(addr_bytes[1]) << 16) |
	(u32(addr_bytes[2]) << 8) | u32(addr_bytes[3])

	for i in 0..<num_subnets {
		subnet_addr_u32 := addr_u32 + u32(i) * increment
		subnet_bytes: [4]u8
		subnet_bytes[0] = u8(subnet_addr_u32 >> 24)
		subnet_bytes[1] = u8(subnet_addr_u32 >> 16)
		subnet_bytes[2] = u8(subnet_addr_u32 >> 8)
		subnet_bytes[3] = u8(subnet_addr_u32)

		result[i] = IP4_Network{
			address = cast(net.IP4_Address)subnet_bytes,
			prefix_len = new_prefix,
		}
	}

	return result, true
}

subnets6 :: proc(network: IP6_Network, new_prefix: u8, allocator := context.allocator) -> (result: []IP6_Network, ok: bool) {
	if new_prefix <= network.prefix_len || new_prefix > 128 {
		return nil, false
	}

	subnet_bits := new_prefix - network.prefix_len
	num_subnets := 1 << subnet_bits
	result = make([]IP6_Network, num_subnets, allocator)

	host_bits := 128 - new_prefix
	increment := u128(1) << host_bits

	addr_u128 := addr6_to_u128(network.address)

	for i in 0..<num_subnets {
		subnet_addr_u128 := addr_u128 + u128(i) * increment

		result[i] = IP6_Network{
			address = u128_to_addr6(subnet_addr_u128),
			prefix_len = new_prefix,
		}
	}

	return result, true
}

// ============================================================================
// VALIDATION
// ============================================================================

is_valid4 :: proc(addr: net.IP4_Address) -> bool {
	return true
}

is_valid6 :: proc(addr: net.IP6_Address) -> bool {
	return true
}

is_valid_network4 :: proc(network: IP4_Network) -> bool {
	return network.prefix_len <= 32
}

is_valid_network6 :: proc(network: IP6_Network) -> bool {
	return network.prefix_len <= 128
}

bitlen4 :: proc(addr: net.IP4_Address) -> int {
	return 32
}

bitlen6 :: proc(addr: net.IP6_Address) -> int {
	return 128
}

// ============================================================================
// WELL-KNOWN ADDRESSES
// ============================================================================

ipv4_unspecified :: proc() -> net.IP4_Address {
	return net.IP4_Address{0, 0, 0, 0}
}

ipv6_unspecified :: proc() -> net.IP6_Address {
	return net.IP6_Address{}
}

ipv4_broadcast :: proc() -> net.IP4_Address {
	return net.IP4_Address{255, 255, 255, 255}
}

ipv4_loopback :: proc() -> net.IP4_Address {
	return net.IP4_Address{127, 0, 0, 1}
}

ipv6_loopback :: proc() -> net.IP6_Address {
	result: net.IP6_Address
	segments := cast([8]u16be)result
	segments[7] = 1
	return cast(net.IP6_Address)segments
}

ipv6_link_local_all_nodes :: proc() -> net.IP6_Address {
	result: [8]u16be
	result[0] = 0xFF02
	result[7] = 0x0001
	return cast(net.IP6_Address)result
}

ipv6_link_local_all_routers :: proc() -> net.IP6_Address {
	result: [8]u16be
	result[0] = 0xFF02
	result[7] = 0x0002
	return cast(net.IP6_Address)result
}

// ============================================================================
// ACCESSOR
// ============================================================================

network_addr4 :: proc(network: IP4_Network) -> net.IP4_Address {
	return network.address
}

network_addr6 :: proc(network: IP6_Network) -> net.IP6_Address {
	return network.address
}

network_bits4 :: proc(network: IP4_Network) -> int {
	return int(network.prefix_len)
}

network_bits6 :: proc(network: IP6_Network) -> int {
	return int(network.prefix_len)
}

// ============================================================================
// RAW CONSTRUCTOR
// ============================================================================

network_from4 :: proc(addr: net.IP4_Address, prefix_len: u8) -> IP4_Network {
	return IP4_Network{addr, prefix_len}
}

network_from6 :: proc(addr: net.IP6_Address, prefix_len: u8) -> IP6_Network {
	return IP6_Network{addr, prefix_len}
}

// ============================================================================
// MUST PARSE
// ============================================================================

must_parse_cidr4 :: proc(s: string, loc := #caller_location) -> IP4_Network {
	network, ok := parse_cidr4(s)
	if !ok {
		panic("invalid IPv4 CIDR notation", loc)
	}
	return network
}

must_parse_cidr6 :: proc(s: string, loc := #caller_location) -> IP6_Network {
	network, ok := parse_cidr6(s)
	if !ok {
		panic("invalid IPv6 CIDR notation", loc)
	}
	return network
}

// ============================================================================
// ADDRESS CONVERSION
// ============================================================================

addr4_to_u32 :: proc(addr: net.IP4_Address) -> u32 {
	bytes := cast([4]u8)addr
	return (u32(bytes[0]) << 24) | (u32(bytes[1]) << 16) |
	(u32(bytes[2]) << 8) | u32(bytes[3])
}

addr6_to_u128 :: proc(addr: net.IP6_Address) -> u128 {
	segments := cast([8]u16be)addr
	result: u128 = 0
	for i in 0..<8 {
		result = (result << 16) | u128(segments[i])
	}
	return result
}

u32_to_addr4 :: proc(val: u32) -> net.IP4_Address {
	bytes: [4]u8
	bytes[0] = u8(val >> 24)
	bytes[1] = u8(val >> 16)
	bytes[2] = u8(val >> 8)
	bytes[3] = u8(val)
	return cast(net.IP4_Address)bytes
}

u128_to_addr6 :: proc(val: u128) -> net.IP6_Address {
	segments: [8]u16be
	temp := val
	for i := 7; i >= 0; i -= 1 {
		segments[i] = u16be(temp & 0xFFFF)
		temp >>= 16
	}
	return cast(net.IP6_Address)segments
}
