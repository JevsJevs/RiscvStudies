.globl _start

.text

.set STATUSGPS, 0xFFFF0100
.set STATUSPROX, 0xFFFF0102
.set PROXDIST, 0xFFFF011c
.set STATUSSTEER, 0xFFFF0120
.set ENGINEDIR, 0xFFFF0121
.set STATUSHB, 0xFFFF0122


_start:
    li a0, 1
    li a1, ENGINEDIR
    sb a0, (a1)

    li a4, 3
    li a3, 2040
    mul a3, a3, a4
    beq a2, a3, outloop  
    li a2,0
    leftloop:
        li a0, -127
        li a1, STATUSSTEER
        sb a0, (a1)
        addi a2, a2, 1
    blt a2, a3, leftloop
    sb zero, (a1)
    outloop:


    j _start



# car starts at 180, 2, -108
# target to reach (15m radius from) 73, 1, -19
turnLeftDeg:
    # la a0, CAR



# Turnleft

# turnright

# forward

# backward

