// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import '../models/models.dart';

/// One topic the offline Doubt Buddy can explain.
class KbEntry {
  const KbEntry({
    required this.id,
    required this.title,
    required this.keywords,
    required this.answer,
    this.examples = const {},
  });

  final String id;
  final String title;

  /// Lower-case words or phrases that point to this topic.
  final List<String> keywords;

  /// Simple-words explanation.
  final String answer;
  final Map<Lang, String> examples;
}

const List<KbEntry> doubtKb = [
  KbEntry(
    id: 'greeting',
    title: 'Hi there!',
    keywords: ['hello', 'hi', 'hey', 'help', 'who are you'],
    answer: "I'm Byte, your Doubt Buddy! Ask me anything about Python, C, C++ "
        'or Java - for example "What is a loop?", "Why do I need a semicolon?" '
        'or "What is a pointer?". Tip: pick a language chip so my examples '
        'match the world you are playing.',
  ),
  KbEntry(
    id: 'variable',
    title: 'Variables',
    keywords: ['variable', 'variables', 'store a value', 'declare', 'assign', 'assignment'],
    answer: 'A variable is a labelled box that stores a value. You give it a '
        'name, put a value in it, and use the name later. You can also '
        'replace the value. In Python you just write name = value. In C, C++ '
        'and Java you must also say the type, like int or double.',
    examples: {
      Lang.python: 'score = 10\nscore = score + 5\nprint(score)  # 15',
      Lang.c: 'int score = 10;\nscore = score + 5;\nprintf("%d", score); // 15',
      Lang.cpp: 'int score = 10;\nscore += 5;\ncout << score; // 15',
      Lang.java: 'int score = 10;\nscore += 5;\nSystem.out.println(score); // 15',
    },
  ),
  KbEntry(
    id: 'types',
    title: 'Data types',
    keywords: ['data type', 'datatype', 'type', 'int', 'float', 'double', 'char', 'string', 'str', 'bool', 'boolean'],
    answer: 'A data type tells the computer what kind of value something is. '
        'Common ones: whole numbers (int), decimals (float/double), single '
        'letters (char), text (string) and true/false (bool / boolean). The '
        'type decides what you can do: you can add numbers, but "5" + "5" '
        'joins text to make "55".',
    examples: {
      Lang.python: 'age = 20        # int\nprice = 9.99    # float\nname = "Om"     # str\nok = True       # bool',
      Lang.c: "int age = 20;\nfloat price = 9.99;\nchar grade = 'A';",
      Lang.cpp: 'int age = 20;\ndouble price = 9.99;\nstring name = "Om";\nbool ok = true;',
      Lang.java: 'int age = 20;\ndouble price = 9.99;\nString name = "Om";\nboolean ok = true;',
    },
  ),
  KbEntry(
    id: 'output',
    title: 'Printing output',
    keywords: ['print', 'printf', 'cout', 'println', 'output', 'display', 'show on screen'],
    answer: 'Printing shows text or values on the screen. Each language has '
        'its own command: print() in Python, printf in C, cout << in C++ and '
        'System.out.println in Java.',
    examples: {
      Lang.python: 'print("Hello")\nprint("Sum:", 2 + 3)',
      Lang.c: 'printf("Hello\\n");\nprintf("Sum: %d\\n", 2 + 3);',
      Lang.cpp: 'cout << "Hello" << endl;\ncout << "Sum: " << 2 + 3 << endl;',
      Lang.java: 'System.out.println("Hello");\nSystem.out.println("Sum: " + (2 + 3));',
    },
  ),
  KbEntry(
    id: 'input',
    title: 'Reading input',
    keywords: ['input', 'scanf', 'cin', 'scanner', 'read from user', 'keyboard', 'user enter'],
    answer: 'Input lets the user type a value while the program runs. Python '
        'uses input() (it always gives text, so convert with int()). C uses '
        'scanf with &, C++ uses cin >>, and Java uses a Scanner.',
    examples: {
      Lang.python: 'age = int(input("Age? "))\nprint(age + 1)',
      Lang.c: 'int age;\nscanf("%d", &age);\nprintf("%d", age + 1);',
      Lang.cpp: 'int age;\ncin >> age;\ncout << age + 1;',
      Lang.java: 'Scanner sc = new Scanner(System.in);\nint age = sc.nextInt();\nSystem.out.println(age + 1);',
    },
  ),
  KbEntry(
    id: 'if',
    title: 'If / else',
    keywords: ['if', 'else', 'elif', 'else if', 'condition', 'decision', 'conditional'],
    answer: 'if lets your program choose. If the condition is true, its code '
        'runs; otherwise the else part runs. Use elif (Python) or else if '
        '(C, C++, Java) to check more conditions. Only the FIRST true branch '
        'runs, so check the most specific case first.',
    examples: {
      Lang.python: 'if marks >= 40:\n    print("Pass")\nelse:\n    print("Fail")',
      Lang.c: 'if (marks >= 40) {\n    printf("Pass");\n} else {\n    printf("Fail");\n}',
      Lang.cpp: 'if (marks >= 40) {\n    cout << "Pass";\n} else {\n    cout << "Fail";\n}',
      Lang.java: 'if (marks >= 40) {\n    System.out.println("Pass");\n} else {\n    System.out.println("Fail");\n}',
    },
  ),
  KbEntry(
    id: 'for-vs-while',
    title: 'for vs while',
    keywords: ['for vs while', 'difference between for and while', 'for and while', 'while and for'],
    answer: 'Both repeat code. Use a for loop when you know how many times to '
        'repeat or you want to visit every item in a list. Use a while loop '
        'when you repeat until something happens (for example "until the '
        'user types quit"). Any for loop can be rewritten as a while loop.',
    examples: {
      Lang.python: 'for i in range(3):   # known count\n    print(i)\n\nwhile answer != "quit":  # unknown count\n    answer = input()',
      Lang.java: 'for (int i = 0; i < 3; i++) { ... }\nwhile (!answer.equals("quit")) { ... }',
    },
  ),
  KbEntry(
    id: 'for',
    title: 'for loops',
    keywords: ['for loop', 'for', 'range', 'loop', 'loops', 'iterate', 'repeat', 'iteration'],
    answer: 'A loop repeats code. A for loop is great when you know how many '
        'times to repeat: it has a counter that changes each round. In Python, '
        'range(3) gives 0, 1, 2 (it stops BEFORE 3). In C, C++ and Java a for '
        'loop has three parts: start; condition; step.',
    examples: {
      Lang.python: 'for i in range(3):\n    print(i)   # 0 1 2',
      Lang.c: 'for (int i = 0; i < 3; i++) {\n    printf("%d ", i);  // 0 1 2\n}',
      Lang.cpp: 'for (int i = 0; i < 3; i++) {\n    cout << i << " ";  // 0 1 2\n}',
      Lang.java: 'for (int i = 0; i < 3; i++) {\n    System.out.println(i);  // 0 1 2\n}',
    },
  ),
  KbEntry(
    id: 'while',
    title: 'while loops',
    keywords: ['while', 'while loop', 'do while', 'do-while', 'infinite loop'],
    answer: 'A while loop keeps repeating as long as its condition is true. '
        'Make sure something inside the loop changes, or it will run forever '
        '(an infinite loop). A do-while loop (C, C++, Java) always runs at '
        'least once because it checks the condition at the end.',
    examples: {
      Lang.python: 'n = 3\nwhile n > 0:\n    print(n)\n    n -= 1   # 3 2 1',
      Lang.c: 'int n = 3;\nwhile (n > 0) {\n    printf("%d ", n);\n    n--;\n}',
      Lang.cpp: 'int n = 3;\nwhile (n > 0) {\n    cout << n-- << " ";\n}',
      Lang.java: 'int n = 3;\nwhile (n > 0) {\n    System.out.println(n);\n    n--;\n}',
    },
  ),
  KbEntry(
    id: 'break',
    title: 'break and continue',
    keywords: ['break', 'continue', 'exit loop', 'skip'],
    answer: 'break stops the loop completely and jumps to the code after it. '
        'continue skips only the rest of the current round and goes to the '
        'next round.',
    examples: {
      Lang.python: 'for i in range(5):\n    if i == 1:\n        continue  # skip 1\n    if i == 3:\n        break     # stop at 3\n    print(i)    # 0 2',
      Lang.java: 'for (int i = 0; i < 5; i++) {\n    if (i == 1) continue;\n    if (i == 3) break;\n    System.out.println(i); // 0 2\n}',
    },
  ),
  KbEntry(
    id: 'function',
    title: 'Functions and methods',
    keywords: ['function', 'functions', 'method', 'methods', 'def', 'call', 'parameter', 'argument'],
    answer: 'A function is a named, reusable block of code - like your own '
        'command. You give it inputs (parameters), it does some work, and it '
        'can give back a result with return. In Java, functions inside a '
        'class are called methods.',
    examples: {
      Lang.python: 'def add(a, b):\n    return a + b\n\nprint(add(2, 3))  # 5',
      Lang.c: 'int add(int a, int b) {\n    return a + b;\n}\n// printf("%d", add(2, 3));',
      Lang.cpp: 'int add(int a, int b) {\n    return a + b;\n}\n// cout << add(2, 3);',
      Lang.java: 'static int add(int a, int b) {\n    return a + b;\n}\n// System.out.println(add(2, 3));',
    },
  ),
  KbEntry(
    id: 'return',
    title: 'return',
    keywords: ['return', 'returns', 'void', 'none', 'return value'],
    answer: 'return sends a value back to the code that called the function '
        'and ends the function. A function that returns nothing is void in '
        'C, C++ and Java. In Python it automatically returns None.',
    examples: {
      Lang.python: 'def square(x):\n    return x * x\n\ny = square(4)  # 16',
      Lang.c: 'void sayHi() {\n    printf("Hi");  // returns nothing\n}',
    },
  ),
  KbEntry(
    id: 'array',
    title: 'Arrays and lists',
    keywords: ['array', 'arrays', 'list', 'lists', 'vector', 'index', 'arraylist'],
    answer: 'An array (or list) stores many values under one name, in order. '
        'You get an item by its index, and the first index is 0, not 1! '
        'Python lists and C++ vectors can grow; C and Java arrays have a '
        'fixed size.',
    examples: {
      Lang.python: 'nums = [4, 8, 15]\nprint(nums[0])   # 4\nnums.append(16)',
      Lang.c: 'int nums[3] = {4, 8, 15};\nprintf("%d", nums[0]);  // 4',
      Lang.cpp: 'vector<int> nums = {4, 8, 15};\nnums.push_back(16);\ncout << nums[0];  // 4',
      Lang.java: 'int[] nums = {4, 8, 15};\nSystem.out.println(nums[0]);  // 4\nSystem.out.println(nums.length); // 3',
    },
  ),
  KbEntry(
    id: 'string',
    title: 'Strings (text)',
    keywords: ['string', 'strings', 'text', 'concatenate', 'concatenation', 'join text', 'length'],
    answer: 'A string is text - a sequence of characters inside quotes. You '
        'can join strings with + and find their length. In C there is no '
        'built-in string type: text is an array of char ending with a hidden '
        r"'\0'.",
    examples: {
      Lang.python: 'name = "Om"\nprint("Hi " + name)\nprint(len(name))  # 2',
      Lang.c: 'char name[] = "Om";\nprintf("%s %lu", name, strlen(name));',
      Lang.cpp: 'string name = "Om";\ncout << "Hi " + name << name.length();',
      Lang.java: 'String name = "Om";\nSystem.out.println("Hi " + name);\nSystem.out.println(name.length());',
    },
  ),
  KbEntry(
    id: 'class',
    title: 'Classes and objects (OOP)',
    keywords: ['class', 'classes', 'object', 'objects', 'oop', 'constructor', 'inheritance', 'encapsulation', 'polymorphism'],
    answer: 'A class is a blueprint (like a cookie cutter) and an object is a '
        'real thing made from it (a cookie). A class groups data (fields) '
        'and actions (methods). OOP ideas: encapsulation (hide details), '
        'inheritance (a class can extend another), polymorphism (one name, '
        'many behaviours). C has no classes; Python, C++ and Java do.',
    examples: {
      Lang.python: 'class Dog:\n    def __init__(self, name):\n        self.name = name\n    def bark(self):\n        print(self.name, "says Woof")\n\nDog("Rex").bark()',
      Lang.cpp: 'class Dog {\npublic:\n    string name;\n    void bark() { cout << name << " says Woof"; }\n};\nDog d; d.name = "Rex"; d.bark();',
      Lang.java: 'class Dog {\n    String name;\n    Dog(String n) { name = n; }\n    void bark() { System.out.println(name + " says Woof"); }\n}\nnew Dog("Rex").bark();',
    },
  ),
  KbEntry(
    id: 'pointer',
    title: 'Pointers',
    keywords: ['pointer', 'pointers', 'address', '&', 'dereference', 'reference', 'segfault', 'segmentation fault'],
    answer: 'A pointer is a variable that stores the ADDRESS of another '
        'variable - like writing down a house number instead of copying the '
        'house. & gets an address, * follows the address to the value. Using '
        'a pointer that points nowhere (NULL) or to freed memory causes a '
        'crash called a segmentation fault. Python and Java hide pointers '
        'from you.',
    examples: {
      Lang.c: 'int x = 5;\nint *p = &x;   // p holds the address of x\n*p = 10;       // change x through p\nprintf("%d", x);  // 10',
      Lang.cpp: 'int x = 5;\nint* p = &x;\n*p = 10;\ncout << x;  // 10\nint& r = x;  // a reference is a safer alias',
    },
  ),
  KbEntry(
    id: 'memory',
    title: 'Memory: malloc / new',
    keywords: ['malloc', 'free', 'new', 'delete', 'memory', 'heap', 'memory leak', 'garbage collector'],
    answer: 'Some memory is borrowed while the program runs (the heap). In C '
        'you borrow with malloc and give back with free. In C++ use new / '
        'delete, or better, smart pointers and vectors that clean up for you. '
        'Java and Python have a garbage collector that frees memory '
        'automatically. Forgetting to free memory is a memory leak.',
    examples: {
      Lang.c: 'int *a = malloc(5 * sizeof(int));\nif (a != NULL) {\n    a[0] = 42;\n    free(a);\n}',
      Lang.cpp: 'auto p = make_unique<int>(42);  // freed automatically\nvector<int> v(5);              // also automatic',
    },
  ),
  KbEntry(
    id: 'semicolon',
    title: 'Why semicolons?',
    keywords: ['semicolon', ';', 'expected ;', 'missing semicolon'],
    answer: 'In C, C++ and Java a semicolon ; marks the end of a statement, '
        'like a full stop ends a sentence. If you forget one, the compiler '
        'gets confused and reports an error (often on the NEXT line). Python '
        'does not need semicolons - a new line ends the statement.',
    examples: {
      Lang.c: 'int x = 5;      // correct\nint y = 6       // error: expected ;',
      Lang.java: 'String name = "Om";\nSystem.out.println(name);',
    },
  ),
  KbEntry(
    id: 'indentation',
    title: 'Indentation',
    keywords: ['indentation', 'indent', 'indentationerror', 'spaces', 'tabs', 'whitespace'],
    answer: 'Indentation means the spaces at the start of a line. In Python it '
        'is REQUIRED: it shows which lines belong inside an if, loop or '
        'function. Use 4 spaces and be consistent, or you get an '
        'IndentationError. C, C++ and Java use { } braces instead, but '
        'indenting still makes code easier to read.',
    examples: {
      Lang.python: 'if x > 0:\n    print("positive")   # inside the if\nprint("done")           # outside the if',
    },
  ),
  KbEntry(
    id: 'comment',
    title: 'Comments',
    keywords: ['comment', 'comments', '#', '//', '/*'],
    answer: 'Comments are notes for humans. The computer skips them. Python '
        'uses #. C, C++ and Java use // for one line and /* ... */ for many '
        'lines.',
    examples: {
      Lang.python: '# This is a comment\nprint("Hi")  # also a comment',
      Lang.c: '// one line\n/* many\n   lines */',
    },
  ),
  KbEntry(
    id: 'modulus',
    title: 'The % (modulus) operator',
    keywords: ['%', 'modulus', 'modulo', 'remainder', 'mod', 'even', 'odd'],
    answer: '% gives the REMAINDER after division. 7 % 2 is 1 because 7 = '
        '2 x 3 + 1. A number is even when n % 2 == 0. (Careful: inside '
        'printf, %d is a format code, not the modulus operator.)',
    examples: {
      Lang.python: 'print(7 % 2)   # 1\nprint(10 % 5)  # 0',
      Lang.java: 'System.out.println(7 % 2);  // 1',
    },
  ),
  KbEntry(
    id: 'division',
    title: 'Integer division',
    keywords: ['division', 'divide', '7/2', 'integer division', 'decimal', '//', 'floor'],
    answer: 'In C, C++ and Java, dividing two ints gives an int - the decimal '
        'part is thrown away, so 7 / 2 is 3. Make one side a decimal (7.0 / 2) '
        'to get 3.5. In Python, / always gives a decimal (3.5) and // gives '
        'the whole-number part (3).',
    examples: {
      Lang.python: 'print(7 / 2)   # 3.5\nprint(7 // 2)  # 3',
      Lang.c: 'printf("%d", 7 / 2);      // 3\nprintf("%.1f", 7.0 / 2);  // 3.5',
      Lang.java: 'System.out.println(7 / 2);    // 3\nSystem.out.println(7.0 / 2);  // 3.5',
    },
  ),
  KbEntry(
    id: 'errors',
    title: 'Errors and bugs',
    keywords: ['error', 'errors', 'bug', 'bugs', 'debug', 'syntax error', 'compile error', 'runtime error', 'not working', 'traceback'],
    answer: 'There are three kinds of errors. Syntax errors: the code breaks '
        'the language rules (missing ; or :). Runtime errors: the program '
        'crashes while running (dividing by zero, bad index). Logic errors: '
        'it runs but gives the wrong answer. Read the error message from the '
        'top, check the line number (and the line before it!), and print '
        'values to see what is happening.',
  ),
  KbEntry(
    id: 'exception',
    title: 'Exceptions (try / catch)',
    keywords: ['exception', 'exceptions', 'try', 'catch', 'except', 'throw', 'raise'],
    answer: 'An exception is a runtime error that you can catch and handle '
        'instead of crashing. Put risky code in try, and handle the problem '
        'in catch (Java, C++) or except (Python).',
    examples: {
      Lang.python: 'try:\n    x = int("abc")\nexcept ValueError:\n    print("Not a number!")',
      Lang.java: 'try {\n    int x = Integer.parseInt("abc");\n} catch (NumberFormatException e) {\n    System.out.println("Not a number!");\n}',
      Lang.cpp: 'try {\n    throw runtime_error("Oops");\n} catch (const exception& e) {\n    cout << e.what();\n}',
    },
  ),
  KbEntry(
    id: 'recursion',
    title: 'Recursion',
    keywords: ['recursion', 'recursive', 'calls itself', 'factorial', 'base case'],
    answer: 'Recursion is when a function calls itself to solve a smaller '
        'version of the same problem. It always needs a base case - a simple '
        'case where it stops - otherwise it never ends.',
    examples: {
      Lang.python: 'def fact(n):\n    if n <= 1:        # base case\n        return 1\n    return n * fact(n - 1)\n\nprint(fact(5))  # 120',
      Lang.c: 'int fact(int n) {\n    if (n <= 1) return 1;\n    return n * fact(n - 1);\n}',
    },
  ),
  KbEntry(
    id: 'main',
    title: 'The main function',
    keywords: ['main', 'main function', 'main method', 'entry point', 'string[] args', 'int main'],
    answer: 'main is where a C, C++ or Java program starts running. In C and '
        'C++ it is int main() and returning 0 means "finished OK". In Java it '
        'is public static void main(String[] args) inside a class. Python has '
        'no required main - it simply runs from the top of the file.',
  ),
  KbEntry(
    id: 'include',
    title: '#include and import',
    keywords: ['include', '#include', 'import', 'header', 'library', 'stdio', 'iostream', 'using namespace'],
    answer: 'Libraries are ready-made code you can reuse. C and C++ bring them '
        'in with #include (like stdio.h or iostream). Java and Python use '
        'import. "using namespace std;" in C++ lets you write cout instead of '
        'std::cout.',
    examples: {
      Lang.python: 'import math\nprint(math.sqrt(16))  # 4.0',
      Lang.c: '#include <stdio.h>\n#include <math.h>',
      Lang.cpp: '#include <iostream>\nusing namespace std;',
      Lang.java: 'import java.util.Scanner;',
    },
  ),
  KbEntry(
    id: 'logic',
    title: 'and / or / not',
    keywords: ['and', 'or', 'not', '&&', '||', 'logical', 'boolean operator'],
    answer: 'Logical operators combine conditions. AND is true only when both '
        'sides are true. OR is true when at least one side is true. NOT flips '
        'true and false. Python writes and / or / not; C, C++ and Java write '
        '&& / || / !.',
    examples: {
      Lang.python: 'if age >= 13 and age <= 19:\n    print("Teen")',
      Lang.java: 'if (age >= 13 && age <= 19) {\n    System.out.println("Teen");\n}',
    },
  ),
  KbEntry(
    id: 'compiled',
    title: 'Compiled vs interpreted',
    keywords: ['compile', 'compiler', 'compiled', 'interpreted', 'interpreter', 'jvm', 'bytecode', 'gcc', 'g++', 'javac'],
    answer: 'A compiler translates your whole program into machine code before '
        'it runs (C and C++ with gcc / g++), which makes it very fast. Python '
        'is interpreted: it reads and runs your code line by line, which is '
        'easier to experiment with. Java compiles to "bytecode" (javac) that '
        'runs on the Java Virtual Machine (JVM), so it works on any computer.',
  ),
  KbEntry(
    id: 'which-first',
    title: 'Which language should I learn first?',
    keywords: ['which language', 'learn first', 'difference between', 'best language', 'python vs', 'c vs', 'java vs', 'c++ vs', 'easier'],
    answer: 'Python is the friendliest start: short, readable code. C teaches '
        'how memory and computers really work. C++ adds classes and is used '
        'for games and fast software. Java is great for big apps and Android, '
        'and has strong typing. Ideas like variables, loops and functions '
        'are the same in all four - learn them once, use them everywhere!',
  ),
  KbEntry(
    id: 'scope',
    title: 'Scope (local and global)',
    keywords: ['scope', 'local', 'global', 'not defined', 'undefined', 'cannot find symbol'],
    answer: 'Scope is where a variable can be used. A variable made inside a '
        'function or block is local - it disappears when that block ends. '
        'If you get "not defined" or "cannot find symbol", you are probably '
        'using a variable outside its scope or misspelled its name.',
    examples: {
      Lang.python: 'def f():\n    x = 5     # local to f\nf()\nprint(x)      # NameError: x is not defined',
      Lang.java: 'for (int i = 0; i < 3; i++) { }\n// i cannot be used here - it only lives inside the loop',
    },
  ),
  KbEntry(
    id: 'null',
    title: 'null / None',
    keywords: ['null', 'none', 'nullpointer', 'null pointer', 'nullpointerexception', 'nullptr'],
    answer: 'null (None in Python, nullptr in C++) means "no value / points to '
        'nothing". Calling a method on null causes errors like Java\'s '
        'NullPointerException. Always check that something exists before '
        'using it.',
    examples: {
      Lang.java: 'String s = null;\nif (s != null) {\n    System.out.println(s.length());\n}',
      Lang.python: 'result = None\nif result is not None:\n    print(result)',
    },
  ),
];
