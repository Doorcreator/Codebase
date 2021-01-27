INDEX=0
function traverse_dir {
    local mst_dir="$1"
    for f in "$mst_dir"/*;do
        if [ -d "$f" ];then
            traverse_dir "$f"
        else
            FILES+=(["$INDEX"]="$f")
            INDEX=$(( INDEX+1 ))
        fi
    done
}

function str2arr {
# Convert a string to array
# arg: string
# return value: array as a global variable '$ARR'
    oIFS=$IFS
    IFS=", " read -a ARR <<< $1
    IFS=$oIFS
    unset oIFS
}

function isinarr {
# Determine whether a string is in an array
# arg01: string
# arg02: another string to be used as array
# return value: string as a global variable '$MATCH_TYPE'(True/False)
    str="$1"
    str2arr "$2"
    arr=("${ARR[@]}")
    MATCH_TYPE=False
    for i in "${arr[@]}";do
        if [[ "$i" = "$str" ]];then
            MATCH_TYPE=True
            break
        fi
    done
    unset str arr
}

function calsiz {
# Calculate the size of a file
# arg: full path to file
# return value: file size in Mbytes
    local fmsize
    local fbsize=$(stat -c %s "$1")
    fmsize=$(awk -v a=$fbsize 'BEGIN{printf "%.3f", a/1024/1024}')
    echo $fmsize
}

function cmpnum {
# return 1 if $1 < $2, else return 0
   awk -v n1="$1" -v n2="$2" 'BEGIN {printf (n1<n2?1:0)}'
}

function split {
# Split a time range to two time strings
# arg: e.g. "2021-01-02 23:59:59, 2021-01-27 23:59:59"
# return value: two global time string STTTM and ENDTM
    local delimiter=","
    declare -a arr=($(echo "$1" | sed -e "s/$delimiter */\t/g;s/ /~/g"))
    local str=${arr[@]}
    arr=($(echo "$str"))
    STTTM=`echo ${arr[0]} | sed 's/~/ /g'`
    ENDTM=`echo ${arr[1]} | sed 's/~/ /g'`
}
function fltdir {
# Filter files to another dir according to conditions:
# option 1: -d, indicate target dir to filter, required arg, raise error if not provided
# option 2: -t, indicate time range to filter, required arg, raise error if not provided
# option 3: -x, indicate file extensions to filter out, multiple extensions separated by commas, optional arg, filter out none (i.e., all file types shall be included to back up dir) if not provided
# option 4: -v, indicate file size in Mbytes to filter, optional arg, filter out none (i.e., all file sizes shall be included to back up dir) if not provided
    while getopts "d:t:x:v:" opt;do
        case $opt in
        d)
          local srcdir="${OPTARG}"
          local dstdir="$srcdir""_flt"
          ;;
        t)
          local tmr="${OPTARG}"
          split "$tmr"
          local sttTM=$(date -d "${STTTM}" +"%s")
          local endTM=$(date -d "${ENDTM}" +"%s")
          ;;
        x)
          local ext="${OPTARG}"
          ;;
        v)
          local vol="${OPTARG}"
          ;;
        esac
    done
    
    if [[ -z "$srcdir" ]] || [[ -z "$tmr" ]];then echo "Err: args missing";exit;fi
    if [[ -z "$vol" ]];then ((vol=2**24));fi
    mkdir -p "$dstdir"
    traverse_dir "$srcdir"
    for f in "${FILES[@]}";do
        if [ -f "$f" ];then
            local mod_date=$(date -r "$f" +%s)
            local suf=${f##*.}
            local siz=$(calsiz "$f")
            isinarr "$suf" "$ext"
            if [[ $MATCH_TYPE = False ]] &&
            [[ "$mod_date" -gt "$sttTM" &&
            "$mod_date" -lt "$endTM" ]] &&
            [[ $(cmpnum $siz $vol) -eq 1 ]]
            then
                cp -u "$f" "$dstdir"/"${f##*/}"
            fi
        fi
    done
}
