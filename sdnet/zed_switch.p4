/**
 * The Reference ZedSwitch. 
 * Author: Nyasha Bryan Katemauswa
 * Date: 29 September 2019'
 */

#ifndef _ZED_SWITCH_P4_
#define _ZED_SWITCH_P4_


#include "xilinx.p4"

/* Ethertype in Ethernet Frame */
typedef bit<16> ethertype_t;

/* IP Version in the beginning of IPv4 and IPv6 packets */
typedef bit<4> ip_version_t;

/* Internet Protocol Number: Protocol in IPv4 and Next Header IPv6 */
typedef bit<8> ip_number_t;


/* The zed_metadata struct used in the switch */
struct zed_metadata_t{
    switch_port_t   ingress_port;
    switch_port_t   egress_port;
    bit<1>          valid_bit;
    bit<11>         packet_length;
    bit<16>         in_timestamp;
    bit<16>         out_timestamp;
}

#endif
