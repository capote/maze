# tools.asm
#
# contains tools for looking around, checking the spot ahead, checking if we're
#	at the end, storing and backtracking from the maze_record

.globl is_end
.globl look_forward
.globl split_path

.globl backtrack

.globl retrace_maze
.globl copy_maze

.globl maze_record
.globl maze_top


# maze characters
# ---------------
LETTER_S = 83
LETTER_E = 69
NUMBER_SIGN = 35
DOT = 46

.data

# an address for storing prior moves when retracing the whole maze
# ----------------------------------------------------------------
some_address:
.word 0

.text

# takes:
# a0: address of the current move (position)
# a1: address of the size of the maze
# returns:
# v0: true if there's an end adjacent to current move
#
# checks if there's a letter E around our current position

is_end:
	addi $sp, $sp, -20
	sw $ra, 16($sp)
	sw $s3, 12($sp)
	sw $s2, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)

	move $s0, $a0
	move $s1, $a1

		
	lw $s2, 4($s1)			# s2 | width of maze for lookin' around
	addi $s2, $s2, 2		#	(add 2 for null/nl)
	li $s3, LETTER_E		# s3 | the letter E for end

	lw $t0, 0($s0)
	lb $t1, 1($t0)			# check to the right (one over from position in maze)
	beq $s3, $t1, end_found

	lw $t0, 0($s0)
	lb $t1, -1($t0)			# check to the left (-one over)
	beq $s3, $t1, end_found

	lw $t0, 0($s0)
	add $t0, $t0, $s2
	lb $t1, 0($t0)			# check down (width to the right)
	beq $s3, $t1, end_found

	lw $t0, 0($s0)
	sub $t0, $t0, $s2
	lb $t1, 0($t0)			# check up (-width to the left)
	beq $s3, $t1, end_found

	li $v0, 0
	j is_end_done

end_found:
	li $v0, 1

is_end_done:

	lw $ra, 16($sp)
	lw $s3, 12($sp)
	lw $s2, 8($sp)
	lw $s1, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 20

	jr $ra

# takes:
# a0: pointer to memory address of current location
# a1: which direction we're looking in.  the direction is taken, as throughout
#   the program, as -1/1 for left/right, and -width/+width for up or down
#   (which correspond to the actual locations of the data in the maze)
# returns:
# v0: true if path exists ahead
#
# just checks if there exists a path ahead of the current position/facing
# by making sure there's no pound sign in front.

look_forward:
	addi $sp, $sp, -20
	sw $ra, 16($sp)
	sw $s3, 12($sp)
	sw $s2, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)

	move $s0, $a0
	move $s1, $a1

	lw $s2, 0($s0)
	add $s3, $s2, $s1	# find the new spot by adding the facing to the current
	lb $s2, 0($s3)		# load whatever's in that spot

	slti $v0, $s2, NUMBER_SIGN	# if it's less than the number sign, it's none
					# of the characters possible in the maze.

	lw $ra, 16($sp)
	lw $s3, 12($sp)
	lw $s2, 8($sp)
	lw $s1, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 20

	jr $ra

# takes:
# a0: the address of the move to check.
# a1: the length of a row, including newline and null, to know how to look up
#	and down
# returns:
# v0: true if it's a split path
#
# this will look around and check if there's another path.  if it finds a space
#	it returns true.  there are dots in the place we already checked, so it'll
#	only return true if there's ANOTHER path.

split_path:
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)

	move $s1, $a1
	li $s0, 1 			# to compare forward output
	
	jal look_forward	# we start by checking down.  a1 is already the width.
	beq $v0, $s0, is_split

	sub $a1, $zero, $s1	# we check up, just negative width.
	jal look_forward
	beq $v0, $s0, is_split

	li $a1, -1 			# check left, -1
	jal look_forward
	beq $v0, $s0, is_split

	li $a1, 1 			# check right, +1
	jal look_forward
	beq $v0, $s0, is_split

	li $v0, 0			# 0 if we get here
	j done_split

is_split:
	li $v0, 1 			# 1 if it's split path

done_split:

	lw $ra, 8($sp)
	lw $s1, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 12

	jr $ra

# takes:
# a0: as usual, a location of our current move
# a1: the width of the maze including newline and null
#
# this just continually backs up in our maze calling split_path until it finds
#	a split path.  it's called when we hit a dead end so we can "backtrack"

backtrack:
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)

	move $s1, $a1		# save width because it gets lost by split_path

back_up:
	jal back 		# we start with the location we get in arg

	move $a1, $s1		# we need to put our width back in every loop
	jal split_path
	beq $v0, $zero, back_up	# keep backing up until we hit a split path

	jal rec 		# we then record our new position (which is a0 now)
				# 	to the top of the stack. 
	lw $ra, 8($sp)
	lw $s1, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 12

	jr $ra

# takes:
# a0: the copy of our maze we were working on
# a1: the original maze, to copy dots into
#
# retraces our steps from the record and puts dots in the empty maze, because
#	the maze we were working in is probably full of pesky dots everywhere we
#	tried to go

retrace_maze:
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)

	sub $s0, $a1, $a0	# s0 | the difference between mazes, 
				#	to know where to copy

next_moveback:
	la $a0, some_address	# we need to store our prior move somewhere
				#	not in the real maze
	jal back

	lw $s1, 0($a0)			# check what's in that move
	beq $s1, $zero, done_retrace	# if we've hit the bottom of our stack
					#	(no move value) we're done

	li $t0, DOT 		# otherwise, s1 is a move which we have to 
	add $s1, $s1, $s0	#	store a dot in.  we add the difference
	sb $t0, 0($s1)		#	so that we store the dot in the fresh
				#	maze
	j next_moveback

done_retrace:
	lw $ra, 8($sp)
	lw $s1, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 12

	jr $ra

# takes:
# a0: an address to a move.  the move is actually a location in the maze, so
#   this is really an address an address to a character somewhere... but it's
#   a unique identifier of a location at which we were.
# 
# this records a move to our maze record.  it is a push function to the stack.

rec:
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)

	la $s0, maze_top	# s0 | load where the top of the maze stack is
	lw $s1, 0($s0)

	addi $s1, $s1, 4	# increase the stack size
	sw $s1, 0($s0)		# store it back

	lw $s0, 0($a0)		# and save our new move to it
	sw $s0, 0($s1)

	lw $ra, 8($sp)
	lw $s1, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 12

	jr $ra

# takes:
# a0: an address where to put the move we are recalling.  we're recalling an
#   address to a character, and we're going to store that address at a0.
#
# this rewinds back a move from our maze record.  it's a pop function.

back:
	addi $sp, $sp, -16
	sw $ra, 12($sp)
	sw $s2, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)

	la $s0, maze_top	# s0 | load top of maze stack
	lw $s1, 0($s0)

	lw $s2, 0($s1)		# grab the move and store it
	sw $s2, 0($a0)

	addi $s1, $s1, -4	# lower top of maze
	sw $s1, 0($s0)

	lw $ra, 12($sp)
	lw $s2, 8($sp)
	lw $s1, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 16

	jr $ra
