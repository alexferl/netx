package netx

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

	_, a_last := network_range4(a)
	b_first := b.address

	next_addr, ok := next_ip4(a_last)
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

can_merge6 :: proc(a, b: IP6_Network) -> bool {
	if a.prefix_len != b.prefix_len {
		return false
	}
	if a.prefix_len == 0 {
		return false
	}

	_, a_last := network_range6(a)
	b_first := b.address

	next_addr, ok := next_ip6(a_last)
	if !ok {
		return false
	}

	return next_addr == b_first
}

merge6 :: proc(a, b: IP6_Network) -> IP6_Network {
	return IP6_Network{
		address = a.address,
		prefix_len = a.prefix_len - 1,
	}
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
			_, last := network_range4(network)

			if compare_addr4(last, end) <= 0 {
				best_prefix = prefix
				break
			}
		}

		network := network_from4(current, best_prefix)
		append(&result, network)

		_, last := network_range4(network)
		next, ok := next_ip4(last)
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
			_, last := network_range6(network)

			if compare_addr6(last, end) <= 0 {
				best_prefix = prefix
				break
			}
		}

		network := network_from6(current, best_prefix)
		append(&result, network)

		_, last := network_range6(network)
		next, ok := next_ip6(last)
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

	first, _, ok := usable_host_range4(network)
	if ok {
		pool.next_candidate = first
	} else {
		pool.next_candidate = network.address
	}

	return pool
}

pool4_destroy :: proc(pool: ^IP4_Pool) {
	delete(pool.allocated)
}

pool4_allocate :: proc(pool: ^IP4_Pool) -> (addr: net.IP4_Address, ok: bool) {
	first, last, range_ok := usable_host_range4(pool.network)
	if !range_ok {
		return {}, false
	}

	start := pool.next_candidate
	current := start

	for {
		if current not_in pool.allocated && contains4(pool.network, current) {
			if compare_addr4(current, first) >= 0 && compare_addr4(current, last) <= 0 {
				pool.allocated[current] = true
				next, next_ok := next_ip4(current)
				if next_ok && compare_addr4(next, last) <= 0 {
					pool.next_candidate = next
				} else {
					pool.next_candidate = first
				}
				return current, true
			}
		}

		next, next_ok := next_ip4(current)
		if !next_ok || compare_addr4(next, last) > 0 {
			current = first
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
	first, last := network_range6(pool.network)

	start := pool.next_candidate
	current := start

	for {
		if current not_in pool.allocated && contains6(pool.network, current) {
			if !is_unspecified6(current) {
				pool.allocated[current] = true
				next, next_ok := next_ip6(current)
				if next_ok && compare_addr6(next, last) <= 0 {
					pool.next_candidate = next
				} else {
					pool.next_candidate = first
				}
				return current, true
			}
		}

		next, next_ok := next_ip6(current)
		if !next_ok || compare_addr6(next, last) > 0 {
			next, _ = next_ip6(first)
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
