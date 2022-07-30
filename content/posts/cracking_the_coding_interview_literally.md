---
title: "Cracking the Coding Interview (literally)"
date: 2022-07-29T18:32:00+02:00
author: "NIBOUCHA Redouane"
description: "A trick for getting an extended time (and memory) limit on competitive-programming environments"
cover: "https://res.cloudinary.com/dik00g2mh/image/upload/v1659112199/cracking_the_coding_interview_literally/hrtfrb5ctykeifit3xyw.jpg"
tags: ["programming","tricks","low level","competitive programming"]
categories: ["programming","security"]
---
# Table of Contents
1. [Introduction](#0b79795d3efc95b9976c7c5b933afce2)
	1. [About competitive programming](#6477f0987fb5a53e6369d1917e269d7f)
	2. [Why is it important?](#8fcb81cfdd7b25a2e8fe175f3c88cfec)
	3. [Types of failed submissions](#c49d19689605f60652d71577f5e93b59)
	4. [Let's focus on time limits, what?](#877ffcb70d0e01f13693cf0d93797a15)
		1. [Hackerrank](#6642e4bb428f8cadd1b0873fc4013baf)
		2. [CodinGame for Work](#667319ac566eaac797fdca146988803d)
		3. [Codechef](#5dc25e8e747697d445a5d2110618850f)
2. [My Idea](#f9e976a90ad6e9dbab943c1e08234c3d)
	1. [Choice for the slower programming language (for the stub)](#551e06d6aba9bf326dd4db6f034fb0ff)
	2. [Initial enumeration on the different platforms](#c331a5c9792d72a6b203c4ce3670fa9b)
		1. [Hackerrank](#6642e4bb428f8cadd1b0873fc4013baf)
		2. [Codingame](#b63e2d7786dac4c313fa11a061fa29c6)
		3. [Codechef](#5dc25e8e747697d445a5d2110618850f)
	3. [Writing the stub](#746756a27857e5ce81151d21b3c84292)
	4. [Implementing the stub](#52310a1a8adabc58b0df39e7774dbbc1)
		1. [Decompressing the native executable](#0d6f0596a96b53b273088a5bc9335903)
		2. [Getting pointers to `memfd_create`, `write` and `fexecve`](#9e9c3afd84a2af46ae2565cb302fc78e)
		3. [Creating the anonymous file, and writing the binary to it](#c4bceb8d0b2fed6978281df08032e4fd)
		4. [Preparing a fake `ARGV` and `ENVP` for `fexecve`](#b8f5f3f6245c02368be4b47dedeb0f12)
		5. [Calling the loaded executable](#3fd8fc54792153098b4b7c558025442b)
	5. [Testing with a C program that prints "hello world"](#c6dff7ea9b9f521dbeb6cbdc0c9a4507)
		1. [Hackerrank](#6642e4bb428f8cadd1b0873fc4013baf)
		2. [Codingame](#b63e2d7786dac4c313fa11a061fa29c6)
		3. [Codechef](#5dc25e8e747697d445a5d2110618850f)
	6. [Impact, and possible mitigations](#f8479c834875bd02e4e5b5da124ff5de)
3. [Conclusion](#6f8b794f3246b0c1e1780bb4d4d5dc53)

<script type="text/javascript"
    src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML">
</script>

# <span id='0b79795d3efc95b9976c7c5b933afce2'>Introduction</span>

Competitive programming was my entry point into computer science. I joined [Hackerrank](https://www.hackerrank.com/), [Codechef](https://www.codechef.com/), [Project Euler](https://projecteuler.net/) and more similar platforms around 2014, to practice and improve my skills, because I was having fun solving algorithmic problems, and because I was interested in mastering at least a few programming languages (for general scripting and low-level programming mainly).

## <span id='6477f0987fb5a53e6369d1917e269d7f'>About competitive programming</span>

For those who are not familiar with this mind-sport, it's about solving computer science problems with given constraints, for example, calculating the n-th Fibonacci number that is also prime, finding the shortest path in a graph, or finding all the ways to write a number as the sum of at least three positive numbers. Each problem has some constraints (Sizes of the inputs it gets). 
The user also gets some example inputs and outputs, and should write and submit a computer program that can read inputs in the given format, solve the problem and print the corresponding outputs.
The user's submission gets executed in the cloud, and its output gets compared with the precomputed correct output of "hidden" testcases. If it's the same, the submission is considered as correct.

## <span id='8fcb81cfdd7b25a2e8fe175f3c88cfec'>Why is it important?</span>

- Competitive programming is used as a basis for hiring by numerous companies: The first step of the hiring process is often a programming challenge to solve on a platform like [Hackerrank](https://www.hackerrank.com/) or [Codingame](https://www.codingame.com/).
- Contests: There are a lot of them ([ACM ICPC](https://icpc.global/), [Google CodeJam](https://codingcompetitions.withgoogle.com/codejam), [Meta HackerCup](https://www.facebook.com/codingcompetitions/hacker-cup) ...), just like CTFs.

## <span id='c49d19689605f60652d71577f5e93b59'>Types of failed submissions</span>

There are different kinds of failed submissions:

- `Wrong answer`: When the output of the program is different than the expected output of the testcase.
- `Time-Limit exceeded`: When the program takes too much time to execute, execution is stopped, and this error is returned.
- `Compilation Error`: When the program doesn't compile, or contains syntax errors.
- `Runtime Error`: When the program crashes (unhandled exception, segmentation fault, or any other type of errors).

## <span id='877ffcb70d0e01f13693cf0d93797a15'>Let's focus on time limits, what?</span>

The `TLE`, or Time-Limit Exceeded error happens when a submission takes more than the maximum duration allocated for it. People running these platforms have figured out that comparing the execution time of programs written in different programming languages is unfair (and would give a clear advantage to C/C++ programmers for instance). For this reason, they defined a multiplier that is specific to each programming language. On Hackerrank for example, Ruby or Python submissions get an execution time that is 5 times higher than C or C++ submissions (this aims to compensate the runtime overhead).

Below are some numbers taken from the different (and most popular) competitive programming platforms at the time of writing (For platforms that can host "work" interviews, these are the configurations of the environment where candidate submissions will be executed).

### <span id='6642e4bb428f8cadd1b0873fc4013baf'>Hackerrank</span>

| Programming language | Description             | Time (secs) | Memory (MB) |
| -------------------- | ----------------------- | ----------- | ----------- |
| C                    | GCC 8.3.0, C11 standard | 2           | 512         |
| C#                   | .NET 6.0.2, C# 10.0     | 3           | 512         |
| C++                  | G++ 8.3.0               | 2           | 512         |
| Coffeescript         | Node.js v14.15.4        | 10          | 1024        |
| Common Lisp          | SBCL 1.4.2              | 12          | 512         |
| Erlang               | Erlang/OTP 21           | 12          | 1024        |
| Go                   | 1.13                    | 4           | 1024        |
| Haskell              | ghc 8.6.5, lts-14.7     | 5           | 512         |
| Java 15              | OpenJDK 15.0.2          | 4           | 512         |
| Lua                  | 5.3.3                   | 12          | 512         |
| OCaml                | ocamlopt 4.09           | 3           | 512         |
| Perl                 | Perl (v5.26.3)          | 9           | 512         |
| PHP                  | PHP 7.3.13              | 9           | 512         |
| PyPy 3               | PyPy3.6 v6.0.0          | 4           | 512         |
| Python 3             | Python 3.9.4            | 10          | 1024        |
| Ruby                 | Ruby 2.6.4p104          | 10          | 512         |

The full table can be found [here](https://support.hackerrank.com/hc/en-us/articles/1500002392722--Execution-Environment-and-Samples).

### <span id='667319ac566eaac797fdca146988803d'>CodinGame for Work</span>

| Programming language | Description             | Time (secs) | Memory (MB) |
| -------------------- | ----------------------- | ----------- | ----------- |
| C                    | gcc 10.2.1              | 2           | 768         |
| C#                   | C# 8.0, .NET Core 3.1.3 | 1           | 768         |
| C++                  | g++ 10.2.1              | 2           | 768         |
| Go                   | 1.17.1                  | 2           | 768         |
| Haskell              | Haskell Platform 8.4.3  | 2           | 768         |
| Java                 | JDK 1.8.0 OpenJDK 11.0.2| 2           | 768         |
| Lua                  | 5.4.3                   | 6           | 768         | 
| OCaml                | 4.12.0                  | 6           | 768         |
| Perl                 | 5.32.1                  | 6           | 768         |
| PHP                  | PHP 7.3.9               | 2           | 768         |
| Python 3             | Python 3.9.2            | 5           | 768         |
| Ruby                 | Ruby 3.0.1              | 6           | 768         |

The full table can be found [here](https://help.codingame.com/article/273-what-environment-does-my-test-run-in).

### <span id='5dc25e8e747697d445a5d2110618850f'>Codechef</span>

| Programming language   | Time Multiplier  |
| ---------------------- | ---------------- |
| C, C++, Go, OCaml, ... | 1                |
| Java, PyPy3, C#, Scala | 2                |
| Ruby, PHP, Lisp, Scheme| 3                |
| Python                 | 5                |

The updated table can be found [here](https://blog.codechef.com/2009/04/01/announcing-time-limits-based-on-programming-language/).

# <span id='f9e976a90ad6e9dbab943c1e08234c3d'>My Idea</span>

Looking back into this common practice of having different time limits for different programming languages, I got an idea: what if I could somehow execute faster code from a slower programming language, and get an extended time limit?
While the constraints are often picked in a way that makes naive or unoptimized solutions time out, this could for example allow candidates to submit a sub-optimal solution in `C`, `C++` or `Go` (embedded in a stub written in a slower programming language), and avoid the time-limit exceeded error (because the platform would pick the time limit of the slower programming language).

## <span id='551e06d6aba9bf326dd4db6f034fb0ff'>Choice for the slower programming language (for the stub)</span>

We can choose any programming language that is considered as slow compared to `C`, and that has a builtin library that allows low-level memory hacking (calling native functions, manipulating pointers for example).

Possible choices are:

- Python with [ctypes](https://docs.python.org/3/library/ctypes.html).
- Ruby with [fiddle](https://ruby-doc.org/stdlib/libdoc/fiddle/rdoc/Fiddle.html).
- Probably more.

## <span id='c331a5c9792d72a6b203c4ce3670fa9b'>Initial enumeration on the different platforms</span>

Let's first check the operating systems, kernel and libc versions on the different platforms.

We run these lines of code in `Lua` to gather informations about the execution environments.

```lua
local commands = { 'uname -a', 'id', 'ls -l /lib/x86_64-linux-gnu/libc.so.6' };

os.execute( table.concat(commands, ' ; ') );
```

### <span id='6642e4bb428f8cadd1b0873fc4013baf'>Hackerrank</span>

![hackerrank_enum](https://res.cloudinary.com/dik00g2mh/image/upload/v1659101412/cracking_the_coding_interview_literally/zy0if5wqenvqckrzkwby.png)

### <span id='b63e2d7786dac4c313fa11a061fa29c6'>Codingame</span>

![codingame](https://res.cloudinary.com/dik00g2mh/image/upload/v1659101639/cracking_the_coding_interview_literally/ruui5x36ymj8ycdf5gda.png)

### <span id='5dc25e8e747697d445a5d2110618850f'>Codechef</span>

![codechef](https://res.cloudinary.com/dik00g2mh/image/upload/v1659101412/cracking_the_coding_interview_literally/akaon3ankqmtwscku8sx.png)

## <span id='746756a27857e5ce81151d21b3c84292'>Writing the stub</span>

For a proof of concept, we will be doing the following:

- From the slower programming language, create an anonymous file that lives in `tmpfs` with `memfd_create`.
- Decompress and decode the payload (`zlib` and `base64`), and write it to the anonymous file (using `write`).
- Execute the anonymous file from memory using `fexecve`.

More details about these functions will be given below.

We will avoid writing data on the disk, as different environments can have different configurations, and some might not allow writing data on the disk.

## <span id='52310a1a8adabc58b0df39e7774dbbc1'>Implementing the stub</span>

### <span id='0d6f0596a96b53b273088a5bc9335903'>Decompressing the native executable</span>

```ruby
require 'fiddle'
require 'zlib'
require 'base64'

exe = <<DEFLATED
eJztW31wG8UV35PlL0gkBZLgOF8mdaYOwYoFTrBJApYtOyd6DiaxA4WYi2yd
YzGy5Eon4lCgpiaBQ1FIGYYyHZiGGZjS4SvTmTIlpcHGTghQOomHMoEQ6qGh
yASCCUlwSJzr27tdxW4jFdpYmOnoeaR377fvvX23u7fe1e37Rb3QYOE4RCkH
...
RV0TjH1qv0QmrqbvsM1jzPZ0nd5UYY6Ttac0hdMxak3XsRuIfQmjzjqbRupn
kN7Ufh6Dc2m4BV1IvcRMnAy4uUjIjYedPwpRht9MepbquCPGOTvgTstgv65K
B86MAWvWb7A6tNYT
DEFLATED

exe = Zlib.inflate(Base64.decode64(exe))
```

### <span id='9e9c3afd84a2af46ae2565cb302fc78e'>Getting pointers to `memfd_create`, `write` and `fexecve`</span>

```ruby
libc = Fiddle.dlopen('/lib/x86_64-linux-gnu/libc.so.6');

# int memfd_create(const char *name, unsigned int flags)
memfd_create = Fiddle::Function.new(
    libc['memfd_create'],
    [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],
    Fiddle::TYPE_INT
)

# ssize_t write(int fd, const void *buf, size_t count);
write = Fiddle::Function.new(
    libc['write'],
    [Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T],
    Fiddle::TYPE_SSIZE_T
);

# int fexecve(int fd, char *const argv[], char *const envp[]);
fexecve = Fiddle::Function.new(
    libc['fexecve'],
    [Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
    Fiddle::TYPE_INT
);
```

### <span id='c4bceb8d0b2fed6978281df08032e4fd'>Creating the anonymous file, and writing the binary to it</span>

From the manual page of `memfd_create` (It's a system call in Linux).

![memfd_create_man](https://res.cloudinary.com/dik00g2mh/image/upload/v1659218805/cracking_the_coding_interview_literally/hcafdgp5mft8s9jsy5yg.png)

It's exactly the function we need to create a pseudo-file that doesn't get written to the disk.

```ruby
fd = memfd_create.call('exec', 0)

written = write.call(fd, exe, exe.length)
```

`write` is the syscall that writes data to a file.

### <span id='b8f5f3f6245c02368be4b47dedeb0f12'>Preparing a fake `ARGV` and `ENVP` for `fexecve`</span>

```ruby
# set argv[0] = "exec"
argv0 = Fiddle::Pointer.malloc(5)

argv0[0, 5] = 'exec' + 0.chr;

# set argv = { "exec", NULL }
argv = Fiddle::Pointer.malloc(2*Fiddle::SIZEOF_VOIDP)
argv[0,8] = [argv0.to_i].pack('Q')
argv[8,8] = 0.chr * 8

# set envp = { NULL }
envp = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
envp[0, 8] = 0.chr * 8
```

### <span id='3fd8fc54792153098b4b7c558025442b'>Calling the loaded executable</span>

`fexecve` Executes a program from a file descriptor. It works like the `execve` syscall, but instead of taking a file path, it takes the file descriptor of an open file.

![fexecve_man](https://res.cloudinary.com/dik00g2mh/image/upload/v1659219066/cracking_the_coding_interview_literally/gstcmnkw6vbvgmlhgmhs.png)

```ruby
ret = fexecve.call(fd, argv, envp)
```

## <span id='c6dff7ea9b9f521dbeb6cbdc0c9a4507'>Testing with a C program that prints "hello world"</span>

The program below runs the following C code:

```c
#include <stdio.h>

int main()
{
	puts("Hello world from C ^^");
}
```

We compress and encode it with the following lines of Ruby.

```ruby
require 'zlib'
require 'base64'

exe = File.open('exe', 'rb', &:read)
compressed = Zlib.deflate(exe)
encoded = Base64.encode64(compressed)
```

The Ruby stub with the compressed ELF embedded inside is around 100 lines of code. We will test it on the different platforms.

```ruby
require 'fiddle'
require 'zlib'
require 'base64'
exe = <<DEFLATED
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
8E35O/jv7LG4jXPg/f8DwekbgQ==
DEFLATED

exe = Zlib.inflate(Base64.decode64(exe))

libc = Fiddle.dlopen('/lib/x86_64-linux-gnu/libc.so.6');

# int memfd_create(const char *name, unsigned int flags)
memfd_create = Fiddle::Function.new(
    libc['memfd_create'],
    [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],
    Fiddle::TYPE_INT
)

# ssize_t write(int fd, const void *buf, size_t count);
write = Fiddle::Function.new(
    libc['write'],
    [Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T],
    Fiddle::TYPE_SSIZE_T
);

# int fexecve(int fd, char *const argv[], char *const envp[]);
fexecve = Fiddle::Function.new(
    libc['fexecve'],
    [Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
    Fiddle::TYPE_INT
);

fd = memfd_create.call('exec', 0)

written = write.call(fd, exe, exe.length)

argv0 = Fiddle::Pointer.malloc(5)

argv0[0, 5] = 'exec' + 0.chr

argv = Fiddle::Pointer.malloc(2*Fiddle::SIZEOF_VOIDP)
argv[0,8] = [argv0.to_i].pack('Q')
argv[8,8] = 0.chr * 8

envp = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP)
envp[0, 8] = 0.chr * 8

ret = fexecve.call(fd, argv, envp)
```

### <span id='6642e4bb428f8cadd1b0873fc4013baf'>Hackerrank</span>

![hackerrank_result](https://res.cloudinary.com/dik00g2mh/image/upload/v1659101413/cracking_the_coding_interview_literally/zakum1pvetkmrgwwwnkv.png)

### <span id='b63e2d7786dac4c313fa11a061fa29c6'>Codingame</span>

![codingame_result](https://res.cloudinary.com/dik00g2mh/image/upload/v1659101413/cracking_the_coding_interview_literally/creljybozifmj2jnkgp5.png)

### <span id='5dc25e8e747697d445a5d2110618850f'>Codechef</span>

![codechef_result](https://res.cloudinary.com/dik00g2mh/image/upload/v1659101412/cracking_the_coding_interview_literally/mc61efflhpihew4tjkbk.png)

It didn't work in codechef right away. It looks like libc support for `memfd_create` is not available. We can still get to call it manually:

```ruby
# void *mmap(void *addr, size_t length, int prot, int flags,
#            int fd, off_t offset);
mmap = Fiddle::Function.new(
    libc['mmap'],
    [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T, Fiddle::TYPE_INT, Fiddle::TYPE_INT,
    Fiddle::TYPE_INT, Fiddle::TYPE_INT],
    Fiddle::TYPE_VOIDP
)

# 7 = PROT_READ | PROT_WRITE | PROT_EXEC
# 0x22 = MAP_ANONYMOUS | MAP_PRIVATE
mem = mmap.call(0, 0x1000, 7, 0x22, -1, 0);

# write the shellcode:
# mov eax, 0x13f
# syscall
shellcode = %w[b8 3f 01 00 00 0f 05 c3].map{|byte| byte.to_i(16).chr }.join

mem[0, shellcode.length] = shellcode;

memfd_create = Fiddle::Function.new(
    mem,
    [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],
    Fiddle::TYPE_INT
)
```

![codechef_result2](https://res.cloudinary.com/dik00g2mh/image/upload/v1659101412/cracking_the_coding_interview_literally/dhto4vgms4ykyipjjy9v.png)


## <span id='f8479c834875bd02e4e5b5da124ff5de'>Impact, and possible mitigations</span>

The impact of this isn't huge, because:

- Solutions that have a different time complexity are likely to take more than 5 times the duration of execution of the better ones (depending on the size of the inputs, and the time complexity), if the naive approach is an \\(O(2^n)\\) algorithm, and the optimized one \\(O(n^2)\\), the former could take thousands of times the duration of execution of the latter.
- If the code of the candidate gets reviewed, the deceit will be blatant (It's not always the case, on contests and some automated hiring processes, candidates might be able to run away with it).

However, it can give a substantial advantage over the other contenders. More memory available, and a higher time-limit for a solution written in a low-level programming language like `C` or `C++`.

Below are some possible mitigations that would solve this issue:

- A seccomp whitelist (why would a candidate call `memfd_create`, or `execve` ?!).
- Modified programming language runtimes to prevent unsafe operations (no `ctypes` module for python for example).

# <span id='6f8b794f3246b0c1e1780bb4d4d5dc53'>Conclusion</span>

This post did not demonstrate a vulnerability, but rather a logic flaw in the execution environments of the most popular competitive programming platforms. This post is intended for educational purpose only. You should not use the approach described in this article at your advantage, and I am not responsible of any misuse or damage related to that.

I hope you've enjoyed reading this article. Don't hesitate to follow me on [Twitter](https://twitter.com/red0xff) and [Github](https://github.com/red0xff), or to ask me any kind of questions.
