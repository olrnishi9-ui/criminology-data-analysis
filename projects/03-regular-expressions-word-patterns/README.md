# Project 3 — Regular Expressions II: Word Patterns and Transformations

The follow-up to Project 2: the same word-list setting, but now the regular
expressions *change* the words instead of just finding them, using
backreferences — the `(.)\1` trick that lets a pattern refer to something it
matched earlier in the same word.

## What the code does

`code/regular_expressions_word_patterns.R` reads a word list (chosen with
`file.choose()`) and works through exercises with `grep()` and `gsub()`:

- Find words with a doubled letter, and four-letter palindromes such as "abba"
- Move each word's first letter to the end
- Uppercase every word starting with `g` (using `perl = TRUE` and `\U`)
- Delete the last three letters of each word; collapse `ll` to `l`; collapse any doubled letter to a single one
- Split each four-letter word into hyphenated letters (`a-b-c-d`)
- Count which first letter is most common
- Summarise every word as a consonant/vowel pattern (e.g. `CVCC`) and tabulate which patterns occur most often

## Data

- A plain-text word list, one word per line, read with `readLines(file.choose())`. See `data/README.md`.

## Status

Complete.
