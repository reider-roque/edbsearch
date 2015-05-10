#TODO List

* Add `-i edbid` option for showing available exploit information from 
files.csv
* Do not ignore the `-t` option if platform was not specified with `-p` option.
Make it search through all exploits of all platforms that have exploits of
the specified type available
* Add negate operator (probably use `~`) for search terms to search for
exploits that do not contain specifed term
* Add `-E` and `-G` options to interpret search terms as extended (ERE) or basic
(BRE) search patterns (same as for grep)
* Review analogous tools for features worth porting:
    * searchsploit
    * https://github.com/mattoufoutu/exploitdb
    * https://github.com/Spacecow99/searchsploit2
    * https://github.com/jakl/exploitdb.rb

