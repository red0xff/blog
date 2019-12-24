---
title: "Himayatic 2017 - Rev400 Writeup"
author: "Redouane"
date: "2017-11-05T00:00:00+02:00"
description: "An obfuscated .NET crackme that hides code dynamically using RunPE and other techniques"
tags: ["reversing", "security", "reverse engineering", "assembly", "windows", "writeup"]
---
Hello, today I'll crack a .NET crackme, it was featured on Himayatic CTF, November 2nd 2017.
Download link : https://drive.google.com/open?id=0B7U3AsTA9UVfRHdTY2hfQzZrQm8

Let's start :)
First, we notice that it's a .NET crackme, it asks for a serial, and displays ``"Wrong Serial ... !!!"`` when we enter a random one.

[![Wrong Serial](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109597/himayatic17_rev400/wrong_serial_amajtp.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109597/himayatic17_rev400/wrong_serial_amajtp.png)

We open it in a .NET decompiler (I used ``dnSpy``, which is a fork of ``ILSpy``), and we immediately locate this function :
 
[![Obfuscated](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109597/himayatic17_rev400/obfuscated_ir2vqf.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109597/himayatic17_rev400/obfuscated_ir2vqf.png)

The code looks obfuscated, we follow the ``N`` and ``M`` functions in the namespace ``A``, and we find this:

[![CryptoObfuscator](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109592/himayatic17_rev400/cryptoobfuscator_dckoxz.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109592/himayatic17_rev400/cryptoobfuscator_dckoxz.png)

Looks like they used ``CryptoObfuscator`` to obfuscate the code, we'll use the popular .NET deobfuscator [de4dot](https://github.com/0xd4d/de4dot) to clean the executable.

[![de4dot](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109580/himayatic17_rev400/de4dot_m4uxpr.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109580/himayatic17_rev400/de4dot_m4uxpr.png)

We open the cleaned executable in ``dnSpy``, the obfuscation is gone!

[![deobfuscated](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109589/himayatic17_rev400/deobfuscated_bqpjzj.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109589/himayatic17_rev400/deobfuscated_bqpjzj.png)

But it's a wrong flag, if it were the real flag, the else part would display ``"Wrong Serial ... !!!"`` and not ``"Illusion ... !!"`` (of course, we still try it, who knows :p).
We don't find anything interesting in the ``Form`` class, so we try debugging in ``x64dbg``, we notice that when we open the program with ``x64dbg``, it spawns itself in a new process and then exits from the main process, we breakpoint on ``CreateProcessA`` and ``CreateProcessW``, just to ensure that we are correct, and yes, we hit the breakpoint on ``CreateProcessW``, I did not notice the ``CREATE_SUSPENDED`` state in ``dwCreationFlags``, I immediately went back to the decompiler, to find out where it spawns the new process, and what it does exactly.

[![CreateProcessW](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109599/himayatic17_rev400/createprocessw_tbtofd.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109599/himayatic17_rev400/createprocessw_tbtofd.png)

We suspect that it uses the ``RunPE`` technique, which in short works like this:
- It spawns itself as a new process in suspended state
- It locates the base address of the new exe.
- It uses ``WriteProcessMemory`` or a similar API to write every section to the new exe
- It sets the context of the main thread of the new process
- It resumes the new process

We go back to ``dnSpy``, and we find out that we were correct, the code is in the ``Skins`` class.

[![RunPE](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109615/himayatic17_rev400/runpe_fzwxiw.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109615/himayatic17_rev400/runpe_fzwxiw.png)

Now, to analyze the code in the new process, we have two possiblities:
- dump it while it's running
- hook the API that writes to the new process, and intercept the data written

Let's follow the first option, I used [pd (process dump)](http://split-code.com/processdump.html) to dump the process and all its DLLs while it was running, this way I got the final exe.

[![process dump](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109608/himayatic17_rev400/procdump_nonkkb.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109608/himayatic17_rev400/procdump_nonkkb.png)

The new exe looks a lot like the original one.

[![more fake flags](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109609/himayatic17_rev400/more_fake_flags_iookp8.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109609/himayatic17_rev400/more_fake_flags_iookp8.png)

More fake flags :p.

after more investigation, we find this function :

[![load dll](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109595/himayatic17_rev400/loaddll_wew2xr.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109595/himayatic17_rev400/loaddll_wew2xr.png)

It Loads another Base64-encoded assembly, we look for ``T1.Text`` to ``T4.Text``, they are initialized in the ``InitializeComponent`` method in ``FZero`` class, all this way:
``this.T1.Text = componentResourceManager.GetString("T1.Text");``
We find the strings in the resources

[![base64](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109591/himayatic17_rev400/base64_zqczfy.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109591/himayatic17_rev400/base64_zqczfy.png)

We concatenate them, decode as ``base64``, and save output as a file, it's a DLL.

[![decode dll](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109588/himayatic17_rev400/decode_dll_zwyb0c.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109588/himayatic17_rev400/decode_dll_zwyb0c.png)

We load it in ``dnSpy``, and this time, we find the real check :

[![real code](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109615/himayatic17_rev400/real_code_acrdxu.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109615/himayatic17_rev400/real_code_acrdxu.png)
 
the method ``V`` calls the method ``E`` to encrypt the user input, then it calls the method ``VR`` to check if it's correct, ``VR`` compares a fixed, twice-``base64``-encoded string (stored encoded once in ressources) with the encrypted and twice-encoded user input, then it calls ``DS`` if the check succeeds, we find ``"Wrong Serial ... !!|Yeah,, you did it :)'"`` in the resources.

the method ``E`` (which encrypts) looks like this:

[![encryption](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109595/himayatic17_rev400/encrypt_e1pwlo.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109595/himayatic17_rev400/encrypt_e1pwlo.png)

It concatenates the second argument with ``"Himayatic_0xC001"``, then hashes the result using ``md5``, then it initializes a buffer of ``32`` characters, then it copies the ``md5`` hash to a buffer starting at index ``0`` (copies ``16`` characters), then copies the same ``md5`` hash to the same buffer starting at index ``15`` (copies ``16`` characters), so it overwrites the last character of the first copy, then it uses the buffer as the key to encrypt the first function parameter, it encrypts it using ``AES`` in ``ECB`` mode, then encodes it using ``base64``.

We go back to where the assembly is loaded and used, we look for references to the function ``GetSkin``, which returns an instance of ``CTFs__.Himayatic``

We find it in ``FZero_Load`` : ``this.o = RuntimeHelpers.GetObjectValue(this.Himayatic.getSkin());``
We look for references to ``this.o``, and we find this :

[![real check](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109608/himayatic17_rev400/real_check_d7vsvn.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109608/himayatic17_rev400/real_check_d7vsvn.png)

It's pretty straightforward to understand this code, it's calling the method ``V``, something like this : ``V( this.FL__.Text, this.Name, true)``

``this.FL__.Text`` is the user input, ``this.Name`` can be found in ``FZero`` class ( ``this.Name = "FZero";`` ).

After that, it's pretty simple to get the flag, just a simple Ruby script:

```ruby
require'base64';
require'openssl';
require'digest';
begin
	enc = Base64.decode64 "FQUFl/85WMFJp5XXfJX5Xykt8WhTPcy1MD0/0+SqEsj/IdMrolb3Haaq9yiZvcuH";
	e = OpenSSL::Cipher::AES.new(256,:ECB)
	e.decrypt; # initialize it for decryption
	md5 = Digest::MD5.digest("FZero" + "Himayatic_0xC001");
	key = "\x00" * 32;
	key[0,16] = md5;
	key[15, 16] = md5;
	e.key = key;	
	puts (e.update(enc)+e.final); # should output the flag
rescue Exception => e
	# show the exception
    p e;
    p e.message;
    p e.backtrace
ensure
	# wait before exiting
    gets
end
```

[![congrats](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109587/himayatic17_rev400/we_did_it_ahceyx.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1558109587/himayatic17_rev400/we_did_it_ahceyx.png)

``Himayatic{*1LLu510N__W17h0u7_C4rD5*}``
Really nice challenge.

