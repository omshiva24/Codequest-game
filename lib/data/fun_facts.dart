// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

/// Short "Did you know?" facts shown on the home screen - one per day.
const List<String> funFacts = [
  'Python is named after the comedy group Monty Python, not the snake.',
  'The first computer "bug" was a real moth found stuck inside a computer in 1947.',
  'C was created in 1972 to build the Unix operating system. Linux and Windows still use lots of C.',
  'C++ started as "C with Classes". The ++ means "one step better than C".',
  'Java was first called Oak, after a tree outside its creator\'s office.',
  'Indentation in Python is not just style - it tells Python which lines belong together.',
  'Programmers count from 0, so the first item in a list is item number 0.',
  'Most games you play are built with C++, because it runs very fast.',
  'Android apps were mainly written in Java for many years.',
  'NASA used Python to help analyse pictures of a black hole.',
  'A "Hello, World!" program is the classic first program in almost every language.',
  'Reading code is a skill too: good programmers read far more code than they write.',
];

String factOfTheDay(DateTime day) {
  final dayOfYear = day.difference(DateTime(day.year)).inDays;
  return funFacts[dayOfYear % funFacts.length];
}
