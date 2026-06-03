# Command to help deal with Magnum log files
def mag [
	--decompress (-d): bool	# unzip .gz files
	--keep (-k): bool	# keep .gz files
	--join (-j): string 	# combine files into a '-full' file
	--time (-t): string 	# gawk pattern regex matching datetime range in string
	--uniq (-u): string	# find all unique lines in file and write to '-uniq' 
	--pattern (-p): string 	# gawk pattern to use
	--count (-c): int 	# TODO count occurrences of pattern
	...files: string	# all the files to run commands on
] { 
	# decompress files
	if $decompress and $keep { 
		echo 'Unzipping, keeping *.gz files'
		gzip -dk *.gz 
	} else if $decompress { 
		echo 'Unzipping, deleting *.gz files'
		gzip -d *.gz 
	} else {
		# do nothing
	} 

	# join matching-prefix files
	let uniques = (ls | get name | split column '.' base | uniq | get base)
	if $join != null { 
		for $file in ($uniques) { 
			echo $"Joining files into _($file)-full"
			ls **/* | where name =~ $"^($file)\\." | cat | save --append $"_($file)-full"
		}
	}

	# unique lines in matching-prefix files
	for $file in (ls **/* | where name =~ '-full$') {
		gawk $"BEGIN{IGNORECASE=1} // {print $0}" $file | gawk -F '###' 'BEGIN{IGNORECASE=1} !seen[$2]++ {print $1}' > $"($file)-uniq" # 1
		#gawk $"BEGIN{IGNORECASE=1; print 'Summary (first occurrence of match ignoring numbers):'} // {a = \$0; gsub(/[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}|[0-9a-f]{2}(:[0-9a-f]{2}){5}|[0-9]+|0x[0-9a-f]+|[0-9]+/,'',a); print $0, '###', a}" $file | gawk -F '###' 'BEGIN{IGNORECASE=1} !seen[$2]++ {print $1}' > $"($file)-uniq" # 1
		if $pattern != null and $time != null {
			gawk $"BEGIN{IGNORECASE=1; print \"Summary (first occurrence of match ignoring numbers):\"} ($pattern) ($time) {a = \$0; gsub(/[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}|[0-9a-f]{2}(:[0-9a-f]{2}){5}|[0-9]+|0x[0-9a-f]+|[0-9]+/,\"\",a); print \$0, \"###\", a}" $file | gawk -F '###' 'BEGIN{IGNORECASE=1} !seen[$2]++ {print $1}' > $"($file)-pattern-uniq" # 2
		}
	}

	# join relevant files
	(if $join != null { 
		echo 'Joining files into _full'
		ls **/* | where name =~ $join | save _full
		cat _full 
	} else { 
		echo 'Not joining files into _full'
		cat $files
	}) |
		# process files
		lines | 
		parse "{date} {device} {service}: {level}:{process}:{payload}" |
		where date =~ ($time | str replace --regex '^/' '' | str replace --regex '/$' '') |
		insert dateF {|it| $it.date | into datetime }
}
