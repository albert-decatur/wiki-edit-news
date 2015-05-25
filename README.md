# wiki-edit-news

*A very bashy twitter bot that loves Wikipedia . . .*


Unofficial twitter bot that posts [DBpedia events](http://dbpediawww.informatik.uni-leipzig.de/datasets/events) based on newsworthy Wikipedia edits.
Almost all the work is done by DBpedia in prepping these events and their descriptions!
Updates when DBpedia events are updated.

### features

1. ignores all but the last event in a series (turtle file) with the same URI
  1. prevents many many fast paced edits about the same topic from all showing up
1. performs unicode code point conversion to wonderful UTF-8
1. ignores events that contain DBpedia URIs directly
  1. usually junk
1. provides URL to visit edited Wikipedia article

### prerequisites

* [twurl]((https://github.com/twitter/twurl))
* raptor-utils
* lftp
* mawk
* GNU parallel
* perl's URI::Escape

### installation

These instructions assume a debian based linux distribution.

```bash
# install utils to convert dbpedia turtle files (ttl) to ntriples (raptor-utils), use find on HTTP (lftp), and awk faster! (mawk)
sudo apt-get install raptor-utils lftp mawk
# install twurl to easily use twitter API
sudo apt-get install rubygems1.9.1
sudo gem i twurl --source http://rubygems.org
# at this step, manually configure twurl with your twitter consumer key / consumer secret
# install GNU parallel
sudo apt-get install parallel
# install URI escape and unescape perl module to handle unicode code points from dbpedia events
cpan -i URI::Escape
```

If you've already got moreutils installed on your system you'll want to replace it's *parallel* utility with GNU parallel.
Here's how

```bash
wget -c http://ftp.gnu.org/gnu/parallel/parallel-latest.tar.bz2
tar jxvf parallel-latest.tar.bz2
cd parallel-{VERSION}/
./configure && make && make install
# moreutils has a util called parallel, but this is not GNU parallel
# remove moreutils parallel
sudo rm $(which parallel)
# replace it with GNU parallel
sudo cp src/parallel /usr/bin/parallel
```

### use

```bash
# make executable
chmod +x wiki-edit-news.sh
# post latest dbpedia events to twitter, with 15 second wait time between posts
./wiki-edit-news.sh 15
```

Note that the log file *events_dbpedia_urls.log* will be keeping track of which dbpedia events have already been posted.
A primitive system!
All it holds is the URLs of dbpedia events scraped previously.

### TODO

* when invoking without a URL, post for all tll files after the latest in the log txt
* only post descriptions with links - helps catch broken posts
