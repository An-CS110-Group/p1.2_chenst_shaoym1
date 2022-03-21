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
li a6, 2                # calloc... Takes in a1 nitems and a2 size of each item. Zeros out the allocated memory. Returns a pointer to that block in a0
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
mv s10, a0              # global var s10, to save the address
# setup complete
la s0, rvc_codes                # load the address of first instruction
li t0, 0                        # current working instruction
li t1, 0x3                      # constant 0b11
read_next:
beq t0, s7, finish_reading      # finish reading if reaches the end
lhu s1, 0(s0)                   # load half word
addi s0, s0, 2                  # Go to the next half-word
andi s2, s1, 0x3                # last 2 bits (if equal to 0x3, 32-bit instruction)
bne s2, t1, NCI_read            # Non compressed instruction
lhu s3, 0(s0)                   # Upper 16 bit of 32-bit instruction
addi s0, s0, 2                  # Go to the next half-word
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

# parse all 32-bit instructions here
add zero, zero, zero

# parse all compressed instructions
li t0, 0                        # t0 is the number of (compressed) instruction we are dealing with
mul t1, t0, s8                  # t1 is the relative address of current instruction
add t1, t1, s10                 # Now t1 is the absolute address of current instruction
parse_CI_main_loop:
beq t0, s7, finish_parse_CI     # if (t0 == s7) finish
addi t0, t0, 1                  # t0 += 1; t0 should not be used until next loop
lw t2, 0(t1)                    # originalValue is loaded into t2
beqz t2, parse_CI_main_loop     # if (compressed[i] == NULL) continue;
        # here we are going to parse a valid compressed risc-v instruction
srli t3, t2, 12                 # funct4 = originalValue >> 12;
sb t3, 4(t1)                    # store funct4 to memory
srli t3, t2, 13                 # funct3 = originalValue >> 13;
sb t3, 5(t1)                    # store funct3 to memory
srli t3, t2, 10                 # funct6 = originalValue >> 10;
sb t3, 6(t1)                    # store funct6 to memory
                # funct2 here
srli t3, t2, 10                 # if (ov >> 10 == 0b11)
addi t3, t3, -0b11              # if (ov >> 10 == 0b11)
srli t4, t2, 5                  # (ov >> 5)
beqz t3, L1                     # keep t4
srli t4, t2, 10                 # modify t4 -> (ov >> 10)
L1:
andi t4, t4, 0b11               # funct2 = (ov >> ?) & 0b11 (stored in t4)
sb t4, 7(t1)                    # store funct2 to memory
                # funct2 ends
srli t3, t2, 7                  # rd/rs1 = (ov >> 7) & 0b11111
andi t3, t3, 0b11111            # rd/rs1 = (ov >> 7) & 0b11111
sb t3, 8(t1)                    # store rd/rs1 to memory
srli t3, t2, 2                  # rs2 = (ov >> 2) & 0b11111
andi t3, t3, 0b11111            # rs2 = (ov >> 2) & 0b11111
sb t3, 9(t1)                    # store rd/rs1 to memory
srli t3, t2, 7                  # rs1' = (ov >> 7) & 0b111
andi t3, t3, 0b111              # rs1' = (ov >> 7) & 0b111
sb t3, 10(t1)                   # store rs1' to memory
srli t3, t2, 2                  # rs2' = (ov >> 2) & 0b111
andi t3, t3, 0b111              # rs2' = (ov >> 2) & 0b111
sb t3, 11(t1)                   # store rs2' to memory
srli t3, t2, 7                  # rd' = (ov >> 7) & 0b111 (rd' = rs1')
andi t3, t3, 0b111              # rd' = (ov >> 7) & 0b111 (rd' = rs1')
sb t3, 12(t1)                   # store rd' to memory (rd' = rs1')
andi t3, t2, 0b11               # opcode = ov & 0b11
sb t3, 13(t1)                   # store opcode to memory
                                # TODO: imm here

j parse_CI_main_loop
finish_parse_CI:

# expand all compressed instructions
add zero, zero, zero

# update all addresses
add zero, zero, zero

# write "originalValue" field for instructions
add zero, zero, zero

# print to file
li t0, 0                        # t0 stands for current position
print_next:
beq t0, s7, finish_print        # finish printing if all lines are finished
mul t1, t0, s9                  # multiple by 32 to get relative position
add t1, t1, s11                 # Get the absolute address (saved in t1)
lw t2, 0(t1)                    # The "originalValue" field is saved in t2

li t3, 31                       # start loop
print_next_bit:
blt t3, zero, finish_single_ins # All bits of this instruction is printed
srl t4, t2, t3                  # Now the bit we want is in the rightmost bit
andi t4, t4, 1                  # The only bit left is what we want
mv a1, t4                       # Now print!
li a0, 1                        # "print_int" option in venus
ecall
addi t3, t3, -1                 # move onto the next bit
j print_next_bit
finish_single_ins:
addi t0, t0, 1                  # move onto the next instruction
li a1, 10                       # Now print '\n' here
li a0, 11                       # "print_character" option in venus
ecall
j print_next

finish_print:
add zero, zero, zero

# free all memory allocated
# free space of 32-bit instruction
li a0, 0x3CC            # vlib page
li a6, 4                # free
mv a1, s11              # 32-bit
ecall                   # transfer control to OS(venus here) to free space
# free space of 16-bit, compressed instruction
li a0, 0x3CC            # vlib page
li a6, 4                # free(frees the pointer given in a1. It will merge other free blocks around it if any exist. Does not return anything)
mv a1, s10              # 16-bit
ecall                   # transfer control to OS(venus here) to free space
# free complete

# Exit with error code 0
add a1, x0, x0
addi a0, x0, 17
ecall