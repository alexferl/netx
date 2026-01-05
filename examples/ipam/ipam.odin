package main

import "core:fmt"
import "core:net"
import netx "../.."

main :: proc() {
	// ========================================================================
	// CIDR AGGREGATION
	// ========================================================================

	fmt.println("--- CIDR Aggregation ---")

	// Two adjacent /25 networks merge into /24
	networks := []netx.IP4_Network{
		netx.must_parse_cidr4("192.168.1.0/25"),
		netx.must_parse_cidr4("192.168.1.128/25"),
	}

	fmt.println("Before aggregation:")
	for net in networks {
		fmt.printf("  %s\n", netx.network_to_string4(net))
	}

	aggregated := netx.aggregate_networks4(networks, context.temp_allocator)
	fmt.println("After aggregation:")
	for net in aggregated {
		fmt.printf("  %s\n", netx.network_to_string4(net))
	}

	// Four /26 networks merge into /24
	fmt.println("\nMultiple network aggregation:")
	many_networks := []netx.IP4_Network{
		netx.must_parse_cidr4("10.0.0.0/26"),
		netx.must_parse_cidr4("10.0.0.64/26"),
		netx.must_parse_cidr4("10.0.0.128/26"),
		netx.must_parse_cidr4("10.0.0.192/26"),
	}

	fmt.println("Before:")
	for net in many_networks {
		fmt.printf("  %s\n", netx.network_to_string4(net))
	}

	aggregated_many := netx.aggregate_networks4(many_networks, context.temp_allocator)
	fmt.println("After:")
	for net in aggregated_many {
		fmt.printf("  %s\n", netx.network_to_string4(net))
	}

	// ========================================================================
	// RANGE TO CIDR CONVERSION
	// ========================================================================

	fmt.println("\n--- Range to CIDR Conversion ---")

	start := net.IP4_Address{ 192, 168, 1, 10 }
	end := net.IP4_Address{ 192, 168, 1, 50 }

	fmt.printf("Converting range %s - %s to CIDRs:\n",
	netx.addr_to_string4(start), netx.addr_to_string4(end))

	cidrs := netx.range_to_cidrs4(start, end, context.temp_allocator)
	for cidr in cidrs {
		first, last := netx.network_range4(cidr)
		fmt.printf("  %s (%s - %s)\n",
		netx.network_to_string4(cidr),
		netx.addr_to_string4(first),
		netx.addr_to_string4(last))
	}

	// ========================================================================
	// ADDRESS POOL ALLOCATION
	// ========================================================================

	fmt.println("\n--- Address Pool Allocation ---")

	pool_network := netx.must_parse_cidr4("10.0.1.0/29")  // Small pool: 6 usable IPs
	fmt.printf("Creating pool from %s\n", netx.network_to_string4(pool_network))

	pool := netx.pool4_init(pool_network)
	defer netx.pool4_destroy(&pool)

	fmt.printf("Available IPs: %d\n", netx.pool4_available(&pool))

	// Allocate some addresses
	fmt.println("\nAllocating addresses:")
	allocated_ips: [dynamic]net.IP4_Address
	defer delete(allocated_ips)

	for _ in 0 ..< 4 {
		ip, ok := netx.pool4_allocate(&pool)
		if ok {
			fmt.printf("  Allocated: %s\n", netx.addr_to_string4(ip))
			append(&allocated_ips, ip)
		} else {
			fmt.println("  Failed to allocate")
		}
	}

	fmt.printf("\nRemaining available: %d\n", netx.pool4_available(&pool))

	// Free one address
	if len(allocated_ips) > 0 {
		freed_ip := allocated_ips[1]
		fmt.printf("\nFreeing %s\n", netx.addr_to_string4(freed_ip))
		netx.pool4_free(&pool, freed_ip)
		fmt.printf("Available after free: %d\n", netx.pool4_available(&pool))

		// Allocate again - should get the freed address
		new_ip, ok := netx.pool4_allocate(&pool)
		if ok {
			fmt.printf("Re-allocated: %s\n", netx.addr_to_string4(new_ip))
		}
	}

	// Check allocation status
	fmt.println("\nAllocation status:")
	for ip in allocated_ips {
		is_allocated := netx.pool4_is_allocated(&pool, ip)
		fmt.printf("  %s: %s\n",
		netx.addr_to_string4(ip),
		is_allocated ? "allocated" : "free")
	}

	// ========================================================================
	// IPv6 POOL
	// ========================================================================

	fmt.println("\n--- IPv6 Pool Allocation ---")

	pool6_network := netx.must_parse_cidr6("2001:db8::/126")  // Small pool
	fmt.printf("Creating IPv6 pool from %s\n", netx.network_to_string6(pool6_network))

	pool6 := netx.pool6_init(pool6_network)
	defer netx.pool6_destroy(&pool6)

	fmt.println("\nAllocating IPv6 addresses:")
	for _ in 0 ..< 3 {
		ip6, ok := netx.pool6_allocate(&pool6)
		if ok {
			fmt.printf("  Allocated: %s\n", netx.addr_to_string6(ip6))
		}
	}

	// ========================================================================
	// SUPERNET CALCULATION
	// ========================================================================

	fmt.println("\n--- Supernet Calculation ---")

	net_a := netx.must_parse_cidr4("192.168.0.0/24")
	net_b := netx.must_parse_cidr4("192.168.1.0/24")

	fmt.printf("Finding supernet of %s and %s\n",
	netx.network_to_string4(net_a),
	netx.network_to_string4(net_b))

	super := netx.supernet4(net_a, net_b)
	fmt.printf("Supernet: %s\n", netx.network_to_string4(super))

	// Distant networks
	fmt.println("\nDistant network supernet:")
	distant_a := netx.must_parse_cidr4("10.0.0.0/24")
	distant_b := netx.must_parse_cidr4("172.16.0.0/24")

	fmt.printf("Finding supernet of %s and %s\n",
	netx.network_to_string4(distant_a),
	netx.network_to_string4(distant_b))

	distant_super := netx.supernet4(distant_a, distant_b)
	fmt.printf("Supernet: %s (encompasses both networks)\n", netx.network_to_string4(distant_super))

	// IPv6 supernet
	fmt.println("\n--- IPv6 Supernet ---")
	net6_a := netx.must_parse_cidr6("2001:db8::/64")
	net6_b := netx.must_parse_cidr6("2001:db8:0:1::/64")

	fmt.printf("Finding supernet of %s and %s\n",
	netx.network_to_string6(net6_a),
	netx.network_to_string6(net6_b))

	super6 := netx.supernet6(net6_a, net6_b)
	fmt.printf("Supernet: %s\n", netx.network_to_string6(super6))

	// ========================================================================
	// NETWORK EXCLUSION
	// ========================================================================

	fmt.println("\n--- Network Exclusion ---")

	from := netx.must_parse_cidr4("192.168.1.0/24")
	exclude := netx.must_parse_cidr4("192.168.1.128/25")

	fmt.printf("Excluding %s from %s\n",
	netx.network_to_string4(exclude),
	netx.network_to_string4(from))

	remaining := netx.exclude4(from, exclude, context.temp_allocator)
	fmt.println("Remaining networks:")
	for net in remaining {
		first, last := netx.network_range4(net)
		fmt.printf("  %s (%s - %s)\n",
		netx.network_to_string4(net),
		netx.addr_to_string4(first),
		netx.addr_to_string4(last))
	}

	// Exclude a smaller subnet
	fmt.println("\nExcluding smaller subnet:")
	from2 := netx.must_parse_cidr4("10.0.0.0/24")
	exclude2 := netx.must_parse_cidr4("10.0.0.64/26")

	fmt.printf("Excluding %s from %s\n",
	netx.network_to_string4(exclude2),
	netx.network_to_string4(from2))

	remaining2 := netx.exclude4(from2, exclude2, context.temp_allocator)
	fmt.println("Remaining networks:")
	for net in remaining2 {
		fmt.printf("  %s\n", netx.network_to_string4(net))
	}

	// No overlap - should return original
	fmt.println("\nExcluding non-overlapping network:")
	from3 := netx.must_parse_cidr4("192.168.1.0/24")
	exclude3 := netx.must_parse_cidr4("10.0.0.0/24")

	fmt.printf("Excluding %s from %s\n",
	netx.network_to_string4(exclude3),
	netx.network_to_string4(from3))

	remaining3 := netx.exclude4(from3, exclude3, context.temp_allocator)
	fmt.println("Remaining networks:")
	for net in remaining3 {
		fmt.printf("  %s\n", netx.network_to_string4(net))
	}

	// IPv6 exclusion
	fmt.println("\n--- IPv6 Network Exclusion ---")
	from6 := netx.must_parse_cidr6("2001:db8::/64")
	exclude6 := netx.must_parse_cidr6("2001:db8::/65")

	fmt.printf("Excluding %s from %s\n",
	netx.network_to_string6(exclude6),
	netx.network_to_string6(from6))

	remaining6 := netx.exclude6(from6, exclude6, context.temp_allocator)
	fmt.println("Remaining networks:")
	for net in remaining6 {
		fmt.printf("  %s\n", netx.network_to_string6(net))
	}

	// ========================================================================
	// ADDRESS CONVERSION UTILITIES
	// ========================================================================

	fmt.println("\n--- Address Conversion ---")

	addr := net.IP4_Address{ 192, 168, 1, 100 }
	fmt.printf("Address: %s\n", netx.addr_to_string4(addr))

	addr_u32 := netx.addr4_to_u32(addr)
	fmt.printf("As u32: %d (0x%08X)\n", addr_u32, addr_u32)

	back_to_addr := netx.u32_to_addr4(addr_u32)
	fmt.printf("Back to address: %s\n", netx.addr_to_string4(back_to_addr))

	// IPv6 conversion
	fmt.println("\nIPv6 address conversion:")
	addr6 := netx.ipv6_loopback()
	fmt.printf("Address: %s\n", netx.addr_to_string6(addr6))

	addr6_u128 := netx.addr6_to_u128(addr6)
	fmt.printf("As u128: %d\n", addr6_u128)

	back_to_addr6 := netx.u128_to_addr6(addr6_u128)
	fmt.printf("Back to address: %s\n", netx.addr_to_string6(back_to_addr6))
	// ========================================================================
	// FINDING FREE SUBNETS
	// ========================================================================

	fmt.println("\n--- Finding Free Subnets ---")

	// Parent network with some used subnets
	parent := netx.must_parse_cidr4("10.0.0.0/16")
	used_subnets := []netx.IP4_Network{
		netx.must_parse_cidr4("10.0.1.0/24"),
		netx.must_parse_cidr4("10.0.3.0/24"),
		netx.must_parse_cidr4("10.0.5.0/24"),
	}

	fmt.printf("Parent network: %s\n", netx.network_to_string4(parent))
	fmt.println("Used subnets:")
	for subnet in used_subnets {
		fmt.printf("  %s\n", netx.network_to_string4(subnet))
	}

	// Find all available /24 subnets
	free_24s := netx.find_free_subnets4(parent, used_subnets, 24, context.temp_allocator)
	fmt.printf("\nFound %d free /24 subnets (showing first 10):\n", len(free_24s))
	for subnet, i in free_24s {
		if i >= 10 {
			break
		}
		fmt.printf("  %s\n", netx.network_to_string4(subnet))
	}

	// Find available /23 subnets
	free_23s := netx.find_free_subnets4(parent, used_subnets, 23, context.temp_allocator)
	fmt.printf("\nFound %d free /23 subnets (showing first 5):\n", len(free_23s))
	for subnet, i in free_23s {
		if i >= 5 {
			break
		}
		fmt.printf("  %s\n", netx.network_to_string4(subnet))
	}

	// ========================================================================
	// LARGEST FREE BLOCK
	// ========================================================================

	fmt.println("\n--- Finding Largest Free Block ---")

	// Network with several allocated subnets
	datacenter := netx.must_parse_cidr4("172.16.0.0/16")
	allocated := []netx.IP4_Network{
		netx.must_parse_cidr4("172.16.0.0/20"), // 4096 IPs
		netx.must_parse_cidr4("172.16.32.0/20"), // 4096 IPs
		netx.must_parse_cidr4("172.16.64.0/18"),  // 16384 IPs
	}

	fmt.printf("Datacenter network: %s\n", netx.network_to_string4(datacenter))
	fmt.println("Allocated subnets:")
	for subnet in allocated {
		first, last := netx.network_range4(subnet)
		fmt.printf("  %s (%d hosts: %s - %s)\n",
		netx.network_to_string4(subnet),
		netx.host_count4(subnet),
		netx.addr_to_string4(first),
		netx.addr_to_string4(last))
	}

	largest, ok := netx.largest_free_block4(datacenter, allocated, context.temp_allocator)
	if ok {
		fmt.printf("\nLargest free block: %s (%d hosts)\n",
		netx.network_to_string4(largest),
		netx.host_count4(largest))
	}

	// Scenario with highly fragmented space
	fmt.println("\n--- Fragmented Network Space ---")
	fragmented_parent := netx.must_parse_cidr4("192.168.0.0/22")
	fragmented_used := []netx.IP4_Network{
		netx.must_parse_cidr4("192.168.0.0/26"),
		netx.must_parse_cidr4("192.168.0.128/25"),
		netx.must_parse_cidr4("192.168.1.0/26"),
		netx.must_parse_cidr4("192.168.2.64/26"),
	}

	fmt.printf("Parent: %s\n", netx.network_to_string4(fragmented_parent))
	fmt.println("Used (fragmented):")
	for subnet in fragmented_used {
		fmt.printf("  %s\n", netx.network_to_string4(subnet))
	}

	largest_frag, ok_frag := netx.largest_free_block4(fragmented_parent, fragmented_used, context.temp_allocator)
	if ok_frag {
		fmt.printf("\nLargest contiguous free block: %s\n",
		netx.network_to_string4(largest_frag))
	}

	// ========================================================================
	// SUBNET UTILIZATION
	// ========================================================================

	fmt.println("\n--- Subnet Utilization Analysis ---")

	// Calculate utilization of the datacenter network
	util := netx.subnet_utilization4(datacenter, allocated)
	fmt.printf("Datacenter %s utilization: %.1f%%\n",
	netx.network_to_string4(datacenter),
	util * 100)

	// Calculate utilization of fragmented network
	util_frag := netx.subnet_utilization4(fragmented_parent, fragmented_used)
	fmt.printf("Fragmented %s utilization: %.1f%%\n",
	netx.network_to_string4(fragmented_parent),
	util_frag * 100)

	// Empty network
	empty_network := netx.must_parse_cidr4("10.1.0.0/24")
	util_empty := netx.subnet_utilization4(empty_network, []netx.IP4_Network{ })
	fmt.printf("Empty %s utilization: %.1f%%\n",
	netx.network_to_string4(empty_network),
	util_empty * 100)

	// Full network
	util_full := netx.subnet_utilization4(empty_network, []netx.IP4_Network{ empty_network })
	fmt.printf("Full %s utilization: %.1f%%\n",
	netx.network_to_string4(empty_network),
	util_full * 100)

	// ========================================================================
	// IPv6 SUBNET UTILITIES
	// ========================================================================

	fmt.println("\n--- IPv6 Subnet Utilities ---")

	parent6 := netx.must_parse_cidr6("2001:db8::/32")
	used6 := []netx.IP6_Network{
		netx.must_parse_cidr6("2001:db8:1::/48"),
		netx.must_parse_cidr6("2001:db8:3::/48"),
	}

	fmt.printf("Parent: %s\n", netx.network_to_string6(parent6))
	fmt.println("Used subnets:")
	for subnet in used6 {
		fmt.printf("  %s\n", netx.network_to_string6(subnet))
	}

	// Find free /48 subnets (limited search)
	free6_48s := netx.find_free_subnets6(parent6, used6, 48, context.temp_allocator)
	fmt.printf("\nFound %d free /48 subnets (showing first 5):\n", len(free6_48s))
	for subnet, i in free6_48s {
		if i >= 5 {
			break
		}
		fmt.printf("  %s\n", netx.network_to_string6(subnet))
	}

	// Largest free block
	largest6, ok6 := netx.largest_free_block6(parent6, used6, context.temp_allocator)
	if ok6 {
		fmt.printf("\nLargest free IPv6 block: %s\n",
		netx.network_to_string6(largest6))
	}

	// Utilization
	util6 := netx.subnet_utilization6(parent6, used6)
	fmt.printf("IPv6 network utilization: %.6f%%\n", util6 * 100)

	// ========================================================================
	// PRACTICAL IPAM WORKFLOW
	// ========================================================================

	fmt.println("\n--- Practical IPAM Workflow ---")
	fmt.println("Scenario: Allocating networks for new departments")

	// Corporate network
	corporate := netx.must_parse_cidr4("10.0.0.0/8")
	existing_allocations := []netx.IP4_Network{
		netx.must_parse_cidr4("10.0.0.0/16"), // IT department
		netx.must_parse_cidr4("10.1.0.0/16"), // Sales department
		netx.must_parse_cidr4("10.2.0.0/16"),   // Engineering
	}

	fmt.printf("Corporate network: %s\n", netx.network_to_string4(corporate))
	fmt.println("Existing allocations:")
	for dept, i in existing_allocations {
		dept_names := []string{ "IT", "Sales", "Engineering" }
		fmt.printf("  %s: %s\n", dept_names[i], netx.network_to_string4(dept))
	}

	// Check utilization before new allocation
	current_util := netx.subnet_utilization4(corporate, existing_allocations)
	fmt.printf("\nCurrent utilization: %.4f%%\n", current_util * 100)

	// Find space for new Marketing department (/16)
	fmt.println("\nFinding space for Marketing department (/16):")
	free_16s := netx.find_free_subnets4(corporate, existing_allocations, 16, context.temp_allocator)
	if len(free_16s) > 0 {
		marketing := free_16s[0]
		fmt.printf("Allocated to Marketing: %s\n", netx.network_to_string4(marketing))

		// Calculate new utilization
		new_allocations := make([dynamic]netx.IP4_Network, context.temp_allocator)
		append(&new_allocations, ..existing_allocations[:])
		append(&new_allocations, marketing)

		new_util := netx.subnet_utilization4(corporate, new_allocations[:])
		fmt.printf("New utilization: %.4f%%\n", new_util * 100)

		// Show remaining largest block
		largest_after, ok_after := netx.largest_free_block4(corporate, new_allocations[:], context.temp_allocator)
		if ok_after {
			fmt.printf("Largest remaining block: %s (%d hosts)\n",
			netx.network_to_string4(largest_after),
			netx.host_count4(largest_after))
		}
	}
}
