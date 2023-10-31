# .globl _start
.globl recursive_tree_search
.globl atoi
.globl itoa
.globl gets
.globl puts
.globl exit

.section .data
head_node:_start:
#     la a0, head_node
#     li a1, -798
#     jal recursive_tree_search

    
#     la a1, buffer
#     li a2, 10
#     jal itoa

#     jal puts
    

#     jal exit
    .word 12
    .word node2
    .word node3


node2:
    .word 5
    .word node4
    .word node5

node3:
    .word -78
    .word 0x0
    .word node6

node4:
    .word -43
    .word 0x0
    .word 0x0

node5:
    .word 361
    .word 0x0
    .word 0x0

node6:
    .word 562
    .word node7
    .word node8

node7:
    .word 9
    .word 0x0
    .word 0x0

node8:
    .word -798
    .word 0x0
    .word 0x0

buffer: .skip 33
putsCharBuffer: .skip 1
.section .text

exit:
li a7, 93
ecall

# _start:
#     la a0, head_node
#     li a1, -798
#     jal recursive_tree_search

    
#     la a1, buffer
#     li a2, 10
#     jal itoa

#     jal puts
    

#     jal exit



recursive_tree_search:
# int recursive_tree_search(Node* rootNode, int val)    w.c O(n)
li a2, 1
addi sp, sp, -4
sw ra, 0(sp)
jal rts_recursion
lw ra, 0(sp)
addi sp, sp, 4

ret

rts_recursion:
# int recursive_tree_search(Node* rootNode, int val, int depth)
    lw a3, 0(a0) 
    lw a4, 4(a0)
    lw a5, 8(a0)

    bnez a0, rtsNullNodeEndIf
        li a0, 0
        ret
    rtsNullNodeEndIf:

    bne a3, a1, rtsValueFoundEndIf
        mv a0, a2                       #set return variable to current depth
        ret 
    rtsValueFoundEndIf:

    addi sp, sp, -20
    sw a5, 16(sp)
    sw a4, 12(sp)
    sw a3, 8(sp)
    sw a2, 4(sp)
    sw ra, 0(sp)


    mv a0, a4
    #a1 remains val
    addi a2, a2, 1
    jal rts_recursion                   #if value != 0 save
    seqz a6, a0                         #a6 = 1 if returned 0

    lw ra, 0(sp)
    lw a2, 4(sp)
    lw a3, 8(sp)
    lw a4, 12(sp)
    lw a5, 16(sp)

    addi sp, sp, 20


    beqz a6, rstFoundOnLeftBranch
        addi sp, sp, -8
        sw a2, 4(sp)
        sw ra, 0(sp)


        mv a0, a5
        addi a2, a2, 1
        jal rts_recursion

        lw ra, 0(sp)
        lw a2, 4(sp)
        addi sp, sp, 8
    rstFoundOnLeftBranch:
ret



itoa:
#char* itoa(int val, char* str, int base)
#This implementation assumes base = 10 || base = 16 only

    mv t1, a1                       #stores str absolute start adr

    li a4, 10
    bne a2, a4, itoaBaseNot10
        bgez a0, itoaSignedNotNegative
            li a4, -1
            mul a0, a0, a4 
            li a4, 0x2d
            sb a4, 0(a1)
            addi a1, a1, 1
        itoaSignedNotNegative:
    itoaBaseNot10:

    li a5, 10
    mv t2, a1                               #saves first digit char adr to reverse
    itoaParsingLoop:
        remu a4, a0, a2
        blt a4, a5, itoaIfDecimalDigitThen  #if remainder > 10
            addi a4, a4, 0x57               #corrects value to [a, f] ascii chars
            j itoaIfDecimalDigitEndIf
        itoaIfDecimalDigitThen:             #else
            addi a4, a4, 0x30               #corrects value to [0, 9] ascii chars
        itoaIfDecimalDigitEndIf:
        
        divu a0, a0, a2

        sb a4, 0(a1)
        addi a1, a1, 1
    bnez a0, itoaParsingLoop

    mv a0, t1                               #retrieves to a0, the string absolute start adr

    addi sp, sp, -8
    sw a1, 8(sp)
    sw a0, 4(sp)
    sw ra, 0(sp)

    mv a0, t2
    addi a1, a1, -1
    jal reverseString
    addi a1, a1, 1

    lw ra, 0(sp)
    lw a0, 4(sp)
    lw a1, 8(sp)
    addi sp, sp, 8

    sb zero, 0(a1)                          #null terminates string
    ret    

reverseString:
# void reverseString(char* startAdr, char* endAdr)
    reverseStringLoop:
        blt a1, a0, reverseStringLoopEnd
        beq a0, a1, reverseStringLoopEnd
        lb t1, 0(a0)
        lb t2, 0(a1)
        sb t2, 0(a0)
        sb t1, 0(a1)
        addi a0, a0, 1
        addi a1, a1, -1
        j reverseStringLoop
    reverseStringLoopEnd:

    ret

atoi:
#int atoi(const char* str)
    mv a1, a0
    atoiWSloop:
        addi sp, sp, -8
        sw a1, 4(sp)
        sw ra, 0(sp)

        lb a0, 0(a1)
        
        jal isspace

        mv t1, a0
        
        lw ra, 0(sp)
        lw a1, 4(sp)
        addi sp, sp, 8

        beqz t1, atoiOptionalSign
        addi a1, a1, 1
        j atoiWSloop
    atoiWSEndLoop:

    #optional plus minus
    atoiOptionalSign:
    li a2, 0x2d         #'-' char ascii
    li a3, 0x2b         #'+' char ascii
    li t1, 1            #final num to multiply

    lb a0, 0(a1) 
    bne a0, a2, atoiIfOptionalSign  
        #if char read == '-' then t1 = -1 (will multiply final number by this register) 
        li t1, -1
        addi a1, a1, 1
        j atoiIfOptionalSignEndIf
    atoiIfOptionalSign:
    bne a0, a3, atoiIfOptionalSignEndIf
        addi a1, a1, 1
    atoiIfOptionalSignEndIf:

    mv a2, a1
    li a3, 0x30
    li a4, 0x3A
    li t2, 1
    li t3, 10

    atoiDigitCounterLoop:
        lb a0, 0(a1)
        blt a0, a3, atoiDigitCounterLoopEnd
        bge a0, a4, atoiDigitCounterLoopEnd
        addi a1, a1, 1
        mul t2, t2, t3                      #For each char passed
        j atoiDigitCounterLoop
    atoiDigitCounterLoopEnd:
    div t2, t2, t3                          #correction because extra multiplication


    li a0, 0
    mv a1, a2                               #retrieve into a1 digit seqence start
    atoiCharToIntLoop:
        beqz t2, atoiCharToIntLoopEnd
        lb a2, 0(a1)
        addi a2, a2, -0x30
        mul a2, a2, t2                      #val = di * pow
        add a0, a0, a2
        div t2, t2, t3                      #pow = pow/10 
        addi a1, a1, 1
        j atoiCharToIntLoop
    atoiCharToIntLoopEnd:

    mul a0, a0, t1
    ret

isspace:
#int isspace(int c)
    li a1, 0x20
    li a2, 0x9
    li a3, 0xa
    li a4, 0xb
    li a5, 0xc
    li a6, 0xd
    
    beq a0, a1, isWhiteSpace
    beq a0, a2, isWhiteSpace
    beq a0, a3, isWhiteSpace
    beq a0, a4, isWhiteSpace
    beq a0, a5, isWhiteSpace
    beq a0, a6, isWhiteSpace

    li a0, 0
    ret

    isWhiteSpace:
    li a0, 1
    ret

gets:
#char* gets(char* str)
    li t2, 10           #temp register to test if char == newline
    mv t0, a0           #Copies str start adr
    mv a1, a0           #Load str pointer from a0 to a1, making it the buffer for the read syscall
    li a2, 1
    li a7, 63
    getsCharLoop:
        li a0, 0        #Cleans ecall return and sets file descriptor to stdin
        ecall
        lb t1, 0(a1)

        addi a1, a1, 1

        beqz t1, getsCharEndLoop
        beq t1, t2, getsCharEndLoop
        j getsCharLoop
    getsCharEndLoop:
    
    sb zero, 0(a1)

    mv a0, t0 
    
    ret

puts:
#void puts(char* str)
    mv a4, a0

    li a0, 1
    la a1, putsCharBuffer
    li a2, 1
    li a7, 64
    putsOutLoop:
        #load current char to print
        lb a5, 0(a4)

        #check validity of char
        blt a5, zero, putsError
        beq a5, zero, putsOutEndLoop

        #stores char in buffer
        sb a5, 0(a1)

        #prints
        ecall

        addi a4, a4, 1
        j putsOutLoop
    putsOutEndLoop:

    #prints EOL
    li a5, 10
    sb a5, 0(a1)
    ecall
    
    li a0, 0x0
    ret

    putsError:

    li a0, 0x0
    ret
