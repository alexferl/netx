package main

import "core:fmt"
import netx "../.."

main :: proc() {
	// ========================================================================
	// MAC ADDRESS PARSING
	// ========================================================================

	fmt.println("--- MAC Address Parsing ---")

	// Different formats
	mac1, ok1 := netx.parse_mac("00:1A:2B:3C:4D:5E")
	if ok1 {
		fmt.printf("Colon format: %s\n", netx.mac_to_string_colon(mac1, true))
	}

	mac2, ok2 := netx.parse_mac("00-1a-2b-3c-4d-5e")
	if ok2 {
		fmt.printf("Hyphen format: %s\n", netx.mac_to_string_hyphen(mac2, true))
	}

	mac3, ok3 := netx.parse_mac("001a2b3c4d5e")
	if ok3 {
		fmt.printf("Raw format: %s\n", netx.mac_to_string_raw(mac3, true))
	}

	// Must parse (panics on failure)
	mac := netx.must_parse_mac("AA:BB:CC:DD:EE:FF")
	fmt.printf("Must parsed: %s\n", netx.mac_to_string_colon(mac, true))

	// ========================================================================
	// MAC ADDRESS FORMATTING
	// ========================================================================

	fmt.println("\n--- MAC Address Formatting ---")

	sample := netx.must_parse_mac("00:1A:2B:3C:4D:5E")

	fmt.printf("Uppercase colon: %s\n", netx.mac_to_string_colon(sample, true))
	fmt.printf("Lowercase colon: %s\n", netx.mac_to_string_colon(sample, false))
	fmt.printf("Uppercase hyphen: %s\n", netx.mac_to_string_hyphen(sample, true))
	fmt.printf("Lowercase hyphen: %s\n", netx.mac_to_string_hyphen(sample, false))
	fmt.printf("Raw hex: %s\n", netx.mac_to_string_raw(sample, false))

	// ========================================================================
	// MAC ADDRESS PROPERTIES
	// ========================================================================

	fmt.println("\n--- MAC Address Properties ---")

	unicast := netx.must_parse_mac("00:11:22:33:44:55")
	multicast := netx.must_parse_mac("01:00:5E:00:00:FB")
	broadcast := netx.mac_broadcast()
	locally_admin := netx.must_parse_mac("02:11:22:33:44:55")

	fmt.printf("%s is unicast: %v\n", netx.mac_to_string_colon(unicast, true), netx.is_unicast_mac(unicast))
	fmt.printf("%s is multicast: %v\n", netx.mac_to_string_colon(multicast, true), netx.is_multicast_mac(multicast))
	fmt.printf("%s is broadcast: %v\n", netx.mac_to_string_colon(broadcast, true), netx.is_broadcast_mac(broadcast))
	fmt.printf("%s is locally administered: %v\n", netx.mac_to_string_colon(locally_admin, true), netx.is_locally_administered(locally_admin))
	fmt.printf("%s is globally unique: %v\n", netx.mac_to_string_colon(unicast, true), netx.is_globally_unique(unicast))

	// ========================================================================
	// OUI EXTRACTION
	// ========================================================================

	fmt.println("\n--- OUI (Organizationally Unique Identifier) ---")

	mac_with_oui := netx.must_parse_mac("00:1A:2B:3C:4D:5E")
	oui := netx.get_oui(mac_with_oui)
	nic := netx.get_nic_specific(mac_with_oui)

	fmt.printf("MAC Address: %s\n", netx.mac_to_string_colon(mac_with_oui, true))
	fmt.printf("OUI (first 3 bytes): %02X:%02X:%02X\n", oui[0], oui[1], oui[2])
	fmt.printf("NIC specific (last 3 bytes): %02X:%02X:%02X\n", nic[0], nic[1], nic[2])

	// ========================================================================
	// EUI-64 CONVERSION
	// ========================================================================

	fmt.println("\n--- EUI-64 Conversion ---")

	mac_for_eui := netx.must_parse_mac("00:1A:2B:3C:4D:5E")
	fmt.printf("Original MAC: %s\n", netx.mac_to_string_colon(mac_for_eui, true))

	eui64 := netx.mac_to_eui64(mac_for_eui)
	fmt.printf("As EUI-64: %s\n", netx.eui64_to_string(eui64, ":", true))
	fmt.println("  (Note: bit 7 flipped, FF:FE inserted)")

	// Convert back
	recovered_mac, can_recover := netx.eui64_to_mac(eui64)
	if can_recover {
		fmt.printf("Recovered MAC: %s\n", netx.mac_to_string_colon(recovered_mac, true))
	}

	// ========================================================================
	// IPv6 LINK-LOCAL ADDRESS GENERATION
	// ========================================================================

	fmt.println("\n--- IPv6 Link-Local Address from MAC ---")

	mac_for_ipv6 := netx.must_parse_mac("00:1A:2B:3C:4D:5E")
	fmt.printf("MAC Address: %s\n", netx.mac_to_string_colon(mac_for_ipv6, true))

	link_local := netx.mac_to_ipv6_link_local(mac_for_ipv6)
	fmt.printf("Link-local IPv6: %s\n", netx.addr_to_string6(link_local))
	fmt.println("  (fe80::/64 + EUI-64 interface ID)")

	// Extract MAC back from IPv6 address
	extracted_mac, can_extract := netx.ipv6_to_mac(link_local)
	if can_extract {
		fmt.printf("Extracted MAC: %s\n", netx.mac_to_string_colon(extracted_mac, true))
	}

	// ========================================================================
	// EUI-64 PARSING AND FORMATTING
	// ========================================================================

	fmt.println("\n--- EUI-64 Addresses ---")

	eui1, eui_ok1 := netx.parse_eui64("02:1A:2B:FF:FE:3C:4D:5E")
	if eui_ok1 {
		fmt.printf("Parsed EUI-64: %s\n", netx.eui64_to_string(eui1, ":", true))
	}

	eui2, eui_ok2 := netx.parse_eui64("021a2bfffe3c4d5e")
	if eui_ok2 {
		fmt.printf("Raw format: %s\n", netx.eui64_to_string(eui2, "-", false))
	}

	// Get IPv6 interface ID segments from EUI-64
	interface_id := netx.eui64_to_ipv6_interface_id(eui1)
	fmt.printf("Interface ID segments: %04X:%04X:%04X:%04X\n",
	u16(interface_id[0]),
	u16(interface_id[1]),
	u16(interface_id[2]),
	u16(interface_id[3]))

	// ========================================================================
	// WELL-KNOWN MAC ADDRESSES
	// ========================================================================

	fmt.println("\n--- Well-Known MAC Addresses ---")

	fmt.printf("Broadcast: %s\n", netx.mac_to_string_colon(netx.mac_broadcast(), true))
	fmt.printf("Null: %s\n", netx.mac_to_string_colon(netx.mac_null(), true))

	// ========================================================================
	// MAC ADDRESS COMPARISON
	// ========================================================================

	fmt.println("\n--- MAC Address Comparison ---")

	mac_a := netx.must_parse_mac("00:1A:2B:00:00:01")
	mac_b := netx.must_parse_mac("00:1A:2B:00:00:02")
	mac_c := netx.must_parse_mac("00:1A:2B:00:00:01")

	fmt.printf("%s vs %s: %d\n",
	netx.mac_to_string_colon(mac_a, true),
	netx.mac_to_string_colon(mac_b, true),
	netx.compare_mac(mac_a, mac_b))

	fmt.printf("%s vs %s: %d\n",
	netx.mac_to_string_colon(mac_b, true),
	netx.mac_to_string_colon(mac_a, true),
	netx.compare_mac(mac_b, mac_a))

	fmt.printf("%s vs %s: %d (equal)\n",
	netx.mac_to_string_colon(mac_a, true),
	netx.mac_to_string_colon(mac_c, true),
	netx.compare_mac(mac_a, mac_c))

	fmt.printf("%s < %s: %v\n",
	netx.mac_to_string_colon(mac_a, true),
	netx.mac_to_string_colon(mac_b, true),
	netx.less_mac(mac_a, mac_b))

	// ========================================================================
	// MAC ADDRESS VALIDATION
	// ========================================================================

	fmt.println("\n--- MAC Address Validation ---")

	valid := netx.must_parse_mac("00:1A:2B:3C:4D:5E")
	null := netx.mac_null()

	fmt.printf("%s is valid: %v\n", netx.mac_to_string_colon(valid, true), netx.is_valid_mac(valid))
	fmt.printf("%s is valid: %v (null MAC not considered valid)\n",
	netx.mac_to_string_colon(null, true),
	netx.is_valid_mac(null))

	// ========================================================================
	// CONSTRUCTOR
	// ========================================================================

	fmt.println("\n--- Constructing from Bytes ---")

	bytes := [6]u8{0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF}
	mac_from_bytes := netx.mac_from_bytes(bytes)
	fmt.printf("Created from bytes: %s\n", netx.mac_to_string_colon(mac_from_bytes, true))

	eui_bytes := [8]u8{0x02, 0x1A, 0x2B, 0xFF, 0xFE, 0x3C, 0x4D, 0x5E}
	eui_from_bytes := netx.eui64_from_bytes(eui_bytes)
	fmt.printf("Created EUI-64 from bytes: %s\n", netx.eui64_to_string(eui_from_bytes, ":", true))
}
