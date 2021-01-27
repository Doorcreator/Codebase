# $PWD must be a local git repo like /d/local/repo/git
function retro_bkp {
# Use GPG uid <$3> to encrypt all files modified before specified date <$2> in directory <$1> and back them up to a remote git repo
    local src="$1"
    local tmr="$2"
    local ext="$3"
    local vol="$4"
    local dst="$src""_flt"
    local uid="$5"
    local tdy=
    local dstx="$dst"_"$(date +'%Y%m%d')".7z.gpg
    . "$PWD"/fltdir.sh
    . "$PWD"/zip_encrypt_dir.sh
    . "$PWD"/git_enc_push.sh
    fltdir -d "$src" -t "$tmr" -x "$ext" -v "$vol" &&
    zip_enc "$dst" "$uid" &&
    rm -rf "$dst" &&
    pshit "$dstx"
}
# cd "/f/pythonx/git" && . retro_bkp.sh
retro_bkp "/F/dload/test" "2010-01-01 00:00:00, 2029-12-31 23:59:59" "sdltm,tmx,sdltb,sdlxliff,xlf,sdlproj,pdf,doc,docx,txt,xlsx,xls,ppt,pptx,sql,rar,torrent,pyc,mobi" 5 "Oliver Yuan"
