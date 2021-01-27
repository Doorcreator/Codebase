# Push a local encrypted file to remote repository without having to create a local repo frequently.
# THREE-NEVER RULE FOR GIT
# 1. Never push a file with a size of > 100MB
# 2. Never create a depo with a size of > 1GB
# 3. Never remove a file in local directory without using "git rm" command
#*******************************************************************
function bkup_fld {
# Back up a local file to a git repo.
# usage: bkup_fld <src_file>
# <src_file> is a local file to be backed up.
    src_f="$1"
    fbsize=$(stat -c %s "$src_f")
    # file with a size of greater than 100MB shall not be processed
    if [ $fbsize -ge 104857600 ];then
        echo "Warning: Oversied file. Push not allowed!"
    else
        chk_vol .
        if [ $TOTALVOL -ge 1048576000 ];then
            echo "Warning: Oversied repository! Push not allowed. Please create a new repository."
        else
            fmsize=$(awk -v a=$fbsize 'BEGIN{printf "%.3f", a/1024/1024}')
            git add "$src_f" &&
            git commit -m "${fmsize} Mbytes" &&
            git push -f origin master &&
            if [ $? -eq 0 ];then
                REPOVOL=$(awk -v a=$fmsize -v b=$REPOVOL 'BEGIN{printf "%.2f",a+b}') &&
                rm -f "$src_f"
            fi
        fi
    fi
}

function chk_vol {
# Check repo volume info in local directory.
# usage: chk_vol <working directory>
    wkd="$1"
    echo > "$wkd"/repo.vol
    TOTALVOL=0
    # local fnm=$(git ls-files --debug |sed -n 's/\(^[^ ].*\)/\1%/p')
    local fsz=$(git ls-files --debug | sed -n '/size/p' | awk '{print $2}')
    IFS=" " read -a FSZ <<< $(echo $fsz)
    for x in "${!FSZ[@]}";do
        TOTALVOL=$(( $TOTALVOL + ${FSZ[$x]} ))
    done
    TOTALMVOL=$(awk -v x=$TOTALVOL 'BEGIN{printf "%.2f",x/1024/1024}')
    sed -i "1i\Vol: $TOTALVOL bytes, $TOTALMVOL Mbytes" "$wkd"/repo.vol
    sed -i "/^$/d" "$wkd"/repo.vol
}
function pshit {
# arg: file to push to git repo
    src="$1"
    fnm=`basename "$src"`
    dst="./$fnm"
    mv "$src" "$dst"
    # cd $(dirname "$0")
    cd $PWD &&
    bkup_fld "$dst" &&
    chk_vol . &&
    git add "./repo.vol" &&
    git commit -m "repo vol. consumed: ${TOTALMVOL} Mbytes" &&
    git push -f origin master &&
    git rm ./repo.vol
}