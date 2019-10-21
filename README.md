<style>
  code {
    color: darkred !important;
    font-family: lucida console !important;
  }
</style>
# MuseScore 2.x plugin - Notes from Chord texts

This plugin for [MuseScore 2.x](http://musescore.org/) reads chord (Harmony) texts and creates Chord notes in one added staff, and bass note in another added one if chosen. The created notes have correct durations according to the duration of the written chord, and are playable by MuseScore.

The plugin uses rules in [wiki: Chord names and symbols (popular music)][1] (as I understand them). All possible combinations of chords according to rules in that page are recognized and will generate notes.

The created notes are more of a suggestion, to get it to sound nice it's perhaps a good idea to move some notes one octave up or down, or just remove them.

**Example, _before_:**  
![Example before](https://github.com/per-d/notesFromChordTexts/raw/master/test/silent_night_test_before.PNG)  

**_After_**:  
Ran with default settings, and chose to manually add "pipe organ" with only 2 clefs (see [__Staves for Chord and bass notes__](#staves-for-chord-and-bass-notes)).  
The 7th in the last chord is manually moved down 1 octave after the plugin.  
![Example after](https://github.com/per-d/notesFromChordTexts/raw/master/test/silent_night_test_after.PNG)

[Click to see another example](https://github.com/per-d/notesFromChordTexts/raw/master/test/test_chords_after.PNG) that uses default options except these:  
__Octave for bass note:__ "`Don't use`", __Reduce chords:__ "`None`", option __Write parsed Harmony texts__ and __Write Chord letters:__ "`Yes`".  
This example also shows some alternative ways of writing chords, and have some comments added.

## Idea from

This plugin was inspired from MuseScore 2.x plugin [Generate Notes from Chords annotations](https://github.com/berteh/musescore-chordsToNotes).

## How-To

- [Download](https://github.com/per-d/notesFromChordTexts/zipball/master) and [install the plugin](https://musescore.org/en/handbook/plugins-0#installation) to your MuseScore 2.0+ plugin folder.
- Only the [qml file](https://github.com/per-d/notesFromChordTexts/raw/master/notesFromChordTexts.qml) is needed, but it can be a good idea to copy the folder into the plugin folder, partly to use test scores in sub folder [test](https://github.com/per-d/notesFromChordTexts/tree/master/test), and in the future perhaps translation files will be added.
- [Enable](https://musescore.org/en/handbook/plugins#enable-disable-plugins) the plugin "notesFromChordTexts", and restart MuseScore.
- Open a score with chord texts.
- Run the plugin via ``Plugins > Chords > Notes from Chord texts``
- The plugin adds two staves*, one for chord notes (called root chord) and one for bass notes*.
- *The plugin starts with an option box, there you can set the options you want, see [__Options__](#options) below. E.g. don't add bass notes.
- The plugin will try to close the score when finished, then asking for `<Save>`, `<Discard>` or `<Cancel>`. The reason is that the score will be in a bad state after the plugin have finished, and the added notes are not playable yet. So, do save/close.
- Reopen the score and listen to the music.
- To easy change the added notes see [MuseScore shortcuts](https://musescore.org/en/handbook/note-input), e.g. ctrl up/down to move a note up/down one octave.

## Rules
Chords can be written in different ways, this plugin allows all alternatives described in [used Chord rules][1], and some more. "Chord containing quarter tones" and "Polychords" are not implemented though.

__Allowed synonyms for:__

<table>
  </tr><tr>
    <td></td><td></td>
  <tr>
    <td><b><i>Extension</i></b></td>
    <td><b><i>Synonyms</i></b></td>
  </tr><tr>
    <td><code>m</code></td><td>− (Unicode hx2212), -, min, minor</td>
  </tr><tr>
    <td><code>maj</code></td><td>^, t, Δ, ∆, M, j, ma, major (t only as "alone")</td>
  </tr><tr>
    <td><code>aug</code></td><td>+</td>
  </tr><tr>
    <td><code>dim</code></td><td>° ("degree"), o (low case character)</td>
  </tr><tr>
    <td><code>0&nbsp;(zero)</code></td><td>Ø, ø</td>
  </tr><tr>
    <td><code>sus4</code></td><td>4, sus</td>
  </tr><tr>
    <td><code>sus2</code></td><td>2</td>
  </tr><tr>
    <td></td><td></td>
  </tr><tr>
    <td><b><i>Alteration</i></b></td>
    <td><b><i>Synonyms</i></b></td>
  </tr><tr>
    <td><code>b</code></td><td>♭ (Unicode), -, dim</td>
  </tr><tr>
    <td><code>#</code></td><td>♯ (Unicode), +, aug</td>
  </tr><tr>
    <td><code>add</code></td><td>dom, maj (<code>maj</code> is not the same as <code>#</code> according to <a href="https://en.wikipedia.org/wiki/Chord_names_and_symbols_(popular_music)">used Chord rules</a>)</td>
  </tr><tr>
    <td><code>omit</code></td><td>no, drop</td></td>
  </tr><tr>
    <td></td><td></td>
  </tr><tr>
    <td colspan="2"><b><i>Alternative syntax and short ways</i></b></td>
  </tr><tr>
    <td>ending&nbsp;<code>0</code></td><td>same as <code>07</code></td>
  </tr><tr>
    <td>alone&nbsp;<code>^</code>&nbsp;or&nbsp;<code>t</code></td><td>same as <code>maj7</code> (but not alone <code>maj</code>; <code>Cmaj</code> = <code>C</code>, <code>C^</code> = <code>Cmaj7</code>)</td>
  </tr><tr>
    <td>only&nbsp;<code>[tone]+/aug</code></td><td>same as <code>aug[tone]</code>, e.g. <code>C7+</code> = <code>C+7</code></td>
  </tr><tr>
    <td><code>N.C.</code>&nbsp;(no chord)</td><td>also allows <code>N.C</code>, <code>n.c.</code> and <code>n.c</code></td>
  </tr><tr>
    <td></td><td></td>
  </tr><tr>
    <td colspan="2"><b><i>Specials</i></b></td>
  </tr><tr>
    <td colspan="2">Chord texts that starts with "<code>(</code>", or if it ends with "<code>)</code>" without any "<code>(</code>" before, will be totally ignored.</td>
  </tr><tr>
    <td colspan="2"><code>alt</code>, <code>lyd</code> and for only text in parentheses, e.g. <code>(blues)</code> is just ignored. E.g. <code>Calt</code> will generate a normal <code>C</code>; <code>C-E-G</code>, but the ignored part is shown as "Staff text" above staff #2.</td>
  </tr><tr>
    <td></td><td></td>
  </tr>
</table>

## Notes

- The plugin extends one chord until next chord. To avoid that, if you want no sounding chord, use `N.C.` (which means "no chord") as chord text.

- The plugin uses note signatures according to the chord extensions for the added notes. E.g. `Cdim` will add `C-Eb-Gb` and not `F#`, and `Caug` will add `C-E-G#` and not `Ab`. But double key signatures and "specials" are changed, e.g. `Cdim7` will add `C-Eb-Gb-A` __not__ `Bbb`, and `C#aug` will add `C#-F-A` __not__ `C#-E#-G##`.

- If the plugin can't parse some part of the chord text it will just ignore that. In that case the ignored part is shown as "Staff text" above staff #2.

- Added Chord notes (in staff #2) will include also the root note. If "bass notes" is used (staff #3) it will add the root note also as bass note (some octaves down, see [__Options__](#options)), but if it's a different bass note using "slash notation" it will be that note as bass note.

- __"German" and "Full German"__. The plugin handles these variants, as long as it's correctly set in MuseScore.  

## Options

[Show screenshot of the Options box](https://github.com/per-d/notesFromChordTexts/raw/master/test/screenshot.PNG)  
The plugin starts with an option box, there you have these choices:  
- __Octave for root Chord__  
_1, 0 or -1_  
Octave `0` starts with C0.

- __Max root note, otherwise 1 octave down__  
_"Don't use", D, E, F, G, A or B_  
`Don't use:` Don't change octave, root note of chords always in __Octave for root Chord__.  
`D, E, ...:` If the root note of the chord is above this the chord notes will be one octave down relative to __Octave for root Chord__.

- __Octave for bass note__  
_"Don't use", 0, -1, -2 or -3_  
`Don't use:` No staff with bass notes will be used (but the staff will be added anyway).  
Octave `0` starts with C0.

- __Min bass note, otherwise 1 octave up__  
_"Don't use", D, E, F, G, A or B_  
`Don't use:` Don't change octave, bass note of chords always in __Octave for bass note__.  
`D, E, ...:` If the bass note of the chord is under this the bass note will be one octave up relative to __Octave for bass note__.

- __Lower case keys mean minor chords__  
`c` (lower case) means `Cm` (C minor) and `C` (upper case) means `C` (C major).  
This is __not__ dependent on the MuseScore setting "_Lower case minor chords_". Normally all chord keys are shown in MuseScore with upper case no matter if it's typed in with lower or upper case (if "_Automatic Capitalization_" is used). If the MuseScore setting "_Lower case minor chords_" is used they are shown as they are typed in. If the setting is used for the plugin it will treat lower case keys as minor chords even if it's not set in MuseScore and therefore shown in MuseScore with upper case.

- __Allow add to last harmony (experimental)__  
E.g. `C` will generate `C-E-G`, and if next chord text is only `7` it's adding the notation to `C` (the last chord) and generating `C-E-G-Bb`. It's the same as writing `C7`. The next can then be `6` which means `C7/6` (`c7add6`).  
It's experimental, and only there because a friend of mine uses that notation.

- __Reduce chords__  
Reducing chords according to [used Chord rules][1] where it mention "... is often omitted".  
`None:`  
Don't reduce chords.  
`Medium:`  
for _11th chord_ : no major 3rd.  
for _13th chord_ : no perfect 5th or perfect 11th/4th.  
`Max, as Medium plus:`  
as `Medium` plus these  
for _9th chord_ : no perfect 5th.  
for _13th chord_ : no major 9th, no major 2nd (unless "`sus2`" is used).

- __9th, 11th and 13th extension implies lower__  
9th chord implies 7th, 11th chord implies 9th and 7th, and 13th chord implies 11th, 9th and 7th. According to [used Chord rules][1].  
If you use this but want only the 9th for some chord use e.g. `Cadd9`.

- __Write parsed Harmony texts__  
The plugin allows different ways of writing chords. When parsing them it tries to change them to "correct" syntax. To see the parsed chord texts, use this option.  
If used it will add the parsed chord text as both "Chord text" and as "Staff text", above staff #2, then you can see how MuseScore will show them and also the real text after parsed by the plugin.  
These will also show ignored parts of the chord text (if any).

- __Write Chord letters__  
Write generated notes as letters, can be a help to easy see what notes are generated. It's written as "lyrics" under staff #2 if used, that is because the measures ought to be stretched to avoid overlaying.  
`No:`&nbsp; Don't use this.  
`Yes`: Write real note letters as e.g. `D-F#-A-C#` for `Dmaj7`.  
`In C-scale` : Write note letters in C-scale, e.g. `C-E-G-B` for `Dmaj7`, to easy recognize the chord.

## Staves for Chord and bass notes

The plugin uses 1 or 2 staves depending on if "bass notes" is used. Generating Chord notes in staff #2 and bass notes in staff #3 - if used. Either in automatically added or existing staves.

After the Options box it checks that there are enough staves. There are some alternatives:

- If only one staff in the Score it asks if you want to create 2 (or 1) extra staves.  
  - If you answer "`Yes`" it adds two staves with instrument "Piano" (will use only one if not "bass notes").  
The staff for bass notes is however using normal G-clef (unlike when adding the instrument in the UI), and the bass notes will reside far down (if "bass notes" is used). After the plugin it's a good idea to change to a F-clef to have it more readable.
  - Answer "`No`" if you want to choose what instrument to add. Make sure you add enough staves, 2 if "bass notes" is used, otherwise 1. If not enough staves it gives an error message.
  - Or "`Cancel`" to quit the plugin.  

- If enough staves already exist it asks if it's ok to use them (or only one if not "bass notes").  
It will then __overwrite any notes__ that are already there, for voice #1. Notes in other voices are not touched.

- If more than one staff but not enough it will give an error message.

## Issues

Kindly report issues or requests in the [issue tracker](https://github.com/per-d/notesFromChordTexts/issues).

If you find something that doesn't follow [used Chord rules][1], or something in that page that isn't correct or missing, I would appreciate if you report that.

## Known issues
(won't fix)  
- For some scores the plugin crashes. To avoid this, start the plugin with no score opened. Just click the shown error message and then open the score you want and run the plugin again. This "fix" will last for the whole MuseScore session.  
If the plugin still crashes even if this is done, then you can report that as an issue.

- The plugin is depending on notes or rests for every chord text. If a chord text has no "own" note or rest it will not generate notes for that, acting as if it's no chord text there and extending the notes from the last chord. To solve that, split the note before so you have one "under" the chord text and bind them with a legato (or add a rest there if it's more suitable).

## Tip

- For "soft" melodies, e.g. "Silent Night" it sounds better (IMHO) with "pipe organ" for the added chords and "violin" for the melody. If you add the extra staves before the plugin with your own choices of instruments it will use them instead of adding "piano" staves.

- It's a good idea to make a copy of the score before starting the plugin.

## Defaults

The "Options box" is using default values. They are defined in the code in _notesFromChordTexts.qml_. It's kind of easy to change the default values if you know javascript programming, they are all defined in the top when defining `var glb`.

The default values are optimized for a nice sound for soft melodies when using "violin" for the melody and "pipe organ" for the added chord and bass notes, IMHO.

[1]: https://en.wikipedia.org/wiki/Chord_names_and_symbols_(popular_music)