//----------------------------------------------------------------------------
//   This file is owned and controlled by Xilinx and must be used solely    //
//   for design, simulation, implementation and creation of design files    //
//   limited to Xilinx devices or technologies. Use with non-Xilinx         //
//   devices or technologies is expressly prohibited and immediately        //
//   terminates your license.                                               //
//                                                                          //
//   XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" SOLELY   //
//   FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY   //
//   PROVIDING THIS DESIGN, CODE, OR INFORMATION AS ONE POSSIBLE            //
//   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR STANDARD, XILINX IS     //
//   MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION IS FREE FROM ANY     //
//   CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE FOR OBTAINING ANY      //
//   RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY      //
//   DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE  //
//   IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR         //
//   REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF        //
//   INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A  //
//   PARTICULAR PURPOSE.                                                    //
//                                                                          //
//   Xilinx products are not intended for use in life support appliances,   //
//   devices, or systems.  Use in such applications are expressly           //
//   prohibited.                                                            //
//                                                                          //
//   (c) Copyright 1995-2017 Xilinx, Inc.                                   //
//   All rights reserved.                                                   //
//----------------------------------------------------------------------------
#ifndef _XILINX_CORE_P4_
#define _XILINX_CORE_P4_

extern packet_mod {
    /// UPDATE header with hdr at packet cursor, and then advance cursor.
    /// In second case, mask is used to select a subset of fields to update.
    void update<H>(in H hdr);
    void update<H>(in H hdr, in bit<32> mask);

    /// REMOVE a header from packet.
    /// In second case, H has exactly one variable size field
    /// with size varFieldSizeInBits.
    /// May trigger PacketTooShort error.
    void extract<H>();
    void extract<H>(in bit<32> varFieldSizeInBits);

    /// INSERT data into packet before the cursor, skipping invalid headers.
    /// H can be a header, stack, or union type. It can also be
    /// a struct containing fields with such types
    void emit<H>(in H hdr);

    /// ADVANCE the packet cursor by the size of a header (first case),
    /// or by the specified number of bits (second case).
    /// May trigger PacketTooShort error.
    void advance<H>();
    void advance(in bit<32> sizeInBits);

    /// RETURN remaining number of bits from packet cursor to end of packet.
    ///
    /// NOTE: Might not be supported by some targets,
    ///       or might have target-imposed restrictions.
    bit<32> length();
}

/* match_kind - additional supported match type(s) for table keys */
match_kind {
    direct  /* index lookup */
}

#endif  /* _XILINX_CORE_P4_ */
