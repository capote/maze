# maze.asm
#
# by George Capote
#
# takes an input maze with height, width, and maze drawn with ascii, finds a
#	solution using a depth-first search algorithm, and prints out solution.
#
# the input is given as in the following example:
#
# 5
# 15
# ###############
# #           #E#
# # # ### # # # #
# #S#   # # #   #
# ###############
# 
# the first two lines being the height, and width, and then the maze entered
#	with number signs being walls, S being start, and E being end.
#
# the maze program uses a stack structure with push/pop operation to record
#	moves it makes, keeps track of a facing and location (known as "move")
#	and backtracks through its stack if it hits a dead end.  at every spot
#	it either tries to keep going, or spins around until it finds a new way to
#	go, or backtracks until it finds a spot with ambiguity.

.globl maze_in
.globl maze_out

.globl is_end
.globl look_forward
.globl split_path

.globl maze_record
.globl maze_top

.globl rec
.globl back
.globl backtrack
.globl retrace_maze

# syscall constants
# -----------------
PRINTINT = 1
PRINTSTR = 4

# maze characters
# ---------------
LETTER_S = 83
LETTER_E = 69
NUMBER_SIGN = 35
DOT = 46

.data

# maze size structure
# this will, upon reading, contain a height, width, and width + 2 for use most
#	of the time, considering the null and newline at the end of each line.
# ------------------------------------------------------------------------------
maze_size:
.word 0
.word 0
.word 0

# two mazes with maximum allowed size
# -----------------------------------
maze_1: .space 80*82
maze_2: .space 80*82

# our stack structure, with lots of room.  the maze top starts as the first
#	word in the stack, so its initial value is the first position in the stack
# ----------------------------------------------------------------------------
maze_record: .space 800
maze_top: .word maze_record

# our moves (which here are just addresses of actual parts of the maze)
# ---------------------------------------------------------------------
current_move: .word 0
start_move: .word 0

# text printouts
# --------------
greeting:
.asciiz "==============================\nMIPS Maze Solver by George ^.^\n=============================="

original_top:
.asciiz "Input Maze:\n\n"

solution_top:
.asciiz "\n\nSolution:\n\n"

test_start:
.asciiz "\nSEARCH\n"

test_checked_end:
.asciiz "\nCHECKED END\n"

test_checked_fw_block:
.asciiz "\nCHECKED FW\n"

test_looking_around:
.asciiz "\nLOOKIN AROUND\n"


.text

main:

	la $a0, maze_size		# read the maze size and maze into our space
	la $a1, maze_1
	jal maze_in 

	la $a0, greeting		# print our greeting 
	li $v0, PRINTSTR
	syscall

	la $a0, original_top	# print original maze header
	li $v0, PRINTSTR
	syscall

	la $a0, maze_size
	la $a1, maze_1
	jal maze_out			# and print it out


	la $t0, maze_1			# make a copy of the maze
	la $t1, maze_2
	li $t2, 80*82-1
	move $t5, $zero

copy_loop:
	lb $t3, 0($t0)
	sb $t3, 0($t1)
	addi $t0, $t0, 1
	addi $t1, $t1, 1
	addi $t5, $t5, 1
	bne $t5, $t2, copy_loop

	# here I'm going to find the letter S in the maze

	li $t0, LETTER_S		# t0 | the S we are looking for
	la $t1, maze_size
	la $t4, maze_1			# t4 | the maze
	lw $t2, 4($t1)			# t2 | get the width of the maze
	addi $t2, $t2, 2		# get actual width (null and nl)

goto_start_loop:
	lb $t3, 0($t4)			# t3 | current place in maze
	beq $t3, $t0, goto_start_done

	addi $t4, $t4, 1		# next pos in maze
	j goto_start_loop

goto_start_done:
	la $t5, start_move
	sw $t4, 0($t5)			# store start position to start_move

	# make current move our start move
	la $t0, start_move
	lw $t1, 0($t0)
	la $t0, current_move
	sw $t1, 0($t0)

	la $t1, maze_size	# maze size storage
	lw $t2, 8($t1)		# load pos 8 which is width + nl and null
	sub $s1, $zero, $t2	# get negative width for UP facing into s1

	# OLD INITIAL HEADING
	# li $s1, 1		# s1 | our direction.  we start with 1 
				# (one to the right).  -1 will be to the left,
				# and up and down will be +/- the total width.
				# s1 will always keep the direction for the next
				# move from when we look around for open paths.

				# figured I'd start looking right and not up
				# because it's easier to load it here, and I'm
				# going to be spinning clockwise later down
				# anyway so...

search_loop:
	la $a0, current_move	# load our size and current spot to check if end
	la $a1, maze_size
	jal is_end
	bne $v0, $zero, at_end

	la $a0, current_move	# load current spot and facing to see if blocked
	move $a1, $s1			# if it's blocked, we check other directions for
	jal look_forward		# openings

	beq $v0, $zero, look_around

	# otherwise, our current heading is open, so we can move into it.

	move $s5, $a0			# s5 | our old location

	lw $s4, 0($s5)			# s4 | get our new position to move to by adding our
	add $s4, $s4, $s1		# direction

	sw $s4, 0($s5)			# update our current_loc to it
	jal rec

	li $t4, DOT				# and stick a dot in our old location
	lw $t5, 0($s5)
	sb $t4, 0($t5)

	move $t0, $a0
	lw $t1, 0($t0)			# add our facing to get new position to advance to
	add $t1, $t1, $s1


	j search_loop			# after we've moved into it, we repeat

look_around:

	# here we're going to change our facing until we find an open place.  once 
	# we find one, we restart the process, setting s1 to our new direction.
	
	la $a0, current_move                                                        
        la $t0, maze_size               # doing the spiel again to get the size + null/nl
        lw $t1, 4($t0)                                                              
        addi $t1, $t1, 2                # checking up, - width size                 
        sub $a1, $zero, $t1                                                         
        jal look_forward 

        bne $v0, $zero, found_path  

	la $a0, current_move
	li $a1, 1				# checking right (one over)
	jal look_forward

	bne $v0, $zero, found_path

	la $a0, current_move
	la $t0, maze_size		# doing the spiel again to get the size + null/nl
	lw $t1, 4($t0)
	addi $a1, $t1, 2		# check down, + width size
	jal look_forward

	bne $v0, $zero, found_path

        la $a0, current_move                                                        
        li $a1, -1                      # checking left (-one over)         
        jal look_forward                                                            
                                                                                    
        bne $v0, $zero, found_path   

	la $a0, current_move	# we've hit a dead end.
	la $t0, maze_size
	lw $t1, 4($t0)
	addi $a1, $t1, 2
	jal backtrack			# if we found no path looking around, we back up
	j search_loop			# then start again from the last ambiguous spot


found_path:

	move $s1, $a1		# here, we set our heading to the one we found,
	j search_loop		# then restart the process, where we will move into
						# that spot.

at_end:

	la $a0, maze_1
	la $a1, maze_2
	jal retrace_maze

	la $a0, solution_top
	li $v0, PRINTSTR
	syscall

	la $a0, maze_size
	la $a1, maze_2
	jal maze_out

	li $v0, 10
	syscall



