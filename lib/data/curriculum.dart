import '../models/models.dart';

// All learning content lives here as plain data, so it is easy to review,
// test and extend. Answers are written first (index 0) for readability; the
// game shuffles the options at runtime.

Question _q(
  String id,
  String prompt,
  List<String> options,
  String explanation, {
  String? code,
}) =>
    Question(
      id: id,
      prompt: prompt,
      code: code,
      options: options,
      answer: 0,
      explanation: explanation,
    );

// ---------------------------------------------------------------------------
// PYTHON JUNGLE
// ---------------------------------------------------------------------------
final List<Level> _python = [
  Level(
    id: 'py-1',
    lang: Lang.python,
    number: 1,
    title: 'Hello, Python!',
    kind: LevelKind.runner,
    lesson: const Lesson(
      title: 'Talking to the computer',
      story: 'A program is a list of instructions. In Python, print() shows a '
          'message on the screen. Text goes inside quotes. Python does maths '
          'too: print(2 + 3) shows 5. Lines that start with # are comments - '
          'notes for humans that the computer skips.',
      code: r'''# This is a comment
print("Hello, World!")
print(2 + 3)''',
      keyPoints: [
        'print() shows things on the screen.',
        'Text (a "string") goes inside quotes.',
        '# starts a comment. Python ignores it.',
        'Python uses indentation (spaces) to group code.',
      ],
    ),
    questions: [
      _q('py-1-1', 'Which line shows text on the screen?',
          ['print("Hi")', 'echo "Hi"', 'show("Hi")'],
          'print() is the Python command for showing output.'),
      _q('py-1-2', 'What does this show?', ['5', '2 + 3', '23'],
          'Without quotes, Python calculates 2 + 3 first, then prints 5.',
          code: 'print(2 + 3)'),
      _q('py-1-3', 'A comment in Python starts with...', ['#', '//', '--'],
          'Python comments start with #. (// is used in C, C++ and Java.)'),
      _q('py-1-4', 'What does this show?', ['HiHiHi', 'Hi3', 'Error'],
          'Multiplying a string by a number repeats it.',
          code: 'print("Hi" * 3)'),
      _q('py-1-5', 'Python groups code blocks using...',
          ['Indentation', '{ } braces', 'begin / end'],
          'Python uses spaces at the start of lines (indentation) instead of braces.'),
    ],
  ),
  Level(
    id: 'py-2',
    lang: Lang.python,
    number: 2,
    title: 'Variables & Types',
    kind: LevelKind.battle,
    enemy: const Enemy('Type Goblin', '👺'),
    lesson: const Lesson(
      title: 'Boxes with labels',
      story: 'A variable is like a box with a label. You put a value inside '
          'and use the label later. Every value has a type: whole numbers are '
          'int, decimals are float, text is str and True/False is bool. In '
          'Python you do not write the type - Python figures it out.',
      code: r'''age = 20          # int
price = 9.99      # float
name = "Om"       # str
is_fun = True     # bool
print(name, age)''',
      keyPoints: [
        'Make a variable with name = value.',
        'type(x) tells you the type of x.',
        'Names can use letters, digits and _, but cannot start with a digit.',
        '"5" (text) is different from 5 (number).',
      ],
    ),
    questions: [
      _q('py-2-1', 'What does this print?',
          ["<class 'str'>", "<class 'int'>", '5', 'Error'],
          'Anything inside quotes is a string (str), even if it looks like a number.',
          code: 'y = "5"\nprint(type(y))'),
      _q('py-2-2', 'Which is a valid variable name?',
          ['my_score', '2score', 'my-score', 'class'],
          'Names cannot start with a digit, cannot contain -, and cannot be keywords like class.'),
      _q('py-2-3', 'What does this print?', ['15', '10', '105', 'a + 5'],
          'a starts at 10, then a + 5 makes 15 and stores it back in a.',
          code: 'a = 10\na = a + 5\nprint(a)'),
      _q('py-2-4', 'What type is 3.14?', ['float', 'int', 'str', 'bool'],
          'Numbers with a decimal point are floats.'),
      _q('py-2-5', 'What does this print?', ['Hi Om', 'Hi + name', 'Hi name', 'Error'],
          'The + joins (concatenates) two strings.',
          code: 'name = "Om"\nprint("Hi " + name)'),
    ],
  ),
  const Level(
    id: 'py-3',
    lang: Lang.python,
    number: 3,
    title: 'If / Else Decisions',
    kind: LevelKind.puzzle,
    lesson: Lesson(
      title: 'Choosing a path',
      story: 'Programs make decisions with if. If the condition is True, the '
          'indented code runs. elif means "else if" - another check. else runs '
          'when nothing above was True. Do not forget the colon : and the '
          'indentation!',
      code: r'''marks = 82
if marks >= 90:
    print("A")
elif marks >= 75:
    print("B")
else:
    print("C")''',
      keyPoints: [
        'Comparisons: ==, !=, >, <, >=, <=',
        'Every if / elif / else line ends with a colon :',
        'The code inside must be indented (4 spaces).',
        'Only the first True branch runs.',
      ],
    ),
    puzzles: [
      PuzzleSpec(
        id: 'py-3-1',
        goal: 'Print "Adult" if age is 18 or more, otherwise print "Kid".',
        lines: [
          'age = 20',
          'if age >= 18:',
          '    print("Adult")',
          'else:',
          '    print("Kid")',
        ],
        explanation: 'First store the age, then check it with if. else catches every other case.',
        output: 'Adult',
      ),
      PuzzleSpec(
        id: 'py-3-2',
        goal: 'Print "Even" if n is even, otherwise "Odd".',
        lines: [
          'n = 7',
          'if n % 2 == 0:',
          '    print("Even")',
          'else:',
          '    print("Odd")',
        ],
        explanation: '% gives the remainder. Even numbers have remainder 0 when divided by 2.',
        output: 'Odd',
      ),
      PuzzleSpec(
        id: 'py-3-3',
        goal: 'Give grade A for 90+, B for 75+, otherwise C.',
        lines: [
          'marks = 82',
          'if marks >= 90:',
          '    print("A")',
          'elif marks >= 75:',
          '    print("B")',
          'else:',
          '    print("C")',
        ],
        explanation: 'Check the highest grade first. elif is only checked when the if above was False.',
        output: 'B',
      ),
    ],
  ),
  Level(
    id: 'py-4',
    lang: Lang.python,
    number: 4,
    title: 'Loop Run',
    kind: LevelKind.runner,
    lesson: const Lesson(
      title: 'Doing things again and again',
      story: 'Loops repeat code so you do not have to copy it. A for loop goes '
          'through each item in a sequence. range(3) gives 0, 1, 2 - it starts '
          'at 0 and stops BEFORE 3. A while loop keeps going as long as its '
          'condition is True. break jumps out of a loop early.',
      code: r'''for i in range(3):
    print(i)        # 0, 1, 2

count = 3
while count > 0:
    print(count)    # 3, 2, 1
    count = count - 1''',
      keyPoints: [
        'range(n) counts 0 up to n-1.',
        'range(a, b) counts a up to b-1.',
        'while repeats while a condition is True.',
        'break exits the loop. continue skips to the next round.',
      ],
    ),
    questions: [
      _q('py-4-1', 'What does this print?', ['0 1 2', '1 2 3', '0 1 2 3'],
          'range(3) starts at 0 and stops before 3.',
          code: 'for i in range(3):\n    print(i)'),
      _q('py-4-2', 'Which numbers does range(1, 5) give?',
          ['1 2 3 4', '1 2 3 4 5', '0 1 2 3 4'],
          'The start is included but the end (5) is not.'),
      _q('py-4-3', 'Which loop repeats while a condition is True?',
          ['while', 'if', 'def'],
          'while keeps looping as long as its condition stays True.'),
      _q('py-4-4', 'What does break do inside a loop?',
          ['Exits the loop', 'Skips one round', 'Restarts it'],
          'break stops the loop completely. continue only skips the current round.'),
      _q('py-4-5', 'How many times does this loop run?', ['3', '1', '4'],
          'A for loop over a string visits each character: a, b, c.',
          code: 'for c in "abc":\n    print(c)'),
    ],
  ),
  Level(
    id: 'py-5',
    lang: Lang.python,
    number: 5,
    title: 'Boss: Functions',
    kind: LevelKind.battle,
    isBoss: true,
    enemy: const Enemy('Bug King', '👑'),
    lesson: const Lesson(
      title: 'Making your own commands',
      story: 'A function is a reusable mini-program with a name. Create one '
          'with def, give it inputs (parameters), and send a result back with '
          'return. Then "call" it by writing its name with brackets.',
      code: r'''def add(a, b):
    return a + b

result = add(2, 3)
print(result)   # 5

def greet(name="friend"):
    print("Hi", name)

greet()         # Hi friend''',
      keyPoints: [
        'def name(parameters): starts a function.',
        'return sends a value back to the caller.',
        'No return? The function gives back None.',
        'Parameters can have default values.',
      ],
    ),
    questions: [
      _q('py-5-1', 'Which keyword creates a function?',
          ['def', 'function', 'func', 'fn'],
          'Python functions start with def (short for "define").'),
      _q('py-5-2', 'What does this print?', ['5', '23', 'add', 'None'],
          'add returns a + b, which is 5.',
          code: 'def add(a, b):\n    return a + b\nprint(add(2, 3))'),
      _q('py-5-3', 'A function without a return statement gives back...',
          ['None', '0', 'An empty string', 'An error'],
          'Python returns None automatically when there is no return.'),
      _q('py-5-4', 'What does this print?', ['Hi friend', 'Hi name', 'Error', 'Hi'],
          'No argument was given, so the default value "friend" is used.',
          code: 'def hi(name="friend"):\n    print("Hi", name)\nhi()'),
      _q('py-5-5', 'Find the bug!',
          ['Missing colon after (x)', 'x * x is wrong', 'return needs brackets', 'Nothing is wrong'],
          'Every def line must end with a colon :',
          code: 'def square(x)\n    return x * x'),
    ],
  ),
];

// ---------------------------------------------------------------------------
// C CAVES
// ---------------------------------------------------------------------------
final List<Level> _c = [
  Level(
    id: 'c-1',
    lang: Lang.c,
    number: 1,
    title: 'Hello, C!',
    kind: LevelKind.runner,
    lesson: const Lesson(
      title: 'Your first C program',
      story: 'Every C program starts running from main(). To print, we use '
          'printf, which lives in the stdio.h library - so we #include it at '
          'the top. Each instruction ends with a semicolon ; like a full stop '
          'in a sentence. \\n inside text means "go to a new line".',
      code: r'''#include <stdio.h>

int main() {
    // print a message
    printf("Hello, World!\n");
    return 0;
}''',
      keyPoints: [
        '#include <stdio.h> gives you printf.',
        'The program starts at main().',
        'Statements end with ;',
        r'\n makes a new line. // starts a comment.',
      ],
    ),
    questions: [
      _q('c-1-1', 'Which function prints text in C?', ['printf', 'print', 'echo'],
          'printf (print formatted) comes from stdio.h.'),
      _q('c-1-2', 'Every C statement ends with...', [';', '.', ':'],
          'The semicolon tells the compiler where a statement ends.'),
      _q('c-1-3', 'A C program starts running from...',
          ['main()', 'start()', 'Line 1'],
          'main() is the entry point of every C program.'),
      _q('c-1-4', r'What does \n mean inside printf?',
          ['New line', 'A space', 'The letter n'],
          r'\n is an "escape sequence" that moves output to the next line.'),
      _q('c-1-5', 'To use printf you must include...',
          ['stdio.h', 'math.h', 'string.h'],
          'stdio.h = standard input/output, home of printf and scanf.'),
    ],
  ),
  Level(
    id: 'c-2',
    lang: Lang.c,
    number: 2,
    title: 'Variables & Types',
    kind: LevelKind.battle,
    enemy: const Enemy('Type Goblin', '👺'),
    lesson: const Lesson(
      title: 'Every box needs a type',
      story: 'In C you must say the type when you make a variable: int for '
          'whole numbers, float or double for decimals, char for one letter. '
          'printf needs a format code to print a variable: %d for int, %f '
          'for float, %c for char. Dividing two ints throws away the decimal '
          'part!',
      code: r'''int age = 20;
float price = 9.5;
char grade = 'A';
printf("%d %.1f %c\n", age, price, grade);
printf("%d\n", 7 / 2);   // 3, not 3.5''',
      keyPoints: [
        'Declare: type name = value;',
        '%d int, %f float, %c char, %s text',
        'int / int gives an int (decimal part is dropped).',
        'a += 3 is short for a = a + 3',
      ],
    ),
    questions: [
      _q('c-2-1', 'What does this print?', ['3', '3.5', '4', 'Error'],
          'Both numbers are ints, so C does integer division and drops .5',
          code: 'int x = 7 / 2;\nprintf("%d", x);'),
      _q('c-2-2', 'Which format code prints an int?', ['%d', '%f', '%c', '%s'],
          '%d means "decimal integer".'),
      _q('c-2-3', "Best type to store one letter like 'A'?",
          ['char', 'float', 'double', 'void'],
          'char holds a single character.'),
      _q('c-2-4', 'What does this print?', ['8', '53', '5', '3'],
          'a += 3 adds 3 to a, so 5 becomes 8.',
          code: 'int a = 5;\na += 3;\nprintf("%d", a);'),
      _q('c-2-5', 'What does this print?', ['5.0', '5', '2.5', '4.0'],
          'p * 2 is 5.0, and %.1f prints one digit after the decimal point.',
          code: 'float p = 2.5;\nprintf("%.1f", p * 2);'),
    ],
  ),
  const Level(
    id: 'c-3',
    lang: Lang.c,
    number: 3,
    title: 'If / Else Decisions',
    kind: LevelKind.puzzle,
    lesson: Lesson(
      title: 'Branches in the cave',
      story: 'In C the condition goes inside round brackets ( ) and the code '
          'to run goes inside curly braces { }. else if adds more checks, and '
          'else catches everything left over.',
      code: r'''int t = 30;
if (t > 35) {
    printf("Hot\n");
} else if (t > 20) {
    printf("Warm\n");
} else {
    printf("Cold\n");
}''',
      keyPoints: [
        'if (condition) { ... }',
        '== checks equality. = stores a value!',
        '&& means AND, || means OR.',
        'Braces { } group the code of each branch.',
      ],
    ),
    puzzles: [
      PuzzleSpec(
        id: 'c-3-1',
        goal: 'Print "Pass" if marks are 40 or more, else "Fail".',
        lines: [
          'int marks = 55;',
          'if (marks >= 40) {',
          r'    printf("Pass\n");',
          '} else {',
          r'    printf("Fail\n");',
          '}',
        ],
        explanation: 'The condition sits in ( ), each branch sits in { }, and the final } closes the else.',
        output: 'Pass',
      ),
      PuzzleSpec(
        id: 'c-3-2',
        goal: 'Print "Even" if n is even, else "Odd".',
        lines: [
          'int n = 4;',
          'if (n % 2 == 0) {',
          r'    printf("Even\n");',
          '} else {',
          r'    printf("Odd\n");',
          '}',
        ],
        explanation: 'n % 2 is the remainder after dividing by 2. Even numbers give 0.',
        output: 'Even',
      ),
      PuzzleSpec(
        id: 'c-3-3',
        goal: 'Print "Hot" above 35, "Warm" above 20, else "Cold".',
        lines: [
          'int t = 30;',
          'if (t > 35) {',
          r'    printf("Hot\n");',
          '} else if (t > 20) {',
          r'    printf("Warm\n");',
          '} else {',
          r'    printf("Cold\n");',
          '}',
        ],
        explanation: 'Checks run from top to bottom, so the biggest limit must be checked first.',
        output: 'Warm',
      ),
    ],
  ),
  Level(
    id: 'c-4',
    lang: Lang.c,
    number: 4,
    title: 'Loop Run',
    kind: LevelKind.runner,
    lesson: const Lesson(
      title: 'Round and round',
      story: 'A for loop has three parts: start; condition; step. i++ means '
          '"add 1 to i". A while loop checks its condition before each round. '
          'A do-while loop runs once first and checks afterwards.',
      code: r'''for (int i = 0; i < 3; i++) {
    printf("%d ", i);   // 0 1 2
}

int n = 3;
while (n > 0) {
    printf("%d ", n);   // 3 2 1
    n--;
}''',
      keyPoints: [
        'for (start; condition; step)',
        'i++ adds 1, i-- subtracts 1.',
        'do { } while (...); always runs at least once.',
        'continue skips to the next round, break exits.',
      ],
    ),
    questions: [
      _q('c-4-1', 'How many times does this loop run?', ['3', '2', '4'],
          'i takes the values 0, 1 and 2. When i becomes 3, i < 3 is false.',
          code: 'for (int i = 0; i < 3; i++)'),
      _q('c-4-2', 'What does i++ do?', ['Adds 1 to i', 'Doubles i', 'Prints i'],
          '++ is the increment operator.'),
      _q('c-4-3', 'Which loop checks AFTER running once?',
          ['do-while', 'while', 'for'],
          'do-while runs the body first, then checks the condition.'),
      _q('c-4-4', 'How many times does the body run?', ['0', '5', 'Forever'],
          'i > 5 is false at the start (5 is not greater than 5), so the body never runs.',
          code: 'int i = 5;\nwhile (i > 5) { i--; }'),
      _q('c-4-5', 'What does continue do?',
          ['Skips to next round', 'Exits the loop', 'Stops program'],
          'continue jumps straight to the next round of the loop.'),
    ],
  ),
  Level(
    id: 'c-5',
    lang: Lang.c,
    number: 5,
    title: 'Boss: Functions',
    kind: LevelKind.battle,
    isBoss: true,
    enemy: const Enemy('Segfault Dragon', '🐉'),
    lesson: const Lesson(
      title: 'Splitting the work',
      story: 'A C function has a return type, a name and parameters with '
          'types. void means it returns nothing. If you call a function '
          'before writing it, add a prototype (a one-line declaration) at the '
          'top. C passes copies of values into functions.',
      code: r'''#include <stdio.h>

int add(int a, int b);   // prototype

int main() {
    printf("%d\n", add(4, 5));  // 9
    return 0;
}

int add(int a, int b) {
    return a + b;
}''',
      keyPoints: [
        'returnType name(type param, ...) { ... }',
        'void = returns nothing.',
        'A prototype tells the compiler about a function early.',
        'Arguments are copied (pass by value).',
      ],
    ),
    questions: [
      _q('c-5-1', 'What does this print?', ['9', '45', '4 + 5', 'Error'],
          'add returns 4 + 5 = 9.',
          code: 'int add(int a, int b) { return a + b; }\nprintf("%d", add(4, 5));'),
      _q('c-5-2', 'Return type of a function that returns nothing?',
          ['void', 'null', 'empty', 'none'],
          'void means "no value".'),
      _q('c-5-3', 'What is a function prototype?',
          ['A declaration before use', 'A test copy', 'A comment', 'A loop'],
          'It tells the compiler the function name, return type and parameters before the full code appears.'),
      _q('c-5-4', 'Find the bug!',
          ['Missing ; after x * x', 'Wrong return type', 'Needs printf', 'Nothing is wrong'],
          'Every statement needs a semicolon, including return statements.',
          code: 'int square(int x) {\n    return x * x\n}'),
      _q('c-5-5', 'When you pass an int to a function, it receives...',
          ['A copy of the value', 'The original variable', 'Nothing', 'Its address'],
          'C uses pass-by-value. To change the original you would pass a pointer.'),
    ],
  ),
];

// ---------------------------------------------------------------------------
// C++ CASTLE
// ---------------------------------------------------------------------------
final List<Level> _cpp = [
  Level(
    id: 'cpp-1',
    lang: Lang.cpp,
    number: 1,
    title: 'Hello, C++!',
    kind: LevelKind.runner,
    lesson: const Lesson(
      title: 'Streams of text',
      story: 'C++ is C with super-powers. To print, send text into cout with '
          'the << arrows, like pouring water into a cup. endl ends the line. '
          'To read from the keyboard, use cin with >> arrows.',
      code: r'''#include <iostream>
using namespace std;

int main() {
    cout << "Hello, World!" << endl;
    int age;
    cin >> age;
    cout << "You are " << age << endl;
    return 0;
}''',
      keyPoints: [
        '#include <iostream> gives cout and cin.',
        'cout << prints, cin >> reads input.',
        'endl ends the line.',
        'Statements end with ;',
      ],
    ),
    questions: [
      _q('cpp-1-1', 'Which line prints in C++?',
          ['cout << "Hi";', 'print("Hi")', 'echo "Hi"'],
          'cout with << sends output to the screen.'),
      _q('cpp-1-2', 'What does endl do?', ['Ends the line', 'Ends the program', 'Adds a comment'],
          'endl moves to a new line (and flushes the output).'),
      _q('cpp-1-3', 'Which header gives you cout?',
          ['<iostream>', '<stdio>', '<cout>'],
          'iostream = input/output streams.'),
      _q('cpp-1-4', 'How do you read user input?', ['cin >> x;', 'cout << x;', 'input(x)'],
          'cin with >> reads a value into a variable.'),
      _q('cpp-1-5', 'What does this show?', ['5', '2 + 3', '23'],
          'C++ calculates 2 + 3 first, then prints 5.',
          code: 'cout << 2 + 3;'),
    ],
  ),
  Level(
    id: 'cpp-2',
    lang: Lang.cpp,
    number: 2,
    title: 'Variables & Types',
    kind: LevelKind.battle,
    enemy: const Enemy('Type Goblin', '👺'),
    lesson: const Lesson(
      title: 'Typed treasure chests',
      story: 'C++ variables have types like int, double, char, bool and '
          'string. auto lets the compiler pick the type for you. const makes a '
          'value that can never change. % gives the remainder of a division.',
      code: r'''#include <string>
int coins = 10;
double speed = 4.5;
string hero = "Om";
bool alive = true;
auto lives = 3;          // int
const int MAX_LIVES = 5; // cannot change''',
      keyPoints: [
        'string stores text (include <string>).',
        'auto picks the type from the value.',
        'const values cannot be changed later.',
        'cout prints true as 1 and false as 0.',
      ],
    ),
    questions: [
      _q('cpp-2-1', 'Which type stores text like "hello"?',
          ['string', 'char', 'text', 'word'],
          'std::string holds a sequence of characters.'),
      _q('cpp-2-2', 'With auto x = 4.5; what type is x?',
          ['double', 'int', 'auto', 'string'],
          'A decimal literal like 4.5 is a double.'),
      _q('cpp-2-3', 'What does this print?', ['1', 'true', '0', 'Error'],
          '5 > 3 is true, and cout prints true as 1 by default.',
          code: 'bool ok = 5 > 3;\ncout << ok;'),
      _q('cpp-2-4', 'What does this print?', ['1', '3', '3.33', '0'],
          '10 divided by 3 is 3 remainder 1. % gives the remainder.',
          code: 'int a = 10, b = 3;\ncout << a % b;'),
      _q('cpp-2-5', 'What happens here?',
          ['Compile error', 'MAX becomes 6', 'MAX stays 5 silently', 'Crash at runtime'],
          'const variables are read-only. The compiler stops you from changing them.',
          code: 'const int MAX = 5;\nMAX = 6;'),
    ],
  ),
  const Level(
    id: 'cpp-3',
    lang: Lang.cpp,
    number: 3,
    title: 'If / Else Decisions',
    kind: LevelKind.puzzle,
    lesson: Lesson(
      title: 'Which door to open?',
      story: 'C++ decisions look like C: the condition goes in ( ) and the '
          'code in { }. Use else if for extra checks. You can combine checks '
          'with && (and) and || (or).',
      code: r'''int score = 70;
if (score >= 90) {
    cout << "Gold";
} else if (score >= 60) {
    cout << "Silver";
} else {
    cout << "Bronze";
}''',
      keyPoints: [
        'if (condition) { ... } else { ... }',
        '== compares, = assigns.',
        '&& is AND, || is OR, ! is NOT.',
        'Check the biggest limit first.',
      ],
    ),
    puzzles: [
      PuzzleSpec(
        id: 'cpp-3-1',
        goal: 'Read an age and print "Can vote" if it is 18+, else "Too young".',
        lines: [
          'int age;',
          'cin >> age;',
          'if (age >= 18) {',
          '    cout << "Can vote";',
          '} else {',
          '    cout << "Too young";',
          '}',
        ],
        explanation: 'Declare the variable, read it with cin, then decide with if / else.',
        output: 'Can vote',
        input: '20',
      ),
      PuzzleSpec(
        id: 'cpp-3-2',
        goal: 'Give Gold for 90+, Silver for 60+, otherwise Bronze.',
        lines: [
          'int score = 70;',
          'if (score >= 90) {',
          '    cout << "Gold";',
          '} else if (score >= 60) {',
          '    cout << "Silver";',
          '} else {',
          '    cout << "Bronze";',
          '}',
        ],
        explanation: 'The highest medal is checked first; else if only runs when the check above failed.',
        output: 'Silver',
      ),
    ],
  ),
  Level(
    id: 'cpp-4',
    lang: Lang.cpp,
    number: 4,
    title: 'Loop Run',
    kind: LevelKind.runner,
    lesson: const Lesson(
      title: 'Marching through vectors',
      story: 'C++ has the same for and while loops as C. It also has a '
          'range-based for loop that visits every item of a container like a '
          'vector - a list that can grow. v.size() tells you how many items '
          'it has.',
      code: r'''#include <vector>
vector<int> nums = {4, 8, 15};
nums.push_back(16);        // add an item

for (int n : nums) {
    cout << n << " ";      // 4 8 15 16
}
cout << nums.size();       // 4''',
      keyPoints: [
        'for (int i = 1; i <= 3; i++) counts 1, 2, 3.',
        'for (int x : v) visits each item.',
        'vector grows with push_back().',
        'while (true) needs a break to stop.',
      ],
    ),
    questions: [
      _q('cpp-4-1', 'What does for (int x : nums) do?',
          ['Visits each item', 'Counts to x', 'Sorts nums'],
          'The range-based for loop gives you each element one by one.'),
      _q('cpp-4-2', 'What does this print?', ['123', '012', '1234'],
          'i starts at 1 and the loop runs while i <= 3.',
          code: 'for (int i = 1; i <= 3; i++)\n    cout << i;'),
      _q('cpp-4-3', 'while (true) with no break runs...',
          ['Forever', 'Once', 'Never'],
          'The condition is always true, so it is an infinite loop.'),
      _q('cpp-4-4', 'Which is a list that can grow?', ['vector', 'int', 'char'],
          'vector is a dynamic array that can grow and shrink.'),
      _q('cpp-4-5', 'What does v.size() give?',
          ['Number of items', 'The last item', 'Memory address'],
          'size() returns how many elements are in the vector.'),
    ],
  ),
  Level(
    id: 'cpp-5',
    lang: Lang.cpp,
    number: 5,
    title: 'Boss: Classes',
    kind: LevelKind.battle,
    isBoss: true,
    enemy: const Enemy('Null Pointer Ghost', '👻'),
    lesson: const Lesson(
      title: 'Blueprints and objects',
      story: 'A class is a blueprint, like a cookie cutter. An object is a '
          'real thing made from it, like a cookie. Classes keep data and '
          'functions (methods) together. private parts can only be used '
          'inside the class; public parts can be used by everyone.',
      code: r'''class Dog {
private:
    string name;
public:
    Dog(string n) { name = n; }     // constructor
    void bark() { cout << name << ": Woof!"; }
};

Dog d("Rex");
d.bark();   // Rex: Woof!''',
      keyPoints: [
        'class = blueprint, object = real thing.',
        'Use . to call a method: d.bark()',
        'private = inside the class only.',
        'Same name, different parameters = overloading.',
      ],
    ),
    questions: [
      _q('cpp-5-1', 'Which keyword creates a blueprint for objects?',
          ['class', 'object', 'new', 'blueprint'],
          'class defines a new type with data and methods.'),
      _q('cpp-5-2', 'What does this print?', ['Woof', 'bark', 'Dog', 'Error'],
          'd is a Dog object; calling d.bark() runs the bark method.',
          code: 'class Dog {\npublic:\n  void bark() { cout << "Woof"; }\n};\nDog d;\nd.bark();'),
      _q('cpp-5-3', 'Same function name, different parameters is called...',
          ['Overloading', 'Overriding', 'Looping', 'Hiding'],
          'Function overloading lets you reuse a name with different parameter lists.'),
      _q('cpp-5-4', 'private members can be used...',
          ['Only inside the class', 'Anywhere', 'Only in main', 'Never'],
          'private hides data so only the class itself can touch it (encapsulation).'),
      _q('cpp-5-5', 'Find the bug!',
          ['twice() is missing an argument', 'Wrong return type', 'cout cannot print ints', 'Nothing is wrong'],
          'twice needs one int, e.g. twice(4).',
          code: 'int twice(int x) {\n    return 2 * x;\n}\ncout << twice();'),
    ],
  ),
];

// ---------------------------------------------------------------------------
// JAVA VOLCANO
// ---------------------------------------------------------------------------
final List<Level> _java = [
  Level(
    id: 'java-1',
    lang: Lang.java,
    number: 1,
    title: 'Hello, Java!',
    kind: LevelKind.runner,
    lesson: const Lesson(
      title: 'Everything lives in a class',
      story: 'In Java, all code lives inside a class. The program starts in '
          'the main method. System.out.println prints a line of text and then '
          'moves to the next line; System.out.print stays on the same line. '
          'A public class named Main must be saved in Main.java.',
      code: r'''public class Main {
    public static void main(String[] args) {
        // print a message
        System.out.println("Hello, World!");
    }
}''',
      keyPoints: [
        'Code lives inside a class.',
        'The program starts in main.',
        'println prints and adds a new line.',
        'Statements end with ;',
      ],
    ),
    questions: [
      _q('java-1-1', 'Which line prints in Java?',
          ['System.out.println("Hi");', 'print("Hi")', 'echo "Hi"'],
          'System.out.println is Java\'s print command.'),
      _q('java-1-2', 'Java code must live inside a...', ['class', 'folder', 'loop'],
          'Java is object-oriented: every method belongs to a class.'),
      _q('java-1-3', 'A Java program starts running in...',
          ['main method', 'first class', 'start()'],
          'public static void main(String[] args) is the entry point.'),
      _q('java-1-4', 'Compared with print, println also adds...',
          ['A new line', 'A space', 'Nothing'],
          'println = print line. It moves to the next line after printing.'),
      _q('java-1-5', 'public class Main must be saved as...',
          ['Main.java', 'main.txt', 'Program.java'],
          'The file name must match the public class name.'),
    ],
  ),
  Level(
    id: 'java-2',
    lang: Lang.java,
    number: 2,
    title: 'Variables & Types',
    kind: LevelKind.battle,
    enemy: const Enemy('Type Goblin', '👺'),
    lesson: const Lesson(
      title: 'Strongly typed lava rocks',
      story: 'Java needs a type for every variable: int, double, boolean, '
          'char, or String (with a capital S). int divided by int drops the '
          'decimal. When you add a String and a number, Java glues them '
          'together as text.',
      code: r'''int lives = 3;
double speed = 2.5;
boolean ready = true;
String hero = "Om";
System.out.println(hero.length());   // 2
System.out.println("A" + 1 + 2);     // A12''',
      keyPoints: [
        'String has a capital S.',
        'boolean is true or false.',
        'int / int drops the decimal part.',
        'String + number = joined text.',
      ],
    ),
    questions: [
      _q('java-2-1', 'What does this print?', ['2', '2.5', '3', 'Error'],
          '10 and 4 are ints, so the result is an int: 2.',
          code: 'int x = 10 / 4;\nSystem.out.println(x);'),
      _q('java-2-2', 'Which type stores true or false?',
          ['boolean', 'bool', 'bit', 'int'],
          'Java calls it boolean (C++ calls it bool).'),
      _q('java-2-3', 'What does this print?', ['2', '1', 'Hi', '3'],
          'length() counts the characters: H and i.',
          code: 'String s = "Hi";\nSystem.out.println(s.length());'),
      _q('java-2-4', 'What does this print?', ['5.0', '5', 'Error', '5.00'],
          'The int 5 is converted to a double, which prints as 5.0',
          code: 'double d = 5;\nSystem.out.println(d);'),
      _q('java-2-5', 'What does this print?', ['A12', 'A3', '3A', 'Error'],
          'Java reads left to right: "A" + 1 is "A1", then + 2 gives "A12".',
          code: 'System.out.println("A" + 1 + 2);'),
    ],
  ),
  const Level(
    id: 'java-3',
    lang: Lang.java,
    number: 3,
    title: 'If / Else Decisions',
    kind: LevelKind.puzzle,
    lesson: Lesson(
      title: 'Hot or not?',
      story: 'Java decisions use if, else if and else. The condition must be '
          'a boolean (true or false) inside ( ). The code for each branch '
          'goes inside { }.',
      code: r'''int n = 9;
if (n > 0) {
    System.out.println("Positive");
} else if (n < 0) {
    System.out.println("Negative");
} else {
    System.out.println("Zero");
}''',
      keyPoints: [
        'if (condition) { ... }',
        'Compare numbers with ==, compare Strings with .equals()',
        '&& AND, || OR, ! NOT',
        'Only one branch runs.',
      ],
    ),
    puzzles: [
      PuzzleSpec(
        id: 'java-3-1',
        goal: 'Print "Hot" if temp is above 25, else "Cool".',
        lines: [
          'int temp = 30;',
          'if (temp > 25) {',
          '    System.out.println("Hot");',
          '} else {',
          '    System.out.println("Cool");',
          '}',
        ],
        explanation: 'Store the temperature first, then use if / else to pick a message.',
        output: 'Hot',
      ),
      PuzzleSpec(
        id: 'java-3-2',
        goal: 'Say if n is Positive, Negative or Zero.',
        lines: [
          'int n = 9;',
          'if (n > 0) {',
          '    System.out.println("Positive");',
          '} else if (n < 0) {',
          '    System.out.println("Negative");',
          '} else {',
          '    System.out.println("Zero");',
          '}',
        ],
        explanation: 'Two checks cover positive and negative; else handles the only case left: zero.',
        output: 'Positive',
      ),
    ],
  ),
  Level(
    id: 'java-4',
    lang: Lang.java,
    number: 4,
    title: 'Loop Run',
    kind: LevelKind.runner,
    lesson: const Lesson(
      title: 'Lava laps',
      story: 'Java loops work like C loops. Arrays store many values of the '
          'same type, and their index starts at 0. The enhanced for loop '
          'visits every item without counting.',
      code: r'''int[] nums = {3, 6, 9};
for (int i = 0; i < nums.length; i++) {
    System.out.println(nums[i]);
}
for (int n : nums) {        // enhanced for
    System.out.println(n);
}''',
      keyPoints: [
        'Array index starts at 0.',
        'arr.length gives the size.',
        'for (int n : arr) visits each item.',
        'do-while runs at least once.',
      ],
    ),
    questions: [
      _q('java-4-1', 'How many times does this loop run?', ['4', '3', '5'],
          'i goes 0, 1, 2, 3 - that is 4 rounds.',
          code: 'for (int i = 0; i < 4; i++)'),
      _q('java-4-2', 'What does for (int n : nums) do?',
          ['Visits each item', 'Counts to n', 'Makes an array'],
          'The enhanced for loop walks through every element.'),
      _q('java-4-3', 'What is i at the end?', ['1', '0', '-1'],
          'do-while runs once (i becomes 1) before checking i < 0, which is false.',
          code: 'int i = 0;\ndo { i++; } while (i < 0);'),
      _q('java-4-4', 'Array index starts at...', ['0', '1', '-1'],
          'The first element is arr[0].'),
      _q('java-4-5', 'What does break do?',
          ['Exits the loop', 'Skips a round', 'Ends program'],
          'break leaves the loop immediately.'),
    ],
  ),
  Level(
    id: 'java-5',
    lang: Lang.java,
    number: 5,
    title: 'Boss: Methods & Objects',
    kind: LevelKind.battle,
    isBoss: true,
    enemy: const Enemy('Exception Hydra', '🐲'),
    lesson: const Lesson(
      title: 'Objects and their abilities',
      story: 'A method is a function inside a class. static methods belong to '
          'the class itself, so you can call them without an object. To make '
          'an object, use new. If something goes wrong at runtime, Java throws '
          'an exception - you can catch it with try / catch.',
      code: r'''static int square(int x) {
    return x * x;
}

Dog d = new Dog();      // create an object
System.out.println(square(3));   // 9

try {
    int[] a = new int[5];
    a[5] = 1;           // index 5 does not exist!
} catch (ArrayIndexOutOfBoundsException e) {
    System.out.println("Oops!");
}''',
      keyPoints: [
        'new creates an object.',
        'void methods return nothing.',
        'Valid indexes are 0 to length - 1.',
        'try / catch handles exceptions.',
      ],
    ),
    questions: [
      _q('java-5-1', 'How do you create a Dog object?',
          ['Dog d = new Dog();', 'Dog d = Dog;', 'make Dog d;', 'create Dog();'],
          'new builds a fresh object and calls its constructor.'),
      _q('java-5-2', 'What does this print?', ['9', '6', '33', 'Error'],
          'sq(3) returns 3 * 3 = 9.',
          code: 'static int sq(int x) { return x * x; }\nSystem.out.println(sq(3));'),
      _q('java-5-3', 'A method that returns nothing has type...',
          ['void', 'null', 'empty', 'none'],
          'void means the method gives no value back.'),
      _q('java-5-4', 'Using arr[5] when arr.length is 5 causes...',
          ['ArrayIndexOutOfBoundsException', 'It returns 0', 'It returns null', 'Nothing'],
          'Valid indexes are 0-4, so Java throws an exception.'),
      _q('java-5-5', 'Find the bug!',
          ['Missing ; after "Om"', 'String must be string', 'println is wrong', 'Nothing is wrong'],
          'Each statement needs a semicolon at the end.',
          code: 'String name = "Om"\nSystem.out.println(name);'),
    ],
  ),
];

/// Every world and its levels, in play order.
final Map<Lang, List<Level>> curriculum = {
  Lang.python: _python,
  Lang.c: _c,
  Lang.cpp: _cpp,
  Lang.java: _java,
};

List<Level> levelsFor(Lang lang) => curriculum[lang] ?? const [];

List<Level> get allLevels =>
    [for (final lang in Lang.values) ...levelsFor(lang)];

Level? levelById(String id) {
  for (final level in allLevels) {
    if (level.id == id) return level;
  }
  return null;
}

/// The level after [level] in the same world, if any.
Level? nextLevel(Level level) {
  final list = levelsFor(level.lang);
  final i = list.indexOf(level);
  return (i >= 0 && i + 1 < list.length) ? list[i + 1] : null;
}
