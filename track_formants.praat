# To run this script:
#	1. Select the sound object and TextGrid, View & Edit
#	2. Make sure that "Show formant" under the "Formant" menu is checked
#	4. Adjust Formant settings to whatever numbers that give you the best formant tracking
#	5. Click File > Open editor script...
#	6. Open this script
#	7. There are some variables you might want to change, like the number of places 
#		to take measurements from and the output path
#	8. Run this script

# this specifies how many places in the vowel you want to take measurements from
numsteps = 3

# the file to write the output to
outputFile$ = "formants.csv"

# write row header
writeFileLine: outputFile$, "vowel,word,interval,time,f1,f2, f3,f4"

# the vowels you want to track formants from
vowels$ = "3a3e3i3o3u"


info$ = Sound info
soundend$ = extractLine$(info$, "End time:")
soundend = extractNumber(soundend$, "")

Move cursor to... 0
intend = 0

while intend < soundend
	Select next interval
	# making sure you're on the segment tier
	label$ = Get label of interval
	labellen = length (label$)
	if labellen > 1
		Select previous tier
	endif

	intstart$ = Get start of selection
	intstart = extractNumber(intstart$, "")
	intend$ = Get end of selection
	intend = extractNumber(intend$, "")

	duration = intend - intstart
	increment = duration/(numsteps+1)

	for i from 1 to numsteps
		t[i] = intstart + (increment * i)
	endfor

	isvowel = index(vowels$, label$)
		
	if isvowel > 0 and labellen < 3 and labellen > 0 and label$ != "3"
		Select next tier
		word$ = Get label of interval
		Select previous tier
		Zoom... intstart intend
		for i from 1 to numsteps
			Move cursor to... t[i]
			finfo$ = Formant listing
    			finfo$ = replace$(finfo$, "Time_s   F1_Hz   F2_Hz   F3_Hz   F4_Hz", "", 0)
  			finfo$ = replace$(finfo$, newline$, "", 0)
  			finfo$ = replace$(finfo$, "   ", ",", 0)
			appendFileLine: outputFile$,label$,",",word$,",",i,",",finfo$
		endfor
	endif

endwhile