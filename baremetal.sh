#! /bin/bash

## # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#     CLI Args
#

set -e
usage() {
    echo "Usage: $0 -p <PACK> -f <FILE> -v <VERSION> -c <CONFIG_FILE> -u <USER_FILE>" 1>&2;
    echo "" 1>&2;
    echo "  -c <CONFIG_FILE   Specify the config file. (Default: ./baremetal.conf)" 1>&2;
    echo "  -f <JSON_FILE>    Specify the json file inside the pack. (Default: main.json)" 1>&2;
    echo "  -h <HOSTNAME>     Hostname of target machine (optional. Default in config file)" 1>&2;
    echo "  -i <IP>           IP of target machine. (Default in config file)" 1>&2;
    echo "  -p <PACK>         Pack. (Default: ubuntu)" 1>&2;
    echo "  -u <USER_FILE>    User Config File. (Default: ./user.conf)" 1>&2;
    echo "" 1>&2;
    exit 1;
}

FILE="main.json"
PACK="ubuntu"
CONFIG_FILE="baremetal.conf"
USER_FILE="user.conf"

CLI_IP=
CLI_HOST=

while getopts ":c:f:u:p:i:h:" o; do
    case "${o}" in
        i)
            IP="$OPTARG"
            ;;
        h)
            HOST="$OPTARG"
            ;;
        f)
            FILE="$OPTARG"
            ;;
        p)
            PACK="$OPTARG"
            ;;
        c)
            CONFIG_FILE="$OPTARG"
            ;;
        u)
            USER_FILE="$OPTARG"
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

[[ -z "$PACK" ]] && { echo "Missing pack choice" 1>&2; ARGS_MISSING=true; }
[[ -z "$CONFIG_FILE" ]] && { echo "Missing config file" 1>&2; ARGS_MISSING=true; }

[[ -z "$ARGS_MISSING" ]] || { echo "Args missing." 1>&2; usage; exit 1; }

[[ ! -f "$CONFIG_FILE" ]] && { echo "Config file $CONFIG_FILE does not exist" 1>&2; FILES_MISSING=true; }
[[ ! -f "$USER_FILE" ]] && { echo "User config file does not exist" 1>&2; FILES_MISSING=true; }
[[ ! -f "packs/$PACK/$FILE" ]] && { echo "Json file \"$FILE\" does not exist in packs/$PACK" 1>&2; FILES_MISSING=true; }

[[ -z "$FILES_MISSING" ]] || { echo "Files missing." 1>&2; usage; exit 1; }



## # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#     Config Args
#

IP=
SSH_USER=ubuntu
SSH_PASS=ubuntu
HOST=

USER=
SSH_KEY=

. "$CONFIG_FILE"
. "$USER_FILE"

[[ -z "$SSH_USER" ]] && { echo "Missing initial ssh user" 1>&2; CONFIG_MISSING=true; }
[[ -z "$SSH_PASS" ]] && { echo "Missing initial ssh password" 1>&2; CONFIG_MISSING=true; }

[[ -z "$USER" ]] && { echo "Missing user" 1>&2; CONFIG_MISSING=true; }
[[ -z "$SSH_KEY" ]] && { echo "Missing user's public ssh key" 1>&2; CONFIG_MISSING=true; }

[[ -n "$CLI_IP" ]] && IP="$CLI_IP"
[[ -z "$IP" ]] && { echo "Missing IP of target machine. Can be set in config file or as cli arg" 1>&2; CONFIG_MISSING=true; }

[[ -n "$CLI_HOST" ]] && HOST="$CLI_HOST"

[[ -z "$CONFIG_MISSING" ]] || { echo "Config missing from config file." 1>&2; usage; exit 1; }



## # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
#     Build
#


cd "packs/$PACK"

echo "packer build -force -only=\"null\" -var \"ip=$IP\" -var \"ssh_user=$SSH_USER\" -var \"ssh_pass=$SSH_PASS\" -var \"host=$HOST\" -var \"user=$USER\" -var \"ssh_key=$SSH_KEY\"  \"$FILE\""
 
packer build -force -only="null" -var "ip=$IP" -var "ssh_user=$SSH_USER" -var "ssh_pass=$SSH_PASS" -var "host=$HOST" -var "user=$USER" -var "ssh_key=$SSH_KEY" "$FILE"






