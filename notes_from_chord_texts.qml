//=============================================================================
// vim: ft=javascript
//
//  MuseScore - Chord texts to playable Chord and bass notes
//
//  Copyright (C) 2019 PerD - https://github.com/
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//
//  documentation: https://github.com/
//  support:       https://github.com/
//
//=============================================================================

/*******************************************************************************
 * Vocabulary in variable names and comments.
 * - tick      The position for a Segment or current Cursor.
 * - harmony   The written chord, e.g. "Dmaj7", also MS Harmony object.
 * - chord     Notes for a harmony, also MS Chord object.
 * - rest      A rest (instead of a chord), also MS Rest object.
 * - duration, durationType, ticks
 *             The length (ticks) for a Chord/Rest. MS#duration is another
 *             thing, it's an object for the duration of the Chord/Rest.
 * - note      Most often MS Note object, the representation in a Score.
 * - tone      The "musical" term for the pitch,
 *             in C-scale: 1 = C, 2 = D, 3 = E, 4 = F etc.
 * - pitch     The pitch, here "half-tones" over the root, in MS it's counting
 *             from a low low C increasing by 12 for every octave.
 *             in C-scale: 0 = C, 1 = C#/Db, 2 = D, 3 = D#/Eb, 4 = E, 5 = F etc.
 * - semitones "Half step" or "half tone". The diff between 'pitch' for a tone
 *             and the 'pitch' for the root of the chord.
 * - tpc       tpc is ...TPC. Using TPC is a way of specifying how the tone should
 *             be represented as note. E.g. the pitch 3 (C-scale) can mean both
 *             D# and Eb, but in TPC they have different representations.
 *
 * The parsing of chords (written chords, in the code called harmonies) is based on:
 * [r]:
 * https://en.wikipedia.org/wiki/Chord_names_and_symbols_(popular_music)
 * https://en.wikipedia.org/wiki/Chord_(music)
 * (there is a fault in the above page I think, "C-(b5)" resolves to "C Eb Gb Bb"
 * but should be "C Eb Gb" according to other rules in the page)
 * https://en.wikipedia.org/wiki/Suspended_chord
 * [r2]:
 * http://www.musikipedia.se/ackord
 * etc.
 * [r] and [r2] in comments means rules that I found on these pages.
 * It's my own understanding of all different variants of writing a harmony,
 * and not necessarily how it should be.
 * Same harmony variant can be written in many different ways, depending on the
 * music style (e.g. jazz). And also played in different ways depending on the
 * instrument it is played on, for some instruments some of the notes that
 * should be included according to the rules are just ignored (I think).
 *
 * "seventh chords" and other twists:
 * This is kind of confusing, and may be up to the player to interpret it correct.
 * Here I use the definitions in [r]-first, both real definitions and from
 * examples, all examples in C-scale.
 *  - "C^" (C with Unicode 0394 or 2206) is usually interpreted as "C^7" ("Cmaj7"),
 *    but some will mean "Cmaj" ("C").
 *    I use "C^" = "C^7".
 *  - Straight tones (not sharp nor flat) is called different for different tones:
 *    major 2nd, perfect 4th, perfect 5th, major 6th, major 9th, perfect 11th
 *    and major 13th.
 *    They are all "straight", so e.g. "major 6" = only "6" (= A) and not equal
 *    to "#6" (= A#), "minor 6" is however equal to "b6" (= Ab).
 *    For 7th it's different (according to examples in [r]). "major 7" = B,
 *    "#7" is also = B (not B# or C). Only "7" is = Bb, the same as "minor 7"
 *    and "b7". "7" in a "dim" chord means Bbb (= A).
 *  - I'm using "A" instead of "Bbb" for "diminished seventh". Also other
 *    is treated the same way, e.g. "bb6" (Abb) in "Cm(bb6)" is changed to "5" (G),
 *    if that for some reason is used.
 *
 *  - "sus". "sus"/"4" means "sus4", "2" means "sus2", both if that is the main
 *    extension. Some may mean that e.g. "C2" should mean "Cmaj2" (or "Cadd2"),
 *    but as I understand it the most common is that it means "Csus2". Just
 *    use "Cadd2"/"Cmaj2"/"Cdom2"/"C(2)" if it shouldn't mean "Csus2". The same
 *    with "4".
 *
 * "alt" in e.g. "C7alt" is not implemented here, "alt" is just ignored. The
 * reason is that this is mostly(?) used in jazz and is up to the player what
 * alterations that should be played:
 * https://en.wikipedia.org/wiki/Altered_chord
 * "neutral chords", e.g. "Cn", are either not implemented, just ignored.
 *
 * See the generated notes as a suggestion. Depending on what instrument for
 * the chords it can sound better if some of the generated notes are removed,
 * or moved up or down one octave.
 *******************************************************************************/

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.3

import MuseScore 1.0

MuseScore {

version:     "1.0"
description: "This plugin expands harmonies into chord and bass notes in" +
             " added staves, playable by MuseScore."
menuPath:    "Plugins.Create Notes from Harmonies"
//requiresScore: true //not supported before 2.1.0, manual checking in mainObject.initLg

/***
 * Main object.
 */
property var mainObject: function() {
//xxxMainxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
var mo = this;

var staffObj, elemDo;

var gStaff = {
  main: 0,
  mid:  1,
  bass: 2
};
mo.gStaff = gStaff;

var glb = {
  // What should be written by console.log
  // 0:  basic
  // 1:  basic+
  // 2:  adding semitone/note
  // 4:  write chord
  // 10: harmony -> chord notes, details
  // 15: harmony, line with result
  // etc.  (look in code for first parameter to 'conLog')
  debugLevels:   [ 0, 1, 15 ],

  // Name for the debug file, set it to falsy ("", null, false, 0...) or just
  // comment it out if not logging to file
  //debugFile:     "debug_notes_from_chord_texts",

  // If settings dialog should be shown, can be annoying with the dialog when debugging
  // (normally true)
  swUseDialog:   true,

  // If dialog to adding staves should be shown, otherwise adding without question
  // (normally true)
  swAskStaffAdd: true,

  // Decides if ok message should be shown after successful run
  // (normally true)
  swShowOk:      true,

  // Decides if close document dialog should be shown when the plugin finish
  // also 'swShowOk' must be true
  // (normally true)
  swAskClose:    true,

  // instrument for staves that are added if only one staff in the Score
  // NB! must be present in [MuseScore program folder]/instruments/instruments.xml
  addStavesInstrument:     "piano",

  /// Defaults for Settings box, and as settings for the code ///

  // Octave for the notes in the chord
  // for Settings box (1 = 0)
  octaveRootDefaultIndex:  1,
  // for the code, gets value from the Settings box if used
  octaveRoot:              0,

  // Octave for the bass note from the chord
  // for Settings box (3 = -2)
  octaveBassDefaultIndex:  3,
  // for the code, gets value from the Settings box if used
  octaveBass:              -2,

  // Max pitch for the chord's root, above will add notes one octave down (from
  // 'octaveRoot'), set it to falsy to not use it (0 is also falsy)
  // for Settings box (4 = G)
  rootMaxDefaultIndex:     4,
  // for the code, gets value from the Settings box if used (7 = G)
  rootMaxPitch:            7,

  // Min pitch for the chord's bass note, below will add the note one octave up
  // (from 'octaveBass'), set it to falsy to not use it (0 is also falsy)
  // for Settings box (2 = E)
  bassMinDefaultIndex:     2,
  // for the code, gets value from the Settings box if used (4 = E)
  bassMinPitch:            4,

  // If reducing notes in extended chords should be done.
  // It's done according to [r] in that case. Two levels, 1 and 2:
  //   0/falsy: nothing reduced.
  //   1: 11th chord, remove 3rd if that is major (not sharp nor flat).
  //      13th chord, remove 5th if that is perfect (major),
  //                  remove 11th if that is perfect (major),
  //                  the same with 4th (1 octave under 11th) if that is perfect.
  //   2: same as "level 1" plus:
  //      9th chord,  remove 5th if that is perfect (major).
  //      13th chord, remove 9th if that is major,
  //                  the same with 2th (1 octave under 9th) if that is major
  //                  - and not a sus2 chord.
  // used in code and as default in Settings box if used (0 = None)
  reduceChordsLevel:   0,

  // If 9th chord should imply 7th, 11th imply 9th and 7th etc.
  // used in code and as default in Settings box if used
  extImpliesLower:     true,

  // Lower case letters means minor harmonies
  // used in code and as default in Settings box if used
  lowIsMinor:          false,

  // Allow harmony notation to add to last harmony (experimental)
  // used in code and as default in Settings box if used
  allowAddToLast:      false,
  // show in Settings box
  allowAddToLastShow:  true,

  // Write the parsed Harmony text as Staff Text
  // used in code and as default in Settings box if used
  writeParsed:         false,

  // Write Chord note letters in, 1 = yes, 2 = in C-scale, as Staff Text
  // used in code and as default in Settings box if used (0 = No)
  writeChordNotes:     0,

  /// Used internally: ///

  swQuit:            false,
  alwaysTranspose:   true,
              // tone:  1   2   3   4   5   6   7
  toneToSemiPitch:   [  0,  2,  4,  5,  7,  9, 11 ],
  toneLetters:       [ 'C','D','E','F','G','A','B' ],

  tpcLetters:        [ 'F', 'C', 'G', 'D', 'A', 'E', 'B' ],
  tpcAlts:           [ 'bb', 'b', '', '#', '##' ],
  tpcToneC:          14,
  tpcAlterFact:      7,
  // pitch is 60 for C in octave 0, incr/decr by 12 for each octave up/down.
  pitchCinOctave0:   60,
  pitchOctave:       12,
  crochetTicks:      480, // ticks for 1/4 note

  harmonyNbr:        0,
  lyricsNbr:         0,

  // undef: <- don't define it's used as "undefined" value

  resultText:     "",
  resultInfoText: "",
  resultIcon:     StandardIcon.Information,
  resultButtons:  StandardButton.Ok,

  // ignore harmonies that starts with "(" or "[", or ends with "(" (without
  // any earlier "("), parentheses can span over two harmonies.
  ignoreHarmonyRegex: /^((\(|\[)|[^(]*\)$)/,
  // [r] "N.C." means "no chord", should be a rest instead
  noChordRegex:       /^\s*(N\.C\.?)\s*$/i
};

mo.glb = glb;

/***
 * Staff object. Methods/properties for handle staves.
 */
mo.staffObject = function() {
  var st = this;

  var cursor, curTick,
      chordCursor  = [],
      nextCursor   = [],
      staffDebName = [],
      lastChord    = [];

  /***
   * Init the Staff object.
   * @param {MS Cursor} inCursor
   */
  st.init = function(inCursor) {
    // set all involved cursors
    for (var staffKey in gStaff) {
      var staff = gStaff[staffKey];
      if (staff < 1) continue;
      chordCursor[staff] = curScore.newCursor();
      nextCursor[staff]  = curScore.newCursor();
    }
    // debug names
    staffDebName[gStaff.mid]  = "Mid";
    if (gStaff.bass) staffDebName[gStaff.bass] = "Bass";
    // init cursors
    st.initCursors(inCursor);

    st.measureNbr = 0;
  };

  /***
   * Reinit the cursors.
   * @param {MS Cursor} inCursor
   */
  st.initCursors = function(inCursor) {
    cursor = inCursor;
    cursor.rewind(0);
    // init all involved cursors
    for (var staffKey in gStaff) {
      var staff = gStaff[staffKey];
      if (staff < 1) continue;
      // beginning of score for all of them
      chordCursor[staff].rewind(0);
      nextCursor[staff].rewind(0);
      // and set Staff id
      chordCursor[staff].staffIdx = staff;
      nextCursor[staff].staffIdx = staff;
    }

    st.measureNbr = 0;
  };

  /***
   * "Translates" 'curTick' to human string, see #ticksToStr.
   */
  st.curTickToStr = function(debT, addToStep, showMeasures) {
    return st.ticksToStr(curTick, debT, addToStep, showMeasures);
  };

  /***
   * "Translates" <ticks> to human string, steps and ticks.
   * @param {Number} <ticks>      'tick' from cursor or "duration".
   * @param {String} <debT>       opt. Pre text for debug. If includes "@"
   *                              <showMeasures> is considered true.
   * @param {Number} <addToStep>  opt. Add this to steps (can be useful when it's
   *                              a cursor.tick, first note in system  is
   *                              otherwise as step 0.
   * @param {Bool|String} <showMeasures> opt.
   *                              If <ticks> ('tick') also should be "translated"
   *                              to measure number and step within the measure.
   *                              If {String} it will be as pre text.
   * @return {String} "[steps] ([ticks])"
   *   ticksToStr(2880)             //=> "6 (2880)"
   *   ticksToStr(2880, "Hey ")     //=> "Hey 6 (2880)"
   *   ticksToStr(2880, "Hey @", 1) //=> "Hey @7 (2880) - 2:4 (1440)" (if only 3 steps in measure 1)
   */
  st.ticksToStr = function(ticks, debT, addToStep, showMeasures) {
    if (! debT) debT = "";
    var showAt = /@/.test(debT),
        text   = st.ticksToSteps(ticks, debT, addToStep);
    if (showMeasures || showAt) {
      text += " - ";
      if (typeof(showMeasures) === "string") text += showMeasures;
      text += st.measureNbrFromTick(ticks, "");
    }
    return text;
  };

  /***
   * "Translates" <ticks> to "measure steps" {Number or String} depending on <debT>,
   * see also #ticksToStr.
   * @param {Number} <ticks>      'tick' from cursor or "duration".
   * @param {String} <debT>       opt. Pre text for debug. If String/true it will
   *                              return a String, otherwise a Number.
   * @param {Number} <addToStep>  opt. Add this to steps.
   * @return {Number|String}
   */
  st.ticksToSteps = function(ticks, debT, addToStep) {
    var steps = (ticks ? ticks / glb.crochetTicks : 0);
    if (truthy(debT, "")) {
      if (addToStep) steps += addToStep;
      // add " " if debT and not "@" as last character
      if (debT && ! /@$/.test(debT)) debT += " ";
      steps = debT + steps + " (" + ticks + ")";
    }
    return steps;
  };

  /***
   * "Translates" 'tick' to measure number.
   * @param {Number} <tick>         The tick.
   * @param {String} <debT>         opt. If String it returns a String, but <debT>
   *                                is not included.
   * @param {Number} <denominator>  opt.(4) the measure denominator.
   * @return {Number|String} String if debT is a String with 'tick' in parentheses.
   */
  st.measureNbrFromTick = function(tick, debT, denominator) {
    // secure 0 if nothing (or 0)
    if (! tick) tick = 0;
    var mNbr, step, wholeSteps, measureTick,
        wholeTicks = tick - st.firstMeasureTicks;
    mNbr = 1;
    if (wholeTicks < 0) {
      step = st.ticksToSteps(tick) + 1;
    } else {
      if (! denominator) denominator = 4;
      wholeSteps  = st.ticksToSteps(wholeTicks);
      step        = (wholeSteps % denominator);
      wholeSteps -= step;
      mNbr  += (wholeSteps / denominator) + 1;
      wholeSteps ++;
      step       ++;
    }
    measureTick = (step - 1) * glb.crochetTicks;
    if (truthy(debT, "")) mNbr = "" + mNbr + ":" + step + " (" + measureTick + ")";
    return mNbr;
  };

  /***
   * Inits a lap (new Segment) in main loop.
   */
  st.initLap = function() {
    var measureStep,
        measureStartTick = cursor.measure.firstSegment.tick;
    curTick     = cursor.tick;
    measureStep = (st.ticksToSteps(glb.crochetTicks + (curTick - measureStartTick)));
    if (measureStep === 1) {
      st.measureNbr ++;
      if (st.measureNbr === 1) {
        st.firstMeasureTicks = cursor.measure.lastSegment.tick - measureStartTick;
      }
    }
    st.segmentS = "Segment@" + st.measureNbr + ":" + measureStep + " (" + curTick + ")";
  };

  /***
   * Fixes the last measure. Replacing last Rests with Chords and adjusting durations.
   */
  st.finishUp = function() {
    var chordLast = lastChord[gStaff.mid];
    if (! chordLast) return;
    conLog(0);
    conLog(0, "----- Adjusting last measure ------------------------------------");
    // sheet with 'curTick' to fix Rests in last measure
    curTick += lastChord[gStaff.mid].durationType;
    var text = "last measure, cursorChord.tick -> End";
    st.advanceCursor(text, gStaff.mid, curTick, true);
    if (gStaff.bass) st.advanceCursor(text, gStaff.bass, curTick, true);
  };

  /***
   * Changes the root and bass (if any) tone to upper case.
   * @param {String} <harmonyText>  The Harmony text.
   * @return {String}
   */
  st.harmonyTextNice = function(harmonyText) {
    // securing String
    if (! harmonyText) harmonyText = "";
    var strM, key, bass;
    if ((strM = harmonyText.match(glb.noChordRegex))) return strM[1].toUpperCase();
    if ((strM = harmonyText.match(/^(([a-g])(([^/]|\/(?![a-g]))*))?((\/)([a-g])(.*))?$/i))) {
      key  = strM[2] || "";
      bass = strM[7] || "";
      if (! glb.lowIsMinor) {
        key  = key.toUpperCase();
        bass = bass.toUpperCase();
      }
      return key + (strM[3] || "") + (strM[6] || "") + bass + (strM[8] || "");
    }
    return harmonyText;
  };

  /***
   * Creates a Text object, and adds it to <parent> if value.
   * @param {MS type}    <type>    MuseScore element type.
   * @param {String}     <text>    The text.
   * @param {Int}        <track>   opt. Staff id, where to add Text object.
   * @param {Number}     <posX>    opt. Position x.
   * @param {Number}     <posY>    opt. Position y.
   * @param {MS element} <parent>  opt. Object to add created Text object to.
   * @return {Text object|Boolean} Boolean if <parent>
   */
  st.addText = function(type, text, staffId, posX, posY, parent, color) {
    var textObj;
    textObj       = newElement(type);
    textObj.text  = text;
    if (truthy(staffId, 0)) textObj.track = staffId * 4;
    if (truthy(posX, 0))    textObj.pos.x = posX;
    if (truthy(posY, 0))    textObj.pos.y = posY;
    if (color)              textObj.color = color;
    if (! parent) return textObj;
    parent.add(textObj);
    return true;
  };

  /***
   * Adds a Chord to 'cursor'.
   * @param {MS Cursor} <cursor>
   * @param {MS Chord}  <chord>
   */
  st.cursorAddChord = function(cursor, chord, staff) {
    var posX, posY,
        harmonyObj  = chord.ctnHarmonyObj,
        harmonyText = chord.ctnHarmonyText || (harmonyObj ? harmonyObj.harmonyOrig : ""),
        text        = st.isRest(chord) ? 'rest' : 'chord';
    cursor.add(chord);
    conLog(4,
      "'>' AddCh, Added ", text, " \"", harmonyText,
      "\" dur: ", st.ticksToStr(chord.durationType), ", at: ", st.ticksToStr(cursor.tick, "", 1, "@")
      );

    if (staff === gStaff.mid && harmonyObj) {
      if (glb.writeParsed && harmonyObj.parsedHarmonyS()) {
        // write the Harmony text as both Harmony and Staff Text, to get it nicely
        // shown and to show the real value
        var harmText = harmonyObj.parsedHarmonyS();
        posY  = -0.5;
        st.addText(Element.HARMONY, harmText, cursor.staffIdx, 0, posY, cursor);
        harmText = harmonyObj.parsedHarmonyS(false, true);
        posX  = 0;
        if (glb.harmonyNbr === 1) {
          st.addText(Element.STAFF_TEXT, "Formatted: ", cursor.staffIdx, -10, posY - 0.5, cursor);
          harmText = "Real: " + harmText;
          posX     = -5;
        }
        posY += 1.5;
        var color = (/ignore/.test(harmText) ? "red" : "");
        st.addText(Element.STAFF_TEXT, harmText, cursor.staffIdx, posX, posY, cursor, color);
      }
      if (glb.writeChordNotes && harmonyObj.chordLettersNice) {
        posY = (glb.lyricsNbr++ % 2) * 1.5;
        st.addText(Element.LYRICS, harmonyObj.chordLettersNice, cursor.staffIdx, 0, posY, chord);
      }
    }
  };

  /***
   * Sets duration for Chord and writes it to <staff>. Also adjusting last Chord.
   * @param {Number}   <staff>  Staff id.
   * @param {MS Chord} <chord>  opt. Chord, see <color>.
   * @param {String}   <color>  opt. Colorizes the Harmony text with <color> at
   *                            the current Segment if value, can be used without
   *                            <chord>.
   * @return {Bool|undef} returns 'false' if some error.
   */
  st.writeChord = function(staff, chord, color, errorMessage) {
    var currentChordObj, harmonyObj, ignore, harmonyElem,
        errorPosY = glb.writeParsed ? 2.5 : -0.5;
    conLog(4);
    conLog(4, "WriteCh, curTick: ", st.curTickToStr("", 1, "@"), " '", staffDebName[staff], "' -----");

    // add the new chord
    if (chord && (st.isRest(chord) || chord.notes && chord.notes.length)) {
      conLog(4, "--- Write new chord  ---");
      currentChordObj = (new st.elemObject).init(cursor.element, "current Chord");
      if (currentChordObj.errorMessage) {
        errorWithColorChord(currentChordObj.errorMessage, currentChordObj.errorInfo);
        conLog(4, "---");
        return false;
      }

      conLog(4, "WriteCh, remain ticks in measure: ", st.ticksToStr(currentChordObj.measureRemain));
      // write the chord
      chord.visible = true;
      chord.durationType = currentChordObj.ticks;
      cursor.staffIdx    = staff;
      st.cursorAddChord(cursor, chord, staff);
      // write "ignore error" if any
      if (! glb.writeParsed && (harmonyObj = chord.ctnHarmonyObj)) {
        ignore = (staff === gStaff.bass ? harmonyObj.bassRemain : harmonyObj.rootRemain);
        if (ignore) {
          st.addText(Element.STAFF_TEXT, "ignored: " + ignore, staff, 0, errorPosY, cursor, "red");
          errorPosY += 1.5;
        }
      }
      cursor.staffIdx    = gStaff.main;
    }

    // adjust last chords (now when we know the tick for the new)
    if (currentChordObj || lastChord[staff]) {
      st.advanceCursor("cursorChord.tick -> curTick", staff, curTick, true);
    }

    // color the harmony text
    if (color) {
      if ((harmonyElem = getSegmentHarmony(cursor.segment))) harmonyElem.color = color;
    }
    // add error message as Staff Text
    if (errorMessage) {
      cursor.staffIdx = staff;
      st.addText(Element.STAFF_TEXT, errorMessage, staff, 0, errorPosY, cursor, color || "red");
      cursor.staffIdx = gStaff.main;
    }

    // remember these
    lastChord[staff] = chord;
    conLog(4, "--- WriteCh, -----------");
  };

  /***
   * Advance the "Staff cursor", adjusting Chords/Rests on the way.
   * @param {String} <debT>            Debug text.
   * @param {Number} <staff>           Staff id.
   * @param {Number} <toTick>          Until it's that tick.
   * @param {Bool}   <cleanRemaining>  If adjust found element's duration when advancing.
   */
  st.advanceCursor = function(debT, staff, toTick, cleanRemaining) {
    var lastChordO, elemObj, newChord, segment,
        cursorChord = chordCursor[staff],
        cursorNext  = nextCursor[staff];
    debT += ": " + cursorChord.tick;

    // return if already at "to tick"
    if (cursorChord.tick >= toTick) return;

    conLog(41, "-");
    conLog(41,
      "Adv, useCursor.staffIdx: ", staffDebName[cursorChord.staffIdx],
      ", @tick: ", cursorChord.tick
      );

    // init values for "clean remaining"
    if (cleanRemaining) {
      conLog(42, "");
      conLog(41, "Adv-Clean, get Last Chord ", st.ticksToStr(cursorChord.tick, "", 1, "@"));
      lastChordO = (new st.elemObject).init(cursorChord.element, "last Chord/Rest");
      if (st.stepToNextChordRest("", staff, toTick)) {
        lastChordO.nextChordTick = cursorNext.segment.tick;
      }
      // setting durationType if beyond max
      lastChordO.maxTicks(true, cursorChord, "(Adv-Clean) last Chord init");
    }

    while(truthy(cursorChord.tick, 0) && (cursorChord.tick < toTick)) {
      cursorChord.next();
      // break if "bad cursor" or same as or past 'toTick'
      if ( ! cursorChord.tick || cursorChord.tick < 0 || cursorChord.tick >= toTick) break;

      conLog(42, "");
      conLog(41, "Adv, .next(), new tick: ", st.ticksToStr(cursorChord.tick, "", 1, "@"));

      if (! cleanRemaining) continue;
      segment = cursorChord.segment;
      conLog(41,
        "Adv-Clean, segment: ", segment, ", .segmentType: ", segment.segmentType);
      elemObj = (new st.elemObject).init(cursorChord.element, "next Chord");
      // only if Chord or Rest
      if (! elemObj.isChordRest) continue;

      conLog(41, "Adv-Clean, element: ", elemObj.self, ", duration: ", st.ticksToStr(elemObj.ticks));
      if (st.stepToNextChordRest("", staff, toTick)) {
        elemObj.nextChordTick = cursorNext.segment.tick;
      }

      if (elemObj.isChord || ! lastChordO.isChord) {
        // just set durationType
        if (elemObj.maxTicks(true, cursorChord, "(Adv-Clean, in loop) adjusting Chord/Rest"))
          conLog(41, "Adv-Clean, element.durationType set to maxTicks: ", lastChordO.ticks);

      } else {
        // replace the Rest with a new Chord to extend last Chord over the Rest
        // The Rest is probably there because it wasn't a "whole" Rest for
        // the Measure before the plugin started
        // (Muse's '.clone()' causes the app to crash)
        newChord = st.cloneChord(lastChordO.self, elemObj.maxTicks());
        newChord.ctnHarmonyText = "cloned";
        st.cursorAddChord(cursorChord, newChord, staff);
        st.setPlayAndChordDuration(
          "(Adv-Clean) chord to fill a Rest", newChord, cursorChord, newChord.durationType
          );
        elemObj = (new st.elemObject).init(newChord, "\"cloned\" Chord");
        conLog(41,
          "Adv-Clean, " +
          "replaced the Rest with new Chord to extend last Chord over the Rest"
          );
      }
      if (elemObj.isChord) lastChordO = elemObj;
    }

    conLog(4, "Adv, ", debT, " -> " + cursorChord.tick);
    conLog(41, "-");
  };

  /***
   * Look up next Chord/Rest.
   * @param {String} <debT>    Debug text.
   * @param {Number} <staff>   Staff id.
   * @param {Number} <toTick>  Until it's that tick.
   */
  st.stepToNextChordRest = function(debT, staff, toTick) {
    var swChord    = null,
        cursorNext = nextCursor[staff];
    if (debT === "") debT = "cursorNext.tick -> curTick:: " + cursorNext.tick;

    while(truthy(cursorNext.tick, 0) && (cursorNext.tick < toTick)) {
      cursorNext.next();
      // break if "bad cursor" or past 'toTick'
      if ( ! cursorNext.tick || cursorNext.tick < 0 || cursorNext.tick > toTick) break;
      conLog(41, "- AdvNextCh/Rst, .next(), new tick: ", st.ticksToStr(cursorNext.tick, "", 1, "@"));
      conLog(41, "- AdvNextCh/Rst, element: ", cursorNext.element);
      if ((swChord = st.isChordRest(cursorNext.segment))) {
        conLog(41, "- AdvNextCh/Rst, got Chord/Rest: ", st.ticksToStr(cursorNext.tick, "", 1, "@"));
        break;
      }
    }
    if (swChord === null) swChord = st.isChordRest(cursorNext.segment);
    conLog(4, "- AdvNextCh/Rst, ", debT, " -> " + cursorNext.tick);
    return swChord;
  };

  /***
   * Sets "play" and Chord duration.
   * @param {String}    <debT>         Name for the chord in debug text.
   * @param {MS Chord}  <chord>        Chord.
   * @param {MS Cursor} <useCursor>    Cursor.
   * @param {Number}    <duration>     Duration for the Chord.
   * @param {Number}    <denominator>  opt.(4) the measure denominator.
   */
  st.setPlayAndChordDuration = function(debT, chord, useCursor, duration, denominator) {
    // set "play duration"
    if (! denominator) denominator = 4;
    conLog(4, debT + ".setDuration: ", st.ticksToStr(duration), "/", denominator);
    useCursor.setDuration(st.ticksToSteps(duration), denominator);
    // set "note duration"
    chord.durationType = duration;
    conLog(4, "set ", debT, ".duration to: ", st.ticksToStr(chord.durationType),
      ", (in)duration: ", duration
      );
  };

  /***
   * Clone a Chord. (Muse's 'clone()' doesn't seem to work)
   * @param {MS Chord} <chord>         The Chord to clone.
   * @param {Number}   <durationType>  opt. Duration for the new Chord, default
   *                                   is Duration for <chord>.
   * @return {MS Chord} the new cloned Chord.
   */
  st.cloneChord = function(chord, durationType) {
    var k, note, newChord;
    if (st.isRest(chord)) {
      newChord = newElement(Element.REST);
    } else {
      newChord = newElement(Element.CHORD);
      for (k in chord.notes) {
        note = chord.notes[k];
        newChord.add(createNote(note.pitch, note.tpc1, note.tpc2));
      }
    }
    newChord.durationType = durationType ? durationType : chord.durationType;
    return newChord;
  };

  /***
   * Determine if Segment has a Chord or Rest.
   * @param {MS Segment} <object>  The segment to determine.
   * @return {Bool} If the element is a Rest.
   */
  st.isChordRest = function(object) {
    if (! object) return false;
    if (object.type === Element.SEGMENT) {
      return (object.segmentType === Segment.ChordRest);
    } else {
      return (st.isChord(object) || st.isRest(object));
    }
  };

  /***
   * Determine if Element is a Chord. (Muse's 'isChord()' doesn't seem to work)
   * @param {MS Element} <element>  The element to determine.
   * @return {Bool} If the element is a Chord.
   */
  st.isChord = function(element) {
    return (element && element.type === Element.CHORD);
  };

  /***
   * Determine if Element is a Rest. (Muse's 'isRest()' doesn't seem to work)
   * @param {MS Element} <element>  The element to determine.
   * @return {Bool} If the element is a Rest.
   */
  st.isRest = function(element) {
    return (element && element.type === Element.REST);
  };

  //////////////////////////////////////////////////////////////////////////////

  /***
   * Object for Chord/Rest.
   */
  st.elemObject = function () {
    var el = this;

    var element;

    /***
     * Sets some useful values for a Measure, Segment, Chord or Rest.
     * @param {MS Element} <inElement>  Element to be examined.
     * @param {String}     <debT>       opt. Debug test.
     * @return {elemObject} self
     */
    el.init = function(inElement, debT) {
      element        = inElement;
      el.self        = element;

      var tick = element.parent && element.parent.tick;
      // secure blank
      if (! debT) { debT = ""; } else { debT += " "; }
      // (for some reason I must add "" as last argument, otherwise it will be "undefined" as last - strange...)
      conLog(42, "ElObj, ", debT, "element: ", element, ", @", tick, " ---", "");
      if (! element) return null;

      el.isMeasure     = (element.type === Element.MEASURE);
      el.isSegment     = (element.type === Element.SEGMENT);
      el.isChord       = (element.type === Element.CHORD);
      el.isRest        = (element.type === Element.REST);
      el.isChordRest   = (el.isChord || el.isRest ||
                          el.segmentType && el.segmentType === Segment.ChordRest);
      el.measureRemain = null;
      el.nextChordTick = null;

      var firstSeg, lastSeg, text,
          okBit = 0,
          elm   = element;

      while (elm) {
        conLog(43, "ElObj, elm: ", elm);
        if (elm.type === Element.SYSTEM) break;

        if (elm.type === Element.CHORD || elm.type === Element.REST) {
          el.ticks = elm.durationType;
          conLog(42, "ElObj, elm Chord/Rest.duration: ", st.ticksToStr(el.ticks));
          okBit |= 0x1;

        } else if (elm.type === Element.SEGMENT) {
          el.tick     = elm.tick;
          // (.next is the next global segment)
          // (.nextInMeasure is null if last Segment)
          el.nextSeg  = elm.nextInMeasure;
          el.nextTick = el.nextSeg && el.nextSeg.tick;
          if (! el.ticks && elm.element) el.ticks = elm.element.durationType;
          conLog(43, "ElObj, elm Segment.tick: ", el.tick);
          if (truthy(el.ticks, 0)) {
            okBit |= 0x2;
          } else {
            conLog(42, "ElObj, elm Segment can't set el.ticks (duration)");
          }

        } else if (elm.type === Element.MEASURE) {
          firstSeg = elm.firstSegment;
          lastSeg  = elm.lastSegment;
          text     = lastSeg.segmentType === Segment.EndBarLine ?
            "Segment.EndBarLine" :
            "" + lastSeg.segmentType + " (Segment.EndBarLine = " + Segment.EndBarLine + ")";
          conLog(43, "ElObj, last Segment.segmentType: ", text);
          if (truthy(el.tick, 0) && lastSeg && lastSeg.segmentType === Segment.EndBarLine) {
            // NB 'measureRemain' is including elements durationType
            el.measureRemain  = lastSeg.tick - el.tick;
            if (! el.measureRemain || el.measureRemain < 0) el.measureRemain = 0;
            el.measureTicks = lastSeg.tick - firstSeg.tick;
            conLog(42,
              "ElObj, elm Measure.duration: ", st.ticksToStr(el.measureTicks),
              ", .ticks remain: ", st.ticksToStr(el.measureRemain)
              );
          } else {
            el.errorMessage = "Can't get tick after last element of the measure";
            el.errorInfo    = "\"last element\" of the measure isn't a Bar Line";
            break;;
          }
          el.measureTick = firstSeg.tick;
          if (el.measureTicks) okBit |= 0x4;
        }
        elm = elm.parent;
      }
      if (okBit === (0x1 | 0x2 | 0x4)) {
        el.ok = true;
      } else {
        el.ok = false;
        var text = conLog(42, "ElObj, NO success! okBit: ", okBit);
        if (! el.errorMessage) el.errorMessage = conLog(42, "ElObj, NO success! okBit: ", okBit);
      }
      return el;
    };

    /***
     * Gets max possible duration for 'self', setting it if <swSet> and over max.
     * @param {Bool}      <swSet>   If max duration should be set for 'self'.
     * @param {MS Cursor} <cursor>  opt. Needed if setting the duration.
     * @param {String}    <debT>    opt. Debug text.
     * @return {Number|Bool} max duration unless <swSet> otherwise if duration is changed
     */
    el.maxTicks = function(swSet, cursor, debT) {
      if (! el.nextChordTick) el.nextChordTick = el.tick + el.measureRemain;
      var ticksMax = Math.min(el.measureRemain, el.nextChordTick - el.tick);
      conLog(42,
        "Math.min(el.measureRemain: ", st.ticksToStr(el.measureRemain),
        ", el.nextTick - el.tick: ", st.ticksToStr(el.nextChordTick, "", +1),
        " - ", st.ticksToStr(el.tick, "", +1), " )",
        " = ", st.ticksToStr(ticksMax, "")
        );
      if (! swSet) return ticksMax;
      if (! debT) debT = "";
      if (debT) debT += " ";
      if (el.ticks === ticksMax) {
        conLog(42, debT + "(already max ticks ", st.ticksToStr(el.ticks), ")");
        return false;
      }
      if (debT) debT += "set to maxTicks";
      el.setDurationType(ticksMax, null, cursor, debT);
      return true;
    };

    /***
     * Calling 'setDuration' and sets the duration for 'self'.
     * @param {Number}    <durationType>  Duration to be set (or increase or decrease, see <type>).
     * @param {String}    <type>          opt. "+"/"-" if duration should be increased
     *                                    or decreased instead of absolut value.
     * @param {MS Cursor} <cursor>        Cursor.
     * @param {String}    <debT>          Debug text.
     * @return {Number} the new duration
     */
    el.setDurationType = function(durationType, type, cursor, debT) {
      var ticks = element.durationType, debType = type;
      switch (type) {
        case '+': ticks += durationType; break;
        case '-': ticks -= durationType; break;
        default:
          debType = "";
          ticks   = durationType;
      }
      if (cursor) {
        st.setPlayAndChordDuration(debT, element, cursor, ticks);
      } else {
        element.durationType = ticks;
      }
      el.ticks = element.durationType;
      if (! debT) { debT = ""; } else { debT += " "; };
      conLog(42, "ElObj, " + debT + "set durationType in: ", debType, st.ticksToStr(durationType),
        ", (and element has now: ", st.ticksToStr(element.durationType), ")"
        );
      return el.ticks;
    };

    el.debugNoteTpcs = function(chord, harmonyObj) {
      var note, noteInd = 0;
      while ((note = chord.notes[noteInd++])) {
        if (noteInd === 1) conLog(45, { obj: note });
        conLog(44, "Note, pitch: ", note.pitch,
          ", tpc: ", note.tpc, ", tpc1: ", note.tpc1, ", tpc2: ", note.tpc2,
          ", tpcL: ",  harmonyObj.tpcInfo(note.tpc ).letterAlt,
          ", tpc1L: ", harmonyObj.tpcInfo(note.tpc1).letterAlt,
          ", tpc2L: ", harmonyObj.tpcInfo(note.tpc2).letterAlt
          );
      }
    };
  };

  //////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////

  /***
   * Object for parsing a Harmony text.
   */
  st.harmonyObject = function () {
    var ho = this;
    // (not necessary to init these, only for clarity)
    ho.errorMessage = null;
    ho.ok      = null;
    ho.error   = null;
    ho.noChord = null;
    ho.root    = null;
    ho.bass    = null;

    ho.tFlt2 = -2;
    ho.tFlt  = -1;
    ho.tStr  =  0;
    ho.tShp  = +1;
    ho.tShp2 = +2;

    var strM, chordRemain,
        alterationsRegex = /(omit|add|maj|dom|dim|aug|[b#-+]+)(\d+)/;

    /***
     * Main function, will parse a Harmony text and generate pitches for it.
     * @param {String} <harmony>  Harmony text.
     * @return {harmonyObject.semitones (Array)|null}
     */
    ho.harmonyToSemitones = function(harmony, harmonyElem) {
      conLog(10, "harmO, --- parsing harmony: \"", harmony, "\" ---");
      ho.parseHarmony(harmony, harmonyElem);
      // clean value from last run
      st.lastHarmonyObj = null;
      if (ho.root) {
        if (! ho.error) ho.build();
        if (! ho.error) ho.toSemitoneNumbers();
        // save to next run
        if (! ho.error) st.lastHarmonyObj = ho;
      }
      conLog(10, "harmO, -----------------");
      return ho.setResult();
    };

    /***
     * Check result.
     * @return {Bool} parse Harmony result
     */
    ho.setResult = function() {
      if (ho.errorMessage) ho.error = true;
      ho.ok    = ! ho.error;
      ho.error = ! ho.ok;
      return ho.ok;
    };

    /***
     * Parse a harmony. If <harmonyObj> it will get root, rootAlt, bass, bassAlt
     * from rootTPC and baseTPC of that object, otherwise it's extracted
     * from <harmony>.
     * @param {String} <harmony>     Harmony text.
     * @param {String} <harmonyObj>  opt. Harmony object. (When used in HTML test page
     *                               this has no value).
     * @return {Bool} if successful
     */
    ho.parseHarmony = function(harmony, harmonyElem) {
      var harmonyUse, tpcInfo;

      if (ho.addToLastChord)
        conLog(10, "harmO, --- parsing harmony: \"", harmony, "\" rerun");
      ho.harmonyOrig = harmony;
      ho.harmony     = st.harmonyTextNice(harmony);
      ho.rootRemain  = "";

      // no chord? ("N.C.")
      if (glb.noChordRegex.test(harmony)) {
        ho.noChord = true;
        return true;
      }

      harmonyUse    = harmony.
        replace(/\u2212/g,               "-").   // Unicode for - to "-" (don't seem to use a Unicode for "+")
        replace(/\u0394|\u03B4|\u2206/g, "^").   // Unicode for "triangle" to "^"
                                                 // (x0394 is mistaken for x03B4 in some situations, don't know why)
        replace(/\u00B0/g,               "o").   // Unicode for "degree" to "o"
        replace(/\u00D8|\u00F8/g,        "0").   // Unicode for "big/small 0" to "0"
        replace(/\u266D/g,               "b").   // Unicode for b to "b"
        replace(/\u266F/g,               "#").   // Unicode for # to "#"
        replace(/^([A-Ga-g])e?s(?!u)/g,  "$1b"). // allow german "es" for "b" (E and A has only "s")
        replace(/^([A-Ga-g])is/g,        "$1#"); // allow german "is" for "#"

      // (not implementing german H for B and B for BB for when 'harmonyObj' isn't used)

      // extract Bass - if any
      if ((strM = harmonyUse.match(/^(.*)?\/([a-h])([b#]*)(.*)$/i))) {
        // (extract key with alt, even if they are replaced from TPC if 'harmonyObj' is used)
                                                          // e.g. "c#maj7/abrubish"
        harmonyUse    = strM[1] || "";                         // "c#maj7"
        ho.bass       = strM[2];                               // "a"
        ho.bassOrig   = ho.bass;
        if (! glb.lowIsMinor) ho.bass = ho.bass.toUpperCase(); // "A" unless "low case = minor"
        ho.bass      += strM[3].toLowerCase();                 // "Ab"
        ho.bassAlt    = strM[3];                               // "b"
        ho.bassRemain = strM[4];                               // "rubish"
        if (! harmonyElem) {
          ho.bassTpc = ho.letterToTpc(ho.bass);                // TPC for "Ab"
        } else {
          ho.bassTpc = harmonyElem.baseTpc;
          if (ho.bassTpc < -1) {
            // (just null them if they for some reason has a value)
            ho.bass    = null;
            ho.bassAlt = null;
          } else {
            tpcInfo    = ho.tpcInfo(ho.bassTpc);
            ho.bass    = tpcInfo.letter + tpcInfo.alt;
            ho.bassAlt = tpcInfo.alt;
          }
        }
      };

      // get root
      if ((strM = harmonyUse.match(/^([A-Ha-h])([b#]*)(.*)$/))) {
        // (extract key with alt, even if they are replaced from TPC if 'harmonyObj' is used)
        // get root with "alt"                            // e.g. "c#maj7add4"
        ho.root      = strM[1];                                // "c"
        ho.rootOrig  = ho.root;
        if (! glb.lowIsMinor) ho.root = ho.root.toUpperCase(); // "C" unless "low case = minor"
        ho.root     += strM[2];                                // "C#"
        ho.rootAlt   = strM[2];                                // "#"
        chordRemain  = strM[3];                                // "maj7add4"
        if (! harmonyElem) {
          ho.rootTpc = ho.letterToTpc(ho.root);                // TPC for "C#"
        } else {
          ho.rootTpc = harmonyElem.rootTpc;
          if (ho.rootTpc < -1) {
            // (just null them if they for some reason has a value)
            ho.root    = null;
            ho.rootAlt = null;
          } else {
            tpcInfo    = ho.tpcInfo(ho.rootTpc);
            ho.root    = tpcInfo.letter + tpcInfo.alt;
            ho.rootAlt = tpcInfo.alt;
          }
        }

      } else {
        chordRemain = harmonyUse;
      }

      if (chordRemain) {
        // some special ignores (to not mess up replacings below)
        if ((strM = chordRemain.match(/alt|lyd|\([a-z]+\)/ig))) {
          var ignore, idx = 0;
          while ((ignore = strM[idx++])) {
            ho.rootRemain += ignore;
          }
          chordRemain = chordRemain.replace(/alt|lyd|\([a-z]+\)/ig, "");
        }

        // basic clean up
        chordRemain = chordRemain.
          // all alone upper "M" or "j" to "maj"
          replace(/(^|[^A-Za])(M|j)(?![a-zA-Z])/g, "$1maj").
          // all alone "m" to "min"
          replace(/(^|[^a-z])(m)(?![a-zA-Z])/g,    "$1min").
          toLowerCase().                              // all in lower case
          replace(/inished|mented/,         "").      // long "diminished" and "augmented" to short
          replace(/major|ma(?![jd])/g,      "maj").   // all "major" or "ma" to "maj"
          replace(/minor|([^o])mi(?![n])/g, "$1min"); // all "minor" or "mi" to "min"

        /// NB! all is now in lower case ///

        // change some abbreviations, changes according to [r]
        chordRemain = chordRemain.
          replace(/^(min|-)/,           "m").       // leading "min" or "-" to "m"
          replace(/^maj$/,              "").        // remove only "maj"
          replace(/(^|[^n])o(?=[\db]|$)/g,  "$1dim").  // all lonely "o" to "dim"
          replace(/0$/,                 "07").      // ending only "0" to "07"
          replace(/^([^\d]*)\^(?=$|[^\d])/, "$1maj7"). // only "^" without previous tone to "maj7"
          replace(/\^/g,                "maj").     // all "^" to "maj"
          replace(/^(m?)\+/,            "$1aug").   // leading "+" to "aug"
          replace(/^(m?)(\d+)(\+|aug)$/,"$1aug$2"). // only [tone] and "+/aug" to "aug[tone]"
          replace(/^(m?)([42])$/,       "$1sus$2"). // only 4 or 2 to "sus[4|2]"
          replace(/sus(?![42])/,        "sus4").    // "sus" with no following 4|2 to "sus4"
          replace(/(not?|drop)(?=\d)/,  "omit");    // all "no/not/drop[tone]" to "omit[tone]"

        // change some alternative writings to more correct, and easier to parse
        // (changes according to [r] - I hope)
        chordRemain = chordRemain.
          // remove all "ord suffixes", e.g. "7th" -> "7"
          replace(/(\d\d?)(st|nd|rd|th)/g, "$1").
          // all "/" to "add", e.g. "6/7" and "9/6" to "6add9" and "7add6" (will take all combinations)
          replace(/\//g,                   "add").
          // " ", ",", "." and "(" followed by tone to "add", e.g. "6,9", "6add9" etc.
          replace(/[ ,.(](?=\d+)/g,        "add").
          // all lonely "min" or "-" with tone to "b", except leading
          replace(/([^i])(-|min)(?=\d)/g,  "$1b").
          // remove "add" from e.g. "add#9"
          replace(/add([b#-+]|maj)/g,      "$1").
          // remove all "(", ")", ",", "." and " "
          replace(/[(),. ]/g,              "").
          // allow alterations without prefix, e.g. "7911" means "7add9add11"
          replace(/(1\d)(?=\d)|([2-9])(?=\d)/g, "$1$2add");

        // it's allowed to alter last chord (but only if no bass), in that case
        // some changed initials must be changed back
        if (! ho.root) {
          chordRemain = chordRemain.replace(/^m/, "b").replace(/^aug/, "#");
        }
        ho.chAlters = chordRemain;
      }

      if (! (ho.root || ho.bass)) {
        // allow to just add to last known harmony, e.g. "-7" (above changed back to "b7")
        if (! ho.bass) {
          if (glb.allowAddToLast &&
              ! (ho.addToLastChord || /^\//.test(harmony)) && st.lastHarmonyObj) {
            ho.addToLastChord = true;
            conLog(10, "harmO, -- adding to last run's Harmony object");
            harmonyUse = st.lastHarmonyObj.parsedHarmonyS(false, false, true, 'r');
            return ho.parseHarmony(harmonyUse + "(" + harmony + ")");
          }

          // giving up, the harmony is no good
          setError(
            "Can't identify root harmony \"" + harmonyUse +
            "\" (parsed: " + ho.parsedHarmonyS(true) + ")"
            );
        }
      };

      conLog(10, "harmO, adjusted: ", ho.parsedHarmonyS(true));
      var text = "";
      if (harmonyElem) text = ", from text: " + (ho.rootOrig || "");
      conLog(10, "harmO, root: ", ho.root, ", alt: ",   ho.rootAlt,
        ", alters: ",   ho.chAlters,   ", tpc: ",   ho.rootTpc, text);
      text = "";
      if (harmonyElem) text = ", from text: " + (ho.bassOrig || "");
      conLog(10, "harmO, bass: ", ho.bass, ", b.alt: ", ho.bassAlt,
        ", b.rubish: ", ho.bassRemain, ", b.tpc: ", ho.bassTpc, text);

      if (ho.error) return false;

      // Start parsing
      // (all parentheses, " " and "," are here removed from the string)

      // delete and rebuild this with correct alteration values
      ho.chAlters = "";

      // minor
      if (chordRemain && (strM = chordRemain.match(/^m(?!aj)(.*)$/))) {
        ho.min       = "m";
        ho.chAlters += "m";
        chordRemain  = strM[1];
      } else if (glb.lowIsMinor && ho.rootOrig && /^[a-g]/.test(ho.rootOrig)) {
        // "low case = minor"
        ho.min = true;
      }

      // alterations (extension tone, and maj, dim and aug)
      if (chordRemain) {
        conLog(11, "harmO, remain before maj|dim|aug: ", chordRemain);
        // 5, [r2] "power chord"
        if ((strM = chordRemain.match(/^(5)(.*)$/))) {
          ho.power    = strM[1];
          chordRemain = strM[2];
          addToAlters(1);

        // maj, dim, aug and extended tone
        } else if ((strM = chordRemain.match(/^(0|dim|aug)?(maj)?([b#]+)?(\d+)?(.*)$/))) {
                                    // e.g. "augmaj7add4"
          ho.alter    = strM[1];         // "aug"
          ho.maj      = strM[2];         // "maj"
          ho.extAlt   = strM[3] || null; // null
          ho.extTone  = strM[4] || null; // "7"
          chordRemain = strM[5];         // "add4"
          addToAlters(1, 2, 3, 4);

          // extented tone to numeric
          if (/^\d+$/.test(ho.extTone)) ho.extTone = parseInt(ho.extTone);

          switch (ho.alter) {
            case '0':
            case 'dim': ho.dim = ho.alter; break;
            case 'aug': ho.aug = ho.alter; break;
            default: ho.alter = null;
          }
          // "maj" without tone is a "straight" chord, ignore "maj"
          if (ho.maj && ! ho.extTone) {
            ho.maj = null;
            ho.rootRemain += "maj";
          }
          // "dim" or "aug" means alter the 5th, so just remove 'extTone' if it's 5
          // otherwise it will be a dom 5 later on
          if (ho.extTone === 5 && (ho.dim || ho.aug)) ho.extTone = null;
        }
      }

      // sus
      if (chordRemain) {
        conLog(11, "harmO, remain before sus: ", chordRemain);
        // sus [r]:
        //  - (fixed above) allow "4" and "2" for "sus4" and "sus2", if nothing after
        //  - (fixed above) allow "sus" for "sus4"
        if ((strM = chordRemain.match(/^(.*)(sus)([42])(.*)$/))) {
                            // e.g. "sus4"
          ho.sus      = strM[3]; // "4"
          chordRemain = strM[1] + strM[4];
          addToAlters(2, 3);
        }
      }

      // [r] the pitch for the "seventh" tone is depending on what kind of chord
      if (ho.extTone) {
        ho.extToneOdd = ((ho.extTone % 2) !== 0);
        // (this will allow alteration of 7th also when "maj", e.g. "majb7", it's
        // not correct but handle it anyway)
        if ((ho.extTone > 7 && ho.extToneOdd) || (ho.extTone === 7 && ! ho.extAlt)) {
          ho.seventh = (ho.maj ? ho.tStr : ho.tFlt);
          if (ho.dim) {
            // "half-diminished" or "diminished"
            ho.seventh = (ho.dim === "0" ? ho.tFlt : ho.tFlt2);
          }
        }
        switch (ho.extAlt) {
          case '##': ho.extAlt = ho.tShp2; break;
          case '#':  ho.extAlt = ho.tShp;  break;
          case 'b':  ho.extAlt = ho.tFlt;  break;
          case 'bb': ho.extAlt = ho.tFlt2; break;
          default:   ho.extAlt = ho.tStr;  break;
        }
        if (ho.extTone > 6 && ho.extToneOdd && ! truthy(ho.seventh, 0)) {
          ho.seventh = ho.extAlt;
          // in [r] "#7" seems to mean maj7, but "b7" means dom7 not dim7,
          // so "b7" means the same as "7"
          if (ho.extAlt >= 0) ho.seventh -= 1;
        }
      }

      conLog(10, "harmO, ",
        { slice: [ ho, 'min', 'extTone', 'alter', 'maj', 'dim', 'aug', 'seventh', 'sus' ]}
        );

      // this line will fix the strange crashing for some reason, but not using
      // it, don't want to split up the log file, and it's fixed by starting
      // the plugin with no Score before anything else
      //mo.openLog(true, null, [99, "parse113", ", xxxx: ", 11]);
      return true;
    };

    /***
     * Builds the chord.
     * @return {Object} tones for the harmony as an object
     */
    ho.build = function() {
      if (! ho.root) {
        setError("You must first parse the harmony");
        return ho;
      }

      /// Basic chord ///

      ho.t    = {};
      ho.t[1] = ho.tStr;
      // minor?
      ho.t[3] = (ho.min ? ho.tFlt : ho.tStr);
      ho.t[5] = ho.tStr;

      /// Special chords ///

      // power
      if (ho.power) {
        // 3rd shouldn't be played, only 5th and octave
        ho.t[3] = null;
        ho.t[8] = ho.tStr;
      }
      // dim
      if (ho.dim) {
        ho.t[3] = ho.tFlt;
        ho.t[5] = ho.tFlt;
      }
      // aug
      if (ho.aug) ho.t[5] = ho.tShp;
      // sus
      if (ho.sus) {
        // sus = "4" or "2"
        ho.t[ho.sus] = ho.tStr;
        ho.t[3]      = null;
      }

      // "tone extensions", e.g. D7
      if (ho.extTone) {
        if (ho.extTone < 7 || ! ho.extToneOdd) {
          ho.t[ho.extTone] = ho.extAlt;
        } else {
          // [r] 7 is implicit for the rest
          if (glb.extImpliesLower || ho.extTone === 7) ho.t[7] = ho.seventh;
          if (ho.extTone >= 9) {
            if (! glb.extImpliesLower) ho.t[ho.extTone] = ho.extAlt;
            // [r] 9 is implicit for the rest
            if (glb.extImpliesLower) ho.t[9] = ho.extAlt;
            // [r] perfect 5th is the most commonly omitted tone for 9th
            if (glb.reduceChordsLevel > 1 && ho.extTone === 9 && ho.t[5] === ho.tStr) ho.t[5] = null;
            if (ho.extTone >= 11) {
              // [r] 11 is implicit for the rest
              if (glb.extImpliesLower) ho.t[11] = ho.extAlt;
              // [r] major 3rd is (usually) omitted for 11th
              if (glb.reduceChordsLevel && ho.extTone === 11 && ho.t[3] === ho.tStr) ho.t[3] = null;
              if (ho.extTone >= 13) {
                if (glb.extImpliesLower) ho.t[13] = ho.extAlt;
                if (glb.reduceChordsLevel) {
                  // [r]:
                  // It is common to leave certain notes out. After the 5th,
                  // the most commonly omitted note is the troublesome 11th (4th).
                  // The 9th (2nd) can also be omitted. A very common voicing
                  // on guitar for a 13th chord is just the root, 3rd, 7th and
                  // 13th (or 6th).
                  if (ho.t[5]  === ho.tStr) ho.t[5]  = null;
                  if (ho.t[11] === ho.tStr) ho.t[11] = null;
                  // (4 is the same as 11 - almost)
                  if (ho.t[4]  === ho.tStr) ho.t[4]  = null;
                  if (glb.reduceChordsLevel > 1) {
                    if (ho.t[9] === ho.tStr) ho.t[9] = null;
                    // (2 is the same as 9 - almost)
                    if (ho.sus !== "2" && ho.t[2] === ho.tStr) ho.t[2] = null;
                  }
                }
              }
            }
          }
        }
      }

      // alterations
      ho.buildAlterations(chordRemain);

      return ho.t;
    };

    /***
     * Add tones for alterations for existing "tone object".
     * @param {String} <alterations>
     * @return {Object} tones for the harmony as an object
     */
    ho.buildAlterations = function(alterations) {
      if (! alterations) return null;
      if (! ho.t) ho.t = {};
      var what, tone,
          remain = alterations;
      while ((strM = remain.match(alterationsRegex))) {
        what   = strM[1];
        tone   = strM[2];
        remain =
          remain.substring(0, strM.index) +
          remain.substring(strM.index + what.length + tone.length);
        addToAlters(1, 2);
        conLog(10, "harmO, alter: ", what + tone);
        // special for 7th: "dom/add" = "b", dim = "bb" (otherwise "dom" = "maj")
        if (tone === "7") {
          if (what === "dom" || what === "add") {
            what = "b";
          } else if (what === "dim") {
            what = "bb";
          }
        }
        switch (what) {
          case '##':   ho.t[tone] = ho.tShp2; break;
          case 'aug':
          case '+':
          case '#':    ho.t[tone] = ho.tShp; break;
          // [r] "maj" means straight, not sharp (as I understand it)
          case 'maj':
          case 'dom':
          case 'add':  ho.t[tone] = ho.tStr; break;
          case 'dim':
          case '-':
          case 'b':    ho.t[tone] = ho.tFlt; break;
          case 'bb':   ho.t[tone] = ho.tFlt2; break;
          case 'omit': delete ho.t[tone]; break;
        }
        // special for 7th: "#" = major ("straight", B), "##" = "#" (C)
        if (tone === "7" && ho.t[tone] && ho.t[tone] >= 1) ho.t[tone] -= 1;
      }
      ho.rootRemain += remain;
      return ho.t;
    };

    /***
     * Gets all semitones for 'self'.
     * @return {Array} array of semitones (including root)
     */
    ho.toSemitoneNumbers = function() {
      if (ho.noChord) return "";
      if (! ho.t) {
        setError("You must first parse the harmony and build the tones");
        return null;
      }

      var tone, useTone, toneInd, alt, useAlt, altS, semi, semiAlt, letter, tpc;
      ho.semitones      = [];
      ho.semiTpcs       = [];
      ho.semiLetters    = [];
      ho.semiLettersInC = [];
      conLog(10, "semiNbrs, ho.t: ", { obj: ho.t }, " ----------");

      // adjust if alterations are "##" or "bb"
      for (tone = 1; tone <= 7; tone++) {
        useTone = tone;
        alt     = ho.t[tone];
        if (typeof(alt) !== "number") continue;
        useAlt  = alt;
        if (alt < -1) {
          useTone -= 1;
          useAlt  += 2;
          delete ho.t[tone];
        } else if (alt > 1) {
          useTone += 1;
          useAlt  -= 2;
        }
        if (useTone !== tone) {
          ho.t[useTone] = useAlt;
          delete ho.t[tone];
          conLog(10,
            "semiNbrs, ho.t[", tone, "](", numToSWSign(alt),
            ") -> ho.t[" + useTone + "](", numToSWSign(useAlt), ")", ""
            );
        }
      }

      // extract semitones //
      for (tone in ho.t) {
        alt = ho.t[tone];
        if (typeof(alt) === "number") {
          toneInd = tone - 1;
          semi    = glb.toneToSemiPitch[toneInd % 7];
          letter  = "" + glb.toneLetters[toneInd % 7] + glb.tpcAlts[alt + 2];
          semiAlt = semi + alt;
          // add octaves
          if (tone > 7) semiAlt += (intPart(toneInd / 7)) * 12;
          altS = numToSWSign(alt);
          conLog(10, "semiNbrs, ho.t[", tone, "]: ", altS, ", semiAlt: ", semiAlt, " (", letter, ")");
          if (typeof(semiAlt) === "number") {
            // (this will take care of e.g. "Abb" -> "G", "B#" -> "C", etc.)
            tpc = ho.semitoneToTPC(ho.rootTpc, semi, alt);
            // avoid duplicates
            if (ho.semitones.indexOf(semiAlt) < 0) {
              ho.semitones.push(semiAlt);
              ho.semiTpcs.push(tpc);
              ho.semiLetters.push(ho.tpcInfo(tpc).letterAlt);
              ho.semiLettersInC.push(letter);
            } else {
              conLog(10, "semiNbrs, semitone was a duplicate: ", semiAlt);
            }
          }
        } else {
          conLog(10, "(semiNbrs, tone ", tone, " is no number)");
        }
      }

      var text = "";
      if (ho.root !== "C") text = ", in C-scale: " + objectToStr(ho.semiLettersInC);
      if (glb.writeChordNotes) ho.chordLettersNice =
        objectToStr(glb.writeChordNotes === 1 ? ho.semiLetters : ho.semiLettersInC).
          replace(/[ \[\]]/g, "").replace(/,/g, "-");
      conLog(15,
        "semiNbrs, \"", ho.harmony, "\" (", ho.parsedHarmonyS(true), ")",
        " semitones: ", { obj: ho.semitones }, " (", { obj: ho.semiLetters },
        text, ")", ""
        );
      return ho.semitones;
    };

    /***
     * Makes a harmony String nicely formatted of the parsed harmony.
     * @param {Bool}   <addFnutts>  Surround with ".
     * @param {Bool}   <abs>        As normal rule NOT "low case = minor".
     * @param {Bool}   <forUse>     To be used, not adding "ignore".
     * @param {String} <only>       If only root or bass, 'r' = only root, 'b' = only bass.
     * @return {String}
     */
    ho.parsedHarmonyS = function(addFnutts, abs, forUse, only) {
      var text, alt, min,
          swRoot = (only !== 'b'),
          swBass = (only !== 'r');
      if (ho.noChord) {
        text = "N.C.";
      } else {
        if (swRoot) {
          text = ho.root || "";
          alt  = "";
          min  = "";
          if (text) {
            alt  = text.substr(1);
            text = (abs ? text : (ho.rootOrig || text)).substr(0, 1);
            if (ho.min) {
              if (abs) {
                // always upper for this
                text = text.toUpperCase();
                // it can be "lower case is minor"
                if (ho.min && ! /^m(?!aj|in)/.test(ho.chAlters || "")) min = "m";
              } else {
                // "lower case is minor"?
                text = (glb.lowIsMinor ? text.toLowerCase() : text.toLowerCase());
              }
            }
            text += alt + min + (ho.chAlters || "");
          }
        } else {
          text = "";
        }
        if (swBass && ho.bass) text += "/" + ho.bass;
      }
      if (addFnutts) text = '"' + text + '"';
      if (! forUse) {
        if (swRoot && ho.rootRemain) text += " (ignored: \"" + ho.rootRemain + "\")";
        if (swBass && ho.bassRemain) text += " (ignored in Bass: \"" + ho.bassRemain + "\")";
      }
      return text;
    };

    /***
     * Convert TPC to pitch (midi) note info as an Array.
     * docs at
     *   https://musescore.org/en/plugin-development/tonal-pitch-class-enum
     *   http://www.tonalsoft.com/pub/news/pitch-bend.aspx
     * @param {Number} <tpc>     TPC.
     * @param {Number} <octave>  opt.(0) Octave diff from pitch 60 (C in octave 0).
     * @return {Array} [ base pitch class, pitch (midi) number, letter, alteration ]
     */
    ho.tpcInfo = function(tpc, octave) {
      // securing 0
      if (! tpc)    tpc    = 0;
      if (! octave) octave = 0;
      if (tpc < -1) return { pitch: null, letter: "", alt: "", letterAlt: "" };

      var pitch, letter, alt,
          referenceC = octave * glb.pitchOctave + glb.pitchCinOctave0,
          // TPC to work with, e.g. 28 16 4 (C## D Ebb) = 2, 27 15 3 (F## G Abb) = 1
          tpcAbs     = (tpc - 2 + 12) % 12;
      // tpc to pitch number
      pitch  = referenceC + ((tpcAbs * glb.tpcAlterFact) % 12);
      letter = glb.tpcLetters[(tpc + 1) % glb.tpcAlterFact];
      alt    = glb.tpcAlts[intPart((tpc + 1) / glb.tpcAlterFact)];
      conLog(10, "harmO.tpcToP, pitch: ", pitch, ", letter: \"", letter, "\", alt: \"", alt, "\"", "");

      return { pitch: pitch, letter: letter, alt: alt, letterAlt: "" + letter + alt };
    };

    /***
     * Returns TPC for tone that is <semiTone> (half-tones) higher than rootTPC,
     * e.g. semitoneToTPC(TPC of C#, 4) = TPC of E#.
     * @param {Number} <rootTpc>    TPC for the root tone.
     * @param {Number} <semiTone>   Semitones over the root.
     * @param {Number} <alt>        opt. Alteration, in "semitone", e.g. -1.
     * @param {Number} <adjustRoot> opt. Adjust <rootTpc> from "double alter",
     *                              e.g. bb to straight.
     * @return {Number} TPC for the tone
     */
    ho.semitoneToTPC = function(rootTpc, semiTone, alt, adjustRoot) {
      var tpcAdd = semiTone;
      if ((tpcAdd % 2) !== 0) tpcAdd -= 6;
      if (typeof(alt) === "number") tpcAdd += alt * 7;
      if (adjustRoot) rootTpc = ho.reduceDoubleAlt(rootTpc);
      return ho.reduceDoubleAlt(rootTpc + tpcAdd);
    };

    /***
     * Returns TPC for a tone as letter.
     * @param {Number} <letter>  Tone letter, can be with alter, e.g "C", "Fb", "G##" etc.
     * @param {Number} <alter>   Override alter from <letter>, can be String
     *                           e.g. "#" or num for TPC diff. If between -2 and
     *                           2 it's as pitch diff, otherwise a TPC diff.
     * @return {Number} TPC for the letter and alteration
     */
    ho.letterToTpc = function(letter, alter) {
      var tone, alt, fact;
      strM = letter.toLowerCase().match(/([a-g])([b#]*)/);
      if (! strM) return null;
      tone = strM[1].toUpperCase();
      conLog(10, "harmO.letterToT, strM: ", { obj: strM }, ", tone: ", tone);
      alt  = strM[2];
      // 'alter' from parameters overrides 'alt'
      if (alter) alt = alter;
      // 'alt' can be numeric
      if (typeof(alt) === "number") {
        if (alt >= -2 && alt <= 2) alt *= glb.tpcAlterFact;

      } else {
        alt   = alt.toLowerCase();
        fact  = 0;
        fact  = glb.tpcAlts.indexOf(alt);
        if (fact < 0) fact = 2;
        // will be -2, -1, 0, 1 or 2
        fact -= 2;
        alt   = fact * glb.tpcAlterFact;
      }
      return glb.tpcLetters.indexOf(tone) + 13 + alt;
    };

    /***
     * Adjust bb/## to straight, and where b/# has "own tone".
     * E.g. D## -> E, Fb -> E
     * @param {Number} <tpc>  TPC.
     * @return {Number} adjusted TPC
     */
    ho.reduceDoubleAlt = function(tpc) {
      if (tpc < 8) {
        tpc += 12;
      } else if (tpc > 24) {
        tpc -= 12;
      }
      return tpc;
    };

    /***
     * Adds elements from Array <strM> to <ho.chAlters>
     * @params {Number} <index1, index2, ...>  Indexes for elements to add.
     */
    function addToAlters() {
      var strMInd, text, argInd = 0;
      text = "";
      while ((strMInd = arguments[argInd++])) { text += (strM[strMInd] || ""); }
      if (! text) return;
      // surround new text with parentheses if it starts with character and "alters"
      // ends with character
      if (ho.chAlters  && /[a-z]$/i.test(ho.chAlters) && /^[a-z]/i.test(text))
        text = "(" + text + ")";
      ho.chAlters += text;
    }

    /***
     * Set self as error.
     * @params {String} <errorMessage>  Error message.
     */
    function setError(errorMessage) {
      conLog(10, "harmO, ho.errorMessage: \"", errorMessage, "\"");
      ho.errorMessage = errorMessage;
      ho.error        = true;
    }

  }; // harmonyObject
}; // staffObject

staffObj = new mo.staffObject;
// to easy use "element functions"
elemDo   = new staffObj.elemObject;

/***
 * Take a slice from an object.
 * @param {Object}  <object>
 * @param {variant} <key1, key2, key3, ...>
 * @return {Object}
 */
function objectSlice(object) {
  var key, res = {};
  if (arguments.length === 1) {
    for (var key in object) res[key] = object[key];
  } else {
    for (var idx in arguments) {
      if (idx >= 1) {
        key      = arguments[idx];
        res[key] = object[key];
      }
    }
  }
  return res;
}

/***
 * Doing .toString() for all elements in an Object or Array.
 * @param {Object|Array}  <object>    Object or Array.
 * @param {Bool}          <asObject>  opt. When Array, include indexes in result.
 * @return {String}
 * Examples
 *   objectToStr({ x: 7, y: 88 })  //=> "{ x: 7, y: 88 }"
 *   objectToStr([ 7, 88 ])        //=> "[ 7, 88 ]"
 *   objectToStr([ 7, 88 ], true)  //=> "[ 0: 7, 1: 88 ]"
 */
function objectToStr(object, asObject) {
  var text, value, type, use,
      ind   = 0,
      swObj = isObject(object, asObject);
  text = swObj ? "{ " : "[ ";
  if (! (swObj || Array.isArray(object))) return "[no object (" + object.toString() + ")]";
  // use function '_name()' if available
  if (object._name && /function\(\)/.test(object._name.toString()))
    text += "(_name() = \"" + (object._name() || "") + "\"), ";
  for (var e in object) {
    if (ind++ > 0) text += ", ";
    value = object[e];
    type  = typeof(value);
    use   = (type === "undefined" ? "{u}" : (value === null ? "{null}" : value.toString()));
    text += (swObj ? "" + e + ": " : "") + use.toString();
  }
  text += swObj ? " }" : " ]";
  return text;
};
// (if used in e.g. test HTML page)
mo.objectToStr = objectToStr;

/***
 * Determine if <object> is an Object.
 * @param {Object} <object>
 * @param {Bool}   <asObject>  opt. If return 'true' no matter what.
 * @return {Bool}
 */
function isObject(object, asObject) {
  return (object && (asObject === true || asObject === false ? asObject : /Object/.test(object.constructor())));
}

/***
 * Returning the integer part of a Number. Like Math.floor but acting correct if
 * negative number.
 * @param {Number} <n>  The number.
 * @return {Number} Integer part of <n>
 */
function intPart(n) {
  // ~~(n) is the same as Math.floor but will do it correct also for negative numbers
  return ~~(n);
}

/***
 * Returns number as String with sign (also "+")
 * @param {Number} <n>
 * @return {String}
 */
function numToSWSign(n) {
  var str = "" + n;
  if (n > 0) str = "+" + str;
  return str;
}

/***
 * Doing console.log depending on current "debug level".
 * @param {Number|Bool} <level>  Decides if this should be logged, it will if
 *                               <level> is included in {Array} 'glb.debugLevels'.
 * @return {String} the logged String (id done)
 */
function conLog(level) {
  if (level !== true && level !== 99 && glb.debugLevels.indexOf(level) < 0) return null;

  // 'console.log' is including a " " between all parameters, convert parameters
  // to only one to avoid that (but keeping the code as an alternative though)
  var useStr = true;
  if (glb.debugFile) useStr = true;
  var arg, args = [], str = "";
  function oneArg(a) {
         if (a === glb.undef) { a = "{u}"; }
    else if (a === null)      { a = "{null}"; }
    else                      { a = a.toString().replace(/^(Ms::\w+)\(.*/, "$1"); }
    if (idx === "1" && level === 99) a = ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" + a;
    if (useStr) { str += a; } else { args.push(a); }
  }
  for (var idx in arguments) {
    if (idx > 0) {
      arg = arguments[idx];
      if (isObject(arg) && (arg.obj || arg.slice)) {
        if (arg.slice) arg.obj = objectSlice.apply(this, arg.slice);
        arg = objectToStr(arg.obj);
      }
      oneArg(arg);
    }
  }
  if (useStr) args = [ str ];
  console.log.apply(this, args);
  if (glb.debugFile) log(str + "\n");
  return str;
}
// (if used in e.g. test HTML page)
mo.conLog = conLog;

/***
 * Returns if <value> is "truthy", or additional values in parameters.
 * @param {variant} <value>  The value to test.
 * @return {Bool}
 * Examples
 *   x = 0; truthy(x)    //=> false (exactly the same as if (x) { ... })
 *   x = 0; truthy(x, 0) //=> true
 */
function truthy(value) {
  if (value) return true;
  for (var idx in arguments) {
    if (idx > 0) {
      if (value === arguments[idx]) return true;
    }
  }
  return false;
}
mo.truthy = truthy;

/***
 * Return harmony of segment if any, null if none.
 * If many Harmonies it will prioritize Harmony text that doesn't start
 * with "(" or ends with ")" (with no earlier "(") and is not empty.
 * @param {variant} <segment>  Segment that hopefully should have a Harmony.
 * @return {MS Harmony} found Harmony or null
 */
function getSegmentHarmony(segment) {
  if (! staffObj.isChordRest(segment)) return null;
  var annotation, harmonyElem,
      aCount = 0;
  while((annotation = segment.annotations[aCount++])) {
    if (annotation.type === Element.HARMONY) {
      harmonyElem = annotation;
      // Return if no Harmony text or it doesn't start with "(", or ends
      // with ")" (with no earlier "("), otherwise keep looking, Harmony that
      // starts with "(", or ends with ")", will be returned below if no "good"
      // is found
      if (! harmonyElem.text || ! glb.ignoreHarmonyRegex.test(harmonyElem.text)) break;
    }
  }
  // (secure null)
  return harmonyElem || null;
}

/***
 * Create and return a new Note element with given (midi) pitch, tpc1, tpc2
 * and head type.
 * @param {Number}      <pitch>
 * @param {Number}      <tpc1>
 * @param {Number}      <tpc2>
 * @param {MS NoteHead} <headType>  opt.(NoteHead.HEAD_AUTO).
 * @return {MS Note}
 */
function createNote(pitch, tpc1, tpc2, headType) {
  var note = newElement(Element.NOTE);
  note.pitch    = pitch;
  note.tpc1     = tpc1;
  note.tpc2     = tpc2;
  note.headType = headType || NoteHead.HEAD_AUTO;
  conLog(2, "createNote, created note with pitch: ", pitch, ", tpc1,2: ", tpc1, ",", tpc2);
  return note;
}

/***
 * Handle message.
 * @param {String} <text>      Text for the Message Box.
 * @param {String} <infoText>  Info Text for the Message Box.
 * @param {Bool}   <asError>   opt. If message as error box.
 */
function handleMessage(text, infoText, asError) {
  glb.resultText = text;
  glb.swQuit     = true;
  if (infoText) glb.resultInfoText = infoText;
  glb.resultIcon = asError ? StandardIcon.Critical : StandardIcon.Information;
  conLog(0, (asError ? "ERR!" : "INFO") + ">>> \"", text, "\"");
}

/***
 * Handle info message.
 * @param {String} <text>      Text for the Message Box.
 * @param {String} <infoText>  Info Text for the Message Box.
 */
function infoMessage(text, infoText) {
  handleMessage(text, infoText);
}

/***
 * Handle error message.
 * @param {String} <text>      Text for the Message Box.
 * @param {String} <infoText>  Info Text for the Message Box.
 */
function errorMessage(text, infoText) {
  handleMessage(text, infoText, true);
}

/***
 * Colorize the Harmony text at current Chord cursor to easy see where the plugin
 * goes wrong.
 * @param {String}   <text>      Text for the Message Box.
 * @param {String}   <infoText>  Info Text for the Message Box.
 * @param {MS Chord} <addChord>  opt. If a Chord should be added at current Chord
 *                               cursor.
 */
function errorWithColorChord(text, infoText, addChord) {
  staffObj.writeChord(gStaff.mid, addChord, "red", text);
  text += "\n(the harmony is colored red where the plugin stoped)";
  errorMessage(text, infoText);
}

/***
 * For an newly opened Score Harmony texts are empty. This will populate them.
 * @param {Bool} <swStartCmd>  If 'startCmd' should be done before.
 *                             'endCmd' + 'startCmd' are always done afterward.
 */
function reinitHarmonyTexts(swStartCmd) {
  conLog(1, "reinit Harmony texts");
  if (swStartCmd) curScore.startCmd();
  cmd("transpose-up");
  // (it seems to work with only "transpose-up" - "undo" but I keep the "down")
  cmd("transpose-down");
  cmd("undo");
  cmd("undo");
  curScore.endCmd();
  curScore.startCmd();
}

/***
 * Open log file
 * @param {Int|Bool} <seqNbr>      opt. Add a number after the debug log name.
 *                                 Int:  use that sequence number.
 *                                 true: increase global sequence number and use that.
 *                                 (Only used when tracking down strange bug).
 * @param {Bool}     <closeFirst>  opt. If start with closing the debug log file.
 */
var debugSeqNbr = 1,
    debugOpened = false;
mo.openLog = function(seqNbr, startComment, endComment) {
  if (! glb.debugFile) return;
  mo.closeLog(endComment);
  if (seqNbr === true) {
    // leftfill with zeros
    seqNbr = ("000" + debugSeqNbr++).slice(-4);
  } else if (typeof(seqNbr) !== "number") {
    seqNbr = "";
  }
  openLog(glb.debugFile + seqNbr + ".log");
  if (startComment) conLog.apply(this, startComment);
  debugOpened = true;
};

mo.closeLog = function(endComment) {
  if (glb.debugFile && debugOpened) {
    if (endComment) conLog.apply(this, endComment);
    closeLog();
    debugOpened = false;
  }
};

/***
 * Init function for the plugin.
 * @return {Bool} result
 */
mo.initLg = function() {
  if (! curScore) {
    errorMessage(
      "Generating no Notes from Harmonies. Please open a score before calling this plugin.");
    return false;
  }
  if (glb.swUseDialog) {
    fillDropDowns();
    pluginSettings.open();
    // to get it focused to show that it reacts on [Enter]
    buttonOk.forceActiveFocus();
  } else {
    preThing();
  }
  return true;
};

/***
 * Pre function for the plugin.
 * (the reason to have all these parts is that there is no way in Qt to wait
 * for an answer from a dialog - as far as I know)
 * @return {Bool} result
 */
mo.preLg = function() {
  var useStaves, msg, msgInfo;
  console.log("Generating Notes from Harmonies");
  getSettings();

  if (! glb.swAskStaffAdd) {
    mainThing();
    return true;
  }

  useStaves = (gStaff.bass ? 2 : 1);
  msg = "This plugin will use second staff for chord notes";
  if (useStaves === 2) {
    msg += " and third staff for bass notes";
  } else {
    msg += "                                   ";
  }

  if (curScore.nstaves >= 1 + useStaves) {
    messageBox.doOpen(msg + "\n\nOk?", null,
      StandardButton.Ok + StandardButton.Cancel,
      StandardIcon.Question);
  } else if (curScore.nstaves > 1) {
    msgInfo = "You must either reduce to one staff, so it will be added automatically,\n" +
              "or add one staff your self.\n" +
              "Then restart the plugin.";
    messageBox.doOpen(msg, msgInfo, null, StandardIcon.Critical);
    return false;
  } else {
    msgInfo = "Add staves automatically?\n" +
              "\"" + qsTranslate("PrefsDialogBase", "Yes") +
              "\" = add \"" + glb.addStavesInstrument + "\" automatically\n" +
              "\"" + qsTranslate("PrefsDialogBase", "No") +
              "\" = window \"Add instruments\" opens and you can chose your self\n" +
              "\"" + qsTranslate("PrefsDialogBase", "Cancel") +
              "\" to stop the plugin\n\n" +
              "Tip: Add your self (\"No\") to get nice staves, auto will not fix the F-clef,\n" +
              "\"pipe-organ\" will give a nice sound.";
    messageBox.doOpen(msg, msgInfo,
      StandardButton.Yes + StandardButton.No + StandardButton.Cancel,
      StandardIcon.Question);
  }
  return true;
};

/***
 * Main function for the plugin.
 * @return {Bool} result
 */
mo.mainLg = function() {
  var cursor, segment,
      curTick, harmonyElem, harmonyText, segElement,
      rootTpc, bassTpc, tpc, pitch, semitones, semiTpcs,
      harmonyObj, tempChord,
      transposeTry, useStaves, addStaves;

  // add staves if necessary
  switch((addStaves = getAddStaves())) {
    case 0: break; // do nothing
    case 1: curScore.appendPart(glb.addStavesInstrument); break;
    case 2: cmd("instruments"); break;
    default: return false;
  }
  if (addStaves > 0) {
    curScore.endCmd();
    curScore.startCmd();
  }
  useStaves = (gStaff.bass ? 2 : 1);
  if (curScore.nstaves < 1 + useStaves) {
    errorMessage("The score must have at least " +
      (useStaves > 1 ? "" + useStaves + " extra staves" : "one extra staff"));
    return false;
  }

  // force MuseScore to reinit Harmony texts
  if (glb.alwaysTranspose) {
    reinitHarmonyTexts();
    transposeTry = false;
  } else {
    transposeTry = true;
  }
  cursor = curScore.newCursor();
  staffObj.init(cursor);

  // loop over all segments
  while ((segment = cursor.segment)) {
    harmonyElem = getSegmentHarmony(segment);
    curTick     = cursor.tick;
    staffObj.initLap();

    if (! harmonyElem) {
      // log and ignore this
      conLog(0, "----- (" + staffObj.segmentS + " no chord)");

    } else  {
      glb.harmonyNbr++;
      conLog(0);
      conLog(0, "----- " + staffObj.segmentS + " ------------------------------------");
      segElement  = harmonyElem.parent.elementAt(0);
      harmonyText = staffObj.harmonyTextNice(harmonyElem.text);
      rootTpc     = harmonyElem.rootTpc;
      bassTpc     = harmonyElem.baseTpc;
      harmonyObj  = new staffObj.harmonyObject;

      conLog(0, "----- Doing harmony: \"", harmonyText, "\" --- (", segElement._name(), ")");

      conLog(1,
        "harmony: ", harmonyText, ", ticks: ", staffObj.ticksToStr(segElement.durationType),
        ", root TPC: ", rootTpc, " (" + harmonyObj.tpcInfo(rootTpc).letterAlt + ")" +
        ", bass TPC: ", bassTpc, " (" + harmonyObj.tpcInfo(bassTpc).letterAlt + ")"
        );

      if (! harmonyText) {
        // try transpose if not already done
        if (glb.harmonyNbr === 1 && transposeTry) {
          conLog(0, "----- All Harmonies don't have value in texts, trying transpose; undo ---> Restart");
          reinitHarmonyTexts();
          transposeTry = false;
          staffObj.initCursors(cursor);
          continue;
        }
        errorWithColorChord(
          "All chords are not parsed by MuseScore\n\n" +
          "Undo everything, transpose the whole staff for the chords one step up.\n" +
          "Then one step down again (or down + up), don't use \"undo\". And retry this script.\n" +
          "(tip: assign \"transpose up\" and \"transpose down\" to keys)"
          );
        return false;
      }

      // ignore harmonies with text that starts with "(", or ends with ")" without
      // any earlier "(".
      if (glb.ignoreHarmonyRegex.test(harmonyText)) {
        conLog(0, "harmony starts with \"(\" or ends with \")\" (without any \"(\"), ignore --->");
        cursor.next();
        continue;
      }

      tempChord  = null;

      // parse the chord to semitones (semitones includes root)
      harmonyObj.harmonyToSemitones(harmonyText, harmonyElem);
      // any error message?
      if (harmonyObj.error) {
        errorWithColorChord(
          harmonyObj.errorMessage,
          "(use parentheses to avoid parsing)\n" + (harmonyObj.errorInfo || "")
          );
        return false;
      }

      if (harmonyObj.noChord) {
        // create and write new rest
        // bass
        if (gStaff.bass) {
          (tempChord = newElement(Element.REST)).ctnHarmonyText = harmonyText;
          staffObj.writeChord(gStaff.bass, tempChord);
          if (glb.swQuit) return false;
        }
        // root
        (tempChord = newElement(Element.REST)).ctnHarmonyText = harmonyText;
        staffObj.writeChord(gStaff.mid, tempChord);
        if (glb.swQuit) return false;
        cursor.next();
        continue
      }

      /// Bass note (root note transformed down 2 octaves) ///

      if (gStaff.bass && ! harmonyObj.addToLastChord) {
        tpc = bassTpc;
        // use root tpc, unless explicit bass tpc
        if (tpc < -1) tpc = rootTpc;
        tpc = harmonyObj.reduceDoubleAlt(tpc);
        pitch = harmonyObj.tpcInfo(tpc, glb.octaveBass).pitch;
        // don't use to low notes
        if (glb.bassMinPitch && pitch < glb.bassMinPitch) pitch += glb.pitchOctave;

        // create and write new chord (only one note)
        tempChord = newElement(Element.CHORD);
        tempChord.add(createNote(pitch, tpc, tpc));
        tempChord.ctnHarmonyObj = harmonyObj;
        staffObj.writeChord(gStaff.bass, tempChord);
        if (glb.swQuit) return false;
      }

      /// Root with chord ///

      if (harmonyObj.addToLastChord) {
        tpc = harmonyObj.rootTpc;
        if (! tpc) {
          errorWithColorChord(
            "\"add to last Chord\" is used but there is no last Chord"
            );
          return false;
        }
      } else {
        tpc = rootTpc;
      }
      if (tpc >= -1) {
        pitch = harmonyObj.tpcInfo(tpc, glb.octaveRoot).pitch;
        // don't use too high notes
        if (glb.rootMaxPitch && pitch > glb.rootMaxPitch) pitch -= glb.pitchOctave;

        // create new chord
        tempChord = newElement(Element.CHORD);

        semitones = harmonyObj.semitones;
        semiTpcs  = harmonyObj.semiTpcs;
        // no semitones found?
        if (! semitones || semitones.length < 2) {
          errorWithColorChord(
            "Semitones not found for chord " + harmonyText + "\nPerhaps misspelled?"
            );
          return false;
        }

        // add all notes to the chord (root is included in semitones)
        for (var s in semitones) {
          var semi    = semitones[s],
              semiTpc = semiTpcs[s];
          conLog(2, "- adding semitone: ", semi, ", with TPC: ", semiTpc);
          tempChord.add(createNote(pitch + semi, semiTpc, semiTpc));
        }

        // write the chord with notes
        tempChord.ctnHarmonyObj = harmonyObj;
        staffObj.writeChord(gStaff.mid, tempChord);
        if (glb.swQuit) return false;
      }
    }
    cursor.next();
  }

  staffObj.finishUp();
  console.log("Generation complete");
  return true;

}; // mainLg

}; // mainObject


//xxxFootxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

property variant mainO:   new mainObject;
property variant glb:     mainO.glb;

onRun: {
  if (glb.debugFile) {
    mainO.openLog();
    log("\n");
    log("----------------------------------------------------------------\n");
    log("// vim: ft=javascript\n");
    log("// Log created: " + (new Date()).toLocaleString() + "\n");
    log("----------------------------------------------------------------\n");
    log("\n");
  }
  if (! mainO.initLg()) endItUp();
}

function preThing() {
  if (pluginSettings.visible) pluginSettings.close();
  if (! mainO.preLg()) endItUp();
}

function mainThing() {
  if (pluginSettings.visible) pluginSettings.close();
  curScore.startCmd();
  if (mainO.mainLg() && glb.swShowOk && ! (glb.resultText || glb.resultInfoText)) {
    glb.resultText     = "The generation was successful, DO Save, CLOSE AND REOPEN the Score!";
    glb.resultInfoText = "Otherwise the Score will be in a bad state and MuseScore can crash!";
  }
  curScore.endCmd();
  endItUp();
}

function endItUp() {
  if (pluginSettings.visible) pluginSettings.close();
  if (glb.resultText || glb.resultInfoText) {
    messageBox.doAccepted = function() {
      if (! glb.swQuit && glb.swAskClose) closeScore(curScore);
    };
    messageBox.doOpen();
  }
  mainO.closeLog();
  Qt.quit();
}

property int boxWidth: 80;

function fillOneDropDown(box, currentIdx, dashes) {
  var listText, listElm,
      listIdx = 0,
      list    = box.model;
  list.clear();
  while ((listText = box.textArr[listIdx])) {
    listElm = {
      text:  (dashes ? '-' : listText),
      pitch: box.valueArr[listIdx]
    };
    list.append(listElm);
    listIdx++;
  }
  if (mainO.truthy(currentIdx, 0)) box.currentIndex = currentIdx;
  box.width = boxWidth;
}

function fillDropDowns() {
  // init all combo box lists
  fillOneDropDown(rootOctave,  glb.octaveRootDefaultIndex);
  fillOneDropDown(rootMaxTone, glb.rootMaxDefaultIndex);
  fillOneDropDown(bassOctave,  glb.octaveBassDefaultIndex);
  fillOneDropDown(bassMinTone, glb.bassMinDefaultIndex);
}

function getSettings() {
  if (glb.swUseDialog) {
    // octave for the root Chord
    glb.octaveRoot   = rootOctaveList.get(rootOctave.currentIndex).pitch;
    // octave for the bass Note
    glb.octaveBass   = bassOctaveList.get(bassOctave.currentIndex).pitch;
    // Chord root max pitch
    glb.rootMaxPitch = rootMaxToneList.get(rootMaxTone.currentIndex).pitch;
    // Bass min pitch
    glb.bassMinPitch = bassMinToneList.get(bassMinTone.currentIndex).pitch;

    glb.lowIsMinor        = lowIsMinor.checked;
    glb.allowAddToLast    = allowAddToLast.checked;
    glb.writeParsed       = writeParsed.checked;
    glb.reduceChordsLevel = 0 + reduceChordMedium.checked + 2 * reduceChordMax.checked;
    glb.extImpliesLower   = extImpliesLower.checked;
    glb.writeChordNotes   = 0 + writeChordNotes.checked + 2 * writeChordNotesInC.checked;
  }

  if (glb.octaveBass === -99 || ! mainO.truthy(glb.octaveBass, 0))
    mainO.gStaff.bass = null;

  // fix max/min absolute pitches for chord root/bass
  if (typeof(glb.rootMaxPitch) !== "number") glb.rootMaxPitch = false;
  if (typeof(glb.bassMinPitch) !== "number") glb.bassMinPitch  = false;
  if (glb.rootMaxPitch) // (0 = false)
    glb.rootMaxPitch += glb.octaveRoot * glb.pitchOctave + glb.pitchCinOctave0;
  if (glb.bassMinPitch) // (0 = false)
    glb.bassMinPitch += glb.octaveBass * glb.pitchOctave + glb.pitchCinOctave0;

  // securing true/false
  glb.lowIsMinor      = !!glb.lowIsMinor;
  glb.allowAddToLast  = !!glb.allowAddToLast;
  glb.extImpliesLower = !!glb.extImpliesLower;
  // secure 0/1
  glb.writeParsed     = (glb.writeParsed ? 1 : 0);

  // securing 0
  if (typeof(glb.reduceChordsLevel) !== "number") glb.reduceChordsLevel = 0;
  if (typeof(glb.writeChordNotes)   !== "number") glb.writeChordNotes   = 0;
}

function getAddStaves() {
  var useStaves, res;
  useStaves = (mainO.gStaff.bass ? 2 : 1);
  if (glb.swAskStaffAdd) {
    if (curScore.nstaves >= 1 + useStaves) {
      res = (messageBox.clickedButton === StandardButton.Ok ? 0 : false);
    } else if (curScore.nstaves > 1) {
      res = false;
    } else {
      switch(messageBox.clickedButton) {
        case StandardButton.Yes: res = 1; break;
        case StandardButton.No:  res = 2; break;
        default: res = false;
      }
    }
  } else {
    if (curScore.nstaves >= 1 + useStaves) {
      res = 0;
    } else if (curScore.nstaves > 1) {
      res = 0;
    } else {
      res = 2;
    }
  }
  return res;
}

property string winTitle: " Notes from Chord texts"

MessageDialog {
  id:       messageBox
  title:    winTitle
  modality: Qt.ApplicationModal
  text:     ""
  width:    80
  icon:     StandardIcon.Information
  standardButtons: StandardButton.Ok
  // to be changed
  property var doAccepted: function() { mainThing(); }
  onAccepted: doAccepted()
  onRejected: endItUp()
  onYes:      mainThing()
  onNo:       mainThing()

  function doOpen(resultText, resultInfoText, resultButtons, resultIcon) {
    text  = resultText || glb.resultText || "";
    if (text.length < 55) {
      // to get a nice width
      text += "                                     ".substr(0, 55 - text.length);
    }
    informativeText = resultInfoText || glb.resultInfoText || "";
    if (informativeText) informativeText += "\n";
    // must do this otherwise last value will be shown
    if (! informativeText) informativeText = " ";
    icon            = resultIcon     || glb.resultIcon     || StandardIcon.Information;
    standardButtons = resultButtons  || glb.resultButtons  || StandardButton.Ok;
    open();
  }
}

Dialog {
  id:       pluginSettings
  title:    winTitle
  modality: Qt.ApplicationModal
  width:    350
  height:   620 + (glb.allowAddToLastShow ? 20 : 0)

  contentItem: Rectangle {
    Keys.onReturnPressed: {
      if (buttonCancel.activeFocus) buttonCancel.clicked();
      else buttonOk.clicked();
    }
    Keys.onEscapePressed: buttonCancel.clicked()

    color: "lightgrey"
    anchors.fill: parent

    GridLayout {
      columns: 1
      anchors.fill:    parent
      anchors.margins: 15
      anchors.bottomMargin: 5

      Label {
        text:
          "This plugin sometimes crashes.\n" +
          "In that case try to first start it with no Score opened,\n" +
          "and just click ok.\n" +
          "Then you can open a Score and it seems to work well.\n" +
          "Don't know why.\n"
      }

      GridLayout {
        columns: 2
        Label { text: "Octave for root Chord:" }
        ComboBox {
          id:    rootOctave
          // dummy ListElement required for initial creation of this component
          model: ListModel { id: rootOctaveList; ListElement { text: "dummy" }}
          property variant textArr:  [ "1", "0", "-1" ]
          property variant valueArr: [ 1, 0, -1 ]
        }
        Label { text: "Max root note, otherwise 1 octave down:" }
        ComboBox {
          id:    rootMaxTone
          model: ListModel { id: rootMaxToneList; ListElement { text: "dummy" }}
          property variant textArr:  [ "Don't use", "D", "E", "F", "G", "A", "B" ]
          property variant valueArr: [ 0, 2, 4, 5, 7, 9, 11 ]
        }
        Label { text: "Octave for bass note:" }
        ComboBox {
          id:    bassOctave
          model: ListModel { id: bassOctaveList; ListElement { text: "dummy" }}
          property variant textArr:  [ "Don't use", "0", "-1", "-2", "-3" ]
          property variant valueArr: [ -99, 0, -1, -2, -3 ]
          onCurrentIndexChanged: {
            var doDisable = (currentIndex === 0 && bassMinTone.enabled),
                doEnable  = ! (currentIndex === 0 || bassMinTone.enabled);
            if (doDisable) {
              bassMinTone.saveIndex    = bassMinTone.currentIndex;
              fillOneDropDown(bassMinTone, null, true);
              bassMinTone.enabled      = false;
            } else if (doEnable) {
              bassMinTone.enabled      = true;
              fillOneDropDown(bassMinTone);
              bassMinTone.currentIndex = bassMinTone.saveIndex;
            }
          }
        }
        Label { text: "Min bass note, otherwise 1 octave up:" }
        ComboBox {
          id:    bassMinTone
          model: ListModel { id: bassMinToneList; ListElement { text: "dummy" }}
          property alias textArr:  rootMaxTone.textArr
          property alias valueArr: rootMaxTone.valueArr
          property int saveIndex:  glb.bassMinDefaultIndex
        }
      }

      Column {
        CheckBox {
          id:   lowIsMinor
          text: "Lower case keys means minor chords"
          checked: (!!glb.lowIsMinor)
        }
      }

      Column {
        CheckBox {
          id:   allowAddToLast
          text: "Allow add to last harmony (experimental)"
          checked: (!!glb.allowAddToLast)
          visible: !!glb.allowAddToLastShow
        }
      }

      GroupBox {
        implicitWidth: 315
        Column {
          ExclusiveGroup {
            id: exclId1
          }
          Label {
            text: "Reduce chords:\n"
          }
          RadioButton {
            id:   reduceChordNo
            text: "None"
            checked: (glb.reduceChordsLevel === 0)
            exclusiveGroup: exclId1
          }
          Label { text: " " }
          RadioButton {
            id:   reduceChordMedium
            text: "Medium:\n" +
                  "- 11th chord: no major 3rd\n" +
                  "- 13th chord: no perfect 5th or perfect 11th/4th"
            checked: (glb.reduceChordsLevel === 1)
            exclusiveGroup: exclId1
          }
          Label { text: " " }
          RadioButton {
            id:   reduceChordMax
            text: "Max, as Medium plus:\n" +
                  "-  9th chord: no perfect 5th\n" +
                  "- 13th chord: no major 9th, no major 2nd (unless \"sus2\")"
            exclusiveGroup: exclId1
            checked: (glb.reduceChordsLevel === 2)
          }
          Label { text: " " }
          Column {
            CheckBox {
              id:   extImpliesLower
              text: "9th, 11th and 13th extension implies lower,\n" +
                    "9th chord implies 7th, 11th implies 9th and 7th, etc."
              checked: (!!glb.extImpliesLower)
            }
          }
          Label { text: " " }
        }
      }

      Column {
        CheckBox {
          id:   writeParsed
          text: "Write parsed Harmony texts"
          checked: (!!glb.writeParsed)
        }
      }

      GroupBox {
        implicitWidth: 315
        Row {
          ExclusiveGroup {
            id: exclId2
          }
          Label {
            y: 3.5
            text: "Write Chord letters:  "
          }
          RadioButton {
            id:   writeChordNotesNo
            text: "No"
            checked: (glb.writeChordNotes === 0)
            exclusiveGroup: exclId2
          }
          RadioButton {
            id:   writeChordNotes
            text: "Yes"
            checked: (glb.writeChordNotes === 1)
            exclusiveGroup: exclId2
          }
          RadioButton {
            id:   writeChordNotesInC
            text: "In C-scale"
            checked: (glb.writeChordNotes === 2)
            exclusiveGroup: exclId2
          }
        }
      }

      Label { id: posLabel1; text: " " }

      Row {
        anchors.fill:      posLabel1
        anchors.topMargin: 15
        Button {
          id:   buttonOk
          text: qsTranslate("PrefsDialogBase", "Run")
          onClicked: { preThing(); }
        }
        Button {
          id:   buttonCancel
          text: qsTranslate("PrefsDialogBase", "Cancel")
          onClicked: { endItUp(); }
        }
      }
    }
  } // Rectangle
} // Dialog

} // MuseScore
