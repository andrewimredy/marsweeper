#Andrew Imredy
#api5 Project 1


.eqv  BOARD_SIZE 25
.eqv  BOARD_WIDTH 5
.eqv  BOARD_HEIGHT 5
.eqv  N_MINES 5

.data
	debug:  	.word 0
	first_time:	.word 1
	welcome:	.asciiz "Welcome to Marsweeper	, a GUI-free Minesweeper \n"
	explanation:	.asciiz "You must enter the coordinates of a tile to select it. You get 1 point for each tile selected without a mine.\n"
	prompt_row:	.asciiz "Please select the row to reveal: "
	prompt_col:	.asciiz "Please select the column to reveal: "
	invalid_error:	.asciiz "Your selection is invalid. \n"
	win:		.asciiz "Congrats, you won! \n"
	lose:		.asciiz "BOOM! You lose.\n"
	score:		.asciiz "Your score is: "
	line_break:	.asciiz "\n"
	space:		.asciiz " "
	border:		.asciiz "|"
	border_horiz:	.asciiz "  -------------"
	asterisk:	.asciiz "*  " 
	placeholder: 	.asciiz "o  "
	board:		.word 0:BOARD_SIZE
	reveal_status:	.word 0:BOARD_SIZE
	pdb:		.asciiz "got to here!"
	mine:		.asciiz "spawning mine"
	m:		.asciiz "M"

.text
.globl main
main:
	jal	print_welcome
	#find winning # of reveals
	li t0, BOARD_SIZE
	subi s6, t0, N_MINES
_main_loop:
	#find winning # of reveals
	li t0, BOARD_SIZE
	subi s6, t0, N_MINES
	jal	print_board
	jal	ask_user_input
	#RETURNS row v0, col v1
	# If not first, skip generate
	lw t0, first_time
	beq t0, 0, skip_generate 
		jal generate_board
	skip_generate:
	jal	check_for_mine
	j	_main_loop


#Prints out the welcome message
print_welcome:
	la a0, welcome #print(welcome)
	li v0, 4
	syscall
	la a0, explanation #print(explanation)
	syscall
	jr ra

#Prints the board
print_board:
	push ra
	#PRINT HEADER
	#for (int i = 0; i < width; i++) {print(i)}
	li t0, 0
	header_loop_top:
		bge t0, BOARD_WIDTH, carry_on1 #if i < width
		la a0, space
		li v0, 4 
		syscall #print space to make it look nice
		syscall
		li v0, 1
		move a0, t0
		syscall #print number
		addi t0, t0, 1 #increment i
		j header_loop_top
	carry_on1:
		la a0, line_break #print new line
		li v0, 4
		syscall
		la a0, border_horiz #print border
		syscall
		la a0, line_break
		syscall

	#PRINT ROWS
	#for (int i = 0; i < length; i++) {print row number and each tile in it}
	li t0, 0 # i = 0
	row_loop_top:
		bge t0, BOARD_HEIGHT, carry_on2
		#print row header
		li v0, 1
		move a0, t0
		syscall
		#print border
		li v0, 4
		la a0, border
		syscall
		
		
		#print TILES
		#FOR LOOP i < width
		li t1, 0 #j=0	
		#check for debug mode
		lw t9, debug
		beqz t9, tile_print_loop #if not debug, print regular
		#else print special
		debug_tile_print_loop:
			#while not at end of row
			bge t1, BOARD_WIDTH, end_tile_loop_debug
			#IF  REVEALED, PRINT *
			#get revealed status
			move a2, t0
			move a3, t1
			jal was_revealed
			#if revealed, print asterisk 
			bgtz v1, print_asterisk_debug
			#otherwise print clue or mine
			jal get_tile
			bltz v1, print_mine
				move a0, v1
				li v0, 1
				syscall
				j print_space
			print_mine:
			la a0, m
			li v0, 4
			syscall
			#and print spaces
			print_space:
			la a0, space
			li v0, 4
			syscall 
			syscall
			j printed_value_debug
			print_asterisk_debug:
				la a0, asterisk
				li v0, 4
				syscall
			printed_value_debug:
			addi t1, t1, 1 #j++
			j debug_tile_print_loop
		end_tile_loop_debug:		
		#print line break
		la a0, line_break
		li v0, 4
		syscall
		
		addi t0, t0, 1 #increment i
		j row_loop_top
		
		tile_print_loop:
			#while not at end of row
			bge t1, BOARD_WIDTH, end_tile_loop
			#IF NOT REVEALED, PRINT *
			#get revealed status
			move a2, t0
			move a3, t1
			jal was_revealed
			#if not revealed, print asterisk 
			beqz v1, print_asterisk
			#otherwise print clue
			jal get_tile
			bgez v1, not_mine_print #if its a mine print M
				la a0, m
				li v0, 4
				syscall
				j print_spaces
			not_mine_print:
			move a0, v1
			li v0, 1
			syscall
			print_spaces: 
			la a0, space
			li v0, 4
			syscall 
			syscall
			j printed_value
			print_asterisk:
				la a0, asterisk
				li v0, 4
				syscall
			printed_value:
			addi t1, t1, 1 #j++
			j tile_print_loop
		end_tile_loop:		
		#print line break
		la a0, line_break
		li v0, 4
		syscall
		
		addi t0, t0, 1 #increment i
		j row_loop_top
	carry_on2:
	#return 
	pop ra
	jr ra


#RETURNS row a2, col a3.... i know returns should use v registers but this is the convention everything uses.. 
ask_user_input: #yay abstraction
	push ra
	jal get_row
	jal get_col
	pop ra
	jr ra


get_row:
	#get row input
	la a0, prompt_row #print(prompt_row)
	li v0, 4
	syscall
	li v0, 5
	syscall #v0 = input
	
	#check for valid input
	bltz v0, invalid_row
	bgt v0, BOARD_HEIGHT, invalid_row
	
	#case: valid input
	move a2, v0
	jr ra
		
	#case: invalid input
	invalid_row:
		la a0, invalid_error #print error
		li v0, 4
		syscall
		j get_row
		
get_col:
	#get col input
	la a0, prompt_col #print(prompt_col)
	li v0, 4
	syscall
	li v0, 5
	syscall #v0 = input
	
	#check for valid input
	bltz v0, invalid_col
	bgt v0, BOARD_WIDTH, invalid_col
	
	#case: valid input
	#store col in a3
	move a3, v0
	jr ra
		
	#case: invalid input
	invalid_col:
		la a0, invalid_error #print error
		li v0, 4
		syscall
		j get_col

#populates the board with mines and clues
generate_board:	
	push ra
	#first things first, reveal that tile the user selected. 
	#row a2, col a3
	jal reveal_tile
	
	#since this is the first reveal, initialize score to 1
	li s7, 1 #s7 is the score counter
	#SPAWN THEM MINES
	#For (i = 0; i < N_MINES; i++)
	li t0, 0
	mine_spawn_loop:
		bge t0, N_MINES, make_clues #while there are mines to go:
		#generate random location for mine. a2 = row, a3 = col
		li v0, 42
		li a0, 0
		li a1, BOARD_HEIGHT 
		syscall #yields rand int in a0
		move a2, a0 #store it in a2
		
		li v0, 42
		li a0, 0
		li a1, BOARD_WIDTH 
		syscall #yields rand int in a0
		move a3, a0 #store it in a3
		
		#check that space isn't already filled with mine or first selection
		jal was_revealed #v1 holds revealed status. if 1, go back to top
		bgtz v1, mine_spawn_loop
		
		#otherwise, create a mine at the location
		jal spawn_mine
		addi t0, t0, 1
		j mine_spawn_loop
	#SPAWN THEM CLUES
	make_clues:
		#loop thru each row and col (for i, for j)
		li a2, 0
		clues_row_loop:
		bge a2, BOARD_HEIGHT, generate_board_return #once done rows, exit function
			li a3, 0
			clues_col_loop:
			bge a3, BOARD_WIDTH, exit_col_loop #once cols done, go back to row loop
				#if it's a mine, skip it
				jal get_tile #look at value of tile
				bltz v1, skip_tile #if its a mine, skip it#otherwise, spawn a clue
					jal spawn_clue #pass in row: a2, and col: a3
				skip_tile:
			addi a3, a3, 1 #col++
			j clues_col_loop
			exit_col_loop:
		addi a2, a2, 1 #row++
		j clues_row_loop
		
	generate_board_return:
	#set first_time to 0
	li t9, 0
	sw t9, first_time
	#return
	pop ra
	jr ra

spawn_mine: #(int row a2, int col a3)
	push ra
	li a1, -1 #-1 signifies mine. pass into set_tile
	jal set_tile
	pop ra
	jr ra

spawn_clue: #takes row a2 and col a3, sets tile to clue by checking for mines around it
	push ra
	push a3
	push a2
	li s1, 0 #s1 = total adjacent mines
	
	#i couldn't get this to work in a loop, so we check each tile manually
	check_top_left:
	subi, a2, a2, 1 #move to top left
	subi, a3, a3, 1
	#check that tile exists. if not, goto next
	bltz a2, check_top_middle #check row. 
	bltz a3, check_top_middle #check col
	#if tile exists, check for mine
	jal get_tile #value in v1
	bgez v1, check_top_middle #if v1 >= 0, goto next tile
		addi s1, s1, 1 #clue++
	
	check_top_middle:
	#move one to the right
	addi, a3, a3, 1 #col++
	jal get_tile
	bgez v1, check_top_right
		addi s1, s1, 1 #clue++
	
	check_top_right:
	#move one to the right
	addi, a3, a3, 1 #col++
	#check existance
	bge a3, BOARD_WIDTH, check_left
	jal get_tile
	bgez v1, check_left
		addi s1, s1, 1 #clue++
	
	check_left:
	#move one down
	addi a2, a2, 1
	#move two left
	subi a3, a3, 2
	#no need to check row, but check col
	bltz a3, check_right
	jal get_tile
	bgez v1, check_right
		addi s1, s1, 1 #clue++
	
	check_right:
	#move two right
	addi a3, a3, 2
	#check col. no need to check row
	bge a3, BOARD_WIDTH, check_bot_left
	jal get_tile
	bgez v1, check_bot_left
		addi s1, s1, 1 #clue++
	
	check_bot_left:
	#move one down
	addi a2, a2, 1
	#move two left
	subi, a3, a3, 2
	#check row. can skip all bottom checks
	bge a2, BOARD_HEIGHT, gtfo
	#check col
	bltz a3, check_bot_middle
	jal get_tile
	bgez v1, check_bot_middle
		addi s1, s1, 1 #clue++
	
	check_bot_middle:
	#move one right
	addi a3, a3, 1
	#no need to check
	jal get_tile
	bgez v1, check_bot_right
		addi s1, s1, 1 #clue++
	
	check_bot_right:
	#move one right
	addi a3, a3, 1
	#check col
	bge a3, BOARD_WIDTH, gtfo
	jal get_tile
	bgez v1, gtfo
		addi s1, s1, 1 #clue++

	gtfo:
	#sets value of original tile
	move a1, s1
	pop a2
	pop a3
	jal set_tile
	pop ra
	jr ra

reveal_tile: #row a2, col a3
	#Set reveal status to 1
	#t5: steps from row t6 steps from col
	mul t5, a2, BOARD_WIDTH #t5 = width*row
	mul t5, t5, 4 #t5 = steps to nth row
	mul t6, a3, 4 #t6= steps from beginning of row
	add t5, t5, t6 #t5 = total offset
	li t7, 1
	la t4, reveal_status
	add t4, t4, t5 #t4 = address of tile status box
	sw t7, 0(t4) #status = 1
	jr ra

#returns revealed status (1 or 0) in v1. row a2, col a3
was_revealed: 
	push ra
	#matrix address calc same as above
	mul t5, a2, BOARD_WIDTH
	mul t5, t5, 4
	mul t6, a3, 4
	add t5, t5, t6 #t5 = total offset
	la t4, reveal_status
	add t4, t4, t5 #t4 = address of status
	lw v1, 0(t4)
	pop ra
	jr ra
	
get_tile: #given row a2 and col a3, returns tile value in v1
	#t5: extra steps from row
	#t6: extra steps from col
	mul t5, a2, BOARD_WIDTH # t5 = WIDTH*row
	mul t5, t5, 4 # 4 bytes/word. now we're in the right row
	mul t6, a3, 4 #we've got the col steps
	add t5, t5, t6 #t5 = extra seps
	la t4, board
	add t4, t4, t5 #t4 = address of tile
	lw v1, 0(t4) #v1 = value in tile
	jr ra

set_tile: #sets value of (row a2, col a3) to a1
	#t5: extra steps from row
	#t6: extra steps from col
	push ra
	mul t5, a2, BOARD_WIDTH # t5 = WIDTH*row
	mul t5, t5, 4 # 4 bytes/word. now we're in the right row
	mul t6, a3, 4 #we've got the col steps
	add t5, t5, t6 #t5 = extra seps
	la t4, board
	add t4, t4, t5 #t4 = address of tile
	sw a1, 0(t4)
	pop ra
	jr ra
	
	
check_for_mine: #takes row a2, col a3, if there's a mine there, triggers lose. Otherswise, sets tile to revealed and increments score
	push ra
	jal get_tile #implicit pass of a2, a3
	bltz, v1, is_a_mine 
	#CASE: NOT A MINE
		#set tile to revealed
		jal reveal_tile
		#increment score
		addi s7, s7, 1
		#if all tiles have been revealed, trigger win
		ble s7, s6, go_on_no_win
			j print_win_and_exit
		#return
		go_on_no_win:
		j return_check_for_mine
	is_a_mine:
		#if it is a mine. print lose
		la a0, lose
		li v0, 4
		syscall
		#set revealed
		jal reveal_tile
		#print score
		la a0, score
		li v0, 4
		syscall
		#print actual score int
		move a0, s7
		li v0, 1
		syscall
		#print line break
		la a0, line_break
		li v0, 4
		syscall
		jal print_board
		#exit
		li v0, 10
		syscall
	return_check_for_mine:
	pop ra
	jr ra

print_win_and_exit:
	#print win, print score, exit
	la a0, win
	li v0, 4
	syscall
	la a0, score
	syscall
	move a0, s7
	li v0, 1
	syscall
	#print line break
	la a0, line_break
	li v0, 4
	syscall
	jal print_board
	#exit
	li v0, 10
	syscall
