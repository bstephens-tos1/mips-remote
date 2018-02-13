.kdata						# kernel data
s1:	.word 10
s2:	.word 11

.data
#-----------------------------------------------#
#
# References
#

# button_p: .word 112
# channel_up: .word 117
# channel_down: .word 100
# volume_up: .word 108
# volume_down: .word 107
# button_sleep: .word 115
# button_history: .word 118
# button_back: .word 98

#----------------------------------------------#
#
# Registers Being Used
#

# s1 - power register
# s2 - current channel set to 0
# s3 - default volume set to 0
# s4 - milliseconds counter
# s5 - seconds counter
# s6 - sleep counter

# t0 -> t4 - channel variables
# f0 -> f6 - seconds variables
# t5 - channel swap
# f5 - seconds swap

#-----------------------------------------------#
#
# Word space
#

sleep_counter:
	.word 0
sleep_time:
	.word 0
digit_input_count:
	.word 0
digit_save:
	.word -10
back_channel:
	.word -10
back_counter:
	.word 0

seconds_viewed:
	.space 400
viewed_history:
	.space 24

#-----------------------------------------------#
#
# Ascii Strings
#

new_line: 
	.asciiz "\n"
dash_line:
	.asciiz "-\n"
seconds: 
	.asciiz " sec"
view_channel:
	.asciiz "Channel:  "
view_seconds:
	.asciiz "  Seconds:  "
power_on_status:
	.asciiz "  |  Power: On!"
power_off_status:
	.asciiz "  |  Power: Off!"
channel:
	.asciiz "  |  Channel: "
channel_selection:
	.asciiz "Channel selection: "
channel_button_up: 
	.asciiz "Channel up: "
channel_button_down:
	.asciiz "Channel down: " 
volume:
	.asciiz " | Volume: "
volume_button_up:
	.asciiz "Volume up: "
volume_button_down:
	.asciiz "Volume down: "
sleep_timer:
	.asciiz "  |  sleep timer: "
sleep_plus:
	.asciiz "Sleep time : "
sleep_power_off_string:
	.asciiz "--Power off due to sleep timer!!--\n"
view_history_string:
	.asciiz "Most Watched Channels in Descending order:\n"
on_string:
	.asciiz "ON\n"
off_string:
	.asciiz "OFF\n"
sleep_string: 
	.asciiz "Sleep Status: "
power_string: 
	.asciiz "Power: "
max_volume_string:
	.asciiz "MAXIMUM\n"
min_volume_string:
	.asciiz "MINIMUM\n"
back_string:
	.asciiz "Going back to channel: "
back_set:
	.asciiz "Back button set!\n"

#-----------------------------------------------#
#
# Main
#

.text
.globl main

main:
	mfc0 $a0, $12				# read from the status register
	ori $a0, 0xff11				# enable all interrupts
	mtc0 $a0, $12				# write back to the status register

	lui $t0, 0xFFFF				# $t0 = 0xFFFF0000;
	ori $a0, $0, 2				# enable keyboard interrupt
	sw $a0, 0($t0)				# write back to 0xFFFF0000;

#-----------------------------------------------#
#
# Default Initializing
#
default:
	addi $s7, $0, 0				#initialize $s7
	addi $s0, $0, 0				#channel save
	addi $s1, $0, 0				#power register zero off, 1 on.
	addi $s2, $0, 0				#default channel set to zero.
	addi $s3, $0, 50			#default volume set to zero.
	li $s4, 300					# initialize counter
	li $s5, 0					# initialize seconds counter
	addi $s6, $0, 0				#sleep counter.

	addi $t1, $zero, 0
	sw $t1, sleep_time($0)
	sw $t1, sleep_counter($0)
	sw $t1, digit_input_count($0)
	sw $t1, back_counter($0)
	addi $t1, $zero, -10
	sw $t1, digit_save($0)
	sw $t1, back_channel($0)

	mtc1 $0, $f0
	mtc1 $0, $f1
	mtc1 $0, $f2
	mtc1 $0, $f3
	mtc1 $0, $f4

#-----------------------------------------------#
#
# Main Loop
#

main_loop:
	bne $s7,$zero, power_check		# Power on?

program_loop:

	jal delay_1s

	addi $s4, $s4, -1			# Iterations counter
	bne $s4, $0, main_loop
	li $s4, 300

	addi $s5, $s5, 1			# number of seconds + 1

	lw $t1, back_channel($0) 		#loads save channel
	addi $t0, $zero, -10	 		#value of unchanged digit		
	beq $t1,$t0, dont_back	 		#if unchanged dont start counter	
	lw $t1, back_counter($0) 		# else add to back counter	
	addi $t1, $t1, 1
	addi $t0, $zero, 10			#total untill return channel	
	sw $t1, back_counter($0) 		# save counter.
	beq $t1,$t0, ten_seconds

dont_back:


	lw $t1, digit_save($0)			#loads saved digit
	addi $t0, $zero, -10			# value of unchanged saved digit
	beq $t1, $t0, dont_count		#if unchanged dont start counter
	lw $t1, digit_input_count($0)
	addi $t1, $t1, 1			#else add one to digit_input_counter
	addi $t0, $zero, 2
	sw $t1, digit_input_count($0)		#save counter
	
	beq $t1, $t0, two_seconds

dont_count:

	lw $t3, sleep_time($0)
	beq $t3,$0, skip_sleep_dec
	addi $t3, $t3, -1
	sw $t3, sleep_time($0)
	beq $t3, $0, sleep_power_off
	skip_sleep_dec:


	add $t0, $zero, $s5
	addi $t1, $zero, 3
	div $t0,$t1
	mfhi $t1
	beq $t1,$zero, status			# jump status
	j	main_loop

	li $v0, 10				# exit
	syscall
#-----------------------------------------------#
#
# Go Back
#
ten_seconds:

	
	lw $t1, back_channel($0)		#load channel to return to	
	beq $t1, $s2, same_channel 		 #if return is current channel

	add $s2, $zero, $t1			#sets return channel.

	li $v0,4				#channel selection label
	la $a0, back_string
	syscall

	li $v0,1				#channel set too.
	move $a0, $s2
	syscall

	li $v0,4				#new line
	la $a0, new_line
	syscall

	same_channel:
	addi $t1, $zero,0			#reset counter.
	sw $t1, back_counter($0)
	addi $t1, $zero, -10
	sw $t1, back_channel($0)			

	j dont_back

#-----------------------------------------------#
#
# Channel detection:
# After two seconds from first input.
#
two_seconds:					#after two seconds have passed
	
	jal store_seconds

	lw $t1, digit_save($0)
	add $s2, $zero, $t1			#Set channel!
	
	li $v0,4				#channel selection label
	la $a0, channel_selection
	syscall

	li $v0,1				#channel set too.
	move $a0, $s2
	syscall

	li $v0,4				#new line
	la $a0, new_line
	syscall

	
	addi $t1, $zero, 0
	sw $t1, digit_input_count($0)
	addi $t1, $zero, -10
	sw $t1, digit_save($0)			#reset counter

	j dont_count

#-----------------------------------------------#
#
# Power off by sleep
#
sleep_power_off:				#if sleep time turns off.
	li $v0, 4				#print sleep turn off status.
	la $a0, sleep_power_off_string
	syscall
	addi $s1, $0, 0				#turn off power var.

	j default

#-----------------------------------------------#
#
# This timer loop takes 3 seconds to count from 22,500 down to
# 0 on my PC.  This is based off of the example given in class notes
# for a 10ms delay.  If there is slower hardware, it could take LONGER
# than 3 seconds to perform the count.
#

delay_1s:
	li $t1,	7500				# initialize countdown integer
delay_1s_loop:

	addi $t1, $t1, -1			# begin countdown
	bne $t1, $0, delay_1s_loop		# countdown until 0
	jr $ra

#-----------------------------------------------#
#
# Status for power on or off
#

status:
	li $v0, 1				# prepare syscall for printing integer
	move $a0, $s5				# move contents of s2 into a0
	syscall					# print s2

	li $v0, 4				# prepare to print string
	la $a0, seconds				# load 'seconds' into $a0
	syscall					# print 'seconds'

	li $v0, 4				# prepare to print string
	bne $s1, $zero, print_on
	la $a0,	power_off_status
	syscall
	j done

print_on:
	la $a0,	power_on_status			# load 'power_off' into $a0
	syscall					# print 'power_off'
done:
	li $v0, 4				#prints line
	la $a0,channel
	syscall

	li $v0, 1				# prepare to print string
	move $a0, $s2				# load 'channel' into $a0
	syscall					# print 'channel'


	li $v0, 4				#prints line
	la $a0,volume
	syscall

	li $v0, 1				# prepare to print string
	move $a0,$s3				# load 'volume' into $a0
	syscall					# print 'volume'


	li $v0, 4				# prepare to print string
	la $a0, sleep_timer			# load 'sleep_timer' into $a0
	syscall					# print 'sleep_timer'

	lw $t0, sleep_time($0)
	li $v0,1
	move $a0, $t0
	syscall

	li $v0, 4
	la $a0, new_line
	syscall

	j main_loop
#-----------------------------------------------#
#
# Power Check
#
power_check:                			#checks if power is on
	addi $s0, $zero, 112	   		#adds p value to $s0 register
	beq $s0, $s7, power_on			#if power button value is in register $s7, turns jumps to power_on
	beq $s1,$zero, program_loop

	j check_input

#-----------------------------------------------#
#
# Power controls
#

power_on:                   			#checks if power is on.
	bne $s1, $zero, power_off  		#if power is 1 "on" then jump to power_off.
	addi $s1, $zero, 1 			#else set power to on $s1 = 1
	li $s5, 0				#reset the timer!

	li $v0,4				#power on message
	la $a0, power_string
	syscall

	li $v0,4				#power on message
	la $a0, on_string
	syscall

	addi $s7 , $zero, 0			#reset the key variable $s7 to default
	j check_input				#jump to check input

power_off:					#turns power off if on
	addi $s1, $zero, 0			#sets $s1, the power var to 0

	li $v0,4				#power off message
	la $a0, power_string
	syscall

	li $v0,4				#power off message
	la $a0, off_string
	syscall

	j default				#jumps back to default label to reset vars.

#-----------------------------------------------#
#
#  Sleep Timer
#
sleep_timer_function:

	beq $s6, $zero, off_sleep		#if $s6(sleep var) is 0 branch off_sleep

	addi $t0, $s5, 0			#save second counter to $t0	
	lw $t2, sleep_counter($0)		#load the sleep counter

	sub $t3,$s5,$t2				#subtract the current time and the sleep counter.
	addi $t4, $zero, 3			#add 3 to $t4 	

	bgt $t3,$t4, time_count_status		#branch if the difference between the timer and counter is greater than 3
	lw $t0, sleep_time($0)			#load the the sleep duration	
	addi $t0, $t0, 5			#addi +5 to duration
	addi $t5 , $zero, 200			# save 200 to $t5
	bgt $t0, $t5, off_sleep			# if sleep duration is 200+ turn off

	li $v0, 4				#prints sleep_plus label
	la $a0, sleep_plus 
	syscall

	li $v0, 1				#prints sleep duration
	move $a0, $t0 
	syscall

	li $v0, 4				# newline
	la $a0, new_line
	syscall

	sw $t0, sleep_time($0)			# save sleep duration

	j finish_sleep


time_count_status:				# sdisplays
	addi $s6, $zero, 1			# one to $s6 sleep var.
	sw $s5,sleep_counter($0)		# saves time to sleep counter

	lw $t0, sleep_time($0)			# load sleep duration
	beq $t0, $zero, off_sleep		# if sleep time is 0
	
	li $v0,4				# print sleep string
	la $a0, sleep_string			
	syscall

	lw $t0, sleep_time($0)			# load sleep duration

	li $v0,	1				# print sleep duration
	move $a0, $t0
	syscall

	li $v0, 4				# print new line
	la $a0, new_line
	syscall

	j finish_sleep

off_sleep:						
	addi $t0, $zero, 0			# $t0 hold 0
	sw $t0,sleep_time			# save $t0 to sleep time

	addi $s6, $zero, 1			# add 1 to $s6
	sw $s5,sleep_counter($0)

	li $v0,4				# print sleep string
	la $a0, sleep_string
	syscall
		
	li $v0,4				# print off string
	la $a0, off_string
	syscall

	addi $s6, $zero, 1			# add 1 to $s6

finish_sleep:					# finish label	
	addi $s7, $zero, 0
	j program_loop				# return to program loop

#-----------------------------------------------#
#
# Input check from interrupt.
#

check_input:					# input check function compares $s0 which is loaded a keyboard value
	addi $t0, $zero, 48                 	# check for input 0-9
	blt $s7, $t0, check_non_digit		# if less than 0(ie 48)	
	addi $t0, $zero, 57					
	bgt $s7, $t0 ,  check_non_digit		# if greater than 9(ie 57)		
	j digit_input

check_non_digit:
	addi $t1, $zero, 0			# reset digit value if non-used
	sw $t1, digit_input_count($0)
	addi $t1, $zero, -10
	sw $t1, digit_save($0)	
						# to $s7 which is the value from the interrupt.
	addi $t0, $zero, 112
	beq $t0, $s7, power_on

	addi $t0, $zero,117
	beq $t0, $s7, channel_up

	addi $t0, $zero,100
	beq $t0, $s7, channel_down

	addi $t0, $zero,108
	beq $t0, $s7, volume_up

	addi $t0, $zero,107
	beq $t0, $s7, volume_down

	addi $t0, $zero,115
	beq $t0, $s7, sleep_timer_function

	addi $t0, $zero,118
	beq $t0, $s7, view_history

	addi $t0, $zero,98
	beq $t0, $s7, back_key

	j program_loop

back_key:
	sw $s2, back_channel($0)		# Save return channel
	
	li $v0,4				# Set message
	la $a0, back_set
	syscall
	
	
	addi $s7 , $zero, 0			# Restore $s7
	j program_loop
	


#-----------------------------------------------#
#
# Digit input
#
digit_input:
	lw $t1, digit_save($0)			#loads saved digit
	addi $t0, $zero, -10			# value of unchanged saved digit
	bne $t1, $t0, skip_digit_save

	addi $t0, $zero, 48			#gets key value
	sub  $t2, $s7, $t0			#$t2 hold 0-9
	sw $t2, digit_save($0)			#save digit
		
    li $v0,4					#channel selection label
	la $a0, channel_selection
	syscall

	li $v0,1				#channel var
	move $a0, $t2
	syscall

	li $v0,4				#dashed line print
	la $a0, dash_line
	syscall

return_digit:

	addi $s7 , $zero, 0			#restore $s7
	j program_loop

skip_digit_save:
	jal store_seconds

	lw $t1, digit_save($0)			#load saved digit
	addi $t2, $zero, 10
	mult $t1, $t2				#saved x10
	mflo $t3				#$t3 has save x10

	addi $t0, $zero, 48			#gets key value
	sub  $t2, $s7, $t0			#current digit!
	
	add $t3, $t3, $t2			#$t3 has current plus saved x10
	add $s2, $zero, $t3			# channel has $t3.

	li $v0,4				#channel selection label
	la $a0, channel_selection
	syscall

	li $v0,1				#channel set too.
	move $a0, $t3
	syscall

	li $v0,4				#new line
	la $a0, new_line
	syscall

	addi $t1, $zero, 0
	sw $t1, digit_input_count($0)
	addi $t1, $zero, -10
	sw $t1, digit_save($0)			#reset counter

	j return_digit


#-----------------------------------------------#
#
# Volume control 
#

volume_up:					# volume up "l"

	addi $t0, $zero, 99			#adds value of 99 (max) to temp $t0
	beq $s3,$t0, max_volume			#if value of $s3(volume var) = max volume	
	addi $s3,$s3,1				#else add one to $s3( volume var)
	j done_volume_up			#j to volume done.

max_volume:					#given $s3 is 99
	li $v0,4				#print volune button label
	la $a0, volume_button_up
	syscall
	
	li $v0,4				#print out max string
	la $a0, max_volume_string
	syscall

	addi $s7 , $zero, 0			#restore $s7 back to default 0
	j program_loop

done_volume_up:					#after adding to volume
	li $v0,4				#print volune button label
	la $a0, volume_button_up
	syscall
	
	li $v0,1				#print current volume
	move $a0, $s3 
	syscall

	li $v0,4				#newline
	la $a0, new_line
	syscall

	addi $s7 , $zero, 0			#restore $s7

	j program_loop

volume_down:

	addi $t0, $zero, 0			#adds value of 0 (max) to temp $t0	
	beq $s3,$t0, min_volume			#if value of $s3(volume var) = min volume	
	addi $s3,$s3,-1				#else sub one to $s3( volume var)
	j done_volume_down

min_volume:					#given $s3 is 0
	li $v0,4				#print volune button label
	la $a0, volume_button_down
	syscall

	li $v0,4				#print out min string
	la $a0, min_volume_string
	syscall

	addi $s7 , $zero, 0			#restore $s7 back to default 0	
	j program_loop

done_volume_down:				#after subtracking from volume	
	li $v0,4				#print volune button label
	la $a0, volume_button_down
	syscall

	li $v0,1				#print current volume
	move $a0, $s3 
	syscall

	li $v0,4				#newline
	la $a0, new_line
	syscall

	addi $s7 , $zero, 0			#restore $s7		
	j program_loop

#-----------------------------------------------#
#
# Channel control
#

channel_up:					#increase channel var
	jal store_seconds

	addi $t0, $zero, 99 			#add 99 to $t0
	beq $s2,$t0, max_value			#if channel var = max branch
	addi $s2,$s2,1				#else add one to channel var

channel_0:					#after setting channel to 0
	li $v0,4				#print channel button label
	la $a0, channel_button_up
	syscall
	
	li $v0,1				#print channel var
	move $a0, $s2 
	syscall

	li $v0,4				#print newline
	la $a0, new_line
	syscall

	addi $s7 , $zero, 0			#restore $s7 to default
	j program_loop

max_value: 					#if $s2 = max value
	addi $s2,$zero,0			#set $s2 = 0
	j channel_0 				#jump to channel_0


channel_down:					#decrease channel var
	jal store_seconds

	addi $t0, $zero, 0 			#add 0 to $t0
	beq $s2,$t0, max_value_d		#if channel var = max branch
	addi $s2,$s2,-1				#else sub one to channel var

channel_0_d:					#after setting channel to 99
	li $v0,4				#print channel button label
	la $a0, channel_button_down
	syscall
	
	li $v0,1				#print channel var
	move $a0, $s2 
	syscall

	li $v0,4				#print newline
	la $a0, new_line
	syscall

	addi $s7, $zero, 0			#restore $s7 to default
	j check_input				#jump to input check

max_value_d: 					#if $s2 = max value
	addi $s2,$zero,99			#set $s2 = 99
	j channel_0_d				#jump to channel_0_d

#-----------------------------------------------#
#
# Auxillary Channel control
#

store_seconds:
						# s2 = current channel
	sll $t0, $s2, 2				# fix indexing issue//A[i]
	l.s $f5, seconds_viewed($t0)
	sub $s8, $s5, $s8			# Begin conversion to floating point
	mtc1 $s8, $f7
	cvt.s.w $f7, $f7
	add.s $f5, $f5, $f7
	s.s $f5, seconds_viewed($t0)		# Save results

	la $t0, viewed_history			# Put A[i] first address in t0
	sw $s2, 20($t0)				# store the urrent channel to be compared at 5th spot
	lw $t1, 0($t0)
	bne $s2, $t1, skip_1			# Start comparing
	mov.s $f0, $f5
	sw $0, 20($t0)
	mtc1 $0, $f5
	j sort_me
skip_1:
	lw $t1, 4($t0)
	bne $s2, $t1, skip_2
	mov.s $f1, $f5
	sw $0, 20($t0)
	mtc1 $0, $f5
	j sort_me
skip_2:
	lw $t1, 8($t0)
	bne $s2, $t1, skip_3
	mov.s $f2, $f5
	sw $0, 20($t0)
	mtc1 $0, $f5
	j sort_me
skip_3:
	lw $t1, 12($t0)
	bne $s2, $t1, skip_4
	mov.s $f3, $f5
	sw $0, 20($t0)
	mtc1 $0, $f5
	j sort_me
skip_4:
	lw $t1, 16($t0)
	bne $s2, $t1, sort_me
	mov.s $f4, $f5
	sw $0, 20($t0)
	mtc1 $0, $f5

sort_me:
	c.lt.s $f0, $f1				# store TRUE or FALSE if f0 < f1
	bc1t swap_f0				# swap f0 and f1 if true

	c.lt.s $f1, $f2
	bc1t swap_f1

	c.lt.s $f2 $f3
	bc1t swap_f2

	c.lt.s $f3, $f4
	bc1t swap_f3

	c.lt.s $f4, $f5
	bc1t swap_f4

	addi $s8, $s5, 0			# save current seconds into s8
	jr $ra

swap_f0:
	lw $t1, 0($t0)				# load channel at 0($t0)
	lw $t2, 4($t0)
	sw $t1, 4($t0)				# save 0($t0) at 4($t0)
	sw $t2, 0($t0)
	mov.s $f6, $f0				# move f0 into temp reg
	mov.s $f0, $f1
	mov.s $f1, $f6
	j sort_me
swap_f1:
	lw $t1, 4($t0)
	lw $t2, 8($t0)
	sw $t1, 8($t0)
	sw $t2, 4($t0)
	mov.s $f6, $f1
	mov.s $f1, $f2
	mov.s $f2, $f6
	j sort_me
swap_f2:
	lw $t1, 8($t0)
	lw $t2, 12($t0)
	sw $t1, 12($t0)
	sw $t2, 8($t0)
	mov.s $f6, $f2$
	mov.s $f2, $f3
	mov.s $f3, $f6
	j sort_me
swap_f3:
	lw $t1, 12($t0)
	lw $t2, 16($t0)
	sw $t1, 16($t0)
	sw $t2, 12($t0)
	mov.s $f6, $f3
	mov.s $f3, $f4
	mov.s $f4, $f6
	j sort_me
swap_f4:
	lw $t1, 16($t0)
	lw $t2, 20($t0)
	sw $t1, 20($t0)
	sw $t2, 16($t0)
	mov.s $f6, $f4
	mov.s $f4, $f5
	mov.s $f5, $f6
	j sort_me

#
# Load in the correct string, print the string, load in the channel from it's space in memory
# and print that, then load in the floating point seconds register and print that.
# Does this five times, for the 5-most channels.  TURN INTO A LOOP
#
view_history:
	jal store_seconds
	li $v0, 4
	la $a0, view_history_string
	syscall

	li $v0, 4
	la $a0, view_channel
	syscall

	li $v0, 1
	lw $a0, 0($t0)
	syscall

	li $v0, 4
	la $a0, view_seconds
	syscall

	li $v0, 2
	mov.s $f12, $f0
	syscall

	li $v0, 4
	la $a0, new_line
	syscall

	li $v0, 4
	la $a0, view_channel
	syscall

	li $v0, 1
	lw $a0, 4($t0)
	syscall

	li $v0, 4
	la $a0, view_seconds
	syscall

	li $v0, 2
	mov.s $f12, $f1
	syscall

	li $v0, 4
	la $a0, new_line
	syscall

	li $v0, 4
	la $a0, view_channel
	syscall

	li $v0, 1
	lw $a0, 8($t0)
	syscall

	li $v0, 4
	la $a0, view_seconds
	syscall

	li $v0, 2
	mov.s $f12, $f2
	syscall

	li $v0, 4
	la $a0, new_line
	syscall

	li $v0, 4
	la $a0, view_channel
	syscall

	li $v0, 1
	lw $a0, 12($t0)
	syscall

	li $v0, 4
	la $a0, view_seconds
	syscall

	li $v0, 2
	mov.s $f12, $f3
	syscall

	li $v0, 4
	la $a0, new_line
	syscall

	li $v0, 4
	la $a0, view_channel
	syscall

	li $v0, 1
	lw $a0, 16($t0)
	syscallr

	li $v0, 4
	la $a0, view_seconds
	syscall

	li $v0, 2
	mov.s $f12, $f4
	syscall

	li $v0, 4
	la $a0, new_line
	syscall

	addi $s7 , $zero, 0
	j program_loop

#-----------------------------------------------#
#
# Key value print out(will be deleted)
#
key_out:					# points out key value at $s7
	ori $a0, $s7, 0
	li $v0,11				# print it here.
	syscall

	addi $s7 , $zero, 0
	j program_loop

#-----------------------------------------------#
#
# Interrupt code
#
.ktext 0x80000180				# kernel code starts here

.set noat					# tell the assembler not to use $at, not needed here actually, just to illustrae the use of the .set noat
	move $k1, $at				# save $at. User prorams are not supposed to touch $k0 and $k1
.set at						# tell the assembler okay to use $at

	sw $v0, s1				# We need to use these registers
	sw $a0, s2				# not using the stack because the interrupt might be triggered by a memory reference
						# using a bad value of the stack pointer

	mfc0 $k0, $13				# Cause register
	srl $a0, $k0, 2				# Extract ExcCode Field
	andi $a0, $a0, 0x1f

	bne $a0, $zero, kdone			# Exception Code 0 is I/O. Only processing I/O here

	lui $v0, 0xFFFF				# $t0 = 0xFFFF0000;

	lw $s7,4($v0)   			# saves $v0 to $s7

kdone:
	mtc0 $0, $13				# Clear Cause register
	mfc0 $k0, $12				# Set Status register
	andi $k0, 0xfffd			# clear EXL bit
	ori  $k0, 0x11				# Interrupts enabled
	mtc0 $k0, $12				# write back to status

	lw $v0, s1				# Restore other registers
	lw $a0, s2

.set noat					# tell the assembler not to use $at
	move $at, $k1				# Restore $at
.set at						# tell the assembler okay to use $at

	eret					# return to EPC

