#!/bin/bash

# Compiling the Switch

# Add Vivado and SDNet to Path
PATH="/tools/Xilinx/Vivado/2019.1/bin:$PATH";
PATH="/opt/Xilinx/SDNet/2018.2/bin:$PATH";

# Compile the P4 to SDNet using p4c-sdnet
p4c-sdnet -v switch.p4 -o switch.sdnet --sdnet_info info.json

# Compile the SDNet into HDL
sdnet switch.sdnet -busWidth 32 -busType axi -workDir comp -packetFile Packet.user 
