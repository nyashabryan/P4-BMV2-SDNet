#!/usr/bin/bash

# Compiling the Reflector Switch

# Add Vivado and SDNet to Path
PATH="/tools/Xilinx/Vivado/2019.1/bin:$PATH";
PATH="/opt/Xilinx/SDNet/2018.2/bin:$PATH";

# Compile the P4 to SDNet using p4c-sdnet
p4c-sdnet -v refl.p4 -o refl.sdnet --sdnet_info info.json

# Compile the SDNet into HDL
sdnet -busWidth 32 -busType axi -workDir comp -packetFile Packet.user 
