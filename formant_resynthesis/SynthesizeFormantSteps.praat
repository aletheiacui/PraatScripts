# Praat script by Aletheia Cui 3/2/2019
# This script synthesizes F1 and F2 formant steps for phonetic experiments. 
# To run this script, you will need 
#     1. The sound file of the word that you intend to synthesize from
#     2. A TextGrid with ONE tier, where ONLY the vowel portion is labeled
# This script assumes that you are resynthesizing the vowel of one word. The synthesizes
# process is:
#     1. The vowel portion is cut from the rest of the word (the result is better this way)
#     2. Formants of the vowel portion are modified according to specified intervals and steps
#     3. The resynthesized vowel is concatenated with the rest of the word
# Select the sound file and its corresponding TextGrid, and run this script.
# The outcome of the synthesis in part depends on the parameters you choose for the voice.

sound = selected("Sound")
tg = selected("TextGrid")

select tg
n_int = Get number of intervals: 1

# Move all the TextGrid boundaries to zero crossings
for i to n_int-1
   select tg
   boundary = Get end point: 1, i
   select sound
   zero = Get nearest zero crossing: 1, boundary
   if boundary != zero
      select tg
      Insert boundary: 1, zero
      Remove boundary at time: 1, boundary
   endif
endfor

select sound
plus tg

# Divide the sound into three parts
Extract all intervals: 1, "no"
cons = selected("Sound", 1)
vowel = selected("Sound", 2)
end = selected("Sound", 3)

beginPause: "Change formants cascade"
	real: "F1 start (Hz)", 500
 	real: "F1 step size (Hz)", 40
	integer: "F1 steps",  4
	real: "F2 start (Hz)", 1600
 	real: "F2 step size (Hz)", 70
    integer: "F2 steps", 2
	real: "F1 mean (Hz)", 600
	real: "F2 mean (Hz)", 1700
    real: "Maximum formant (Hz)", 5200
    integer: "Max number of formants", 5
endPause: "Synthesize", 1

# process increment info


if f1_start < 0
	f1 = 0
endif
if f2_start < 0
	f2 = 0
endif
if f1_step_size < 0
	f1_range = 0
endif
if f2_step_size < 0
	f2_range = 0
endif
if f1_steps < 0
	f1_steps = 1
endif
if f2_steps < 0
	f2_steps = 1
endif

f1 = f1_start
f2 = f2_start

# Synthesize formant steps
x = 0
for i from 0 to f1_steps
	for j from 0 to f2_steps
		select vowel
		f1 = f1_start + i * f1_step_size
		if f2_steps < 1
			f2 = 0
		else
			f2 = f2_start + j * f2_step_size
		endif
		call changeformants
		sound'x' = selected("Sound")
		sound'x'$ = selected$("Sound")
		x = x + 1
	endfor
endfor

select end
end_copy = Copy: "untitled"

# Concatenate sound file parts and scale peak to 0.9
x = x - 1
for i from 0 to x
	select cons
	plus sound'i'
    plus end_copy
	Concatenate
	rename$ = sound'i'$
	newsound = selected("Sound")
        Scale peak... 0.9
	Rename... 'rename$'
	select sound'i'
	Remove
	sound'i' = newsound
endfor

# Remove cut up file parts
select cons
plus vowel
plus end
plus end_copy
Remove

# Function to carry out formant synthesis
procedure changeformants
	select vowel
    vowel$ = selected$("Sound")
    v = Copy: vowel$

	sr = Get sample rate
	df1 = f1 - f1_mean
	df2 = f2 - f2_mean

	select v
	hf = Filter (pass Hann band): 5000, 0, 100
	select v
	samplingfrequency = 5000 * 2
	
	resampled = Resample: samplingfrequency, 10
	formant = To Formant (burg): 0.00, max_number_of_formants, maximum_formant, 0.025, 50
	lpc1 = To LPC: samplingfrequency
	plus resampled

	# get source
	source = Filter (inverse)

	select formant
	filtr = Copy: "filtr"

	# this is the code that modifies the formants
	if f1<>0
		Formula (frequencies)... if row = 1 then self + df1 else self fi
	endif
	if f2<>0
		Formula (frequencies)... if row = 2 then self + df2 else self fi
	endif
	# turn formant object into LPC
	lpc2 = To LPC: samplingfrequency
	plus source
	tmp1 = Filter: "no"
	tmp2 = Resample: sr, 10
	f1$ = string$ (f1)
	f2$ = string$ (f2)
	Formula...  self+Object_'hf'[]
    dur = Get total duration
    result = Extract part: 0.025, dur-0.025, "rectangular", 1, "no"
	Rename... 'vowel$'_'f1$'_'f2$'
	Scale peak... 0.9
	select v
	plus hf
	plus resampled
	plus formant
	plus lpc1
	plus source
	plus filtr
	plus lpc2
	plus tmp1
    plus tmp2
	Remove
	select result
endproc
