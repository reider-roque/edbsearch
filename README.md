#Introduction

Exploit-DB search utility performs search through the actual exploit
source files unlike most similar tools (including searchsploit) that 
search only through files.csv. Though it doesn't replace searchsploit,
but rather widens the search surface allowing to find more relevant
exploits.

#Prerequisites
  
On Kali Linux `exploitdb` package must be installed. Or you can get
the latest database version from github and then edit `EDB_PATH`
variable to point to your chosen location.

#Usage

`./edbsearch.sh -p windows -t local windows xp` will search through
windows exploit source files of local type and output those containing
*windows* and *xp* words somewhere in the file.

`./edbsearch.sh -p windows -t local "windows xp" sp3` will search
through windows exploit source files of local type and output those
containing *windows xp* phrase and *sp3* word somewhere in the file.

#Author

Oleg Mitrofanov, 2015


