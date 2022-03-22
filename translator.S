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

lbu t3, 13(t1)                  # t3 = opcode
beqz t3, CL_CS                  # opcode = 0b00
li t4, 0b01
beq t3, t4, imm_other           # opcode = 0b01
        # opcode = 0b10
srli t4, t2, 15                 # The right most bit of instruction
beqz t4, CI_CB_2                # SLLI
li t4, 0                        # No imm field
j end_of_imm

imm_other:                      # opcode = 0b01
lbu t3, 5(t1)                   # t3 = funct3
li t4, 0b010                    # CI-format
beq t3, t4, CI_CB_2             # CI-format
li t4, 0b011                    # CI-format
beq t3, t4, CI_CB_2             # CI-format
beqz t3, CI_CB_2                # CI-format
li t4, 0b110                    # CB_1-format
beq t3, t4, CB_1                # CB_1-format
li t4, 0b111                    # CB_1-format
beq t3, t4, CB_1                # CB_1-format
li t4, 0b101                    # CJ-format
beq t3, t4, CJ                  # CJ-format
li t4, 0b001                    # CJ-format
beq t3, t4, CJ                  # CJ-format
srli t3, t2, 10                 # t3 = (ov >> 10) & 0b11
andi t3, t3, 0b11               # t3 = (ov >> 10) & 0b11
addi t3, t3, -0b11              # if (t3 != 0b11) CB_2;
bnez t3, CI_CB_2                # if (t3 != 0b11) CB_2;
li t4, 0                        # No imm field
j end_of_imm

CB_1:
li t4, 0                        # t4 = imm
srli t5, t2, 3                  # offset[2:1]
andi t5, t5, 0b11               # offset[2:1]
or t4, t4, t5                   # load offset[2:1]
srli t5, t2, 10                 # offset[4:3]
andi t5, t5, 0b11               # offset[4:3]
slli t5, t5, 2                  # load offset[4:3]
or t4, t4, t5                   # load offset[4:3]
srli t5, t2, 2                  # offset[5]
andi t5, t5, 1                  # offset[5]
slli t5, t5, 4                  # load offset[5]
or t4, t4, t5                   # load offset[5]
srli t5, t2, 5                  # offset[7:6]
andi t5, t5, 0b11               # offset[7:6]
slli t5, t5, 5                  # load offset[7:6]
or t4, t4, t5                   # load offset[7:6]
srli t5, t2, 12                 # offset[8]
andi t5, t5, 1                  # offset[8]
slli t5, t5, 7                  # load offset[8]
or t4, t4, t5                   # load offset[8]
j end_of_imm

CJ:
li t4, 0                        # t4 = imm
srli t5, t2, 3                  # offset[3:1]
andi t5, t5, 0b111              # offset[3:1]
or t4, t4, t5                   # load offset[3:1]
srli t5, t2, 11                 # offset[4]
andi t5, t5, 1                  # offset[4]
slli t5, t5, 3                  # load offset[4]
or t4, t4, t5                   # load offset[4]
srli t5, t2, 2                  # offset[5]
andi t5, t5, 1                  # offset[5]
slli t5, t5, 4                  # load offset[5]
or t4, t4, t5                   # load offset[5]
srli t5, t2, 7                  # offset[6]
andi t5, t5, 1                  # offset[6]
slli t5, t5, 5                  # load offset[6]
or t4, t4, t5                   # load offset[6]
srli t5, t2, 6                  # offset[7]
andi t5, t5, 1                  # offset[7]
slli t5, t5, 6                  # load offset[7]
or t4, t4, t5                   # load offset[7]
srli t5, t2, 9                  # offset[9:8]
andi t5, t5, 0b11               # offset[9:8]
slli t5, t5, 7                  # load offset[9:8]
or t4, t4, t5                   # load offset[9:8]
srli t5, t2, 8                  # offset[10]
andi t5, t5, 1                  # offset[10]
slli t5, t5, 9                  # load offset[10]
or t4, t4, t5                   # load offset[10]
srli t5, t2, 12                 # offset[11]
andi t5, t5, 1                  # offset[11]
slli t5, t5, 10                 # load offset[11]
or t4, t4, t5                   # load offset[11]
j end_of_imm

CI_CB_2:
li t4, 0                        # t4 = imm
srli t5, t2, 2                  # imm[4:0]
andi t5, t5, 0b11111            # imm[4:0]
or t4, t4, t5                   # load imm[4:0]
srli t5, t2, 12                 # imm[5]
andi t5, t5, 1                  # imm[5]
slli t5, t5, 5                  # load imm[5]
or t4, t4, t5                   # load imm[5]
j end_of_imm

CL_CS:
li t4, 0                        # t4 = imm
srli t5, t2, 6                  # offset[2]
andi t5, t5, 1                  # offset[2]
or t4, t4, t5                   # load offset[2]
srli t5, t2, 10                 # offset[5:3]
andi t5, t5, 0b111              # offset[5:3]
slli t5, t5, 1                  # load offset[5:3]
or t4, t4, t5                   # load offset[5:3]
srli t5, t2, 5                  # offset[6]
andi t5, t5, 1                  # offset[6]
slli t5, t5, 4                  # load offset[6]
or t4, t4, t5                   # load offset[6]
j end_of_imm                    # imm has been set to t4

end_of_imm:
sw t4, 16(t1)                   # save imm to memory
j parse_CI_main_loop

finish_parse_CI:

# expand all compressed instructions
li t0, 0                        # t0 is the number if instruction we are dealing with
expand_main_loop:
beq t0, s7, end_expand          # if (t0 == s7) finish
mul t1, t0, s8                  # relative address of compressed instruction
add t1, t1, s10                 # t1 is the position of current 16-bit instruction
mul t2, t0, s9                  # relative address of 32-bit instruction
add t2, t2, s11                 # t2 is the position of current 32-bit instruction
addi t0, t0, 1                  # t0 += 1
lw t3, 0(t1)                    # t3 = originalValue
beqz t3, expand_main_loop       # if (compressed[i] == NULL) continue;
lbu t4, 13(t1)                  # t4 = opcode
lbu t5, 5(t1)                   # t5 = funct3
beqz t5, expand_00              # opcode = 0b00
li t6, 0b10                     # opcode = 0b10
beq t5, t6, expand_10           # opcode = 0b10
j expand_01                     # opcode = 0b01

expand_00:
li t6, 0b010                    # LW: funct3 = 0b010
beq t5, t6, ex_LW               # LW: funct3 = 0b010
j ex_SW                         # SW: other conditions

ex_LW:                          # LW: immediate is not negative
li t3, 0b010                    # funct3 = 0b010
sw t3, 12(t2)                   # save funct3
li t3, 0b0000011                # opcode = 0b0000011
sw t3, 4(t2)                    # save opcode
lbu t3, 10(t1)                  # t3 = rs1' (compressed)
addi t3, t3, 0b1000             # t3 = rs1 (32-bit)
sw t3, 16(t2)                   # save rs1
lbu t3, 12(t1)                  # t3 = rd' (compressed)
addi t3, t3, 0b1000             # t3 = rd (32-bit)
sw t3, 8(t2)                    # save rd
lw t3, 16(t1)                   # 16-bit imm
slli t3, t3, 2                  # get 32-bit imm
sw t3, 28(t2)                   # save imm
j expand_next

ex_SW:                          # SW: immediate is not negative
li t3, 0b010                    # funct3 = 0b010
sw t3, 12(t2)                   # save funct3
li t3, 0b0100011                # opcode = 0b0100011
sw t3, 4(t2)                    # save opcode
lbu t3, 10(t1)                  # t3 = rs1' (compressed)
addi t3, t3, 0b1000             # t3 = rs1 (32-bit)
sw t3, 16(t2)                   # save rs1
lbu t3, 11(t1)                  # t3 = rs2' (compressed)
addi t3, t3, 0b1000             # t3 = rs2 (32-bit)
sw t3, 20(t2)                   # save rs2
lw t3, 16(t1)                   # 16-bit imm
slli t3, t3, 2                  # get 32-bit imm
sw t3, 28(t2)                   # save imm
j expand_next

expand_10:
beqz t5, ex_SLLI                # SLLI: funct3 = 0b000
lbu a2, 9(t1)                   # a2 = rs2
lbu a3, 4(t1)                   # a3 = funct4
beqz a2, ex_JR_JALR             # JR/JALR
li t6, 0b1000                   # MV: funct4 = 0b1000
beq a3, t6, ex_MV               # MV: funct4 = 0b1000
j ex_ADD                        # ADD: other conditions

ex_SLLI:                        # SLLI: shamt[5] = 0
li t3, 0b001                    # funct3 = 0b001
sw t3, 12(t2)                   # store funct3
li t3, 0b0010011                # opcode = 0b0010011
sw t3, 4(t2)                    # store opcode
li t3, 0b0000000                # funct7 = 0b0000000
sw t3, 24(t2)                   # store funct7
lbu t3, 8(t1)                   # t3 = rd/rs1
sw t3, 16(t2)                   # store rs1
sw t3, 8(t2)                    # store rd
lw t3, 16(t1)                   # t3 = imm
sw t3, 28(t2)                   # store imm
j expand_next

ex_JR_JALR:
li t6, 0b1000                   # JR: funct4 = 0b1000
beq a3, t6, ex_JR               # JR: funct4 = 0b1000
j ex_JALR                       # JALR: other cases

ex_JR:
li t3, 0b000                    # funct3 = 0b000
sw t3, 12(t2)                   # store funct3
li t3, 0b1100111                # opcode = 0b1100111
sw t3, 4(t2)                    # store opcode
li t3, 0                        # rd = 0
sw t3, 8(t2)                    # store rd
li t3, 0                        # imm = 0
sw t3, 28(t2)                   # store imm
lbu t3, 8(t2)                   # t2 = rs1
sw t3, 16(t2)                   # store rs1
j expand_next

ex_JALR:
li t3, 0b000                    # funct3 = 0b000
sw t3, 12(t2)                   # store funct3
li t3, 0b1100111                # opcode = 0b1100111
sw t3, 4(t2)                    # store opcode
li t3, 1                        # rd = 1
sw t3, 8(t2)                    # store rd
li t3, 0                        # imm = 0
sw t3, 28(t2)                   # store imm
lbu t3, 8(t2)                   # t2 = rs1
sw t3, 16(t2)                   # store rs1
j expand_next

ex_MV:
li t3, 0b0000000                # funct7 = 0b0000000
sw t3, 24(t2)                   # store funct7
li t3, 0b000                    # funct3 = 0b000
sw t3, 12(t2)                   # store funct3
li t3, 0b0110011                # opcode = 0b0110011
sw t3, 4(t2)                    # store opcode
lbu t3, 8(t1)                   # t3 = rd/rs1
sw t3, 8(t2)                    # store rd
lbu t3, 9(t2)                   # t3 = rs2
sw t3, 20(t2)                   # store rs2
li t3, 0                        # rs1 = 0
sw t3, 16(t2)                   # store rs1
j expand_next

ex_ADD:
li t3, 0b0000000                # funct7 = 0b0000000
sw t3, 24(t2)                   # store funct7
li t3, 0b000                    # funct3 = 0b000
sw t3, 12(t2)                   # store funct3
li t3, 0b0110011                # opcode = 0b0110011
sw t3, 4(t2)                    # store opcode
lbu t3, 8(t1)                   # t3 = rd/rs1
sw t3, 8(t2)                    # store rd
sw t3, 16(t2)                   # store rs1
lbu t3, 9(t2)                   # t3 = rs2
sw t3, 20(t2)                   # store rs2
j expand_next


expand_01:
li t6, 0b010                    # LI: funct3 = 0b010
beq t5, t6, ex_LI               # LI: funct3 = 0b010
li t6, 0b011                    # LUI: funct3 = 0b011
beq t5, t6, ex_LUI              # LUI: funct3 = 0b011
beqz t5, ex_ADDI                # ADDI: funct3 = 0b000
li t6, 0b110                    # BEQZ: funct3 = 0b110
beq t5, t6, ex_BEQZ             # BEQZ: funct3 = 0b110
li t6, 0b111                    # BNEZ: funct3 = 0b111
beq t5, t6, ex_BNEZ             # BNEZ: funct3 = 0b111
li t6, 0b101                    # J: funct3 = 0b101
beq t5, t6, ex_J                # J: funct3 = 0b101
li t6, 0b001                    # JAL: funct3 = 0b001
beq t5, t6, ex_JAL              # JAL: funct3 = 0b001
# Depend on funct6
lbu a4, 6(t1)                   # a4 = funct6 & 0b11
andi a4, a4, 0b11               # a4 = funct6 & 0b11
beqz a4, ex_SRLI                # SRLI: last two digits of funct6 is 00
li t6, 0b01                     # SRAI: last two digits of funct6 is 01
beq a4, t6, ex_SRAI             # SRAI: last two digits of funct6 is 01
li t6, 0b10                     # ANDI: last two digits of funct6 is 10
beq a4, t6, ex_ANDI             # ANDI: last two digits of funct6 is 10
# Depend on funct2
lbu a5, 7(t1)                   # a5 = funct2
beqz a5, ex_SUB                 # SUB: funct2 = 0b00
li t6, 0b01                     # XOR: funct2 = 0b01
beq a5, t6, ex_XOR              # XOR: funct2 = 0b01
li t6, 0b10                     # OR: funct2 = 0b10
beq a5, t6, ex_OR               # OR: funct2 = 0b10
li t6, 0b11                     # AND: funct2 = 0b11
beq a5, t6, ex_AND              # AND: funct2 = 0b11
j expand_next                   # This line should not be executed

ex_AND:
li t3, 0b0000000                # funct7 = 0b0000000
sw t3, 24(t2)                   # store funct7
li t3, 0b111                    # funct3 = 0b111
sw t3, 12(t2)                   # store funct3
li t3, 0b0110011                # opcode = 0b0110011
sw t3, 4(t2)                    # store opcode
lbu t3, 12(t1)                  # t3 = rd' (compressed)
addi t3, t3, 0b1000             # t3 = rd (32-bit)
sw t3, 8(t2)                    # store rd
sw t3, 16(t2)                   # store rs1
lbu t3, 11(t1)                  # t3 = rs2' (compressed)
addi t3, t3, 0b1000             # t3 = rs2 (32-bit)
sw t3, 20(t2)                   # store rs2
j expand_next

ex_OR:
li t3, 0b0000000                # funct7 = 0b0000000
sw t3, 24(t2)                   # store funct7
li t3, 0b110                    # funct3 = 0b110
sw t3, 12(t2)                   # store funct3
li t3, 0b0110011                # opcode = 0b0110011
sw t3, 4(t2)                    # store opcode
lbu t3, 12(t1)                  # t3 = rd' (compressed)
addi t3, t3, 0b1000             # t3 = rd (32-bit)
sw t3, 8(t2)                    # store rd
sw t3, 16(t2)                   # store rs1
lbu t3, 11(t1)                  # t3 = rs2' (compressed)
addi t3, t3, 0b1000             # t3 = rs2 (32-bit)
sw t3, 20(t2)                   # store rs2
j expand_next

ex_XOR:
li t3, 0b0000000                # funct7 = 0b0000000
sw t3, 24(t2)                   # store funct7
li t3, 0b100                    # funct3 = 0b100
sw t3, 12(t2)                   # store funct3
li t3, 0b0110011                # opcode = 0b0110011
sw t3, 4(t2)                    # store opcode
lbu t3, 12(t1)                  # t3 = rd' (compressed)
addi t3, t3, 0b1000             # t3 = rd (32-bit)
sw t3, 8(t2)                    # store rd
sw t3, 16(t2)                   # store rs1
lbu t3, 11(t1)                  # t3 = rs2' (compressed)
addi t3, t3, 0b1000             # t3 = rs2 (32-bit)
sw t3, 20(t2)                   # store rs2
j expand_next

ex_SUB:
li t3, 0b0100000                # funct7 = 0b0100000
sw t3, 24(t2)                   # store funct7
li t3, 0b111                    # funct3 = 0b111
sw t3, 12(t2)                   # store funct3
li t3, 0b0110011                # opcode = 0b0110011
sw t3, 4(t2)                    # store opcode
lbu t3, 12(t1)                  # t3 = rd' (compressed)
addi t3, t3, 0b1000             # t3 = rd (32-bit)
sw t3, 8(t2)                    # store rd
sw t3, 16(t2)                   # store rs1
lbu t3, 11(t1)                  # t3 = rs2' (compressed)
addi t3, t3, 0b1000             # t3 = rs2 (32-bit)
sw t3, 20(t2)                   # store rs2
j expand_next

ex_SRLI:
li t3, 0b101                    # funct3 = 0b101
sw t3, 12(t2)                   # store funct3
li t3, 0b0010011                # opcode = 0b0010011
sw t3, 4(t2)                    # store opcode
li t3, 0b0000000                # funct7 = 0b0000000
sw t3, 24(t2)                   # store funct7
lbu t3, 12(t1)                  # t3 = rd'/rs1' (compressed)
addi t3, t3, 0b1000             # t3 = rd/rs1 (32-bit)
sw t3, 8(t2)                    # store rd
sw t3, 16(t2)                   # store rs1
lw t3, 16(t1)                   # t3 = shamt
sw t3, 28(t2)                   # store imm
j expand_next

ex_SRAI:
li t3, 0b101                    # funct3 = 0b101
sw t3, 12(t2)                   # store funct3
li t3, 0b0010011                # opcode = 0b0010011
sw t3, 4(t2)                    # store opcode
li t3, 0b0100000                # funct7 = 0b0100000
sw t3, 24(t2)                   # store funct7
lbu t3, 12(t1)                  # t3 = rd'/rs1' (compressed)
addi t3, t3, 0b1000             # t3 = rd/rs1 (32-bit)
sw t3, 8(t2)                    # store rd
sw t3, 16(t2)                   # store rs1
lw t3, 16(t1)                   # t3 = shamt
sw t3, 28(t2)                   # store imm
j expand_next

ex_ANDI:
li t3, 0b111                    # funct3 = 0b111
sw t3, 12(t2)                   # store funct3
li t3, 0b0010011                # opcode = 0b0010011
sw t3, 4(t2)                    # store opcode
lbu t3, 12(t1)                  # t3 = rd'/rs1' (compressed)
addi t3, t3, 0b1000             # t3 = rd/rs1 (32-bit)
sw t3, 8(t2)                    # store rd
sw t3, 16(t2)                   # store rs1
lw t3, 16(t1)                   # t3 = imm
slli t3, t3, 26                 # sign-extended imm
srai t3, t3, 26                 # sign-extended imm
sw t3, 28(t2)                   # store imm
j expand_next

ex_LI:
li t3, 0b000                    # funct3 = 0b000
sw t3, 12(t2)                   # store funct3
li t3, 0b0010011                # opcode = 0b0010011
sw t3, 4(t2)                    # store opcode
lbu t3, 12(t1)                  # t3 = rd'/rs1' (compressed)
addi t3, t3, 0b1000             # t3 = rd (32-bit)
sw t3, 8(t2)                    # store rd
li t3, 0                        # rs1 = 0
sw t3, 16(t2)                   # store rs1
lw t3, 16(t1)                   # t3 = imm
slli t3, t3, 26                 # sign-extended imm
srai t3, t3, 26                 # sign-extended imm
sw t3, 28(t2)                   # store imm
j expand_next

ex_LUI:
li t3, 0b0010111                # opcode = 0b0110111
sw t3, 4(t2)                    # store opcode
lbu t3, 8(t1)                   # t3 = rd
sw t3, 8(t2)                    # store rd
lw t3, 16(t1)                   # t3 = imm
slli t3, t3, 26                 # sign-extended imm, 26 is correct!
srai t3, t3, 26                 # sign-extended imm, not 14!
sw t3, 28(t2)                   # store imm
j expand_next

ex_ADDI:
li t3, 0b000                    # funct3 = 0b000
sw t3, 12(t2)                   # store funct3
li t3, 0b0010011                # opcode = 0b0010011
sw t3, 4(t2)                    # store opcode
lbu t3, 12(t1)                  # t3 = rd'/rs1' (compressed)
addi t3, t3, 0b1000             # t3 = rd/rs1 (32-bit)
sw t3, 8(t2)                    # store rd
sw t3, 16(t2)                   # store rs1
lw t3, 16(t1)                   # t3 = imm
slli t3, t3, 26                 # sign-extended imm
srai t3, t3, 26                 # sign-extended imm
sw t3, 28(t2)                   # store imm
j expand_next

ex_BEQZ:
li t3, 0b000                    # funct3 = 0b000
sw t3, 12(t2)                   # store funct3
li t3, 0b1100011                # opcode = 0b1100011
sw t3, 4(t2)                    # store opcode
li t3, 0                        # rs2 = 0
sw t3, 20(t2)                   # store rs2
lbu t3, 10(t1)                  # t3 = rs1' (compressed)
addi t3, t3, 0b1000             # t3 = rs1 (32-bit)
sw t3, 16(t2)                   # store rs1
lw t3, 16(t1)                   # t3 = imm
slli t3, t3, 24                 # sign-extended imm
srai t3, t3, 24                 # sign-extended imm
sw t3, 28(t2)                   # store imm
j expand_next

ex_BNEZ:
li t3, 0b001                    # funct3 = 0b001
sw t3, 12(t2)                   # store funct3
li t3, 0b1100011                # opcode = 0b1100011
sw t3, 4(t2)                    # store opcode
li t3, 0                        # rs2 = 0
sw t3, 20(t2)                   # store rs2
lbu t3, 10(t1)                  # t3 = rs1' (compressed)
addi t3, t3, 0b1000             # t3 = rs1 (32-bit)
sw t3, 16(t2)                   # store rs1
lw t3, 16(t1)                   # t3 = imm
slli t3, t3, 24                 # sign-extended imm
srai t3, t3, 24                 # sign-extended imm
sw t3, 28(t2)                   # store imm
j expand_next

ex_J:
li t3, 0b1101111                # opcode = 0b1101111
sw t3, 4(t2)                    # store opcode
li t3, 0                        # rd = 0
sw t3, 8(t2)                    # store rd
lw t3, 16(t1)                   # t3 = imm
slli t3, t3, 21                 # sign-extended imm
srai t3, t3, 21                 # sign-extended imm
sw t3, 28(t2)                   # store imm
j expand_next

ex_JAL:
li t3, 0b1101111                # opcode = 0b1101111
sw t3, 4(t2)                    # store opcode
li t3, 1                        # rd = 1
sw t3, 8(t2)                    # store rd
lw t3, 16(t1)                   # t3 = imm
slli t3, t3, 21                 # sign-extended imm
srai t3, t3, 21                 # sign-extended imm
sw t3, 28(t2)                   # store imm
j expand_next


expand_next:
j expand_main_loop              # Go to next instruction

end_expand:

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