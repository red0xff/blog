require'digest';

if ARGV.count == 0
	puts "[-] Usage : ruby markdown_toc.rb [file.md]";
	exit 1;
end
toc = [ ]
File.open(ARGV[0], ?r) do|f|
	open_code = false;
	data = f.read.lines.map(&:chomp).map{|l|
		open_code = !open_code if l[0,3] == "```";			
		open_code ? l : l.gsub(/^(#+) (.+)/){ $1 + ' ' + "<span id='#{Digest::MD5.hexdigest($2)}'>#$2</span>"};
	};
	metadata_end = data.each_with_index.detect{|l,i| i > 0 && l == '---'}.last
	puts data[0, metadata_end+1]*?\n
	headings = data.select{|e| e =~ /^#+ <span/ };
	puts "# Table of Contents";
	prev_level = -1;
	count_same = [ 0 ];
	headings.each{|h|
		level = h[/^#+/].length - 1;
		puts h.gsub(/^#+\s*<span id='([^']*)'>([^<]*)<\/span>/){
			if level < prev_level
				count_same[prev_level] = 1;
				count_same[level] += 1;
				prev_level = level;
				?\t * level + count_same[level].to_s + '. ';
			elsif level > prev_level
				count_same[level] = 1;
				prev_level = level;
				?\t * level + '1. ';
			else
				count_same[level] += 1;
				prev_level = level;
				?\t * level + count_same[level].to_s + '. ';
			end + "[#$2](##$1)";
		}
	}
	print "\n";
	puts data[metadata_end+2..-1] * ?\n;
end
