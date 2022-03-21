#   Project 1.2 RVC instructions to RISC-V instructions in RISC-V

#   You can suppose you will get the number of machine codes you should translate from 
#   "lines_of_rvc_codes" and get the 16 or 32 bits-machine codes from "rvc_codes". 
#   Both of them are stored in file "input.S"

#   When we test your project, we will change the input files content.

# DO NOT REMOVE THIS LINE WHEN SUBMITTING
# .import input.S

# Your code to convert the RVC codes to RVI codes.

.data

# Constant integer specifying the lines of RVC codes

# DO NOT MODIFY THIS VARIABLE
.globl lines_of_rvc_codes
lines_of_rvc_codes:
    .word 7


# RVC codes, 16-bits instructions mixed with 32-bits instructions
# A 16/32-bits binary number represents one line of rvc code.
# You can suppose all of the input codes are valid. 

# DO NOT MODIFY THIS VARIABLE
.globl rvc_codes
rvc_codes:
    .word 0b00000000000000000000001010110011
    .half 0b0001010111111101
    .half 0b1001001010101010
    .half 0b0001010111111101
    .word 0b11111110000001011101111011100011
    .half 0b1000010100010110
    .half 0b1000000010000010

.text
# The total line of code
lw s7, lines_of_rvc_codes
# Commonly used constant 32
li s9, 32
# Commonly used constant 20
li s8, 20
# Allocate space (set to zero) for 32-bit instruction
li a0, 0x3CC            # vlib page
li a6, 2                # calloc
li a1, 100              # 100 items in total
li a2, 32               # size of item "instruction"
ecall                   # transfer control to OS(venus here) to calloc space
mv s11, a0              # global var s11, to save the address
# Allocate space (set to zero) for 16-bit, compressed instruction
li a0, 0x3CC            # vlib page
li a6, 2                # calloc
li a1, 100              # 100 items in total
li a2, 20               # size of item "instruction"
ecall                   # transfer control to OS(venus here) to calloc space
mv s10, a0              # global var s11, to save the address
# setup complete
Allocate space (set to zero) ford
slli s3, s3, 16                 # Upper 16 bit
or s1, s1, s3                   # Now the whole 32-bit instruction is in the register
# putting 32-bit instruction into memory
mul t2, t0, s9                  # Get the location of t0-th (32-bit) instruction
add t2, t2, s11                 # Absolute address of t0-th (32-bit) instruction
sw s1, 0(t2)                    # save word to it
addi t0, t0, 1                  # Next instruction
j read_next                     # Go back to loop
NCI_read:                       # Non compressed instruction
# putting 16-bit instruction into memory
mul t2, t0, s8                  # Get the location of t0-th compressed instruction
add t2, t2, s10                 # Absolute address of t0-th compressed instruction
sw s1, 0(t2)                    # save word to it
addi t0, t0, 1                  # Next instruction
j read_next                     # Go back to loop
finish_reading:

add zero, zero, zero
add zero, zero, zero
add zero, zero, zero

# free all memory allocated
# free space of 32-bit instruction
li a0, 0x3CC            # vlib page
li a6, 4                # free
mv a1, s11              # 32-bit
ecall                   # transfer control to OS(venus here) to free space
# free space of 16-bit, compressed instruction
li a0, 0x3CC            # vlib page
li a6, 4                # free
mv a1, s10              # 16-bit
ecall                   # transfer control to OS(venus here) to free space
# free complete

# Exit with error code 0
add a1, x0, x0
addi a0, x0, 17
ecall