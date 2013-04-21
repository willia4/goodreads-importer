#!/usr/bin/ruby

# This program is licensed under the MIT license.

# Copyright (c) <2013> <James Williams>

# Permission is hereby granted, free of charge, to any person obtaining a copy 
# of this software and associated documentation files (the "Software"), to deal in 
# the Software without restriction, including without limitation the rights to 
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of 
# the Software, and to permit persons to whom the Software is furnished to do so, 
# subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all 
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
# SOFTWARE.

require 'GoodreadsImporter.rb'
require 'trollop.rb'
require 'api_keys.rb'

###############
# NOTE: This script requires a file called 'api_keys.rb' to be available (probably just in this same directory).
# This file should define a single global variable called API_KEY which is a string version of your good reads API key.
# This file is not included in this public repository for obvious reasons. 
#
###############

# Default to my own user id because why not?
USER_ID = '369276'

opts = Trollop::options do
	version "Goodreads Review Importer 0.1.0 - Copyright 2013 James Williams <james@jameswilliams.me>"
	banner <<-EOS
Goodreads Review Importer fetches a users reviews from Goodreads and converts 
them to a somewhat more markdown friendly format. 

This program is licensed under the MIT license.

Copyright (c) <2013> <James Williams>
	EOS

	opt :fetch, "Number of books to fetch (a number or ALL)", :default => "5", :type => :string
	opt :output, "Output directory", :default => "./", :type => :string, :short => "o"
	opt :overwrite, "Overwrite existing output files", :short => "w"
	opt :user, "Goodreads user id", :short => "u", :type => :string, :default => USER_ID
end

def isInteger(s)
	return (s =~ /^[0-9]+$/)
end

importer = GoodreadsImporter.new(API_KEY)

fetchCount = 5
if opts[:fetch].upcase == "ALL" then 
	fetchCount = 0
else
	if !isInteger(opts[:fetch]) then
		abort("Option for --fetch must be a positive integer")
	end

	fetchCount = Integer(opts[:fetch])
end

outputDirectory = File.expand_path(opts[:output])
if !File.directory?(outputDirectory) then
	abort("Output Directory #{outputDirectory} does not exist or is not a directory")
end

books = importer.listBooks(opt[:user], fetchCount)

if books.count <= 0 then
	abort("Unable to find any reviews from Goodreads\n")
end

print "\n\n"
print "################################"
print "\n\n"
books.each_with_index do |book, index|
	print "#{index + 1}: #{book.title} (#{book.review.date})\n"
end

STDOUT.flush()
print "\n\nSelect Review To Import (or ALL) [1]: "
selected_review = gets.chomp

if selected_review.to_s.empty? then 
	selected_review = "1"
end

booksToImport = []

if selected_review.upcase == "ALL" then 
	booksToImport = books
else
	if !isInteger(selected_review) then
		abort("Unable to parse selection as integer")
	end

	selected_review = Integer(selected_review) - 1
	if !(selected_review >= 0 && selected_review < books.count) then
		abort("Selection was not a valid choice")
	end

	booksToImport << books[selected_review]
end 

booksToImport.each do |b|
	importer.importReview(b, outputDirectory, opts[:overwrite])
	# print b.coverImageData
	# print "\n"
end