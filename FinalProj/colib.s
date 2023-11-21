

.data

testStr: .string "0longString"

strNum: .string "450"

altBuf: .skip 50

buffString: .string "a\n"

.text

# .globl main
# main:
#     la a0, testStr

#     jal puts


.globl set_engine
set_engine:
# int set_engine(int vertical, int horizontal);
    li a7, 10

    #a0 is engineDir, a1 is steeringAngle
    ecall


    ret

.globl read_sensor_distance
read_sensor_distance:
    li a7, 13
    ecall
    ret

.globl get_position
get_position:
    li a7, 15
    ecall
    ret

.globl get_rotation
get_rotation:
    li a7, 16
    ecall
    ret

.globl get_time
get_time:
    li a7, 20
    ecall
    ret

.globl strlen_custom
strlen_custom:
#int strlenCustom(char* str)

    li a2, 0
    strlenCustomLoop:
        lb a1, (a0)
        beqz a1, strlenCustomLoopEnd
        addi a0, a0, 1
        addi a2, a2, 1
        j strlenCustomLoop
    strlenCustomLoopEnd:

    mv a0, a2

    ret

.globl approx_sqrt
approx_sqrt:
#int approxSqrt(int value, int iterations)

    srli a2, a0, 1              #initial guess of sqrt-> k=y/2

    li a4, 0
    sqrtLoop:
        divu a3, a0, a2         #aprox factor -> y/k
        add a2, a2, a3          # k + y/k
        srli a2, a2, 1          #(k+y/k)/2

        addi a4, a4, 1          #iteration counter
    blt a4, a1, sqrtLoop

    mv a0, a2

    ret

.globl get_distance
get_distance:
#int getDistance(int xa, int ya, int za, int xb, int yb, int zb)

    sub a0, a0, a3
    sub a1, a1, a4
    sub a2, a2, a5
    
    mul a0, a0, a0
    mul a1, a1, a1
    mul a2, a2, a2

    add a0, a0, a1
    add a0, a0, a2
    
    addi sp, sp, -4
    sw ra, (sp)

    jal approx_sqrt             # a0-> distance of the points

    lw ra, (sp)
    addi sp, sp, 4

    ret


.globl fill_and_pop
fill_and_pop:
#Node *fill_and_pop(Node *head, Node *fill);

    li a2, 8                    #there are 8 words/fields in the 'Node' struct
    li a3, 0
    fillPopCopyLoop:
        lw a4, (a0)             #swap content of field
        lw a5, (a1)
        sw a4, (a1)
        sw a5, (a0)

        addi a0, a0, 4          #move pointers to next field
        addi a1, a1, 4

        addi a3, a3, 1          
    blt a3, a2, fillPopCopyLoop 

    addi a1, a1, -4             #return to last field of the 'fill' node
    lw a0, (a1)                 #places the 'next' field of the previous 'head' node, currently 'fill' node into return

    ret





//==================================================================================================================
.globl itoa
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
            addi a4, a4, 0x37               #corrects value to [a, f] ascii chars
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


.globl atoi
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


.globl gets
gets:
#char* gets(char* str)
    # addi sp, sp, -8
    # sw ra, (sp)
    # sw a0, 4(sp)


    # la a1, altBuf
    # li a2, 10
    # jal itoa

    # la a0, altBuf
    # jal puts

    # lw ra, (sp)
    # lw a0, 4(sp)
    # addi sp, sp, 8


    mv t0, a0                                   #Copies str start adr
    mv a3, a0                                   #Load str pointer from a0 to a3, making it the buffer for the read syscall

    li a1, 1                                    #a1 = 1 so that 1 byte is read
    li a7, 17

    li a4, 10                                   #temp register to test if char == newline

    la a6, buffer
    getsCharLoop:
        mv a0, a3
        ecall                                   #a0 is byte qty read



        addi zero, zero, 1

        # lb a5, (a3)     #SE REMOVER ISSO MOSTRA OS OUTROS INPUTS
        # addi sp, sp, -40
        # sw ra, (sp)
        # sw a0, 4(sp)
        # sw a1, 8(sp)
        # sw a2, 12(sp)
        # sw a3, 16(sp)
        # sw a4, 20(sp)
        # sw a5, 24(sp)
        # sw a6, 28(sp)
        # sw a7, 32(sp)
        # sw t0, 36(sp)

        # # lb a6, (a3
        # # mv a0, a3
        # # la a1, altBuf
        # # li a2, 16
        # # jal itoa
        # addi a5, a0, 0x30 

        # la a0, altBuf
        # # addi a5, a5, 0x1f
        # sb a5, (a0)
        # sb zero, 1(a0)
        # jal puts



        # lw t0, 36(sp)
        # lw a7, 32(sp)
        # lw a6, 28(sp)
        # lw a5, 24(sp)
        # lw a4, 20(sp)
        # lw a3, 16(sp)
        # lw a2, 12(sp)
        # lw a1, 8(sp)
        # lw a0, 4(sp)
        # lw ra, (sp)
        # addi sp, sp, 40

        # beqz a0, getsCharEndLoopInputEnd        #if no other byte was read break -> nao incr 3



        # beqz a5, getsCharEndLoopNewline              #If eof is reached => null terminator
        beq a5, a4, getsCharEndLoopNewline      #if newline was found end read
        beqz a0, getsCharEndLoopInputEnd        #if no other byte was read break -> nao incr 3
        addi a3, a3, 1
    j getsCharLoop
    getsCharEndLoopInputEnd:
        # addi a3, a3, 1
    getsCharEndLoopNewline:
    
    #tinha um a3 + 1

    # li t6, 0x69
    # sb t6, 0(a3)
    # addi a3, a3, 1

    sb zero, (a3)

    mv a0, t0 

    # addi sp, sp, -8
    # sw ra, (sp)
    # sw a0, 4(sp)

    # li a0, 1
    # li a1, 14
    # li a2, 10
    # li a3, 1 
    # li a4, 0
    # li a5, 3
    # jal get_distance

    # la a1, altBuf
    # li a2, 10
    # jal itoa

    # jal puts

    # lw ra, (sp)
    # lw a0, 4(sp)
    # addi sp, sp, 4
    
    ret


    # mv a2, a0                       #copies buffer adr to a1

    # li a7, 17
    # ecall

    # add a3, a2, a0                 #stores in a2 the eos adr
    
    # sb zero, (a3)                   #null terminates the string

    # mv a0, a2

    # ret

.globl puts
puts:
# void puts ( const char *str );
    addi sp, sp, -8
    sw a0, 4(sp)
    sw ra, (sp)

    jal strlen_custom           #get string length
    mv a1, a0

    lw ra, (sp)
    lw a0, 4(sp)
    addi sp, sp, 8


    add a2, a0, a1              #by the string length we get the end of string position
    li a3, 10
    sb a3, (a2)                 #add \n terminator to string on eos adr

    addi a1, a1, 1              #add the '\n' to the string size so it is written in the ecall

    # mv t1, a0

    li a7, 18
    ecall

    # mv a0, t1

    ret

