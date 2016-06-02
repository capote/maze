maze
====

MIPS text maze solver

note on assembler
-----------------

I used __rasm__ and __[rsim](http://www.cs.rit.edu/~vcss345/documents/rsim.html)__ to test and run this.  It's by [Warren Carithers](http://www.cs.rit.edu/~wrc/), a professor at my school.  As far as I know, it's only compiled for Ubuntu and he doesn't distribute it.  I am not very familiar with the differences in MIPS assemblers, but I guess there's a slight chance it won't work straight up with other tools.  

__You're probably going to need to modify the makefile.__

operation
---------

To run it, I would use: `rsim maze.out`

The program then waits for three inputs.  On the first line, the _height_ of the maze, on the second line, the _width_, and then the following _height_ lines the maze itself.  The maze is composed of the following characters:

+ # (a wall)
+   (a space)
+ S (the starting point)
+ E (the exit)

Subsequently, the program will output the input and its solution with some dull header text!

Here's an example of giving it a maze:

	[george@horses:maze]$ rsim maze.out
	5
	15
	###############
	#           #E#
	# # ### # # # #
	#S#   # # #   #
	###############

And here's an example of an output:

	==============================
	MIPS Maze Solver by George ^.^
	==============================
	
	
	Input Maze:
	
	###############
	#           #E#
	# # ### # # # #
	#S#   # # #   #
	###############
	
	
	Solution:
	
	###############
	#...........#E#
	#.# ### # #.#.#
	#S#   # # #...#
	###############
