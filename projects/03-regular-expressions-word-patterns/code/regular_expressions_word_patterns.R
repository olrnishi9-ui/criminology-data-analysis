words <- readLines(file.choose())

#1
grep("(.)\\1", words, value = TRUE)

#2
grep("^(.)(.)\\2\\1$", words, value = TRUE)

#3
gsub("^(.)(.*)$", "\\2\\1", words)

#4
words_upper <- gsub("^(g.*)$", "\\U\\1", words, perl = TRUE)
grep("^G", words_upper, value = TRUE)

#5
gsub(".{3}$", "", words)

#6
gsub("ll", "l", words)

#7
gsub("(.)\\1", "\\1", words)

#8
gsub("^(.)(.)(.)(.)$", "\\1-\\2-\\3-\\4", words)

#9
first_letters <- gsub(".{3}$", "", words)
sort(table(first_letters), decreasing = TRUE)

#10
patterns <- gsub("[bcdfghjklmnpqrstvwxyz]", "C", tolower(words))

patterns <- gsub("[aeiou]", "V", patterns)

sort(table(patterns), decreasing = TRUE)

gsub("[aeious]", "V", words) |>
  gsub("[^v]", "c",x=_)
