# Project 2 — Regular Expressions I: Four-Letter Scrabble Words

An introduction to pattern matching in R, practised on a word list instead of
crime data: every "question" is answered with a regular expression.

## What the code does

`code/regular_expressions_scrabble_words.R` loads a list of four-letter
Scrabble words (`scrabble4letter.txt`) into a vector called `words`, then works
through a series of pattern-finding exercises with `grep()` / `grepl()`:

- Words that start with `z`, and with a double `zz`
- Words containing no vowels, exactly one vowel, or a consonant–vowel–vowel–consonant pattern
- Words whose vowels and consonants strictly alternate
- In which of the four letter positions the letter `r` appears most often
- Which of the endings `-ar`, `-er`, `-or`, `-ur` is most common
- Words that differ from "mitt" in exactly one letter, and rhymes of "mitt"

## Data

- `scrabble4letter.txt` — a plain-text list of four-letter words, loaded with `scan()`. See `data/README.md`.

## Status

Complete.
