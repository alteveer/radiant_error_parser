require 'fileutils'

@map_name = ARGV[0]
@default_map_dir = 	"c:/trees/iw5/game/map_source"
#@error_log_file = 	"mp_roughneck.errlog"
@error_log_file = 	"#{@map_name}.errlog"
@error_out_file = 	"#{@map_name}.errlog.output"
@error_bak_file = 	"#{@map_name}.errlog.bak"
@map_file = 	"#{@map_name}.map"
Dir.chdir(@default_map_dir)
@file_name = File.join(@default_map_dir, @error_log_file)
@errors = []	
@parsed_errors = {}

def open_and_search(map_file, brush_number, error)
	#puts map_file, brush_number
	#puts @file_handles.key? map_file
	unless(@file_handles.key? map_file)
		@file_handles[map_file] = {:file => File.open(File.join(@default_map_dir, map_file)), :prefabs => {}}
		#puts "adding #{map_file} to look for #{brush_number}"
	end
	if(@file_handles[map_file][:prefabs].key? brush_number)
		#puts "already cached #{map_file}:#{brush_number}"
		return @file_handles[map_file][:prefabs][brush_number]	
	else
		#puts "searching #{map_file} for #{brush_number}"
		file = @file_handles[map_file][:file]
		file.rewind
		file_contents = file.read
		#puts file_contents.count("\n")
		match_data = file_contents.match(/(entity|brush)\s#{brush_number}\s[^{]*{[^}]*"model"\s"([^"]*)/m)
		if(match_data)
			#puts "match success #{match_data[2]}"
			return @file_handles[map_file][:prefabs][brush_number] = match_data[2]
		else 
			puts "**** MATCH FAIL #{error}"
			return false
		end
	end
end

puts "Parsing error file..."
@err_file = File.open(@file_name)
@err_file.each do |error|
	match_data = error.match(/^"[^"]+"\s([-\d\s]+):([-\d\s\.]+)"(.+)"/)
	#puts error
	if(match_data) 
		e = {}
		e['brush_numbers'] = 	match_data[1].strip.split(" ")
		e['viewpos'] = 				match_data[2].strip
		e['message'] = 				match_data[3]
		e['raw'] = 						error
		@errors << e
	end
end

@file_handles = {}
puts "Traversing prefabs..."
@errors.each do |error|
	map_file = @map_file
	i = 0;
	#puts error['brush_numbers']
	#puts "--- #{error}"
	while i < error['brush_numbers'].length - 1 do 
		map_file = open_and_search(map_file, error['brush_numbers'][i], error)
		unless(map_file) 
			break 
		end
		#puts i
		i += 1
	end
	unless(@parsed_errors[map_file])
		@parsed_errors[map_file] = []
	end
	@parsed_errors[map_file] << error
end

map_numbers = []
while(1)
	puts "\nWhich prefab do you want errors from?"
	map_numbers = []
	
	@parsed_errors.keys.each do |e| 
		map_numbers.push e
		puts "#{map_numbers.length}) #{e} (#{@parsed_errors[e].length} error#{@parsed_errors[e].length != 1 ? "s" : ""})"
	end
	
	puts "\nx) To cancel"
	prefab_number = $stdin.gets
	#puts prefab_number
	if(prefab_number.chomp == "x")
		puts "Cancelling..."
		exit
	end
	
	if((1..map_numbers.length) === prefab_number.to_i) 
		break
	end
end

puts "Backing up log file: #{@error_bak_file}"
FileUtils.copy(@error_log_file, @error_bak_file)

puts "Creating single-prefab error log: #{@error_out_file}"
File.open(@error_out_file, "w") do |f|
	@parsed_errors[map_numbers[prefab_number.to_i-1]].each do |e|
		f.puts e['raw']
	end
end

#puts @parsed_errors[map_numbers[prefab_number.to_i-1]]