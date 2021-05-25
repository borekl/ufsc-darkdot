# Unfavorable Semicircle unnamed series analysis

[Unfavorable Semicircle](https://www.unfavorablesemicircle.com/) was a YouTube channel that contained tens of thousands of enigmatic video clips. The original unnamed
series videos have following characteristics:

* 50×50 resolution
* 30 fps (with very few exceptions)
* 120 frames (making for exactly 4 seconds of length)
* solid background of seemingly random color
* most of the videos have single dark pixel in the frame in seemingly random place
* the videos that do not contain discernible dark dot have either very dark background or dark ultramarine blue
* the audio track is one of
  * silence
  * human voice spelling a letter or saying a number
  * human voice saying a full set of letters and numbers
  * pieces of distorted music later found in its entirety in [DELOCK](https://www.unfavorablesemicircle.com/DELOCK) video
  * various other odd sounds

Since I have not found any information about the dark dots and their distribution in the frames, I decided to try
to look into them to see if there's anything interesting. For that purpose I have written this little program.
Here is what it does:

* it uses ffmpeg to average first 60 frames into a PNG image (this step probably isn't needed, but the idea was to clean up some of the compression artifacts)
* it loads the image and tries to find the dark dot
* all of the above is done for every video in the series
* after all of the videos are processed result is saved in the form of JSON file
* there is small script to generate map of the pixels

-----

## What have I found

Not much, really. Around 91% percent of clips have detectable and unambiguous dark pixel. When you plot these in a 50×50 grid you get what looks entirely random.
I have not actually analyzed this for randomness, but visually there are no discernible patterns.

-----

## How to use this code

`usfs-darkdot` expects list of directories that will be searched for MP4 clips, if there is no argument, current directory is searched instead. After the program
finishes running, it will save `usfs-darkdot.json` in current directory. You will need quite a few prerequisites for this to work. First of all you need ffmpeg build
with the `tmix` filter compiled in. Then you also need a bunch of non-default Perl libraries: Moo, Path::Tiny, JSON::MaybeXS, Imager, Term::ANSIColor.

`usfs-darkdot-heatmap` will read the above JSON file and generate a terminal pseudographics that represents the distribution of the dots; default is to generate
grayscale map, but you can also use heatmap coloring with `--heatmap` command-line option. Note, that you need terminal that supports 24-bit colors.

Directory `results` contains my resulting JSON file with both variants of the graphics.
