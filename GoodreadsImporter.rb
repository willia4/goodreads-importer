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

require 'rubygems'
require 'html2md'
require 'hpricot'
require 'net/http'
require 'rexml/document'
require 'cgi'
require 'date'
require 'base64'

BASE_URL = 'http://www.goodreads.com/'

class GoodreadsAPI
	def initialize(api_key)
		@api_key = api_key.to_s
		@last_api_call = Time.now
	end

	def httpCall(url)
		# Avoid spamming Goodreads by waiting some number of seconds between every API request
		# I don't think this is actually working. :( )
		secondsSinceAPICall = ((Time.now - @last_api_call) * 24 * 60 * 60).to_i
		secondsToWait = 7 - secondsSinceAPICall
		if secondsToWait > 0 then 
			sleep(secondsToWait) 
		end
		@last_api_call = Time.now

		Net::HTTP.get_response(URI.parse(url)).body
	end

	def apiCall(method, needsKey, parameters)
		url = BASE_URL + method

		if needsKey || parameters.length > 0 then 
			url = url + "?"
		end

		needsSep = false
		if needsKey then 
			url = url + "key=#{@api_key}"
			needsSep = true 
		end 

		parameters.each_pair do |key,value|
			if needsSep then 
				url = url + "&"
			end 

			url += "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
			needsSep = true 
		end

		return self.httpCall(url)
	end

	def logMessage(msg)
		print "<#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}>: #{msg}\n"
	end
end

class GoodreadsBook
	attr_accessor :id
	attr_accessor :title
	attr_accessor :author
	attr_accessor :author_url
	attr_accessor :goodreads_url
	attr_accessor :user_id
	attr_accessor :review

	def initialize(api, user_id, bookElement)
		@api = api

		self.id = bookElement.elements["id"].text
		self.title = bookElement.elements["title"].text
		self.author = "unknown"
		self.author_url = "http://goodreads.com"
		self.goodreads_url = bookElement.elements["link"].text
		self.user_id = user_id

		@api_image = bookElement.elements["image_url"].text
		@cached_cover_image = nil

		# Goodreads supports multiple authors but *boy* is that complicated. Just use the first one.
		authors = REXML::XPath.match(bookElement, "authors/author")
		if authors.count > 0 then 
			self.author = authors[0].elements["name"].text
			self.author_url = authors[0].elements["link"].cdatas[0].to_s
		end

		# The only way to know if the user has has a review for this book is to try to get it (unfortunately, the list API call doesn't tell us this)
		# Since we need to know if there's a review in order to know if we want to present this book to the user, we may as well load the review now
		self.loadReview
	end

	# Goodreads doesn't provide all of their covers via the API (and instead returns a "No Cover" image)
	# See http://www.goodreads.com/topic/show/817296-nocover-image
	# So, be a bit sneaky and screen-scrape the Goodreads page for the image instead
	def coverImage
		if @cached_cover_image then
			print "cached"
			return @cached_cover_image
		end if 

		@api.logMessage "Loading Cover Image For #{self.title}"

		html_data = @api.httpCall(self.goodreads_url)

		img = Hpricot(html_data).at("//img[@id='coverImage']")
		if !img then
			return @api_image
		end

		img = (img['src']).to_s

		m = img.match /(.*)\/books\/([0-9]+).\/([0-9]+)\.jpg/

		if(!m) then
			return img
		end

		@cached_cover_image = m.captures[0] + '/books/' + m.captures[1] + 'm/' + m.captures[2] + '.jpg'
		return @cached_cover_image
	end

	# Since our method of getting the cover image isn't supported, we can't trust the URLs to be around forever
	# So be even sneakier and turn the cover image into a data url
	def coverImageData
		c = self.coverImage
		if(!c)
			return nil
		end

		data = @api.httpCall(c)
		data = Base64.encode64(data).gsub(/\s+/, '').strip

		return "data:image/jpeg;base64,#{data}"
	end

	def loadReview
		return if self.review 
		self.review = nil

		@api.logMessage "Loading Review For #{self.title}"

		xml_data = @api.apiCall(
			'review/show_by_user_and_book.xml',
			true,
			{
				"user_id" => self.user_id,
				"book_id" => self.id,
				"include_review_on_work" => "true"
			})
		doc = REXML::Document.new(xml_data)
		
		REXML::XPath.match(doc, 'GoodreadsResponse/review').each do |ele|
			r = REXML::XPath.first(doc, "/GoodreadsResponse/review")
			r = GoodreadsReview.new(@api, self, r)

			if r && r.review_markdown then 
				self.review = r
			end 
		end
	end
end

class GoodreadsReview
	attr_accessor :review_html
	attr_accessor :review_markdown
	attr_accessor :review_url
	attr_accessor :rating
	attr_accessor :user_id
	attr_accessor :date
	attr_accessor :book

	def parseGoodreadsDate(dateString)
		#I'm not sure how to make strptime deal with the UTC offset. But we only care about the date, so match it. Unfortunately, 
		#The year is at the very end of the string because WHY?
		m = dateString.match /^(.*) \d\d:\d\d:\d\d [-+]\d+ (\d*)/
		return Date.strptime(m.captures[0].to_s + " " + m.captures[1], "%a %b %d %Y")
	end

	def tryToGetDates(reviewElement, nodesToTry)
		d = nil 
		nodesToTry.each do |n|
			s = reviewElement.elements[n].text
			if(s) then
				d = self.parseGoodreadsDate(s)
			end

			if(d) then
				break
			end
		end

		if(!d) then
			@api.logMessage "WARNING: Could not get review date for #{book.title}. Using today's date instead."
			d = Date.today
		end 

		return d
	end

	def initialize(api, book, reviewElement)
		@api = api

		self.book = book
		self.user_id = book.user_id

		self.review_html = reviewElement.elements["body"].cdatas[0].to_s
		self.review_url = reviewElement.elements["url"].cdatas[0].to_s

		self.rating = reviewElement.elements["rating"].text

		# Dates on reviews (read_at) are optional in Goodreads. So, try date_updated if it's missing
		self.date = tryToGetDates(reviewElement, ["read_at", "date_updated", "date_added"])
		
		self.review_markdown = Html2Md.new(self.review_html).parse
	end

	def review_flavoredmarkdown 
		# This is the final markdown that will be written. 
		# This could probably benefit from a templating system, huh? 

		return 	"Title: Review: #{self.book.title}  \n" + 
				"Date: #{self.date.strftime('%Y-%m-%d')}  \n" +
				"\n\n" +
				"[![#{self.book.title}][cover_image]][book_link]  \n" + 
				"*[#{self.book.title}][book_link]*  \nby [#{self.book.author}][author_link]  \n\n" + 
			 	"My rating: [#{self.rating} of 5 stars][review_link]  \n\n" + 
			 	self.review_markdown + 
			 	"\n\n" + 
			 	"[cover_image]: #{self.book.coverImageData} \n" + 
			 	"[book_link]: #{self.book.goodreads_url} \n" + 
			 	"[author_link]: #{self.book.author_url} \n" + 
			 	"[review_link]: #{self.review_url} \n" + 
			 	"\n\n\n\n\n\n" + 
			 	"<!-- Book ID: #{book.id} -->"
	end
end

class GoodreadsImporter
	def initialize(api_key)	
		@api = GoodreadsAPI.new(api_key)
	end

	def pageBooks(user_id, max)
		hasMore = true

		books = []
		currentPage = 1

		while ((books.count < max || max == 0) && hasMore) do
			@api.logMessage "Loading Page #{currentPage} Of Users Books"

			xml_data = @api.apiCall(
				'review/list.xml',
				true,
				{
					"id" => user_id,
					"sort" => "date_read",
					"order" => "d",
					"per_page" => [max, 200].max,
					"page" => currentPage,
 					"shelf" => "read"
				})

			doc = REXML::Document.new(xml_data)
			list = REXML::XPath.first(doc, "/GoodreadsResponse/books")
			
			pageCount = Integer(list.attributes["numpages"])
			hasMore = (pageCount > currentPage)
			currentPage = currentPage + 1

			REXML::XPath.match(doc, "/GoodreadsResponse/books/book").each do |ele|
				if (books.count < max || max == 0) then
					b = GoodreadsBook.new(@api, user_id, ele)

					if b.review then 
						books << b
					end
				end 
			end
		end

		return books 
	end

	def listBooks(user_id, max)
		return self.pageBooks user_id, max
	end

	def importReview(book, outputDirectory, overwrite)
		outputDirectory = Dir.pwd if !outputDirectory 

		if !File.directory?(outputDirectory) then
			@api.logMessage "ERROR Output directory does not exist (#{outputDirectory})"
			return
		end

		review = book.review
		
		if !review then
			@api.logMessage "ERROR Could not get review for #{book.title}"
			return 
		end

		fileName = CGI.escape("review-" + book.title.downcase.gsub(/\s+/, '-').gsub(/[^0-9a-z]/i, '-') + '.md')
		fileName = File.join(outputDirectory, fileName)

		# It's way cleaner to do this check in writeFile, but I'd like to ERROR out *before* we fetch the cover image (in review_flavoredmarkdown)
		if File::exists?(fileName) then
			if overwrite then 
				@api.logMessage "WARNING Overwriting existing file #{fileName}"
			else
				@api.logMessage "ERROR File #{fileName} already exists in the output directory. Nothing was written."
				return
			end 
		end

		writeFile fileName, review.review_flavoredmarkdown, overwrite
	end

	def writeFile(fileName, content, overwrite)
		File.open(fileName, 'w') {|file| file.write(content)}
		@api.logMessage("Wrote review to #{fileName}")
	end
end