<style>
  :not(pre):not(.hljs) > code, dt { color: darkred; font-family: lucida console; }
  dt { display: inline; }
</style>
# MuseScore 2.0 plugin - Notes from Chord texts

This plugin for [MuseScore 2.0](http://musescore.org/) reads chord (Harmony) texts and creates Chord notes in one staff, and bass note in another one. The created notes have correct durations according to the duration of the written chord, and are playable by MuseScore.

The created notes are more of a suggestion, to get it to sound nice it's perhaps a good idea to move some notes one octave up or down, or just remove them.

## Idea from

This plugin was inspired from MuseScore 2.0 plugin [chordsToNotes](https://github.com/berteh/musescore-chordsToNotes).

## How-To

- [Download](https://github.com/per-d/notes-from-chord-texts/zipball/master) and [install the plugin](https://musescore.org/en/handbook/plugins-0#installation) to your MuseScore 2.0+ plugin folder.
- Only the [qml file](https://github.com/per-d/notes-from-chord-texts/raw/master/notes_from_chord_texts.qml) is needed, but it can be a good idea to copy the folder into the plugin folder, partly to use test scores in sub folder [test](https://github.com/per-d/notes-from-chord-texts/tree/master/test), and in the future translation files will be added.
- [Enable](https://musescore.org/en/handbook/plugins#enable-disable-plugins) the plugin "Create Notes from Chord texts", and restart MuseScore.
- Open a score with chord texts.
- Run the plugin via ``plugin > Create Notes from Chord texts``
- The plugin adds two staves*, one for chord notes (called root chord) and one for bass notes*.
- *The plugin starts with an option box, there you can set wanted options, see __Options__ below. E.g. don't add bass notes.
- The plugin will try to close the score when finished, then asking for `<Save>`, `<Discard>` or `<Cancel>`. The reason is that the score will be in a bad state after the plugin have finished, and the added notes are not playable yet.
- Reopen the score and listen to the music.
- To easy change the added notes see [MuseScore shortcuts](https://musescore.org/en/handbook/note-input), e.g. ctrl up/down to move a note up/down one octave.

## Rules
The plugin uses rules in [wiki: Chord names and symbols (popular music)](https://en.wikipedia.org/wiki/Chord_names_and_symbols_(popular_music)) (as I understand them).

__Allowed values for:__  
_Key signatures_
- `...b` : ...es/s ("full german" notation for `b`, e.g. `Des` means `Db`, `Eb` and `Ab` has only "s"; `Es` and `As`)
- `...#` : ...is ("full german" notation for `#`, e.g. `Dis` means `D#`)

_Extensions_
- `maj:` ^, Δ, ∆, M, j, ma, major</td>
- <dt>m:&nbsp;&nbsp;</dt> − (Unicode hx2212), -, min, minor
- `aug:` +
- `dim:` ° ("degree"), (low case) o
- `0 (digit):` Ø, ø
- `sus4:` 4, sus
- `sus2:` 2


_Alterations_
- <dt>b:&nbsp;&nbsp;</dt> ♭ (Unicode), -, dim
- <dt>#:&nbsp;&nbsp;</dt> ♯ (Unicode), +, aug
- `add:` dom, maj (it's __not__ the same as `#` according to [used Chord rules](https://en.wikipedia.org/wiki/Chord_names_and_symbols_(popular_music)))
- `omit` : no, not, drop

_Alternative syntax and short ways_
- ending `0` same as `07`
- alone `^` same as `maj7` (but not "only" `maj`, `Cmaj` = `C`, `C^` = `Cmaj7`)
- only `[tone]+/aug` same as `aug[tone]`
- `N.C.` (no chord) allows `N.C`, `n.c.` and `n.c`

_Specials_
- Chord texts that starts with "`(`", or if it ends with "`)`" without any "`(`" before, will be totally ignored.
- `alt`, `lyd` and any only text in parentheses, e.g. `(blues)` is just ignored. E.g. `Calt` will generate a normal `C`; `C-E-G`.

## Notes

- The plugin extends one chord until next chord. To avoid that, if you want no sounding chord, use `N.C.` (which means "no chord") as chord text.

- The plugin uses note signatures according to the chord extensions for the added notes. E.g. `Cdim` will add `C-Eb-Gb` and not `F#`, and `Caug` will add `C-E-G#` and not `Ab`. But double key signatures are removed, e.g. `Cdim7` will add `C-Eb-Gb-A` __not__ `Bbb`, and `C#aug` will add `C#-F-A` __not__ `C#-E#-G##`.

- The added staves will use instrument "Piano". The staff for bass notes is however using normal G-clef (unlike when adding the instrument in the UI), and the bass notes will recide far down (if "bass notes" is used). After the plugin it's a good idea to change to a F-clef to have it more readable.

- If the score already has enough staves the plugin __will use staff #2 and #3__ (only #2 if "bass notes" isn't used) and __overwrite any notes__ that are already there (for voice 1).  
To avoid that you must add 2 staves (or 1 if "bass notes" isn't used) yourself as staff #2 and #3 (only #2 if "bass notes" isn't used). Or if you have a melody in e.g. staff #2 you can change that from voice #1 to another voice before you run the plugin and it will not be overwritten.

- Added chord notes (in staff #2) will include also the root note. If "bass notes" is used (staff #3) it will add the root note also as bass note (some octaves down, see __Options__), but if it's a different bass note using "slash" notation it will be that note as bass note.

- If the plugin can't parse some part of the chord text it will just ignore that. In that case the ignored part is shown as "Staff text" above staff #2.

## Options
The plugin starts with an option box, there you have these choices:  
- __Octave for root Chord__  
_1, 0 or -1_  
Octave `0` starts with C0.

- __Max root note, otherwise 1 octave down__  
_"Don't use", D, E, F, G, A or B_  
`Don't use:` Don't change octave, all in __Octave for root Chord__.  
`D, E, ...:` If the root note of the chord is above this the chord notes will be one octave down relative to __Octave for root Chord__.
- __Octave for bass note__  
_"Don't use", 0, -1, -2 or -3_  
`Don't use:` No staff with bass notes will be used (but the staff will be added anyway).  
Octave `0` starts with C0.
- __Min bass note, otherwise 1 octave up__  
_"Don't use", D, E, F, G, A or B_  
`Don't use:` Don't change octave, all in __Octave for bass note__.  
`D, E, ...:` If the bass note of the chord is under this the bass note will be one octave up relative to __Octave for bass note__.
- __Lower case keys mean minor chords__  
`c` (lower case) means `Cm` (C minor) and `C` (upper case) means `C` (C major).
- __Allow add to last harmony (experimental)__  
E.g. `C` will generate `C-E-G`, and if next chord text is only `7` it's adding the notation to `C` (the last chord) and generating `C-E-G-Bb`. It's the same as writing `C7`. The next can then be `6` which means `C76` (`c7add6`).  
It's experimental, and only there because a friend of mine uses that notation.
- __Reduce chords__  
Reducing chords according to [used Chord rules](https://en.wikipedia.org/wiki/Chord_names_and_symbols_(popular_music)) where it mention "... is often omitted".  
`None:`  
Don't reduce chords.  
`Medium:`  
_11th chord_ : no major 3rd.  
_13th chord_ : no perfect 5th or perfect 11th/4th.  
`Max, as Medium plus:`  
as `Medium` plus these  
_9th chord_ : no perfect 5th.  
_13th chord_ : no major 9th, no major 2nd (unless "`sus2`" is used).
- __9th, 11th and 13th extension implies lower__  
9th chord implies 7th, 11th chord implies 9th and 7th, and 13th chord implies 11th, 9th and 7th. According to [used Chord rules](https://en.wikipedia.org/wiki/Chord_names_and_symbols_(popular_music)).  
If you use this but want only the 9th for some chord use e.g. `Cadd9`.
- __Write parsed Harmony texts__  
The plugin allows different styles of writing chords. When parsing them it tries to change them to "correct" syntax. To see the parsed chord texts, use this option.  
If used it will add the parsed chord text as both "Chord text" and as "Staff text", above staff #2, then you can see how MuseScore will show them and also the real text after parsing by the plugin.  
These will also show ignored parts of the chord text (if any).
- __Write Chord letters__  
Write generated notes as letters, can be a help to easy see what notes are generated. It's written as "lyrics" under staff #2 if used, that is because the measures ought to be stretched to avoid overlaying.  
`No:`&nbsp;</dt> Don't use this.  
`Yes`: Write real notes as e.g. `D-F#-A-C#` for `Dmaj7`.  
`In C-scale` : Write notes in C-scale, e.g. `C-E-G-B` for `Dmaj7`, to easy recognize the chord.

## Issues

Kindly report issues or requests in the [issue tracker](https://github.com/per-d/notes-from-chord-texts/issues).

If you find something that doesn't follow [used Chord rules](https://en.wikipedia.org/wiki/Chord_names_and_symbols_(popular_music)), or something in that page that isn't correct or missing, I would appreciate if you report that.

## Known issues
(won't fix)  
- For some scores the plugin crashes. To avoid this close all scores and start the plugin. Just click the shown error message and then open the score you want and run the plugin again.  
If the plugin still crashes even if this is done, then you can report that as an issue.

- The plugin is depending on notes or rests for every chord. If a chord has no "own" note or rest it will not generate notes for that, acting as if there is no chord text there and extending the notes from the last chord. To solve that add a rest "under" the chord text.

## Tip

- For "soft" melodies, e.g. "Silent Night" it sounds better (IMHO) with "pipe organ" for the added chords and "violin" for the melody. If you add the extra staves before the plugin it will use them instead of adding "piano" staves.

- It's a good idea to make a copy of the score before starting the plugin.

## Defaults

The "option box" is using default values. They are defined in the code in _notes_from_chord_texts.qml_. It's kind of easy to change the default values if you know javascript programming, they are all defined in the top when defining `var glb`.

The default values are optimized for a nice sound for soft melodies when using "violin" for the melody and "pipe organ" for the added chord and bass notes.
