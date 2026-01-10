package main

import "core:fmt"
import "core:net"
import netx "../.."

main :: proc() {
	// ========================================================================
	// IPv4 REVERSE DNS PTR RECORDS
	// ========================================================================

	fmt.println("--- IPv4 PTR Record Generation ---")

	// Individual address PTR
	addr1 := net.IP4_Address{192, 168, 1, 100}
	ptr1 := netx.addr4_to_ptr(addr1, context.temp_allocator)
	fmt.printf("%s -> %s\n", netx.addr_to_string4(addr1), ptr1)

	// Loopback
	loopback := net.IP4_Address{127, 0, 0, 1}
	ptr_loopback := netx.addr4_to_ptr(loopback, context.temp_allocator)
	fmt.printf("%s -> %s\n", netx.addr_to_string4(loopback), ptr_loopback)

	// Google DNS
	google_dns := net.IP4_Address{8, 8, 8, 8}
	ptr_google := netx.addr4_to_ptr(google_dns, context.temp_allocator)
	fmt.printf("%s -> %s\n", netx.addr_to_string4(google_dns), ptr_google)

	// ========================================================================
	// IPv4 NETWORK ZONE DELEGATION
	// ========================================================================

	fmt.println("\n--- IPv4 Network Zone Delegation ---")

	// /24 network (standard delegation)
	net24 := netx.must_parse_cidr4("192.168.1.0/24")
	zone24 := netx.network4_to_ptr(net24, context.temp_allocator)
	fmt.printf("%s -> Zone: %s\n", netx.network_to_string4(net24), zone24)

	// /16 network
	net16 := netx.must_parse_cidr4("10.0.0.0/16")
	zone16 := netx.network4_to_ptr(net16, context.temp_allocator)
	fmt.printf("%s -> Zone: %s\n", netx.network_to_string4(net16), zone16)

	// /8 network
	net8 := netx.must_parse_cidr4("172.0.0.0/8")
	zone8 := netx.network4_to_ptr(net8, context.temp_allocator)
	fmt.printf("%s -> Zone: %s\n", netx.network_to_string4(net8), zone8)

	// ========================================================================
	// IPv4 CLASSLESS DELEGATION (RFC 2317)
	// ========================================================================

	fmt.println("\n--- IPv4 Classless Delegation (RFC 2317) ---")
	fmt.println("For subnets smaller than /24:")

	// /26 network
	net26 := netx.must_parse_cidr4("192.168.1.64/26")
	zone26 := netx.network4_to_classless_ptr(net26, context.temp_allocator)
	fmt.printf("%s -> %s\n", netx.network_to_string4(net26), zone26)

	// /27 network
	net27 := netx.must_parse_cidr4("10.0.0.32/27")
	zone27 := netx.network4_to_classless_ptr(net27, context.temp_allocator)
	fmt.printf("%s -> %s\n", netx.network_to_string4(net27), zone27)

	// /30 network (point-to-point link)
	net30 := netx.must_parse_cidr4("192.168.1.4/30")
	zone30 := netx.network4_to_classless_ptr(net30, context.temp_allocator)
	fmt.printf("%s -> %s\n", netx.network_to_string4(net30), zone30)

	// ========================================================================
	// IPv4 PTR PARSING (REVERSE OPERATION)
	// ========================================================================

	fmt.println("\n--- IPv4 PTR Parsing ---")

	// Parse PTR back to address
	ptr_record := "100.1.168.192.in-addr.arpa"
	recovered_addr, ok := netx.ptr_to_addr4(ptr_record)
	if ok {
		fmt.printf("%s -> %s\n", ptr_record, netx.addr_to_string4(recovered_addr))
	}

	// Roundtrip test
	fmt.println("\nRoundtrip test:")
	original := net.IP4_Address{203, 0, 113, 42}
	fmt.printf("Original:  %s\n", netx.addr_to_string4(original))
	addr4_ptr := netx.addr4_to_ptr(original, context.temp_allocator)
	fmt.printf("PTR:       %s\n", addr4_ptr)
	recovered, ok2 := netx.ptr_to_addr4(addr4_ptr)
	if ok2 {
		fmt.printf("Recovered: %s\n", netx.addr_to_string4(recovered))
		fmt.printf("Match:     %v\n", original == recovered)
	}

	// ========================================================================
	// IPv4 PTR VALIDATION
	// ========================================================================

	fmt.println("\n--- IPv4 PTR Validation ---")

	valid_ptrs := []string{
		"100.1.168.192.in-addr.arpa",
		"1.0.0.127.in-addr.arpa",
		"8.8.8.8.in-addr.arpa",
	}

	invalid_ptrs := []string{
		"100.1.168.192",  // Missing suffix
		"1.168.192.in-addr.arpa",  // Too few octets
		"256.1.168.192.in-addr.arpa",  // Invalid octet
		"abc.1.168.192.in-addr.arpa",  // Non-numeric
	}

	fmt.println("Valid PTR records:")
	for ptr in valid_ptrs {
		fmt.printf("  %s: %v\n", ptr, netx.is_valid_ptr4(ptr))
	}

	fmt.println("\nInvalid PTR records:")
	for ptr in invalid_ptrs {
		fmt.printf("  %s: %v\n", ptr, netx.is_valid_ptr4(ptr))
	}

	// ========================================================================
	// IPv6 REVERSE DNS PTR RECORDS
	// ========================================================================

	fmt.println("\n\n=== IPv6 PTR Records ===\n")

	fmt.println("--- IPv6 PTR Record Generation ---")

	// Loopback ::1
	addr6_loopback := netx.ipv6_loopback()
	ptr6_loopback := netx.addr6_to_ptr(addr6_loopback, context.temp_allocator)
	fmt.printf("%s ->\n  %s\n", netx.addr_to_string6(addr6_loopback), ptr6_loopback)

	// Link-local address
	segments_ll: [8]u16be
	segments_ll[0] = 0xFE80
	segments_ll[7] = 0x0001
	addr6_ll := cast(net.IP6_Address)segments_ll
	ptr6_ll := netx.addr6_to_ptr(addr6_ll, context.temp_allocator)
	fmt.printf("\n%s ->\n  %s\n", netx.addr_to_string6(addr6_ll), ptr6_ll)

	// Documentation prefix address
	segments_doc: [8]u16be
	segments_doc[0] = 0x2001
	segments_doc[1] = 0x0DB8
	segments_doc[7] = 0x0001
	addr6_doc := cast(net.IP6_Address)segments_doc
	ptr6_doc := netx.addr6_to_ptr(addr6_doc, context.temp_allocator)
	fmt.printf("\n%s ->\n  %s\n", netx.addr_to_string6(addr6_doc), ptr6_doc)

	// ========================================================================
	// IPv6 NETWORK ZONE DELEGATION
	// ========================================================================

	fmt.println("\n--- IPv6 Network Zone Delegation ---")
	fmt.println("Delegation on nibble boundaries (multiples of 4):")

	// /32 network
	net6_32 := netx.must_parse_cidr6("2001:db8::/32")
	zone6_32 := netx.network6_to_ptr(net6_32, context.temp_allocator)
	fmt.printf("\n%s ->\n  %s\n", netx.network_to_string6(net6_32), zone6_32)

	// /48 network
	net6_48 := netx.must_parse_cidr6("2001:db8::/48")
	zone6_48 := netx.network6_to_ptr(net6_48, context.temp_allocator)
	fmt.printf("\n%s ->\n  %s\n", netx.network_to_string6(net6_48), zone6_48)

	// /64 network (typical assignment)
	net6_64 := netx.must_parse_cidr6("2001:db8::/64")
	zone6_64 := netx.network6_to_ptr(net6_64, context.temp_allocator)
	fmt.printf("\n%s ->\n  %s\n", netx.network_to_string6(net6_64), zone6_64)

	// /56 network (common for end users)
	net6_56 := netx.must_parse_cidr6("2001:db8:ab00::/56")
	zone6_56 := netx.network6_to_ptr(net6_56, context.temp_allocator)
	fmt.printf("\n%s ->\n  %s\n", netx.network_to_string6(net6_56), zone6_56)

	// ========================================================================
	// IPv6 PTR PARSING (REVERSE OPERATION)
	// ========================================================================

	fmt.println("\n--- IPv6 PTR Parsing ---")

	// Parse PTR back to address
	ptr6_record := "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa"
	recovered_addr6, ok6 := netx.ptr_to_addr6(ptr6_record)
	if ok6 {
		fmt.printf("PTR: %s\nAddress: %s\n", ptr6_record, netx.addr_to_string6(recovered_addr6))
	}

	// Roundtrip test
	fmt.println("\nIPv6 Roundtrip test:")
	original6 := addr6_doc
	fmt.printf("Original:  %s\n", netx.addr_to_string6(original6))
	ptr6 := netx.addr6_to_ptr(original6, context.temp_allocator)
	fmt.printf("PTR:       %s\n", ptr6)
	recovered6, ok6_2 := netx.ptr_to_addr6(ptr6)
	if ok6_2 {
		fmt.printf("Recovered: %s\n", netx.addr_to_string6(recovered6))
		fmt.printf("Match:     %v\n", original6 == recovered6)
	}

	// ========================================================================
	// IPv6 PTR VALIDATION
	// ========================================================================

	fmt.println("\n--- IPv6 PTR Validation ---")

	valid_ptr6 := "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa"
	invalid_ptr6_short := "1.0.0.0.ip6.arpa"
	invalid_ptr6_suffix := "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.in-addr.arpa"

	fmt.printf("Valid (32 nibbles):   %v\n", netx.is_valid_ptr6(valid_ptr6))
	fmt.printf("Invalid (too short):  %v\n", netx.is_valid_ptr6(invalid_ptr6_short))
	fmt.printf("Invalid (wrong suffix): %v\n", netx.is_valid_ptr6(invalid_ptr6_suffix))

	// ========================================================================
	// PRACTICAL USE CASES
	// ========================================================================

	// ========================================================================
	// PRACTICAL USE CASES
	// ========================================================================

	fmt.println("\n\n=== Practical Use Cases ===\n")

	fmt.println("--- Generating PTR records for a subnet ---")
	subnet := netx.must_parse_cidr4("192.168.1.0/29")
	fmt.printf("Subnet: %s\n", netx.network_to_string4(subnet))
	fmt.printf("Zone: %s\n\n", netx.network4_to_classless_ptr(subnet, context.temp_allocator))

	range, ok_range := netx.usable_host_range4(subnet)
	if ok_range {
		fmt.println("PTR records for usable hosts:")
		current := range.start
		for {
			netx.addr4_to_ptr(current, context.temp_allocator)
			fmt.printf("  %-15s  IN PTR  host-%d-%d-%d-%d.example.com.\n",
			netx.addr_to_string4(current),
			current[0], current[1], current[2], current[3])

			if current == range.end {
				break
			}
			next, ok_next := netx.next_ip4(current)
			if !ok_next {
				break
			}
			current = next
		}
	}

	fmt.println("\n--- IPv6 /64 delegation zone ---")
	ipv6_subnet := netx.must_parse_cidr6("2001:db8:cafe::/64")
	fmt.printf("Subnet: %s\n", netx.network_to_string6(ipv6_subnet))
	fmt.printf("Delegation zone: %s\n", netx.network6_to_ptr(ipv6_subnet, context.temp_allocator))
}
