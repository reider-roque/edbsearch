#!/usr/bin/env bash

#
# Exploit-DB search utility performing search through the actual exploit
# source files unlike most similar tools (including searchsploit) that 
# search only through files.csv
#  
# On Kali Linux `exploitdb` package must be installed. Or you can get
# the latest database version from github and then edit EDB_PATH
# variable to point to your chosen location
#
# Author: Oleg Mitrofanov, 2015
#

EDB_PATH="/usr/share/exploitdb"
ALL_PLATFORMS=$(ls -d1 $EDB_PATH/platforms/*/ | rev | cut -d/ -f2 | rev | tr '\n' ' ')
# For passing -i flag to grep for case-insensitive search (default)
CASE_INS="i"
SCRIPT_NAME=$(basename $0)


##### HELPER FUNCTIONS BEGIN #####

function show_help {
    printf "Usage: $SCRIPT_NAME [-p platform] [-t type] [-c] SEARCH TERMS\n\n"
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
    printf "\t\t\tThis option is currently ignored if you don't\n"
    printf "\t\t\tspecify any platform with -p option\n"
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
        success)
            printf "\033[1;32m[+]\033[1;m $MESSAGE\n" 
        ;;
        fail)
            printf "\033[1;31m[-]\033[1;m $MESSAGE\n" 
        ;;
        info|*)  # All other types are informational
            printf "\033[1;34m[*]\033[1;m $MESSAGE\n" 
        ;;
    esac
}

##### HELPER FUNCTIONS END #####


##### PARSE ARGUMENTS BEGIN #####

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
            CASE_INS=""
        ;;
        -h|--help)
            show_help
            exit 0 
        ;;
        --help-platforms)
            echo $ALL_PLATFORMS 
            exit 0
        ;;
        -*) # Unknown option
            print_status "Error: option \`$key\` is not known." "warn"
            print_status "Use \`$SCRIPT_NAME --help\` for more information." "info" 
            exit 1
        ;;
        *) # The rest is search terms, stop parsing for options
            break
    esac
    shift
done

##### PARSE ARGUMENTS END #####
    

##### INPUT VALIDATION BEGIN #####

# Check if we have any search terms
if [[ $# < 1 ]]; then
    print_status "Error: no search terms supplied." "warn"
    print_status "Use \`$SCRIPT_NAME --help\` for more information." "info" 
    exit 1
fi


if [ -z $PLATFORM ]; then
    SEARCH_PATH="$EDB_PATH/platforms/"
    print_status "No platform was chosen. Will search through ALL exploits. It may take\n    some time." "info"
elif [ -z $TYPE ]; then
    SEARCH_PATH="$EDB_PATH/platforms/$PLATFORM/"
    print_status "No exploit type was chosen. Will search through all exploits for\n    $PLATFORM platform." "info"
else
    SEARCH_PATH="$EDB_PATH/platforms/$PLATFORM/$TYPE"
fi    
    

if [ ! -d "$SEARCH_PATH" ]; then
    print_status "Error: no $TYPE type exploits exist for $PLATFORM platform." "warn"
    exit 0
fi

##### INPUT VALIDATION END #####


##### SEARCH CMD FORMATION BEGIN #####

# Set the first search term
SEARCH_CMD="grep -Frl$CASE_INS '$1' $SEARCH_PATH |"
shift

# Enumerating through the rest of search terms
for SE_TERM in "$@"
do
    SEARCH_CMD="$SEARCH_CMD xargs grep -Fl$CASE_INS '$SE_TERM' |"
done

# To sort results we first put the last (filename) field in front, then
# do numeric (version) sort, and then remove the filename field we put
# in front
SEARCH_CMD="$SEARCH_CMD awk -F/ '{ print \$NF, \$0 }' | sort -V | sed 's/^[^ ]* //'"

##### SEARCH CMD FORMATION END #####


##### DISPLAY SEARCH RESULTS BEGIN  #####

SEARCH_RESULTS=$(eval "$SEARCH_CMD")

if [ -z "$SEARCH_RESULTS" ]; then
    print_status "Nothing found!" "fail"
    exit 0
fi

# Exploit description will be read from files.csv
FILES_CSV="$EDB_PATH/files.csv"
print_status "Found matches:\n------------------" "success"
for SE_RESULT in $SEARCH_RESULTS
do
    EDB_ID=$(echo $SE_RESULT | rev | cut -d/ -f1 | rev | cut -d. -f1)
    EDB_INFO_LINE=$(grep -E "^$EDB_ID" "$FILES_CSV")

    # First version - fails when third (description) field has commas in it
    # EDB_DESC=$(echo $EDB_INFO_LINE | cut -d, -f3 | sed 's/^"\(.*\)"$/\1/')

    # Second version - fails if the third field is not quoted
    # EDB_DESC=$(echo $EDB_INFO_LINE | grep -o '"[^"]*"' | head -1 | \
    #     sed 's/^"\(.*\)"$/\1/')
    
    # Third version - fails if there are empty fields preceding
    # description field. This solution works best at this time.
    EDB_DESC=$(echo $EDB_INFO_LINE | grep -Eo '([^,]+)|("[^"]+")' | \
        head -n3 | tail -n1 | sed 's/^"\(.*\)"$/\1/')

    printf "$EDB_DESC\n"
    printf "\t$SE_RESULT\n"
done
exit 0

##### DISPLAY SEARCH RESULTS END  #####
