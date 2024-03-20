# this must contains generic variables and functions for including in any script

export GREEN='\033[1;32m'  # Green
export RED='\033[1;31m'    # Red
export NC='\033[0m'        # No Color

#TODO
# - change code in all scripts by this function for printing warnings and messages
#   - then, remove the exports above and insert in the function

print_pattern() {
    #RED='\033[0;31m'
    #GREEN='\033[0;32m'
    #NC='\033[0m'  # No Color

    type_msg=$1
    message=$2

    if [ "$type_msg" == "warning" ]; then
        echo -e "\n${RED}==>${NC} ***** ATTENTION *****\n"
	echo -e "\n${RED}==>${NC} ${message}\n"
    elif [ "$type_msg" == "normal" ]; then
        echo -e "${GREEN}==>${NC} ${message}\n"
    else
        echo "Invalid type. Use 'warning' for RED or 'normal' for GREEN."
    fi
}

# Example usage:
# print_pattern "warning" "a warning message"
# print_pattern "normal" "a normal message"
