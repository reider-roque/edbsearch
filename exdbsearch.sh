#!/usr/bin/env bash

#
# Exploit-DB search utility performing search through the actual exploit
# source files unlike most similar tools (including searchsploit) that 
# search only through files.csv
#  
# On Kali Linux `exploitdb` package must be installed. Or you can get
# the latest database version from github and then edit EXDBPATH
# variable to point to your chosen location
#
# Author: Oleg Mitrofanov, 2015
#

EXDBPATH="/usr/share/exploitdb"
ALL_PLATFORMS=$(ls -d1 $EXDBPATH/platforms/*/ | rev | cut -d/ -f2 | rev | tr '\n' ' ')


function show_help {
    printf "Usage: $0 -p platform -t type [-c] SEARCH TERMS\n\n"
    printf "Perform a search through the actual exploit source files for the specified\n"
    printf "SEARCH TERMS in the Exploit-DB database.\n\n"
    printf "Options:\n"
    printf "  -p, --platform platform\n"
    printf "\t\t\tTarget platform to search exploits for. Use\n"
    printf "\t\t\t--help-platforms to get the list of available\n"
    printf "\t\t\tplatforms\n"
    printf "  -t, --type type"
    printf "\tType of exploit to search for. Possible types: dos,\n"
    printf "\t\t\tlocal, remote, shellcode, webapps\n"
    printf "  -c"
    printf "\t\t\tUse case-sensitive search. The default is\n"
    printf "\t\t\tcase-insensitive\n"
    printf "  -h, --help"
    printf "\t\tShow this help\n"
    printf "      --help-platforms"
    printf "\tShow the list of available platform for which\n"
    printf "\t\t\texploits exist in the database\n"
    
}


function print_status() {
    MESSAGE=$1
    TYPE=$2
    case $TYPE in
        warn)
            printf "\033[1;31m[!]\033[1;m $MESSAGE\n" 
        ;;
        fail)
            printf "\033[1;31m[-]\033[1;m $MESSAGE\n" 
        ;;
        info|*)  # All other types are informational
            printf "\033[1;34m[*]\033[1;m $MESSAGE\n" 
        ;;
    esac
}


# Parsing arguments
while [[ $# > 0 ]]
do
    key="$1"
    
    case $key in
        -p|--platform)
            # Convert to lower case
            PLATFORM=$(echo "$2" | tr "[:upper:]" "[:lower:]")
            shift
        ;;
        -t|--type)
            TYPE=$(echo "$2" | tr "[:upper:]" "[:lower:]")
            shift
        ;;
        -c|--case-sensitive)
            CASESENS="true"
        ;;
        -h|--help)
            show_help
            exit 0 
        ;;
        --help-platforms)
            echo $ALL_PLATFORMS 
            exit 0
        ;;
        -*) # unknown option
            print_status "Error: option \`$key\` is not known." "warn"
            print_status "Use \`$0 --help\` for more information." "info" 
            exit 1
        ;;
        *) # The rest is search tems, stop parsing for options
            break
    esac
    shift
done
    
##### INPUT VALIDATION BEGIN #####

# Check if we have any search terms
if [[ $# < 1 ]]; then
    print_status "Error: no search terms supplied." "warn"
    print_status "Use \`$0 --help\` for more information." "info" 
    exit 1
fi


if [ -z $PLATFORM ]; then
    SEARCH_PATH="$EXDBPATH/platforms/"
    print_status "No platform was chosen. Will search through ALL exploits. It may take\n    some time.\n" "info"
elif [ -z $TYPE ]; then
    SEARCH_PATH="$EXDBPATH/platforms/$PLATFORM/"
    print_status "No exploit type was chosen. Will search through all exploits for\n    $PLATFORM platform.\n" "info"
else
    SEARCH_PATH="$EXDBPATH/platforms/$PLATFORM/$TYPE"
fi    
    

if [ ! -d "$SEARCH_PATH" ]; then
    print_status "Error: no $TYPE type exploits exist for $PLATFORM platform." "warn"
    exit 0
fi

##### INPUT VALIDATION END #####

# For passing -i flag to grep for case-insensitive search
if [[ $CASESENS == "true" ]]; then
    CASEINS="i"
else
    CASEINS=""
fi

# Set the first search term
SEARCH_CMD="egrep -rl$CASEINS \"$1\" $SEARCH_PATH | "
shift

# Enumerating through the rest of search terms
for SE_TERM in "$@"
do
    SEARCH_CMD+="xargs egrep -rl$CASEINS '$SE_TERM' $SEARCH_PATH | "
done

SEARCH_CMD+="sort -V"
SEARCH_RESULTS=$(eval "$SEARCH_CMD")

if [ -z "$SEARCH_RESULTS" ]; then
    print_status "Nothing found!" "fail"
    exit 0
fi

FILES_CSV="$EXDBPATH/files.csv"

# Presenting search results
for SE_RESULT in $SEARCH_RESULTS
do
    EDB_ID=$(echo $SE_RESULT | rev | cut -d/ -f1 | rev | cut -d. -f1)
    EDB_INFO_LINE=$(egrep "^$EDB_ID" "$FILES_CSV")
    EDB_DESC=$(echo $EDB_INFO_LINE | cut -d, -f3 | sed 's/^"\(.*\)"$/\1/')
    echo "$EDB_DESC"
    printf "\t$SE_RESULT\n"
done
exit 0
