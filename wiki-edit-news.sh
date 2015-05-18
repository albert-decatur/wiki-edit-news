#!/bin/bash
# posts events.dbpedia.org wikipedia edit descriptions to twitter
# NB: assumes authentication through twurl's ~/.twurlrc
# NB: works in current directory
# prereqs: twurl, raptor-bin, lftp, mawk, GNU parallel, perl MURI::Escape
# TODO: take only latest update on a subject from the ttl events file
# user args: 1) sleep time in seconds to avoid twitter API abuse
# examples: $0 15

# time to wait between posts - NB: however, parallel is multicore, so perhaps -j 1 should be used
sleeptime=$1
# define a log file - check this file to see if the latest ttl has already been posted to twitter
log=events_dbpedia_urls.log
# defines base dbpedia events url - lftp find command will not include this
baseurl="http://events.dbpedia.org/dataset/"
# get latest ttl (turtle) file from events.dbpedia.org
url=$baseurl$( lftp -e 'find; exit' $baseurl | tail -n 1 )
# define url_decode function
function url_decode { perl -MURI::Escape -e 'print uri_unescape(<STDIN>); print "\n";';}
# if the URL does not already appear in the log file, then post its events
if [[ -z $( grep -F "$url" $log ) ]]; then 
	# make a two col tsv: 1) ttl event uri, 3) ttl event description
	tsv=$(
		# convert from turtle to ntriples format
		rapper -i turtle -o ntriples <( curl -s "$url" ) |\
		# find description tuples
		grep -F 'http://purl.org/dc/terms/description' |\
		# replace escaped description quotes with ditto marks - this makes them look like quotes but makes parsing easy
		sed 's:″::g;s:\t: :g;s:\\":″:g' |\
		# split by double quote (and implicitly space) in order to print quoted description field easily
		mawk '{split($0,a,"\"");print $1,a[2]}' |\
		# remove mentions that have a dbpedia url - look junky and redundant
		grep -vF 'http://dbpedia.org/resource/' |\
		# decode url encoded text
		url_decode |\
		# ignore blank lines
		grep -vE "^$"
	)
	tmptsv=/tmp/tmptsv
	echo "$tsv" > $tmptsv
	# make a list of unique uris - this relies on uris being sorted already by dbpedia
	# the reason we do not sort is to keep the chronological order correct, eg JUSTMARRIED followed by JUSTDIVORCED
	# would be better to get chronology - and real wikipedia URLs - from original TTL instead of rapper converted ntriples
	uniq_uris=$(
		echo "$tsv" |\
		mawk '{print $1}' |\
		uniq
	)
	# for each unique uri, get the most recent description and tweet it
	echo "$uniq_uris" |\
	parallel '
		record=$( grep -F {} '$tmptsv' | tail -n -1 )
		desc=$( 
			# convert dbpedia hex unicode code points to utf8 characters
			echo -e "$record" |\
			# pull just description - blanks wikipedia url column
			mawk "{\$1=\"\";print \$0}" |\
			# remove leading whitespace
			sed "s:^\s\+::g"
		)
		wikilink=$( 
			echo "$record" |\
			mawk "{print \$1}" |\
			grep -oE "[^/]*$" |\
			# remove dbpedia event tags, eg JUSTMARRIED
			# TODO: do not rely on last word in URL not being all capitals after a hyphen, which could actually happen
			# one solution is a full list of dbpedia event tags, another is to really use the input ttl instead of converting to nt
			sed "s:-[A-Z]\+>$::g" |\
			# prepend wikipedia base url
			sed "s:^:http\:\/\/en.wikipedia.org\/wiki\/:g" 
		)
		# post to twitter
		twurl -d "status=$desc $wikilink." /1.1/statuses/update.json
		# sleep for user specified number of seconds
		# this could also be accomplished through GNU parallels sem or -j
		sleep '$sleeptime'
	'
	# append the current url to the log file so those events will not be reposted in future runs
	echo "$url" >> $log
fi