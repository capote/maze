# io.asm
#
# took these functions out of main to shorten main.
# they read in a maze and print it out.

.globl maze_in
.globl maze_out

PRINTSTR = 4
READINT = 5
READSTR = 8

.text

# takes:
# a0: where to put sizes as height: pos 0 width: pos 4
# a1: where to start storing maze
#
# this function will take our dimensions, store them, and then read in our maze
#	line by line, in one big string.  we know how to go to the next line using
#	the width + 2, consiering null end and newlines.

maze_in:
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)
	
	move $s0, $a0	# copy our params
	move $s1, $a1

	li $v0, READINT
	syscall

	sw $v0, 0($s0)	# save height at 0 of a0
	move $t0, $v0	# t0 | copy it for use in reading maze

	li $v0, READINT
	syscall

	sw $v0, 4($s0)	# save width at 4 of a0
	move $t1, $v0	# t1 | same but add 2 for null and newline
	addi $t1, $t1, 2
	sw $t1, 8($s0)	# save width + 2 (null/nl) at pos 8 for easy access

	move $a0, $s1	# load where to read
	move $a1, $t1	# load number of chars to read

read_next:
	beq $t0, $zero, done_in	# break out if we're done with height
	
	li $v0, READSTR
	syscall

	add $a0, $a0, $t1	# advance the long string over by the total width
	addi $t0, $t0, -1	# decrease counter

	j read_next		# and loop


done_in:
	lw $ra, 8($sp)
	lw $s1, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 12

	jr $ra


# takes:
# a0: size address as height: pos 0, width: pos 4
# a1: beginning of maze
#
# prints out the maze.  pretty straightforward.

maze_out:
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)
	
	lw $s0, 0($a0)	# s0 | load height
	lw $s1, 4($a0)	# s1 | load width

	addi $s1, $s1, 2	# add to print length null and newline
	move $a0, $a1		# switch maze into print arg

print_next:
	beq $s0, $zero, done_out	# exit if height is done

	li $v0, PRINTSTR
	syscall

	add $a0, $a0, $s1	# print next line next
	addi $s0, $s0, -1	# decrease counter

	j print_next

done_out:
	lw $ra, 8($sp)
	lw $s1, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 12

	jr $ra
