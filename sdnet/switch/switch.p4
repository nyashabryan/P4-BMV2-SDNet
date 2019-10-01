/**
 * Simple IPv4 Straight Switch. Based on the Xilinx Switch Architecture
 * for the ZedSwitch.
 * Takes in an IPv4 and IPv6 Packets.
 *
 * Author: Nyasha Bryan Katemauswa
 * September 2019
 */

/* -*- P4_16 -*- */
#include <core.p4>
#include "../zed_switch"


typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

const ethertype_t ETHERTYPE_TYPE_IPV4 = 0x0800
const ethertype_t ETHERTYPE_TYPE_IPV6 = 0x86DD;
const ip_version_t IPV4_VERSION = 4;
const ip_version_t IPV6_VERSION = 6;
const ip_number_t IPv6_ENCAPSULATION = 41;

const ip4Addr_t SELFIP4ADD = 0xC0A80001;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

/**
 * Layer 2 Ethernet Frame header structure.
 */
header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

/**
 * IPv4 header structure.
 */
header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

/**
 * IPv6 header structure.
 */
header ipv6_t {
    bit<4> version;
    bit<8> trafficClass;
    bit<24> flowLabel;
    bit<16> payloadLen;
    bit<8> nextHdr;
    bit<8> hopLimit;
    ip6Addr_t srcAddr;
    ip6Addr_t dstAddr;
}


// A struct of the headers to be parsed by the switch.
struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    ipv6_t       ipv6;
}


/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

@Xilinx_MaxPacketRegion(1522*8) // The maximum size of the packets in the region
parser XParser(packet_in packet,
                out headers hdr) {

    state start {
        transition parse_ethernet;
    }

    // Parse the Ethernet headers. Transition to ipv4 or ipv6 using ethertype.
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_TYPE_IPV4: parse_ipv4;
            ETHERTYPE_TYPE_IPV6: parse_ipv6;
            default: accept;
        }
    }

    // Extract the ipv4 header and check version is 4.
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.version) {
            IPV4_VERSION: accept;
            default: reject;
        }

    }

    // Extract the ipv6 header
    state parse_ipv6 {
        packet.extract(hdr.ipv6);
        transition select(hdr.ipv6.version) {
            IPV6_VERSION: accept;
            default: reject;
        }
    }
}

/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control IngressProc(inout headers hdr,
                    inout zed_metadata_t metadata) {
    action drop() {
        metadata.egress_port = 0xF;
    }

    action ipv4_forward() {

        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        metadata.egress_port = 0x1;
    }

    action ipv6_in_ipv4_forward() {
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        metadata.egress_port = 0x1;
        hdr.ipv6.hopLimit = hdr.ipv6.hopLimit - 1;    
    }
    
    action ipv6_encapsulate() {

        // Create the IPv4 headers
        hdr.ipv4.version = IPV4_VERSION;
        hdr.ipv4.ihl = 0x0;
        hdr.ipv4.diffserv = 0x0;
        hdr.ipv4.totalLen = hdr.ipv6.payloadLen + (64 + 128 + 128)/8 + 20; 
        hdr.ipv4.identification = 0x0;
        hdr.ipv4.flags = 0x0;
        hdr.ipv4.fragOffset = 0x0;
        hdr.ipv4.ttl = hdr.ipv6.hopLimit - 1;
        hdr.ipv4.protocol = IPv6_ENCAPSULATION;
        hdr.ipv4.hdrChecksum = 0x0;
        hdr.ipv4.srcAddr = SELFIP4ADD;
        hdr.ipv4.dstAddr = 0x0;

        // Change the IPv6 headers
        hdr.ipv6.nextHdr = IPv6_ENCAPSULATION;
        hdr.ipv6.hopLimit = hdr.ipv6.hopLimit - 1;

        // Mark egress port
        metadata.egress_port = 0x1;
    }
    
    apply {

        if (hdr.ethernet.etherType == ETHERTYPE_TYPE_IPV4) {
            if (hdr.ipv4.isValid()) {
                if(hdr.ipv4.protocol == IPv6_ENCAPSULATION) {
                    ipv6_in_ipv4_forward();
                } else {
                    ipv4_forward();
                }
            } else drop();
        } else if (hdr.ethernet.etherType == ETHERTYPE_TYPE_IPV6) {
            if (hdr.ipv6.isValid()) {
                ipv6_encapsulate();
            } else {
                drop();
            }
        }
    }
}



/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control XDeparser(in headers hdr, packet_out packet) {
    apply {
        
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.ipv6);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

XilinxSwitch(
    XParser(),
    IngressProc(),
    XDeparser()
) main;
