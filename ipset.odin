package netx

import "core:mem"
import "core:net"

// ============================================================================
// IP SET - Efficient IP prefix lookups using radix tree
// ============================================================================

// IP4_Set stores IPv4 networks in a prefix tree for efficient lookups
IP4_Set :: struct {
	root: ^IP4_Set_Node,
	allocator: mem.Allocator,
}

IP4_Set_Node :: struct {
	network: IP4_Network,
	is_end:  bool,  // True if this node represents a complete network
	left:    ^IP4_Set_Node,  // 0 bit
	right:   ^IP4_Set_Node,  // 1 bit
}

// IP6_Set stores IPv6 networks in a prefix tree for efficient lookups
IP6_Set :: struct {
	root: ^IP6_Set_Node,
	allocator: mem.Allocator,
}

IP6_Set_Node :: struct {
	network: IP6_Network,
	is_end:  bool,
	left:    ^IP6_Set_Node,
	right:   ^IP6_Set_Node,
}

// Initialize an IPv4 set
set_init4 :: proc(allocator := context.allocator) -> IP4_Set {
	return IP4_Set{allocator = allocator}
}

// Initialize an IPv6 set
set_init6 :: proc(allocator := context.allocator) -> IP6_Set {
	return IP6_Set{allocator = allocator}
}

// Destroy an IPv4 set and free all nodes
set_destroy4 :: proc(set: ^IP4_Set) {
	_destroy_node4(set.root, set.allocator)
	set.root = nil
}

// Destroy an IPv6 set and free all nodes
set_destroy6 :: proc(set: ^IP6_Set) {
	_destroy_node6(set.root, set.allocator)
	set.root = nil
}

@(private)
_destroy_node4 :: proc(node: ^IP4_Set_Node, allocator: mem.Allocator) {
	if node == nil {
		return
	}
	_destroy_node4(node.left, allocator)
	_destroy_node4(node.right, allocator)
	free(node, allocator)
}

@(private)
_destroy_node6 :: proc(node: ^IP6_Set_Node, allocator: mem.Allocator) {
	if node == nil {
		return
	}
	_destroy_node6(node.left, allocator)
	_destroy_node6(node.right, allocator)
	free(node, allocator)
}

// Insert a network into the IPv4 set
set_insert4 :: proc(set: ^IP4_Set, network: IP4_Network) {
	if set.root == nil {
		set.root = new(IP4_Set_Node, set.allocator)
		set.root.network = network
		set.root.is_end = (network.prefix_len == 0)
		if network.prefix_len == 0 {
			return
		}
	}

	// Convert network address to u32 for bit operations
	addr_u32 := addr4_to_u32(network.address)

	current := set.root
	for bit := u8(0); bit < network.prefix_len; bit += 1 {
		// Check bit at position (31 - bit) from MSB
		bit_value := (addr_u32 >> (31 - bit)) & 1

		if bit_value == 0 {
			if current.left == nil {
				current.left = new(IP4_Set_Node, set.allocator)
			}
			current = current.left
		} else {
			if current.right == nil {
				current.right = new(IP4_Set_Node, set.allocator)
			}
			current = current.right
		}
	}

	current.network = network
	current.is_end = true
}

// Insert a network into the IPv6 set
set_insert6 :: proc(set: ^IP6_Set, network: IP6_Network) {
	if set.root == nil {
		set.root = new(IP6_Set_Node, set.allocator)
		set.root.network = network
		set.root.is_end = (network.prefix_len == 0)
		if network.prefix_len == 0 {
			return
		}
	}

	// Convert network address to u128 for bit operations
	addr_u128 := addr6_to_u128(network.address)

	current := set.root
	for bit := u8(0); bit < network.prefix_len; bit += 1 {
		// Check bit at position (127 - bit) from MSB
		bit_value := (addr_u128 >> (127 - bit)) & 1

		if bit_value == 0 {
			if current.left == nil {
				current.left = new(IP6_Set_Node, set.allocator)
			}
			current = current.left
		} else {
			if current.right == nil {
				current.right = new(IP6_Set_Node, set.allocator)
			}
			current = current.right
		}
	}

	current.network = network
	current.is_end = true
}

// Check if an IPv4 address belongs to any network in the set
set_contains4 :: proc(set: ^IP4_Set, addr: net.IP4_Address) -> bool {
	if set.root == nil {
		return false
	}

	addr_u32 := addr4_to_u32(addr)
	current := set.root

	// Check if root is a /0 network (matches everything)
	if current.is_end && current.network.prefix_len == 0 {
		return true
	}

	for bit := u8(0); bit < 32; bit += 1 {
		// If current node is end of a network and address is in it, found!
		if current.is_end && contains4(current.network, addr) {
			return true
		}

		bit_value := (addr_u32 >> (31 - bit)) & 1
		if bit_value == 0 {
			if current.left == nil {
				return false
			}
			current = current.left
		} else {
			if current.right == nil {
				return false
			}
			current = current.right
		}
	}

	// Check final node
	return current.is_end && contains4(current.network, addr)
}

// Check if an IPv6 address belongs to any network in the set
set_contains6 :: proc(set: ^IP6_Set, addr: net.IP6_Address) -> bool {
	if set.root == nil {
		return false
	}

	addr_u128 := addr6_to_u128(addr)
	current := set.root

	// Check if root is a /0 network (matches everything)
	if current.is_end && current.network.prefix_len == 0 {
		return true
	}

	for bit := u8(0); bit < 128; bit += 1 {
		// If current node is end of a network and address is in it, found!
		if current.is_end && contains6(current.network, addr) {
			return true
		}

		bit_value := (addr_u128 >> (127 - bit)) & 1
		if bit_value == 0 {
			if current.left == nil {
				return false
			}
			current = current.left
		} else {
			if current.right == nil {
				return false
			}
			current = current.right
		}
	}

	// Check final node
	return current.is_end && contains6(current.network, addr)
}

// Find the longest matching network for an IPv4 address
set_longest_match4 :: proc(set: ^IP4_Set, addr: net.IP4_Address) -> (network: IP4_Network, ok: bool) {
	if set.root == nil {
		return {}, false
	}

	addr_u32 := addr4_to_u32(addr)
	current := set.root
	best_match: IP4_Network
	found := false

	// Check if root is a /0 network
	if current.is_end {
		best_match = current.network
		found = true
	}

	for bit := u8(0); bit < 32; bit += 1 {
		if current.is_end && contains4(current.network, addr) {
			best_match = current.network
			found = true
		}

		bit_value := (addr_u32 >> (31 - bit)) & 1
		if bit_value == 0 {
			if current.left == nil {
				break
			}
			current = current.left
		} else {
			if current.right == nil {
				break
			}
			current = current.right
		}
	}

	// Check final node
	if current.is_end && contains4(current.network, addr) {
		best_match = current.network
		found = true
	}

	return best_match, found
}

// Find the longest matching network for an IPv6 address
set_longest_match6 :: proc(set: ^IP6_Set, addr: net.IP6_Address) -> (network: IP6_Network, ok: bool) {
	if set.root == nil {
		return {}, false
	}

	addr_u128 := addr6_to_u128(addr)
	current := set.root
	best_match: IP6_Network
	found := false

	// Check if root is a /0 network
	if current.is_end {
		best_match = current.network
		found = true
	}

	for bit := u8(0); bit < 128; bit += 1 {
		if current.is_end && contains6(current.network, addr) {
			best_match = current.network
			found = true
		}

		bit_value := (addr_u128 >> (127 - bit)) & 1
		if bit_value == 0 {
			if current.left == nil {
				break
			}
			current = current.left
		} else {
			if current.right == nil {
				break
			}
			current = current.right
		}
	}

	// Check final node
	if current.is_end && contains6(current.network, addr) {
		best_match = current.network
		found = true
	}

	return best_match, found
}

// Remove a network from the IPv4 set
set_remove4 :: proc(set: ^IP4_Set, network: IP4_Network) -> bool {
	if set.root == nil {
		return false
	}

	addr_u32 := addr4_to_u32(network.address)
	current := set.root

	if network.prefix_len == 0 {
		if current.is_end && current.network.prefix_len == 0 {
			current.is_end = false
			return true
		}
		return false
	}

	for bit := u8(0); bit < network.prefix_len; bit += 1 {
		bit_value := (addr_u32 >> (31 - bit)) & 1
		if bit_value == 0 {
			if current.left == nil {
				return false
			}
			current = current.left
		} else {
			if current.right == nil {
				return false
			}
			current = current.right
		}
	}

	if current.is_end && current.network == network {
		current.is_end = false
		return true
	}

	return false
}

// Remove a network from the IPv6 set
set_remove6 :: proc(set: ^IP6_Set, network: IP6_Network) -> bool {
	if set.root == nil {
		return false
	}

	addr_u128 := addr6_to_u128(network.address)
	current := set.root

	if network.prefix_len == 0 {
		if current.is_end && current.network.prefix_len == 0 {
			current.is_end = false
			return true
		}
		return false
	}

	for bit := u8(0); bit < network.prefix_len; bit += 1 {
		bit_value := (addr_u128 >> (127 - bit)) & 1
		if bit_value == 0 {
			if current.left == nil {
				return false
			}
			current = current.left
		} else {
			if current.right == nil {
				return false
			}
			current = current.right
		}
	}

	if current.is_end && current.network == network {
		current.is_end = false
		return true
	}

	return false
}
