
# Unzip the mzf tar'd file
def ,unzip-magnum-mzf-file [ 
	file: string 
] { 
	let $dir = ($file | str replace ".mzf" "")
	mkdir $dir
	tar zxvf $file --directory=($dir) 
	cd $dir
}



# Create a folder based on the db name (TODO for all)
# TODO: make sure folders are correct
def ,extract-db-file-to-folder [ 
	file: string 
] { 
	let $dir = ($file | str replace ".db" "")
	mkdir $dir
	cp $file $dir 
	cd $dir
	,reflex-unpack $file
}

# Open a Reflex db file that is either multi-file (JSON) or single-file (YAML)
def ,reflex-unpack [
	file: string 
] { 
	try { # Assume the file is a multi-file db
		open $file
			| get documents 
			| where name == 'reflex' 
			| get content 
			| where revision == 551 #| last 
			| from json 
			| get documents 
			| transpose 
			| each {|r| echo $r.column1.content 
				| save -f $"($r.column1.name | str replace -a '/' '-' | str replace -a ' ' '_')___($r.column0).txt" # TODO: remove -f?
			}

		tail -n +1 ...(ls *txt | get name) 
			| save full.txt 
	} catch { # Otherwise, it is a single-file db
		open $file
			| get documents
			| where name == 'reflex'
			| where revision == 551 #| last 
			| each {|r| echo $r.content 
				| save -f $"($r.metadata | from json | get name | str replace -a '/' '-' | str replace -a ' ' '_')___($r.metadata | from json | get uuid).txt" 
			}
	}
}
