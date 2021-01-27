#!/bin/bash
# Push a local directory to remote repository without having to create a local repo frequently.
# THREE-NEVER RULE FOR GIT
# 1. Never push a file with a size of > 100MB
# 2. Never create a depo with a size of > 1GB
# 3. Never remove a file in local directory without using "git rm" command
#***********************************************************************************
# Normalize a filename by substituting special characters with spaces.
# spec_char_set='–—"#$%&\+,-/:;<=>?@[].\`|}~^!{)(* '
# Single quote is not included in the set due to its special use as delimiter in shell, but it can be individually substituted as well.
spec_char='–—_"#$%&\+,-/:;<=>?@\`|}~^!{)(* '
function norm_flnm {
    local path="$1"
    for ((i=0;i<${#path};i++));do
        char="${path:i:1}"
        if [[ "$spec_char" =~ "$char" ]];then
        # If special characters in the spec_char set are found in a filename, they shall be substituted with whitespaces.
            path=${path//"$char"/ }
        fi
    done
    # An open bracket is substituted with an underline sign, and a closing bracket is deleted. Single quotes are substituted with Chinese quotation marks. A leading underline sign is deleted.
    path=$(echo "$path" | sed "{s/'/”/g;s/ \?\[/_/g;s/\]//g;s/ \+/ /g;s/^_//}")
    # return the substituted result
    echo "$path"
}
# Link a file (with its full path) to a destination folder (with its full path)
# format: lnkf <file> <des_folder>
COUNT_LNK=0
function lnkf {
    src_path="$1"
    des_folder="$2"
    if [ -f "$src_path" ] && [[ "$src_path" =~ .*/.* ]];then
        # extract filename from its full path
        src_file=${src_path##*/}
    else
        echo "Please verify that the source file exits and you are using a full path to the file."
        return
    fi
    if [ ! -d "$des_folder" ];then
        mkdir "$des_folder"
    fi
    if [ ! -f "$des_folder/$src_file" ];then
        ln "$src_path" "$des_folder"
        COUNT_LNK=$[ $COUNT_LNK+1 ]
    else
        echo "Oops!$des_folder has already included $src_file,link not successfully made."
    fi
}
# Compress a file using xz
# format: cmprf <file>
function cmprf {
    filename="$1"
    # only compress a file with a valid name and without a compressed version in the same directory
    if [ -f "$filename" ] && [ ! -f "$filename.xz" ];then
        local fmsize=$(echo $(du -h "$filename") | awk '{print $1}')
        echo compressing "$filename" $fmsize ...
        xz -9kqQf "$filename"
    fi
}
# Back up a local folder to a git repo.
# format: bkup_fld <src_folder> <des_folder>
# <src_folder> is a local folder to be backed up. <des_folder> is a local folder within a local git repository and will be created if it does not exist.
# The script is intended to be run by a bash program (either git bash or Linux bash).
function bkup_fld {
    COUNT_CMPR=0
    COUNT_PUSH=0
    declare -A COUNT_GF
    src_folder="$1"
    des_folder="$2"
    IFS=$'\n'
    for f in $(ls "$src_folder");do
        local sfbsize=$(stat -c %s "$src_folder"/"$f")
        # file with a size of greater than 100MB shall not be processed
        if [ $sfbsize -ge 104857600 ];then
            COUNT_GF+=(["$f"]="$sfbsize")
        else
            src_path="$src_folder/$f"
            lnkf "$src_path" "$des_folder"
            # remove weird characters in file path and rename the file
            newf=$(norm_flnm "$f")
            mv "$des_folder"/"$f" "$des_folder"/"$newf"
            # only files with a size greater than 1 MB shall be compressed
            ## file size in bytes
            fbsize=$(stat -c %s "$des_folder"/"$newf")
            if [ "$fbsize" -gt 1048576 ];then
                cmprf "$des_folder"/"$newf"
                # delete a successfully compressed file
                if [ -f "$des_folder"/"$newf".xz ];then
                    COUNT_CMPR=$[ $COUNT_CMPR+1 ]
                    rm -f "$des_folder"/"$newf"
                fi
            fi
        fi
    done
    for f in $(ls "$des_folder");do
        chk_vol .
        if [ $TOTALVOL -ge 1048576000 ];then
            echo "Warning: Oversied repository! Push not allowed. Please create a new repository."
        else
            
            # fmsize=$(echo $(du -h "$des_folder"/"$f") | awk '{print $1}')
            fbsize=$(stat -c %s "$des_folder"/"$f")
            fmsize=$(awk -v a=$fbsize 'BEGIN{printf "%.3f", a/1024/1024}')
            git add "$des_folder"/"$f"
            git commit -m "${fmsize} Mbytes"
            git push origin master
            if [ $? -eq 0 ];then
                COUNT_PUSH=$(( $COUNT_PUSH+1 ))
                REPOVOL=$(awk -v a=$fmsize -v b=$REPOVOL 'BEGIN{printf "%.2f",a+b}')
                rm -f "$des_folder"/"$f"
            fi
        fi
    done
    rmdir "$des_folder"
    echo "$COUNT_LNK links made, $COUNT_CMPR files compressed, $COUNT_PUSH files pushed successfully, ${#COUNT_GF[@]} oversized files (>100M) not backed up:"
    for fnm in ${!COUNT_GF[@]};do
        echo "$fnm" : ${COUNT_GF["$fnm"]}
    done
}
# Check repo volume info in local directory.
# format: chk_vol <working directory>
function chk_vol {
    wkd="$1"
    echo > "$wkd"/repo.vol
    TOTALVOL=0
    # local fnm=$(git ls-files --debug |sed -n 's/\(^[^ ].*\)/\1%/p')
    local fsz=$(git ls-files --debug | sed -n '/size/p' | awk '{print $2}')
    # IFS="%" read -a FNM <<< $(echo $fnm)
    IFS=" " read -a FSZ <<< $(echo $fsz)
    for x in "${!FSZ[@]}";do
        # echo ${FNM[$x]} ${FSZ[$x]} bytes >> "$wkd"/repo.vol
        TOTALVOL=$(( $TOTALVOL + ${FSZ[$x]} ))
    done
    TOTALMVOL=$(awk -v x=$TOTALVOL 'BEGIN{printf "%.2f",x/1024/1024}')
    sed -i "1i\Vol: $TOTALVOL bytes, $TOTALMVOL Mbytes" "$wkd"/repo.vol
    sed -i "/^$/d" "$wkd"/repo.vol
}
function pshit {
    bkup_fld "$1" "$2"
    chk_vol .
    git add "./repo.vol"
    git commit -m "repo vol. consumed: ${TOTALMVOL} Mbytes"
    git push origin master
    git rm ./repo.vol
}
# pshit "/F/test2" "/F/Pythonx/git/BU2"
