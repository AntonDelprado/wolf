class String
	def titleise
		return self.downcase.gsub(/(\s|^)\w/) { |str| str.upcase }.gsub(/\s((Of)|(A)|(The)|(And)|(But))\s/) { |str| str.downcase }
	end
end

