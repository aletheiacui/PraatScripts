# This script goes through all the sound files in a directory and automatically
# creates a TextGrid and allows the user to edit the TextGrid.
# Each sound file should contain a single word or syllable.
# This was created specifically to process the data from one of our experiments,
# but it can be easily adapted to other projects that requires the annotation
# of wordlists.
#
# For each file it
# 	1. creates a TextGrid, labels it either "e" or "u" depending on what is in the filename
# 	2. allows the user to edit the TextGrid
#	3. gives the user the either saving the textgrid, or discarding the sound file

# set this to the directory of the sound files that you want to annotate
directory$ = ""
strings = Create Strings as file list: "list", directory$ + "/*.wav"
numberOfFiles = Get number of strings

# create a directory to discard unwanted sound files
createDirectory: directory$ + "/discard"
createDirectory: directory$ + "/syllableTG"
for ifile to numberOfFiles
    selectObject: strings
    filename$ = Get string: ifile
    sound = Read from file: directory$ + "/" + filename$
	filename$ = replace$ (filename$, ".wav", "", 0)

	# gets the label of the vowel
	vowel$ = "e"
	hasu = index(filename$, "u")
	if hasu > 0
		vowel$ = "u"
	endif
	syl$ = "b"+vowel$
	Scale peak: 0.9

	tgsyl = To TextGrid (silences): 100, 0, -30, 0.1, 0.1, "", syl$
	
	select sound
	tgvowel = To TextGrid (silences): 100, 0, -10, 0.1, 0.1, "", vowel$
	select tgsyl
	plus tgvowel
	tg = Merge
	Set tier name: 1, "syllable"
	Set tier name: 2, "vowel"

	select tgsyl
	plus tgvowel
	Remove

	select sound
	plus tg
	View & Edit
	editor: "TextGrid merged"
	ifile$ = string$ (ifile)
	numberOfFiles$ = string$ (numberOfFiles)
	loc$ = ifile$ + "/" + numberOfFiles$ + " Choose wisely"
	beginPause: loc$
	clicked = endPause: "Continue", "Discard", 1
	Close
	if clicked = 1
		select tg
		vtg = Extract one tier... 2
		Save as text file... 'directory$'/'filename$'.TextGrid
		select tg
		stg = Extract one tier... 1
		Save as text file... 'directory$'/syllableTG/'filename$'.TextGrid
		select vtg
		plus stg
		Remove
	else
		select sound
		Save as WAV file... 'directory$'/discard/'filename$'.wav 
		deleteFile: directory$ + "/" + filename$ + ".wav"
	endif

	select sound
	plus tg
	Remove
endfor

select strings
Remove