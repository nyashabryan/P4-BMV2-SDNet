/**
 * Simple IPv4 Reflector Switch. Based on the Xilinx Switch Architecture.
 * Takes in an IPv4 packet and reflects it back to the sender.
 */

/* -*- P4_16 -*- */
#include <core.p4>
#include "../xilinx.p4"

const bit<16> TYPE_IPV4 = 0x0800;
const bit<4> IPV4_VERSION = 4;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;


header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

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


struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
}


/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

@Xilinx_MaxPacketRegion(1518*8) // in bit
parser XParser(packet_in packet,
                out headers hdr) {

    state start {
        transition parse_ethernet;
    }

    // Parse the Ethernet headers. Transition to ipv4 or ipv6 using ethertype.
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
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
}

/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control IngressProc(inout headers hdr,
                    inout switch_metadata_t metadata) {
    action drop() {
        metadata.egress_port = 0xF;
    }
    
    action reflect(switch_port_t port) {

        metadata.egress_port = port;
        hdr.ethernet.dstAddr = hdr.ethernet.srcAddr;

        hdr.ipv4.dstAddr = hdr.ipv4.srcAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }
    
    apply {

        if (hdr.ethernet.etherType == TYPE_IPV4) {
            if (hdr.ipv4.isValid()) {
                reflect(metadata.ingress_port);
            } else drop();
        } else drop();
    }
}



/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control XDeparser(in headers hdr, packet_out packet) {
    apply {
        
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
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
