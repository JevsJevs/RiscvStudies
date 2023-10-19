.globl _start


.section .bss
putsCharBuffer: .skip 1   #Arbitrarily set size
getsBuffer: .skip 512

.section .data
# test: .string "this is a null terminated string"
#TEST CASES ATOI
# test: .string "    123af"
test: .string "-123g"
# test: .string "+111"
# test: .string "121"
# test: .string "aaa"
# test: .string " -ho"
#TEST CASES ITOA
# test: .string "                                 "

.section .text


_start:
    la a0, test
    jal puts

    li a0, 0
    li a7, 93
    ecall

itoa:
#char* itoa(int val, char* str, int base)
#This implementation assumes base = 10 || base = 16 only

    mv t1, a1                       #stores str absolute start adr
    li a4, 16
    bne a2, a4, itoaBaseNot16 
        #Sets str first digits to "0x"
        li a4, 0x30
        sb a4, 0(a1) 
        li a4, 0x78
        sb a4, 1(a1) 
        addi a1, a1, 2
    itoaBaseNot16:

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
    li a0, 0
    li a2, 1
    li a7, 63
    getsCharLoop:
        ecall
        lb t1, 0(a1)

        addi a1, a1, 1

        beqz t1, getsCharEndLoop
        beq t1, t2, getsCharEndLoop
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







