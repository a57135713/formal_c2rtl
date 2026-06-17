#------------------------------------------------------------------------------
# c2rtl_setup.tcl — JasperGold C2RTL App Configuration
#------------------------------------------------------------------------------
# Usage: jg -batch -tcl cfg/c2rtl_setup.tcl
#
# This script:
#   1. Reads the C/C++ reference model (c_model/fir_filter.cpp)
#   2. Reads the RTL implementation   (rtl/fir_filter.sv)
#   3. Maps C variables to RTL signals
#   4. Runs sequential equivalence checking
#------------------------------------------------------------------------------

# --- Design Reading ---

# Read C/C++ reference model
#   -top   : the C function we are verifying
#   -I     : include path for header files
sec_read_c -top fir_filter \
    -I ./c_model \
    ./c_model/fir_filter.cpp

# Read and elaborate RTL
analyze -f cfg/dut.f
elaborate fir_filter

# --- Clock and Reset ---
clock clk
reset !rst_n

# --- C-to-RTL Signal Mapping ---
# Syntax: sec_map <c_expression> <rtl_signal> [-pipeline <N>]

# Input
sec_map input        data_in

# Coefficients (read-only, same in C and RTL)
sec_map coeff[0]     coeff[0]
sec_map coeff[1]     coeff[1]
sec_map coeff[2]     coeff[2]
sec_map coeff[3]     coeff[3]
sec_map coeff[4]     coeff[4]
sec_map coeff[5]     coeff[5]
sec_map coeff[6]     coeff[6]
sec_map coeff[7]     coeff[7]

# Delay line state (shift register)
sec_map state[0]     fir_filter.state_reg[0]
sec_map state[1]     fir_filter.state_reg[1]
sec_map state[2]     fir_filter.state_reg[2]
sec_map state[3]     fir_filter.state_reg[3]
sec_map state[4]     fir_filter.state_reg[4]
sec_map state[5]     fir_filter.state_reg[5]
sec_map state[6]     fir_filter.state_reg[6]
sec_map state[7]     fir_filter.state_reg[7]

# Output (4-cycle pipeline latency)
#   C function returns immediately; RTL output appears 4 cycles later
sec_map {fir_filter} data_out -pipeline 4

# --- Prove Equivalence ---
check_sec -app c2rtl
