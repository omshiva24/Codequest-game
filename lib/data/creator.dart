// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

/// Who made CodeQuest, and why. Shown on the title screen, the home screen,
/// Settings and the About screen, so everyone who opens the app knows whose
/// work this is. Change the words here and they change everywhere.
library;

const String creatorName = 'P Om Shiva';
const String creatorCourse = 'M.Tech CSE (2nd year)';
const String creatorUniversity = 'Pondicherry University';
const String creatorGithub = 'https://github.com/omshiva24';

/// "M.Tech CSE (2nd year), Pondicherry University"
const String creatorDetails = '$creatorCourse, $creatorUniversity';

const String copyrightLine = '© 2026 $creatorName. All rights reserved.';

const String noCopyNotice =
    'CodeQuest - its idea, game design, code, levels, characters and text - is the '
    'original work of $creatorName. Copying, reusing, re-uploading or showing any part '
    'of it as your own without written permission from $creatorName is not allowed.';

const String whyTitle = 'Why I made CodeQuest';

/// The creator's message, one paragraph per item.
const List<String> whyMessage = [
  'Too many students are afraid of programming. They see a screen full of brackets '
      'and semicolons, memorise programs just to pass the exam, and decide that coding '
      'is "not for them".',
  'I made CodeQuest to prove that wrong. Every student, from any school and any '
      'background, can learn to code when learning feels like playing instead of '
      'punishment.',
  'Here, a mistake is not a failure. A bug just makes Byte fall in the river - you see '
      'why, you fix it, and you try again. That is exactly how real programmers work '
      'every day.',
  'My dream is simple: no student should ever give up on coding because it felt '
      'boring or scary. Play, make mistakes, keep going. You are a coder.',
];
