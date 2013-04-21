Title: Goodreads Review Importer  
Author: James Williams <http://jameswilliams.me> <james@jameswilliams.me>  

# Introduction
[Goodreads][] is probably the premier social networking site devoted to books and reading. Among other things, Goodreads allows its users to review books as they read them it. It even supports syndicating those reviews to various blogging platforms. 

Unfortunately, when it exports reviews to blogs, it writes some rather nasty HTML. This HTML isn't terribly easy to convert into [Markdown][], so I decided to just go straight to the source. 

This script will look for all the reviews for a given user, convert a selected review to markdown, and stash it in a directory of your choosing. 

The primary use case is for converting your most recent review, but it can also support mass-converting all existing reviews. 

[Goodreads]: http://www.goodreads.com/
[Markdown]: http://daringfireball.net/projects/markdown/

# Options
This script supports the following command-line options: 

* `--fetch [NUM]` --> Indicates how many reviews to present to the user. Defaults to 5.
* `--output [DIRECTORY]` --> Indicates which directory will hold the exported markdown files. Defaults to the current directory.
* `--user [USERID]` --> The user id of the user you want to export reviews for. Defaults to my own user id. See below for details. 
* `--overwrite` --> Indicates that you want to overwrite existing markdown files in --output. Defaults to false.

## User ID
Goodreads assigns each user a unique numeric identifier: this id is used by the API to associate reviews and books to individual users. Your user id is available in the URL for your profile.

My profile is located at <http://www.goodreads.com/user/show/369276-james-williams> so I know that my user id is "369276".

# API Key
In order to use this script, you need an [API Key][] from Goodreads. When you have this key, create a file called "api_keys.rb" in the same directory as the other script files and add a global variable 

    API_KEY = 'SECRET KEY'

[API Key]: http://www.goodreads.com/api/keys

# Dependencies 
This script requires the [html2md][] and [hpricot][] gems to be installed and available:

`sudo gem install html2md`  
`sudo gem install hpricot`

[html2md]: https://github.com/pmorton/html2md
[hpricot]: https://github.com/hpricot/hpricot

# License
The files "GoodreadsImporter.rb" and "import_review.rb" are Copyright 2013 [James Williams][james] and are distributed under the [MIT License][mit]. 

The file "[trollop.rb][trollop]" is Copyright 2007 William Morgan and distributed under the terms of [Ruby's license][ruby license]. It is included here under condition 1 of that license: 

> 1. You may make and give away verbatim copies of the source form of the
>    software without restriction, provided that you duplicate all of the
>	 original copyright notices and associated disclaimers.

[james]: http://jameswilliams.me
[mit]: http://opensource.org/licenses/MIT
[trollop]: http://trollop.rubyforge.org/
[ruby license]: http://www.ruby-lang.org/en/about/license.txt

## MIT License

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
	and associated documentation files (the "Software"), to deal in the Software without 
	restriction, including without limitation the rights to use, copy, modify, merge, publish, 
	distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the 
	Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or 
	substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
	BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
	DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Ruby License

	Ruby is copyrighted free software by Yukihiro Matsumoto <matz@netlab.jp>.
	You can redistribute it and/or modify it under either the terms of the
	2-clause BSDL (see the file BSDL), or the conditions below:

	  1. You may make and give away verbatim copies of the source form of the
	     software without restriction, provided that you duplicate all of the
	     original copyright notices and associated disclaimers.

	  2. You may modify your copy of the software in any way, provided that
	     you do at least ONE of the following:

	       a) place your modifications in the Public Domain or otherwise
	          make them Freely Available, such as by posting said
		  modifications to Usenet or an equivalent medium, or by allowing
		  the author to include your modifications in the software.

	       b) use the modified software only within your corporation or
	          organization.

	       c) give non-standard binaries non-standard names, with
	          instructions on where to get the original software distribution.

	       d) make other distribution arrangements with the author.

	  3. You may distribute the software in object code or binary form,
	     provided that you do at least ONE of the following:

	       a) distribute the binaries and library files of the software,
		  together with instructions (in the manual page or equivalent)
		  on where to get the original distribution.

	       b) accompany the distribution with the machine-readable source of
		  the software.

	       c) give non-standard binaries non-standard names, with
	          instructions on where to get the original software distribution.

	       d) make other distribution arrangements with the author.

	  4. You may modify and include the part of the software into any other
	     software (possibly commercial).  But some files in the distribution
	     are not written by the author, so that they are not under these terms.

	     For the list of those files and their copying conditions, see the
	     file LEGAL.

	  5. The scripts and library files supplied as input to or produced as 
	     output from the software do not automatically fall under the
	     copyright of the software, but belong to whomever generated them, 
	     and may be sold commercially, and may be aggregated with this
	     software.

	  6. THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
	     IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
	     WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
	     PURPOSE.