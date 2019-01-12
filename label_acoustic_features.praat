# This is a script that aids the user in annotating the acoustic features
# of a directory of sound files.
# For each sound file, the script
#    1. produces a TextGrid with the following tiers:
#             word phoneme VOT burst f0 f1 f2 f3 intensity
#    2. opens the TextGrid with the sound file, automatically populates the
#       TextGrid with acoustic measurements and allows the user to manually
#       check the measurements
#    3. once the user is satisfied with the measurements, the script saves
#       the TextGrid and moves on to the next sound file
# This script was written specifically for a language with only CV syllables
# and tone + register contrasts. However, the workflow should be easily
# adaptable for other kinds of input.

# the directory containing all the input files
directory$ = ""

# directory to output labeled TextGrids
outDir$ =  ""

# once a sound file has been labeled, move it to this directory
doneDir$ =  ""

fileList = Create Strings as file list: "list", directory$ + "*.wav"
numFiles = Get number of strings
offset = 0.005

procedure addMeasurements .time
    @beginEditor
    .f0$ = Get pitch
    .f1$ = Get first formant
    .f2$ = Get second formant
    .f3$ = Get third formant
    .intensity$ = Get intensity
    .f0 = round(extractNumber(.f0$, ""))
    .f1 = round(extractNumber(.f1$, ""))
    .f2 = round(extractNumber(.f2$, ""))
    .f3 = round(extractNumber(.f3$, ""))
    .intensity = round(extractNumber(.intensity$, ""))
    endeditor
    select tg
    Insert point: 5, .time, "'.f0'"
    Insert point: 6, .time, "'.f1'"
    Insert point: 7, .time, "'.f2'"
    Insert point: 8, .time, "'.f3'"
    Insert point: 9, .time, "'.intensity'"
    @beginEditor
endproc

procedure beginEditor
    editor: "TextGrid " + filename$
endproc

for ifile to numFiles
    selectObject: fileList
    fname$ = Get string: ifile
    Read from file: directory$ + fname$

	soundfile = selected("Sound")
	filename$ = selected$("Sound")
	prefixIndex = index(filename$, "-")
	suffixIndex = rindex(filename$, "-")

	wordStart = prefixIndex + 1
	wordLen = suffixIndex - prefixIndex - 1
	word$ = mid$(filename$, wordStart, wordLen)
	tone$ = "Low"
	toneNum$ = right$(word$, 2)
	if toneNum$ = "33"
	   tone$ = "Mid"
	endif
	register$ = "Lax"
	isTense = index(word$, "_")
	if isTense > 0
		register$ = "Tense"
	endif
	syllable$ = replace_regex$(word$, "_?[23][13]", "", 0)
	consonant$ = replace_regex$(syllable$, "[aeiou]", "", 0)
	vowel$ = right$(syllable$, 1)
	voiceless = index_regex(consonant$, "^[tpk]")

	tg = To TextGrid: "word phoneme VOT burst f0 f1 f2 f3 intensity", "f0 f1 f2 f3 intensity"
	select soundfile
	plus tg
	View & Edit

	repeat
		beginPause: "Labeling helper"
		@beginEditor
		clicked = endPause: "Intervals", "Points", "Save", 3
		if clicked = 1
			start$ = Get start of selection
			start = extractNumber(start$, "")
			end$ = Get end of selection
			end = extractNumber(end$, "")
			midword = (start + end)/2

			Close
			select tg
			Insert boundary: 1, start
			Insert boundary: 1, end
			Insert boundary: 2, start
			Insert boundary: 2, end
			Insert boundary: 2, midword
			if voiceless > 0
				Insert boundary: 3, start + offset
				Insert boundary: 3, midword
				Insert boundary: 4, start
				Insert boundary: 4, start + offset
			else
				Insert boundary: 3, start
				Insert boundary: 3, midword - offset
				Insert boundary: 4, midword - offset
				Insert boundary: 4, midword
			endif
			Set interval text: 1, 2, consonant$ + "-" + vowel$  + "-" + register$  + "-" + tone$
			Set interval text: 2, 2, consonant$
			Set interval text: 2, 3, vowel$
			select soundfile
			Save as WAV file: doneDir$ + fname$
			channelOne = Extract one channel: 1
			Scale peak: 0.99
			select soundfile
			Remove
			soundfile = channelOne
			select soundfile
			plus tg
			View & Edit
		elsif clicked = 2
			@beginEditor
			pauseScript: "Cursor marks the end of transition?"
			cursor$ = Get cursor
			cursor = extractNumber(cursor$, "")
			endeditor
			select tg
			vowelStart$ = Get start time of interval: 2, 3
			vowelStart = extractNumber(vowelStart$, "")
			vowelEnd$ = Get end time of interval: 2, 3
			vowelEnd = extractNumber(vowelEnd$, "")
			votStart$ = Get start time of interval: 3, 2
			votEnd$ = Get end time of interval: 3, 2
			votStart = extractNumber(votStart$, "")
			votEnd = extractNumber(votEnd$, "")
			vot = votEnd - votStart
			if voiceless = 0
				vot$ = "-" + "'vot'"
			else
				vot$ = "'vot'"
			endif
			Set interval text: 3, 2, vot$
			burstStart$ = Get start time of interval: 4, 2
			burstEnd$ = Get end time of interval: 4, 2
			burstStart = extractNumber(burstStart$, "")
			burstEnd = extractNumber(burstEnd$, "")
			burstMid = burstStart + (burstEnd - burstStart)/2

			# get burst center frequency
			@beginEditor
			Select: burstStart, burstEnd
			View spectral slice
			endeditor
			lpc = selected("Spectrum")
			gravity$ = Get centre of gravity: 2.0
			gravity = round(extractNumber(gravity$, ""))
			select tg
			Set interval text: 4, 2, "'gravity'"
			mid = (cursor  + vowelEnd)/2
			@beginEditor
			Move cursor to: vowelStart
			@addMeasurements: vowelStart
			Move cursor to: cursor
			@addMeasurements: cursor
			Move cursor to: mid
			@addMeasurements: mid
			Move cursor to: vowelEnd
			@addMeasurements: vowelEnd
			endeditor
			consStart$ = Get start time of interval: 3, 2
			consEnd$ = Get end time of interval: 3, 2
			consStart = extractNumber(consStart$, "")
			consEnd = extractNumber(consEnd$, "")
			consInt = (consEnd - consStart)/3
			consOne = consStart + consInt
			consTwo = consEnd - consInt
			@beginEditor
			Move cursor to: consOne
			consIntensityOne$ = Get intensity
			consIntensityOne = round(extractNumber(consIntensityOne$, ""))
			Move cursor to: consTwo
			consIntensityTwo$ = Get intensity
			consIntensityTwo = round(extractNumber(consIntensityTwo$, ""))
			Move cursor to: burstMid
			burstIntensity$ = Get intensity
			burstIntensity = round(extractNumber(burstIntensity$, ""))
			endeditor
			Insert point: 9, consOne, "'consIntensityOne'"
			Insert point: 9, consTwo, "'consIntensityTwo'"
			Insert point: 9, burstMid, "'burstIntensity'"
		endif
	until clicked = 3
	endeditor
	select soundfile
	Save as WAV file: outDir$ + filename$ + ".wav"
	select tg
	Save as text file: outDir$ + filename$ + ".TextGrid"
	deleteFile: directory$ + filename$ + ".wav"
	select soundfile
	plus tg
	plus lpc
	Remove
endfor

select fileList
Remove
