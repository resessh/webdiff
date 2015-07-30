class FileList

	attr_accessor :file_list_arr
	def initialize( list_file_pass )
		@file_list_arr = []
		list_file = File.open( list_file_pass )
		list_file.each do |file_pass|
			@file_list_arr.push( file_pass.gsub( /(^\.\/)|\n/, "" ) )
		end
	end

	def checkFilesDiff
		@file_list_arr.each do |file_pass|
			fdiff = FileDiff.new( file_pass )
			fdiff.check
		end
	end
end

class FileDiff

	def initialize( file_pass )
		@file_pass = file_pass
		@is_image = self.isImage?
		@host1_data_string = ""
		@host2_data_string = ""
		@diff_string = ""
		@http_error = false
	end

	def check
		@diff_string = self.checkDiffByString
		self.output if @diff_string != ""
	end

	def isImage?
		image_file_type_list = [
			/\.jpg/, /\.JPG/,
			/\.jpeg/, /\.JPEG/,
			/\.png/, /\.PNG/,
			/\.gif/, /\.GIF/
		]
		image_file_type_list.each do |file_type|
			if file_type =~ @file_pass
				return true
			end
		end
		return false
	end

	def checkDiffByString
		def getFile( host_name, host_auth_requirement = nil )
			file_data = ""
			begin
				if host_auth_requirement
					open( host_name + @file_pass, {:http_basic_authentication => host_auth_requirement} ).each do |line|
						file_data << line.split( "\r" ).join
					end
				else
					open( host_name + @file_pass ).each do |line|
						file_data << line.split( "\r" ).join
					end
				end
			rescue Exception => e
				@http_error = true
				return ""
			end

			return file_data
		end

		@host1_data_string = getFile( HOST1, ( defined? HOST1AUTH ) ? HOST1AUTH : nil )
		@host2_data_string = getFile( HOST2, ( defined? HOST2AUTH ) ? HOST2AUTH : nil )

		if @http_error
			return "file not accessed."
		end

		if @is_image
			if @host1_data_string != @host2_data_string
				return "This image file has diff."
			end
		else
			diffs = Diff::LCS.sdiff( @host1_data_string.split( /\n/ ), @host2_data_string.split( /\n/ ) )
			diff_lines = ""
			diffs.each do |diff|
				if diff.old_element != diff.new_element
					diff_lines << "#{diff.old_position}: -#{diff.old_element}\n" if diff.old_element
					diff_lines << "#{diff.new_position}: +#{diff.new_element}\n" if diff.new_element
				end
			end
			return diff_lines
		end

		return ""
	end

	def output
		Output.new( @file_pass, @diff_string ).create
	end

end

class Output

	attr_accessor :diff_string
	def initialize( file_pass, diff_string )
		@output_dir_pass = "./diffresult/"
		@file_pass = file_pass.split( "/" ).join( "\\" )
		@diff_string = diff_string
	end

	def create
		Dir.mkdir( @output_dir_pass ) if !Dir.entries( "." ).include?( @output_dir_pass.slice( /\.|\// ) )
		File.open( "#{@output_dir_pass}#{@file_pass}.diff.txt", "w" ) do |file|
			@diff_string.split( "\n" ).each do |line|
				file.puts( line )
			end
		end
	end

end