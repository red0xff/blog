---
title: "GSoC 2020 - Enhancing metasploit support for 'the Hack That Will Never Go Away'"
date: 2020-08-29T16:45:58+02:00
author: "NIBOUCHA Redouane"
description: "an overview of the work I accomplished during Google Summer of Code 2020"
cover: "https://res.cloudinary.com/dik00g2mh/image/upload/v1598731680/gsoc_2020/wozysdpe5qy4gst0tpx9.png"
tags: ["sql injection", "security", "web security", "opensource", "programming"]
---
# Table of Contents
1. [Introduction](#0b79795d3efc95b9976c7c5b933afce2)
2. [My Proposal](#67ed87f44709a5e274e570dc0174bb38)
3. [Community-Bonding period](#7aef9d0c5402a915a1f7711fd90218ed)
4. [Results of my contribution](#fed02dc7f03d495d89a1783a42fa77d3)
5. [My Google Summer of Code journey](#981725cf5d343830f3590df23fbbf285)
	1. [Initial work](#04d84c9eded9f4fdc34c7148a3a77686)
	2. [SQLite support and specs for the library](#d3af9b314b9b5c1de3c386ce802233eb)
	3. [Support for `PostgreSQL`, and other database-management systems](#58adb7987ef3ebb0891820242143bb4d)
6. [Conclusion](#6f8b794f3246b0c1e1780bb4d4d5dc53)

# <span id='0b79795d3efc95b9976c7c5b933afce2'>Introduction</span>

Being interested in computer security, and being an opensource lover, I wanted to
participate in Google Summer of Code this year, after checking out the list of organizations,
I applied for Metasploit, because `Ruby` is my main programming language, and because I
was very interested in contributing to a framework of this popularity.


# <span id='67ed87f44709a5e274e570dc0174bb38'>My Proposal</span>

You can find my proposal [here](https://drive.google.com/file/d/1luwf1cph0Mtnn-IuasecYLw0aT_apvSE/view?usp=sharing).

Google Summer of Code project description [here](https://summerofcode.withgoogle.com/projects/#6297726754488320).

The idea I worked on was enhancing SQL injection support on the Metasploit Framework, SQL injections
are vulnerabilities that have been around for a very long time, they are due to the lack of input
sanitization, and can allow attackers to get access to sensitive data, some metasploit modules already
implement SQL injection attacks, the problem for module writers is that many types of SQL injections
require effort implementing, take for example time-based SQL injections, the module writer has to do
some kind of binary search to leak bytes of data, or for example, cases where the results of the query
are truncated of a given length, the module writer has to leak substrings, and concatenate them.

The aim of my project was to add a library that takes care of all these issues, making module writing
easier in the case of SQL injections, I wanted the library to:

- Support not only HTTP, allow the user to handle connection with the server.
- Have module writers run SQL directly, whether the SQL injection is blind or not.
- Have methods for enumerating table names, column names, whatever is useful and commonly done when doing SQL injection.

# <span id='7aef9d0c5402a915a1f7711fd90218ed'>Community-Bonding period</span>

On May 4th, I got the announcement of being accepted to take part on the program,
during the month of May, I did my best to get familiar with the codebase, I tried fixing
issues, understanding the structure of the libraries that had a similar usage to what I
was willing to develop.

Some issues I fixed in the Community-Bonding period:

- [Fix winrm_login module](https://github.com/rapid7/metasploit-framework/pull/13442)
- [Fix following redirects from send_request_cgi!](https://github.com/rapid7/metasploit-framework/pull/13448)

a module I also contributed during that period:

- [Add the LFI module for QNAP RCE (CVE 2019-7192 - CVE 2019-7195)](https://github.com/rapid7/metasploit-framework/pull/13534)

Thanks to [h00die](https://keybase.io/h00die) for helping out on this module.


# <span id='fed02dc7f03d495d89a1783a42fa77d3'>Results of my contribution</span>

After working three months on implementing the project on my proposal, here are the Pull-Requests I sent during the GSoC period:
1. Merged
- [Support for MySQL/MariaDB injection, and rewrite of some module](https://github.com/rapid7/metasploit-framework/pull/13596)
- [Specs/Unit tests for the library](https://github.com/rapid7/metasploit-framework/pull/13913)
- [Support for SQLite injection, and module for a peplink balance vulnerability (CVE-2017-8835)](https://github.com/rapid7/metasploit-framework/pull/13847)
- Also was able to discover and fix [a bug on cookie parsing](https://github.com/rapid7/metasploit-framework/pull/13900), while testing my library
2. Not merged yet:
- [Support for PostgreSQL, and module for CVE-2019-13375](https://github.com/rapid7/metasploit-framework/pull/14067)
3. PR not sent yet
- [Support for Microsoft SQL Server](https://github.com/red0xff/metasploit-framework/tree/GSOC/MSSQLi_Support)
- [Support for Oracle Database](https://github.com/red0xff/metasploit-framework/tree/GSOC/Oracle-DB-SQLi-Support)
4. To-do work
- Specs for the other implementations, should be using the shared examples, because of the similar structure between DBMS-specific classes.
- Perhaps modules exploiting Oracle Database/MSSQL injection vulnerabilities, and using the library (only testing modules have been provided).

Summary of the work done:

| DBMS                 | Regular SQLi          | Time Blind               | Boolean blind | Reading files        | Writing to files               |
|:--------------------:|:---------------------:|:------------------------:|:-------------:|:--------------------:|:------------------------------:|
| MySQL/MariaDB        | Yes                   | Yes                      | Yes           | Yes (`load_file`)    | Yes (select .. into dumpfile)  |
| SQLite               | Yes                   | Yes (heavy queries)      | Yes           | No                   | Yes (attach database ..)       |
| PostgreSQL           | Yes                   | Yes                      | Yes           | No                   | Yes (copy ... to ...)          |
| Microsoft SQL Server | Yes                   | Yes (stacked queries)    | Yes           | No                   | No                             |
| Oracle Database      | Yes, one row at a time| Yes (`dbms_pipe` package)| Yes           | No                   | No                             |

- Methods for enumerating databases, table names, column names, users also were provided for each DBMS.

# <span id='981725cf5d343830f3590df23fbbf285'>My Google Summer of Code journey</span>

## <span id='04d84c9eded9f4fdc34c7148a3a77686'>Initial work</span>

During the first month of the program, I started working on support for `MySQL/MariaDB`, the design of the library is really something I am proud of,
from the beginning, I decided to let users provide a block that would query the server (so that the library does not have to handle networking stuff),
and to make use of inheritance, so that SQL Injection objects behave the same, even if technically, their exploitation is done differently, take for example
regular SQL injections, running:

```ruby
# @sqli being a MySQLi::Common object
@sqli.run_sql('select group_concat(table_name) from information_schema.tables')
``` 

would yield the given SQL query to the block, but if the object was a `MySQLi::BooleanBasedBlind`, the same call would yield:

```
ascii(mid(cast((select group_concat(table_name) from information_schema.tables) as binary), 1, 1))&1<>0
ascii(mid(cast((select group_concat(table_name) from information_schema.tables) as binary), 1, 1))&2<>0
ascii(mid(cast((select group_concat(table_name) from information_schema.tables) as binary), 1, 1))&4<>0
...
ascii(mid(cast((select group_concat(table_name) from information_schema.tables) as binary), 1, 1))&128<>0

ascii(mid(cast((select group_concat(table_name) from information_schema.tables) as binary), 2, 1))&1<>0
...
```

Each of these is sent to the block to be evaluated as a condition, and leak one bit of information, recall that in boolean-based blind SQLi, we only know
whether the query returned a result or not, so we can only leak one bit with one query, and this is exactly what the library does.

Time-based blind support for `MySQL/MariaDB` was done in a similar manner, except that these conditions were wrapped inside `if(..., sleep(delay), 1)`, so that
a delay is produced if the condition is true, the library also takes care of checking if the target slept more than sleepdelay or not, and all of this is transparent
to the user.

The library had to be refactored multiple times, to support more options, to avoid having repetitive code and make unit-testing possible, also, for printing verbose messages that
could be useful to the user, it was necessary to access the module `datastore` (because printing methods had to access the `VERBOSE` option which is set by the user),
accessing it wasn't an easy task, because the whole library was a mixin (a module the user should include inside their metasploit module class), the mixin methods could access it,
but not the classes that belong to it, a factory pattern was necessary to get this working, basically, a `create_sqli` method that the user calls, that instanciates one of the classes
and injects the datastore through its constructor.

My list of features to add kept growing during this period, and I implemented many of them (support for truncated queries, hex encoding strings, encoders and so on).

Also, during the first month, I re-wrote some SQL injection modules to make them use my library, it reduced a lot of their complexity, and made them more efficient:

- [eyesofnetwork_autodiscovery_rce](https://github.com/rapid7/metasploit-framework/blob/master/modules/exploits/linux/http/eyesofnetwork_autodiscovery_rce.rb) : `527` LoC -> `460` LoC, running time divided by 2.
- [openemr_sqli_dump](https://github.com/rapid7/metasploit-framework/blob/master/modules/auxiliary/sqli/openemr/openemr_sqli_dump.rb) : `235` LoC -> `151` LoC, improved injection (now skips builtin tables and only retrieves userdata).

## <span id='d3af9b314b9b5c1de3c386ce802233eb'>SQLite support and specs for the library</span>

`SQLite` support was the second on my priority list, mostly because I always thought `SQLite` was different because of its minimalism, different in a way that could make it hard for module writers to implement SQL injection attacks
when it is in-use, the part that was a bit more complex was time-based blind SQL injection, because `SQLite` does not have a function like sleep, that causes a delay in the response, I had to use heavy queries, which are queries that
take time to be computed, luckily, there exists a function called `randomblob`, which takes a size parameter, and returns random data of that size, the user specifies a delay in seconds, and I do some benchmarking in the library to
find the perfect randomblob parameter that would cause that delay, once found, `1000000` for example, my SQL injection would work like this:

For example:

```ruby
# @sqli being a SQLitei::TimeBasedBlind object
@sqli.run_sql("select group_concat(tbl_name,';') from sqlite_master where type='table'")
```

The library would yield conditions like this to the block, to be evaluated, and would measure timings, and return the data.

```
unicode(substr(cast((select group_concat(tbl_name,';') from sqlite_master where type='table') as blob), 1, 1))&1<>0 and randomblob(1000000)
unicode(substr(cast((select group_concat(tbl_name,';') from sqlite_master where type='table') as blob), 1, 1))&2<>0 and randomblob(1000000)
unicode(substr(cast((select group_concat(tbl_name,';') from sqlite_master where type='table') as blob), 1, 1))&4<>0 and randomblob(1000000)
...
unicode(substr(cast((select group_concat(tbl_name,';') from sqlite_master where type='table') as blob), 1, 1))&128<>0 and randomblob(1000000)
unicode(substr(cast((select group_concat(tbl_name,';') from sqlite_master where type='table') as blob), 2, 1))&1<>0 and randomblob(1000000)
...
```

If a bit is 1, it should get to the second part of the `and`, which should take some time to run, this is how the library knows the outcome of the condition.

I also had to refactor code when adding support for `SQLite`, because I noticed there was a lot of code shared between DBMS-specific implementations, on blind queries mostly, so I added a `Utils` mixin that acts like an interface that
is implemented in all the classes that make use of the shared code.

For testing I wrote:

- [peplink_bauth_sqli](https://github.com/rapid7/metasploit-framework/blob/master/modules/auxiliary/gather/peplink_bauth_sqli.rb) (writeup [here](https://gist.github.com/red0xff/c4511d2f427efcb8b018534704e9607a))
- [testing module](https://github.com/rapid7/metasploit-framework/blob/master/test/modules/auxiliary/test/sqlite_lab.rb) for [sqlite-lab](https://github.com/incredibleindishell/sqlite-lab)

## <span id='58adb7987ef3ebb0891820242143bb4d'>Support for `PostgreSQL`, and other database-management systems</span>

`PostgreSQL` support was easy to add, because of how popular the DBMS is, it was easy to find vulnerable software to test it, to get it running in a testing environment and so on, I wrote a module for [CVE-2019-13373](https://www.cvedetails.com/cve/CVE-2019-13373/), which is a vulnerability
found on some versions of D-Link Central WiFi Manager CWM(100), and a test module for vulnerable code I wrote myself.

Support for `MSSQL` and `Oracle Database` was added in the last month of the program, I provided test modules for each, but no exploit on real vulnerabilities, might implement some in the future.

# <span id='6f8b794f3246b0c1e1780bb4d4d5dc53'>Conclusion</span>

Working with rapid7 members on the Metasploit Framework was really a great experience for me, I learned a lot of things, would like to thank my mentor, Jeffrey Martin (`Op3n4M3`), as well as other contributors who helped me out,
`h00die`, `zeroSteiner` and `dwelch-r7` to name a few.

I learned a lot, on advanced git topics, on software testing and programming/software engineering best practices.

I will keep contributing to the project, hopefully getting all of the library merged, and getting some other issues I had noticed in the codebase fixed.
