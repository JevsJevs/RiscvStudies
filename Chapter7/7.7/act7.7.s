.globl _start


.section .bss
putsCharBuffer: .skip 1   #Arbitrarily set size

.section .data
test: .string "this is a null terminated string"

.section .text


_start:
    la a0, test
    jal puts

    li a0, 0
    li a7, 93
    ecall




puts:
#a0 -> 
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
    
    #a0 = 1 -> success    
    ret

    putsError:
    
    li a0, -1
    ret







