#!/usr/bin/ruby

class Array
  def sample n
      self.dup.sort_by{rand}[0, n] 
  end
end

words = ["test" ]

File.open("labels2.txt") do |file|
	while line = file.gets
		line.chomp!
		words << line
	end
end

sample_words = words.to_a.sample(5000)

for word in sample_words do
	puts word
end
