.globl _start


.data
strBuff: .skip 32
putsCharBuffer: .skip 1

testingString: .string "TestGo"

.text
.set SERIAL_ADR, 0xFFFF0100

_start:
    # la a0, strBuff
    # li a2, SERIAL_ADR
    # jal readSerial

    // debuggind above
    la a0, strBuff
    jal gets
    jal atoi

    jal serialHub

    # la a0, strBuff
    # jal puts

    exit:
    li a0, 0
    li a7, 93
    ecall


serialHub:
#void serialHub(int opCode)

    li a1, 1
    li a2, 2
    li a3, 3
    li a4, 4

    beq a0, a1, op1
    beq a0, a2, op2
    beq a0, a3, op3
    beq a0, a4, op4
    j noOp

    op1:
        # la a0, strBuff
        # li a1, SERIAL_ADR
        # jal readSerial
        addi sp, sp, -4
        sw ra, (sp)

        la a0, strBuff
        jal gets

        lw ra, (sp)
        addi sp, sp, 4

        addi sp, sp, -4
        sw ra, (sp)
        # jal writeSerial
        jal puts
        lw ra, (sp)
        addi sp, sp, 4
    j noOp

    op2:
        # la a0, strBuff
        # li a1, SERIAL_ADR
        # jal readSerial
        addi sp, sp, -4
        sw ra, (sp)

        la a0, strBuff
        jal gets

        lw ra, (sp)
        addi sp, sp, 4

        addi sp, sp, -4
        sw ra, (sp)
        # jal writeSerial
        # jal puts
        jal reverseString
        la a0, strBuff
        jal puts
        lw ra, (sp)
        addi sp, sp, 4
    j noOp

    op3:
        addi sp, sp, -4
        sw ra, (sp)

        la a0, strBuff
        jal gets
        jal atoi

        lw ra, (sp)
        addi sp, sp, 4

        addi sp, sp, -4
        sw ra, (sp)

        la a1, strBuff
        li a2, 16
        jal itoa

        lw ra, (sp)
        addi sp, sp, 4

        addi sp, sp, -4
        sw ra, (sp)

        la a0, strBuff
        jal puts

        lw ra, (sp)
        addi sp, sp, 4
    j noOp

    op4:
        addi sp, sp, -4
        sw ra, (sp)

        la a0, strBuff
        jal gets
        
        jal arithmeticOperation

        lw ra, (sp)
        addi sp, sp, 4

        addi sp, sp, -4
        sw ra, (sp)

        la a1, strBuff
        li a2, 10
        jal itoa

        jal puts

        lw ra, (sp)
        addi sp, sp, 4

    noOp:

    ret

readSerial:
#char* readSerial(char* str, int serialAdr)
    mv a3, a0                       #stores pointer to end of string

    li a4, 10
    readSerialLoop:
        li t1, 1
        sb t1, 2(a1)
        readSerialBW:
            lb t1, 2(a1)
            lb t4, 3(a1)
        bnez t1, readSerialBW
        lb t2, 3(a1)                #reads ready serial byte
        sb t2, 0(a3)                #stores in end of string
        addi a3, a3, 1              #increment eos adr

    beq t2, t4, readSerialLoopEnd   #if byte read == "\n" stop reading
    bne t2, zero, readSerialLoop    #if byte read != "\0" read next byte
    readSerialLoopEnd:

    lb zero, (a3)

    ret

writeSerial:
#void writeSerial(char* str, int serialAdr)
    mv a3, a0                       #eos pointer

    writeSerialLoop:
        lb t1, 0(a3)                #load string char
        sb t1, 1(a1)                #stores char on serial buffer
        li t2, 1                    
        sb t2, 0(a1)                #prepares and loads 1 into write register of serial
        writeSerialBW:
            lb t2, 0(a1)            #checks if serial register is 0, meaning byte was written
        bnez t2, writeSerialBW
        addi a3, a3, 1              #increments eos adr
    bne t1, zero, writeSerialLoop   #if last written byte was '\0' stop the loop

    ret



arithmeticOperation:
#int arithmeticOperation(char* str) => strFormat "numberOnumber" where O is one of +, -, *, /

    mv a3, a0                       #string char pointer

    li t1, 0x2a
    li t2, 0x2b
    li t3, 0x2d
    li t4, 0x2f
    arithmOperLoop:
        lb a1, 0(a3)
        beq a1, t1, IfIsOperand
        beq a1, t2, IfIsOperand
        beq a1, t3, IfIsOperand
        bne a1, t4, EndIfIsOperand
        IfIsOperand:
            mv a5, a1               # copies the signal
            sb zero, 0(a3)
            mv a4, a3
            addi a4, a4, 1          # stores in a4, the adr of the second number string
            j arithmOperLoopEnd
        EndIfIsOperand:
        addi a3, a3, 1
    j arithmOperLoop
    arithmOperLoopEnd:

    #this loop changes the \n to \0 terminator to 
    mv a3, a4
    li t5, 10 
    secondNumToStrLoop:
        lb a1, (a3)
        bne a1, t5, secondNumStrIfEOL
            sb zero, (a3)
            j secondNumToStrLoopEnd
        secondNumStrIfEOL:
        addi a3, a3, 1
        j secondNumToStrLoop
    secondNumToStrLoopEnd:

    addi sp, sp, -16
    sw ra, (sp)
    sw a0, 4(sp)
    sw a4, 8(sp)
    sw a5, 12(sp)
    
    #a0 = firstStr adr
    jal atoi
    #-> a0 = first number

    lw a5, 12(sp)
    lw a4, 8(sp)
    # sw a0, 4(sp)
    lw ra, (sp)
    addi sp, sp, 16

    addi sp, sp, -16
    sw ra, (sp)
    sw a0, 4(sp)
    sw a4, 8(sp)
    sw a5, 12(sp)

    mv a0, a4                       #Second string adr to arg 0
    jal atoi
    mv a1, a0                       #second number to a1

    lw a5, 12(sp)
    lw a4, 8(sp)
    lw a0, 4(sp)
    lw ra, (sp)
    addi sp, sp, 16

    li t2, 0x2b                     # + 
    li t3, 0x2d                     # -
    li t1, 0x2a                     # *
    li t4, 0x2f                     # /
    beq a5, t2, opAdition
    beq a5, t3, opSubtraction
    beq a5, t1, opMultiplication
    beq a5, t4, opDivision
    j opEnd

    opAdition:
        add a0, a0, a1
    j opEnd

    opSubtraction:
        sub a0, a0, a1
    j opEnd

    opMultiplication: 
        mul a0, a0, a1
    j opEnd

    opDivision: 
        div a0, a0, a1


    opEnd:
    
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
    sb zero, 0(a1)                           #null terminates string

    mv a0, t1                               #retrieves to a0, the string absolute start adr

    addi sp, sp, -12
    sw a1, 8(sp)
    sw a0, 4(sp)
    sw ra, 0(sp)

    mv a0, t2
    jal reverseString

    lw ra, 0(sp)
    lw a0, 4(sp)
    lw a1, 8(sp)
    addi sp, sp, 12

    ret


reverseString:
# void reverseString(char* startAdr)
    mv a1, a0
    findLastCharLoop:
        lb t1, (a1)
        beqz t1, findLastCharLoopEnd
        addi a1, a1, 1
        bltz a1, findLastCharLoopEnd        #if end not found quit loop after ovf
        j findLastCharLoop
    findLastCharLoopEnd:
    addi a1, a1, -1


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
