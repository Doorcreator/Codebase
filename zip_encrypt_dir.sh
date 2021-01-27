function zip_enc {
# Compress a directory/file with 7-zip and encrypt it with GPG
# arg 1: directory/file to be compressed and encrypted
# arg 2: GPG user id
    local src_dir="$1"
    local tdy="$(date +'%Y%m%d')"
    local dst_dir="$src_dir"_"$tdy".7z
    uid="$2"
    7z a -mx=5 "$dst_dir" "$src_dir" &&
    gpg -e --armor -o "$dst_dir".gpg -r "$uid" "$dst_dir" &&
    7z l -ba "$dst_dir" &&
    rm -f "$dst_dir"
}
function dec_unzip {
# Decrypt a file with GPG and decompress it with 7-zip
# arg 1: directory/file to be decrypted and decompressed
# arg 2: GPG user id
    src_dir="$1"
    temp_dir=${src_dir/%".gpg"/""}
    dst_dir=${temp_dir/%".7z"/""}
    uid="$2"
    gpg -d -o "$temp_dir" -r "$uid" "$src_dir"  &&
    7z x "$temp_dir" -o"$dst_dir"
    if [ $? -eq 0 ];then
        rm -f "$temp_dir"
    fi
}