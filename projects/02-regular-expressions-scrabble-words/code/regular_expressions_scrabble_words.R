#0
words <- scan(file="scrabble4letter.txt",what="")

#1
grep("^[z]", dataText, value = TRUE)

#2
grep("^[z][z]", dataText, value = TRUE)

#3
grep("[^aeiou]", words, value = TRUE)

#4
grep("^[^aeiou]*[aeiou][^aeiou]*$", words, value = TRUE)

#5
grep("^[^aeiou][aeiou][aeiou][^aeiou]$", words, value = TRUE)

#6
grep("^([^aeiou][aeiou]){2}$|^([aeiou][^aeiou]){2}$",
     words, value = TRUE)

#7
r_counts <- sapply(1:4, function(position) {
  sum(substr(words, position, position) == "r")
  })

names(r_counts) <- paste("Position", 1:4)

r_counts
names(which.max(r_counts))

#8
endings <- c("ar", "er", "or", "ur")

ending_counts <- sapply(endings, function(ending) { #sapply repeat the same operation, function ending creates a new temporary function(placeholder)
  sum(grepl(paste0(ending, "$"), words))
  })

ending_counts
names(which.max(ending_counts))

#9
grep("^[^m]itt$|^m[^i]tt$|^mi[^t]t$|^mit[^t]$",
     words, value = TRUE)

#10
rhymes <- grep("it{1,2}$", words, value = TRUE) #
rhymes[rhymes != "mitt"]

