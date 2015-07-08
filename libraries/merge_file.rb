#
# Cookbook Name:: master_install
# Library:: merge_file
#
# Copyright 2013, Scholastic
#
# All rights reserved - Do Not Redistribute
#

class Schl_ETL
	def self.mergefile(filename1, filename2)
		File.open(filename1, 'a+') do |file1|
			File.open(filename2, 'r') do |file2|
				File.foreach(filename2) do |line_in_file2|
					file1.rewind
					if file1.read.include? line_in_file2
					else
						file1.puts line_in_file2
					end
				end
			end
		end
	end
end
