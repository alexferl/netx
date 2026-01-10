package netx

import "base:intrinsics"
import "core:net"

// ============================================================================
// IPAM - IP Address Management
// Advanced features for network planning and address allocation
// ============================================================================

// ============================================================================
// CIDR AGGREGATION / MERGING
// ============================================================================

can_merge4 :: proc(a, b: IP4_Network) -> bool {
	if a.prefix_len != b.prefix_len {
		return false
	}
	if a.prefix_len == 0 {
		return false
	}

	a_range := network_range4(a)
	b_first := b.address

	next_addr, ok := next_ip4(a_range.end)
	if !ok {
		return false
	}

	return next_addr == b_first
}

can_merge6 :: proc(a, b: IP6_Network) -> bool {
	if a.prefix_len != b.prefix_len {
		return false
	}
	if a.prefix_len == 0 {
		return false
	}

	a_range := network_range6(a)
	b_first := b.address

	next_addr, ok := next_ip6(a_range.end)
	if !ok {
		return false
	}

	return next_addr == b_first
}

merge4 :: proc(a, b: IP4_Network) -> IP4_Network {
	return IP4_Network{
		address = a.address,
		prefix_len = a.prefix_len - 1,
	}
}

merge6 :: proc(a, b: IP6_Network) -> IP6_Network {
	return IP6_Network{
		address = a.address,
		prefix_len = a.prefix_len - 1,
	}
}

aggregate_networks4 :: proc(networks: []IP4_Network, allocator := context.allocator) -> []IP4_Network {
	if len(networks) == 0 {
		return nil
	}

	sorted := make([]IP4_Network, len(networks), context.temp_allocator)
	copy(sorted, networks)

	for i in 0..<len(sorted) {
		for j in 0..<len(sorted)-i-1 {
			if !less_network4(sorted[j], sorted[j+1]) {
				sorted[j], sorted[j+1] = sorted[j+1], sorted[j]
			}
		}
	}

	result := make([dynamic]IP4_Network, context.temp_allocator)
	for net in sorted {
		append(&result, net)
	}

	merged_something := true
	for merged_something {
		merged_something = false
		new_result := make([dynamic]IP4_Network, context.temp_allocator)

		i := 0
		for i < len(result) {
			if i + 1 < len(result) && can_merge4(result[i], result[i + 1]) {
				merged := merge4(result[i], result[i + 1])
				append(&new_result, merged)
				i += 2
				merged_something = true
			} else {
				append(&new_result, result[i])
				i += 1
			}
		}

		clear(&result)
		for net in new_result {
			append(&result, net)
		}
	}

	final := make([]IP4_Network, len(result), allocator)
	copy(final, result[:])
	return final
}

aggregate_networks6 :: proc(networks: []IP6_Network, allocator := context.allocator) -> []IP6_Network {
	if len(networks) == 0 {
		return nil
	}

	sorted := make([]IP6_Network, len(networks), context.temp_allocator)
	copy(sorted, networks)

	for i in 0..<len(sorted) {
		for j in 0..<len(sorted)-i-1 {
			if !less_network6(sorted[j], sorted[j+1]) {
				sorted[j], sorted[j+1] = sorted[j+1], sorted[j]
			}
		}
	}

	result := make([dynamic]IP6_Network, context.temp_allocator)
	for net in sorted {
		append(&result, net)
	}

	merged_something := true
	for merged_something {
		merged_something = false
		new_result := make([dynamic]IP6_Network, context.temp_allocator)

		i := 0
		for i < len(result) {
			if i + 1 < len(result) && can_merge6(result[i], result[i + 1]) {
				merged := merge6(result[i], result[i + 1])
				append(&new_result, merged)
				i += 2
				merged_something = true
			} else {
				append(&new_result, result[i])
				i += 1
			}
		}

		clear(&result)
		for net in new_result {
			append(&result, net)
		}
	}

	final := make([]IP6_Network, len(result), allocator)
	copy(final, result[:])
	return final
}

// ============================================================================
// IP RANGE TO CIDR CONVERSION
// ============================================================================

range_to_cidrs4 :: proc(start, end: net.IP4_Address, allocator := context.allocator) -> []IP4_Network {
	result := make([dynamic]IP4_Network, allocator)

	current := start

	for compare_addr4(current, end) <= 0 {
		max_prefix := u8(32)

		current_u32 := addr4_to_u32(current)
		if current_u32 == 0 {
			max_prefix = 0
		} else {
			for bit in 0..<32 {
				if (current_u32 & (1 << uint(bit))) != 0 {
					max_prefix = u8(32 - bit)
					break
				}
			}
		}

		best_prefix := u8(32)
		for prefix := max_prefix; prefix <= 32; prefix += 1 {
			network := network_from4(current, prefix)
			net_range := network_range4(network)

			if compare_addr4(net_range.end, end) <= 0 {
				best_prefix = prefix
				break
			}
		}

		network := network_from4(current, best_prefix)
		append(&result, network)

		net_range := network_range4(network)
		next, ok := next_ip4(net_range.end)
		if !ok || compare_addr4(next, end) > 0 {
			break
		}
		current = next
	}

	return result[:]
}

range_to_cidrs6 :: proc(start, end: net.IP6_Address, allocator := context.allocator) -> []IP6_Network {
	result := make([dynamic]IP6_Network, allocator)

	current := start

	for compare_addr6(current, end) <= 0 {
		max_prefix := u8(128)

		current_u128 := addr6_to_u128(current)
		if current_u128 == 0 {
			max_prefix = 0
		} else {
			for bit in 0..<128 {
				if (current_u128 & (1 << uint(bit))) != 0 {
					max_prefix = u8(128 - bit)
					break
				}
			}
		}

		best_prefix := u8(128)
		for prefix := max_prefix; prefix <= 128; prefix += 1 {
			network := network_from6(current, prefix)
			net_range := network_range6(network)

			if compare_addr6(net_range.end, end) <= 0 {
				best_prefix = prefix
				break
			}
		}

		network := network_from6(current, best_prefix)
		append(&result, network)

		net_range := network_range6(network)
		next, ok := next_ip6(net_range.end)
		if !ok || compare_addr6(next, end) > 0 {
			break
		}
		current = next
	}

	return result[:]
}

// ============================================================================
// ADDRESS POOL ALLOCATOR
// ============================================================================

IP4_Pool :: struct {
	network: IP4_Network,
	allocated: map[net.IP4_Address]bool,
	next_candidate: net.IP4_Address,
}

pool4_init :: proc(network: IP4_Network, allocator := context.allocator) -> IP4_Pool {
	pool := IP4_Pool{
		network = network,
		allocated = make(map[net.IP4_Address]bool, allocator),
	}

	range, ok := usable_host_range4(network)
	if ok {
		pool.next_candidate = range.start
	} else {
		pool.next_candidate = network.address
	}

	return pool
}

pool4_destroy :: proc(pool: ^IP4_Pool) {
	delete(pool.allocated)
}

pool4_allocate :: proc(pool: ^IP4_Pool) -> (addr: net.IP4_Address, ok: bool) {
	range, range_ok := usable_host_range4(pool.network)
	if !range_ok {
		return {}, false
	}

	start := pool.next_candidate
	current := start

	for {
		if current not_in pool.allocated && contains4(pool.network, current) {
			if compare_addr4(current, range.start) >= 0 && compare_addr4(current, range.end) <= 0 {
				pool.allocated[current] = true
				next, next_ok := next_ip4(current)
				if next_ok && compare_addr4(next, range.end) <= 0 {
					pool.next_candidate = next
				} else {
					pool.next_candidate = range.start
				}
				return current, true
			}
		}

		next, next_ok := next_ip4(current)
		if !next_ok || compare_addr4(next, range.end) > 0 {
			current = range.start
		} else {
			current = next
		}

		if current == start {
			return {}, false
		}
	}
}

pool4_free :: proc(pool: ^IP4_Pool, addr: net.IP4_Address) -> bool {
	if addr in pool.allocated {
		delete_key(&pool.allocated, addr)
		return true
	}
	return false
}

pool4_available :: proc(pool: ^IP4_Pool) -> int {
	total := int(host_count4(pool.network))
	return total - len(pool.allocated)
}

pool4_is_allocated :: proc(pool: ^IP4_Pool, addr: net.IP4_Address) -> bool {
	return addr in pool.allocated
}

IP6_Pool :: struct {
	network: IP6_Network,
	allocated: map[net.IP6_Address]bool,
	next_candidate: net.IP6_Address,
}

pool6_init :: proc(network: IP6_Network, allocator := context.allocator) -> IP6_Pool {
	pool := IP6_Pool{
		network = network,
		allocated = make(map[net.IP6_Address]bool, allocator),
	}

	pool.next_candidate = network.address
	next, ok := next_ip6(pool.next_candidate)
	if ok {
		pool.next_candidate = next
	}

	return pool
}

pool6_destroy :: proc(pool: ^IP6_Pool) {
	delete(pool.allocated)
}

pool6_allocate :: proc(pool: ^IP6_Pool) -> (addr: net.IP6_Address, ok: bool) {
	range := network_range6(pool.network)

	start := pool.next_candidate
	current := start

	for {
		if current not_in pool.allocated && contains6(pool.network, current) {
			if !is_unspecified6(current) {
				pool.allocated[current] = true
				next, next_ok := next_ip6(current)
				if next_ok && compare_addr6(next, range.end) <= 0 {
					pool.next_candidate = next
				} else {
					pool.next_candidate = range.start
				}
				return current, true
			}
		}

		next, next_ok := next_ip6(current)
		if !next_ok || compare_addr6(next, range.end) > 0 {
			next, _ = next_ip6(range.start)
			current = next
		} else {
			current = next
		}

		if current == start {
			return {}, false
		}
	}
}

pool6_free :: proc(pool: ^IP6_Pool, addr: net.IP6_Address) -> bool {
	if addr in pool.allocated {
		delete_key(&pool.allocated, addr)
		return true
	}
	return false
}

pool6_available :: proc(pool: ^IP6_Pool) -> int {
	host_bits := 128 - pool.network.prefix_len
	if host_bits > 31 {
		return max(int) - len(pool.allocated)
	}
	total := (1 << host_bits)
	return total - len(pool.allocated)
}


pool6_is_allocated :: proc(pool: ^IP6_Pool, addr: net.IP6_Address) -> bool {
	return addr in pool.allocated
}

// ============================================================================
// SUPERNET CALCULATION
// ============================================================================

supernet4 :: proc(a, b: IP4_Network) -> IP4_Network {
	a_bytes := cast([4]u8)a.address
	b_bytes := cast([4]u8)b.address

	common_prefix := u8(0)
	for byte_idx in 0..<4 {
		if a_bytes[byte_idx] == b_bytes[byte_idx] {
			common_prefix += 8
		} else {
			diff := a_bytes[byte_idx] ~ b_bytes[byte_idx]
			for bit in 0..<8 {
				if (diff & (0x80 >> uint(bit))) == 0 {
					common_prefix += 1
				} else {
					break
				}
			}
			break
		}
	}

	mask, _ := prefix_to_mask4(common_prefix)
	return IP4_Network{
		address = apply_mask4(a.address, mask),
		prefix_len = common_prefix,
	}
}

supernet6 :: proc(a, b: IP6_Network) -> IP6_Network {
	a_segs := cast([8]u16be)a.address
	b_segs := cast([8]u16be)b.address

	common_prefix := u8(0)
	for seg_idx in 0..<8 {
		a_val := u16(a_segs[seg_idx])
		b_val := u16(b_segs[seg_idx])

		if a_val == b_val {
			common_prefix += 16
		} else {
			diff := a_val ~ b_val
			for bit in 0..<16 {
				if (diff & (0x8000 >> uint(bit))) == 0 {
					common_prefix += 1
				} else {
					break
				}
			}
			break
		}
	}

	mask := prefix_to_mask6(common_prefix)
	return IP6_Network{
		address = apply_mask6(a.address, mask),
		prefix_len = common_prefix,
	}
}

// ============================================================================
// NETWORK EXCLUSION
// ============================================================================

exclude4 :: proc(from, exclude: IP4_Network, allocator := context.allocator) -> []IP4_Network {
	if !overlaps4(from, exclude) {
		result := make([]IP4_Network, 1, allocator)
		result[0] = from
		return result
	}

	if contains4(exclude, from.address) && exclude.prefix_len <= from.prefix_len {
		return nil
	}

	result := make([dynamic]IP4_Network, allocator)

	subnets, ok := subnets4(from, from.prefix_len + 1, context.temp_allocator)
	if !ok {
		return result[:]
	}

	for subnet in subnets {
		if !overlaps4(subnet, exclude) {
			append(&result, subnet)
		} else if !contains4(exclude, subnet.address) || exclude.prefix_len > subnet.prefix_len {
			sub_result := exclude4(subnet, exclude, context.temp_allocator)
			for s in sub_result {
				append(&result, s)
			}
		}
	}

	return result[:]
}

exclude6 :: proc(from, exclude: IP6_Network, allocator := context.allocator) -> []IP6_Network {
	if !overlaps6(from, exclude) {
		result := make([]IP6_Network, 1, allocator)
		result[0] = from
		return result
	}

	if contains6(exclude, from.address) && exclude.prefix_len <= from.prefix_len {
		return nil
	}

	result := make([dynamic]IP6_Network, allocator)

	if from.prefix_len >= 128 {
		return result[:]
	}

	subnet_a := IP6_Network{from.address, from.prefix_len + 1}

	half_size := u128(1) << (128 - (from.prefix_len + 1))
	addr_u128 := addr6_to_u128(from.address)
	subnet_b_addr := u128_to_addr6(addr_u128 + half_size)
	subnet_b := IP6_Network{subnet_b_addr, from.prefix_len + 1}

	if !overlaps6(subnet_a, exclude) {
		append(&result, subnet_a)
	} else if !contains6(exclude, subnet_a.address) || exclude.prefix_len > subnet_a.prefix_len {
		sub_result := exclude6(subnet_a, exclude, context.temp_allocator)
		for s in sub_result {
			append(&result, s)
		}
	}

	if !overlaps6(subnet_b, exclude) {
		append(&result, subnet_b)
	} else if !contains6(exclude, subnet_b.address) || exclude.prefix_len > subnet_b.prefix_len {
		sub_result := exclude6(subnet_b, exclude, context.temp_allocator)
		for s in sub_result {
			append(&result, s)
		}
	}

	return result[:]
}

// ============================================================================
// ADVANCED SUBNET UTILITIES
// ============================================================================

// find_free_subnets4 finds all available subnets of the specified prefix length
// within the parent network that don't overlap with any used networks.
// Returns a slice of available networks sorted by address.
find_free_subnets4 :: proc(parent: IP4_Network, used: []IP4_Network, prefix: u8, allocator := context.allocator) -> []IP4_Network {
	if prefix < parent.prefix_len {
		// Can't allocate larger than parent
		return nil
	}

	free := make([dynamic]IP4_Network, allocator)

	// Generate all possible subnets of the desired prefix length
	current := masked4(IP4_Network{parent.address, prefix})
	parent_range := network_range4(parent)
	parent_first := parent_range.start
	parent_last := parent_range.end

	for {
		// Check if current subnet is within parent
		current_range := network_range4(current)
		current_first := current_range.start
		current_last := current_range.end

		// Subnet must be fully contained in parent
		if compare_addr4(current_first, parent_first) < 0 || compare_addr4(current_last, parent_last) > 0 {
			break
		}

		// Check if this subnet overlaps with any used networks
		is_free := true
		for used_net in used {
			if overlaps4(current, used_net) {
				is_free = false
				break
			}
		}

		if is_free {
			append(&free, current)
		}

		// Move to next subnet
		next, ok := next_network4(current)
		if !ok {
			break
		}
		current = next
	}

	return free[:]
}

find_free_subnets6 :: proc(parent: IP6_Network, used: []IP6_Network, prefix: u8, allocator := context.allocator) -> []IP6_Network {
	if prefix < parent.prefix_len {
		return nil
	}

	free := make([dynamic]IP6_Network, allocator)

	current := masked6(IP6_Network{parent.address, prefix})
	parent_range := network_range6(parent)
	parent_last := parent_range.end

	for {
		if !contains6(parent, current.address) {
			break
		}

		is_free := true
		for used_net in used {
			if overlaps6(current, used_net) {
				is_free = false
				break
			}
		}

		if is_free {
			append(&free, current)
		}

		next, ok := next_network6(current)
		if !ok {
			break
		}
		current = next

		if compare_addr6(current.address, parent_last) > 0 {
			break
		}
	}

	return free[:]
}



// largest_free_block4 finds the largest contiguous free block within the parent
// network that doesn't overlap with any used networks.
// Returns the largest free network and true, or an empty network and false if
// no free space exists.
largest_free_block4 :: proc(parent: IP4_Network, used: []IP4_Network, allocator := context.allocator) -> (largest: IP4_Network, ok: bool) {
	if len(used) == 0 {
		return parent, true
	}

	// Sort used networks by address
	sorted_used := make([]IP4_Network, len(used), allocator)
	defer delete(sorted_used, allocator)
	copy(sorted_used, used)

	// Bubble sort (simple for small lists)
	for i := 0; i < len(sorted_used); i += 1 {
		for j := i + 1; j < len(sorted_used); j += 1 {
			if compare_network4(sorted_used[i], sorted_used[j]) > 0 {
				sorted_used[i], sorted_used[j] = sorted_used[j], sorted_used[i]
			}
		}
	}

	parent_range := network_range4(parent)
	parent_first := parent_range.start
	parent_last := parent_range.end
	largest_size := u32(0)
	found := false

	// Check gap before first used network
	if len(sorted_used) > 0 {
		first_used_range := network_range4(sorted_used[0])
		first_used_start := first_used_range.start
		if compare_addr4(parent_first, first_used_start) < 0 {
			gap_size := addr4_to_u32(first_used_start) - addr4_to_u32(parent_first)
			if gap_size > largest_size {
				largest_size = gap_size
				// Find the largest prefix that fits
				prefix := _calculate_prefix_for_size4(gap_size)
				largest = IP4_Network{parent_first, prefix}
				found = true
			}
		}
	}

	// Check gaps between used networks
	for i := 0; i < len(sorted_used) - 1; i += 1 {
		current_range := network_range4(sorted_used[i])
		current_end := current_range.end
		next_range := network_range4(sorted_used[i + 1])
		next_start := next_range.start

		// Check if there's a gap
		current_end_u32 := addr4_to_u32(current_end)
		next_start_u32 := addr4_to_u32(next_start)

		if next_start_u32 > current_end_u32 + 1 {
			gap_start := u32_to_addr4(current_end_u32 + 1)
			gap_size := next_start_u32 - current_end_u32 - 1

			if gap_size > largest_size {
				largest_size = gap_size
				prefix := _calculate_prefix_for_size4(gap_size)
				largest = IP4_Network{gap_start, prefix}
				found = true
			}
		}
	}

	// Check gap after last used network
	if len(sorted_used) > 0 {
		last_used_range := network_range4(sorted_used[len(sorted_used) - 1])
		last_used_end := last_used_range.end
		last_used_end_u32 := addr4_to_u32(last_used_end)
		parent_last_u32 := addr4_to_u32(parent_last)

		if parent_last_u32 > last_used_end_u32 {
			gap_start := u32_to_addr4(last_used_end_u32 + 1)
			gap_size := parent_last_u32 - last_used_end_u32

			if gap_size > largest_size {
				largest_size = gap_size
				prefix := _calculate_prefix_for_size4(gap_size)
				largest = IP4_Network{gap_start, prefix}
				found = true
			}
		}
	}

	return largest, found
}

largest_free_block6 :: proc(parent: IP6_Network, used: []IP6_Network, allocator := context.allocator) -> (largest: IP6_Network, ok: bool) {
	if len(used) == 0 {
		return parent, true
	}

	// Sort used networks
	sorted_used := make([]IP6_Network, len(used), allocator)
	defer delete(sorted_used, allocator)
	copy(sorted_used, used)

	for i := 0; i < len(sorted_used); i += 1 {
		for j := i + 1; j < len(sorted_used); j += 1 {
			if compare_network6(sorted_used[i], sorted_used[j]) > 0 {
				sorted_used[i], sorted_used[j] = sorted_used[j], sorted_used[i]
			}
		}
	}

	parent_range := network_range6(parent)
	parent_first := parent_range.start
	parent_last := parent_range.end
	largest_size := u128(0)
	found := false

	// Check gap before first used network
	if len(sorted_used) > 0 {
		first_used_range := network_range6(sorted_used[0])
		first_used_start := first_used_range.start
		if compare_addr6(parent_first, first_used_start) < 0 {
			gap_size := addr6_to_u128(first_used_start) - addr6_to_u128(parent_first)
			if gap_size > largest_size {
				largest_size = gap_size
				prefix := _calculate_prefix_for_size6(gap_size)
				largest = IP6_Network{parent_first, prefix}
				found = true
			}
		}
	}

	// Check gaps between used networks
	for i := 0; i < len(sorted_used) - 1; i += 1 {
		current_range := network_range6(sorted_used[i])
		current_end := current_range.end
		next_range := network_range6(sorted_used[i + 1])
		next_start := next_range.start

		current_end_u128 := addr6_to_u128(current_end)
		next_start_u128 := addr6_to_u128(next_start)

		if next_start_u128 > current_end_u128 + 1 {
			gap_start := u128_to_addr6(current_end_u128 + 1)
			gap_size := next_start_u128 - current_end_u128 - 1

			if gap_size > largest_size {
				largest_size = gap_size
				prefix := _calculate_prefix_for_size6(gap_size)
				largest = IP6_Network{gap_start, prefix}
				found = true
			}
		}
	}

	// Check gap after last used network
	if len(sorted_used) > 0 {
		last_used_range := network_range6(sorted_used[len(sorted_used) - 1])
		last_used_end := last_used_range.end
		last_used_end_u128 := addr6_to_u128(last_used_end)
		parent_last_u128 := addr6_to_u128(parent_last)

		if parent_last_u128 > last_used_end_u128 {
			gap_start := u128_to_addr6(last_used_end_u128 + 1)
			gap_size := parent_last_u128 - last_used_end_u128

			if gap_size > largest_size {
				largest_size = gap_size
				prefix := _calculate_prefix_for_size6(gap_size)
				largest = IP6_Network{gap_start, prefix}
				found = true
			}
		}
	}

	return largest, found
}

// subnet_utilization4 calculates the percentage of the parent network that is
// used by the given networks. Returns a value between 0.0 (empty) and 1.0 (full).
subnet_utilization4 :: proc(parent: IP4_Network, used: []IP4_Network) -> f64 {
	if len(used) == 0 {
		return 0.0
	}

	// Calculate total parent size
	parent_size := u64(1) << (32 - parent.prefix_len)

	// Calculate total used size (accounting for overlaps)
	used_addresses := make(map[u32]bool, allocator = context.temp_allocator)
	defer delete(used_addresses)

	for network in used {
		// Only count addresses within the parent
		if !overlaps4(parent, network) {
			continue
		}

		net_range := network_range4(network)
		current := addr4_to_u32(net_range.start)
		end := addr4_to_u32(net_range.end)

		parent_first_u32 := addr4_to_u32(parent.address)
		parent_last_u32 := parent_first_u32 + u32(parent_size) - 1

		// Clamp to parent range
		if current < parent_first_u32 {
			current = parent_first_u32
		}
		if end > parent_last_u32 {
			end = parent_last_u32
		}

		// Mark all addresses as used
		for addr := current; addr <= end; addr += 1 {
			used_addresses[addr] = true
		}
	}

	used_count := f64(len(used_addresses))
	total_count := f64(parent_size)

	return used_count / total_count
}

subnet_utilization6 :: proc(parent: IP6_Network, used: []IP6_Network) -> f64 {
	if len(used) == 0 {
		return 0.0
	}

	// For large IPv6 networks, we can't enumerate all addresses
	// Instead, calculate based on network sizes
	parent_size := u128(1) << (128 - parent.prefix_len)

	used_size := u128(0)
	for network in used {
		if overlaps6(parent, network) {
			network_size := u128(1) << (128 - network.prefix_len)
			used_size += network_size
		}
	}

	// This is an approximation that doesn't account for overlaps
	// For accurate calculation with overlaps, would need more complex logic
	if used_size > parent_size {
		return 1.0
	}

	return f64(used_size) / f64(parent_size)
}


// Helper function to calculate the largest prefix that fits in a given size
@(private)
_calculate_prefix_for_size4 :: proc(size: u32) -> u8 {
	if size == 0 {
		return 32
	}

	// Find the highest bit set
	bits := 32 - intrinsics.count_leading_zeros(size)

	// The prefix length is 32 - bits
	prefix := u8(32 - bits)

	// But we need to ensure the size is a power of 2
	// If not, use one bit more specific
	if size & (size - 1) != 0 {
		prefix += 1
	}

	return max(prefix, 0)
}

@(private)
_calculate_prefix_for_size6 :: proc(size: u128) -> u8 {
	if size == 0 {
		return 128
	}

	bits := 128 - intrinsics.count_leading_zeros(size)
	prefix := u8(128 - bits)

	if size & (size - 1) != 0 {
		prefix += 1
	}

	return max(prefix, 0)
}
