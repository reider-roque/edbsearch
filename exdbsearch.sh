#!/usr/bin/env bash

#
# Exploit-DB search utility performing search through the files unlike
# most other similar tools that search only through files.csv
#  
# On Kali Linux `exploitdb` package must be installed. Or you can get
# the latest database version from github and then edit EXDBPATH
# variable to point to your chosen location
#
# Author: Oleg Mitrofanov, 2015
#

EXDBPATH="/usr/share/exploitdb"
ALL_PLATFORMS=$(ls -d1 $EXDBPATH/platforms/*/ | cut -d/ -f6 | tr '\n' ' ')
ALL_TYPES="dos local remote shellcode webapps" 


function show_help {
    printf "Usage: $0 -p platform -t type [-c] SEARCH TERMS\n\n"
    printf "Perform a search through the actual exploit source files for the specified\n"
    printf "SEARCH TERMS in the Exploit-DB database.\n\n"
    printf "Options:\n"
    printf "  -p, --platform platform\n"
    printf "\t\tTarget platform to search exploits for. Use --help-platforms\n"
    printf "\t\tto get the list of available platforms\n"
    printf "  -t, --type type\n"
    printf "\t\tType of exploit to search for. Possible values: dos, local,\n"
    printf "\t\tremote, shellcode, webapps\n"
    printf "  -c"
    printf "\t\tUse case-sensitive search. The default is case-insensitive\n"
    printf "  -h, --help"
    printf "\tShow this help\n"
    printf "      --help-platforms\n"
    printf "\t\tShow the list of available platform for which exploits exist \n"
    printf "\t\tin the database\n"
    
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
        --help-types)
            echo $ALL_TYPES 
            exit 0
        ;;
        -*) # unknown option
            echo "Error: option '$key' is unknown."
            show_help
            exit 1
        ;;
        *) # The rest is search tems, stop parsing for options
            break
    esac
    shift
done
    

# Check if we have any search arguments
if [[ $# < 1 ]]
then
    echo "Error: no search terms supplied"
    show_help
    exit 1
fi

SEARCH_PATH="$EXDBPATH/platforms/$PLATFORM/$TYPE/"
if [ ! -d "$SEARCH_PATH" ]
then
    echo "Error: no $TYPE exploits exist for $PLATFORM platform."
    exit 0
fi


# For passing -i flag to grep for case-insensitive search
if [[ $CASESENS == "true" ]]
then
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

if [ -z "$SEARCH_RESULTS" ]
then
    echo "Nothing found!"
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

# echo "PLATFORM  = $PLATFORM"
# echo "TYPE = $TYPE"
# echo "CASESENS = $CASESENS"
# echo "CASEINS = $CASEINS"
# echo "SEARCH_PATH = $SEARCH_PATH"
# echo "SEARCH_CMD = $SEARCH_CMD"
