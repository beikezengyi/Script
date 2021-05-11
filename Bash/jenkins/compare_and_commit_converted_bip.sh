#!/bin/bash
#-------------------------------------------------------------------------------
# compare_and_commit_converted_bip.sh
#　機能名：指定するブランチ内、前ステップで文字コードなどを変換したのbipファイル
#  を差分取り、差分をsvr-listworks/distへコミットする
#　実行例：jenkinsから呼び出し、手動で実施しないでください
#------------------------------------------------------------------------------
# メッセージ出力関数の定義

#引数１：ブランチsrcフォルダ e.x.:src_release_20210430
#(/usr/share/tomcat/.jenkins/workspace/SCM_BuildUniverse/builduniverse/)

# メッセージ出力関数の定義
#jenkins workspace
buildUniverse_workspace=/usr/share/tomcat/.jenkins/workspace/SCM_BuildUniverse
#buildUniverse_workspace=/share/jenkins
#ダウンロードしたソースフォルダ
branch=$1
src_branch=src_$branch
source_place=$buildUniverse_workspace/builduniverse/$src_branch
bip_cover_log=$buildUniverse_workspace/builduniverse/bin/jenkins/log

logfilename=$bip_cover_log/bip_convert_$(date +%Y%m%d)$(date +%H%M%S).log
error_count=0
modify_count=0

outputMsg() {
  iMSG_DATE=$(date +%Y%m%d)
  iMSG_TIME=$(date +%H%M%S)
  cSCRIPT_NAME=$(basename $0)
  if [ "${1^^}" = "ERROR" ]; then
    error_count=$((error_count + 1))
  fi
  msg="${iMSG_DATE}: ${iMSG_TIME}: ${HOSTNAME}: $$: ${cSCRIPT_NAME}: $1: $2"
  echo $msg
  echo $msg >>$logfilename
}

if [[ ! -d $source_place ]]; then
  outputMsg "Error" "指定しているブランチフォルダが存在しません。先にfetchしてください。"$source_place
  exit 8
fi
#svnw.jar path
svnw_path=$buildUniverse_workspace/builduniverse/bin/svnw/svnw.jar
#svn option
svn_option_auth_admin=" --username admin --password admin"
svn_option_other=" --no-auth-cache --non-interactive"
#svn log limit
svn_log_limit=" --limit 1"
#coverted_bip_online   jenkinsがBIPを変換済みの格納フォルダ（online）
coverted_bip_online=$buildUniverse_workspace/builduniverse/build/forms/01_online
#coverted_bip_batch   jenkinsがBIPを変換済みの格納フォルダ（batch）
coverted_bip_batch=$buildUniverse_workspace/builduniverse/build/forms/02_batch
#BIP変換元　online
before_coverte_bip_online=$source_place/report-form/01_online
#BIP変換元　batch
before_coverte_bip_batch=$source_place/report-form/02_batch

#SVNに保存した変換済み（コミット版）BIP
report_form_bip_converted="$source_place/report-form-bip-converted/dist/var/opt/FJSVoast/assets"
report_form_bip_converted_svn_checkout="$source_place/report-form-bip-converted"
#all diff list

# $1  online | batch
# $2  bip file name
# return 0=same | 1=diff | 2=add | 3=delete
function compare_bip_is_changed() {
  #jenkinsがBIPを変換済みの格納フォルダ
  if [ "$1" = "online" ]; then
    coverted_bip_=$coverted_bip_online
  elif [ "$1" = "batch" ]; then
    coverted_bip_=$coverted_bip_batch
  fi
  coverted_bip_file_path=$coverted_bip_/$2
  #コミット済みBIP
  report_form_bip_converted_file_path=$report_form_bip_converted/$2
  if [ -e $coverted_bip_file_path ] && [ -e $report_form_bip_converted_file_path ]; then
    outputMsg "INFO" "ファイル比較。 diff $coverted_bip_file_path $report_form_bip_converted_file_path"
    diffcount=$(diff $coverted_bip_file_path $report_form_bip_converted_file_path | wc -l)
    if [[ $diffcount -gt 0 ]]; then
      return 1
    else
      return 0
    fi
  elif [ -e $coverted_bip_file_path ] && [ ! -e $report_form_bip_converted_file_path ]; then
    return 2
  elif [ ! -e $coverted_bip_file_path ] && [ -e $report_form_bip_converted_file_path ]; then
    return 3
  else
    outputMsg "Error" "両方存在しません $coverted_bip_file_path and $report_form_bip_converted_file_path"
    exit 8
  fi
}

# $1  online | batch
# $2  bip filename
last_svn_log=""
function get_last_svnlog() {
  last_svn_log=""
  if [ "$1" = "online" ]; then
    before_coverte_bip=$before_coverte_bip_online
  elif [ "$1" = "batch" ]; then
    before_coverte_bip=$before_coverte_bip_batch
  fi
  before_coverte_bip_filename=$before_coverte_bip/$2
  echo before_coverte_bip_filename:$before_coverte_bip_filename
  last_svn_log=$(java -jar $svnw_path log $svn_option_auth_admin$svn_option_other$svn_log_limit $before_coverte_bip_filename || outputMsg "Error" "svnログ取得失敗")
  #余計なハイフンを消す
  last_svn_log="${last_svn_log//------------------------------------------------------------------------/}"
  outputMsg "INFO" "$2 svn log:$last_svn_log"
}

#$1 jenkinsがBIPを変換済みの格納フォルダ
#$2 onlie | batch
function loop_all_bip_files() {
  echo $1
  for filename in $1/*.bip; do
    #svn log clear
    last_svn_log=""
    extracted_filename=$(basename -- "$filename")
    compare_bip_is_changed $2 $extracted_filename
    compare_result=$?
    echo compare_result:$compare_result
    if [ "$compare_result" = "1" ]; then
      outputMsg "INFO" "$extracted_filenameは差分検出されました。"
      echo "cp -pf $filename $report_form_bip_converted" >>$logfilename
      cp -pf $filename $report_form_bip_converted
      copyresult=$?
      if [ ! "$copyresult" = "0" ]; then
        outputMsg "Error" "ファイルコピー失敗。（ブランチが読み取り専用であるかを確認してください。）"
      else
        get_last_svnlog $2 $extracted_filename
        echo_update_svn_log=$last_svn_log >>$logfilename
        #todo commit by echo_update_svn_log
        commit_comment="\"jenkins copied from $branch/src-report/form branch and coverted character code(to UTF-8)."$'\n'$echo_update_svn_log\"
        echo $commit_comment >>$logfilename
        #commit bip filname
        commit_command="java -jar $svnw_path commit $svn_option_auth_admin$svn_option_other $report_form_bip_converted/$extracted_filename -m $commit_comment"
        echo "run command: "$commit_command >>$logfilename
        $commit_command
        commitresult=$?
        if [ ! "$commitresult" = "0" ]; then
          outputMsg "Error" "ファイルコミット(update)失敗。$report_form_bip_converted/$extracted_filename"
        else
          modify_count=$((modify_count + 1))
          outputMsg "COMMIT" "$report_form_bip_converted/$extracted_filenameをコミットしました。"
        fi
      fi
    elif [ "$compare_result" = "2" ]; then
      outputMsg "INFO" "$extracted_filenameは新規追加されました。"
      echo "cp -pf $filename $report_form_bip_converted" >>$logfilename
      cp -pf $filename $report_form_bip_converted
      copyresult=$?
      if [ ! "$copyresult" = "0" ]; then
        outputMsg "Error" "ファイルコピー(update)失敗。（ブランチが読み取り専用であるかを確認してください。）"
      else
        get_last_svnlog $2 $extracted_filename
        echo_update_svn_log=$last_svn_log >>$logfilename
        #todo commit by echo_update_svn_log
        commit_comment="\"jenkins copied from $1 branch and coverted character code(to UTF-8)."$'\n'$echo_update_svn_log\"
        echo $commit_comment >>$logfilename
        #commit bip filname
        svn add $svn_option_auth_admin$svn_option_other $report_form_bip_converted/$extracted_filename
        commit_command="java -jar $svnw_path commit $svn_option_auth_admin$svn_option_other $report_form_bip_converted/$extracted_filename -m $commit_comment"
        echo "run command: "$commit_command >>$logfilename
        $commit_command
        commitresult=$?
        if [ ! "$commitresult" = "0" ]; then
          outputMsg "Error" "ファイルコミット(add)が失敗しました。$report_form_bip_converted/$extracted_filename"
        else
          modify_count=$((modify_count + 1))
          outputMsg "COMMIT" "$report_form_bip_converted/$extracted_filenameを削除しました。"
        fi
      fi
    elif [ "$compare_result" = "3" ]; then
      #前述のフォルダのファイルからloopしているので、ここ通るのはありえない
      outputMsg "ERROR" "内部エラー。$extracted_filename"
    elif [ "$compare_result" = "0" ]; then
      outputMsg "INFO" "$extracted_filenameは差分ありません。"
    fi
  done
}

#/src-report/formから削除したファイルをsvr-listworksから削除する
function check_deleted_bip_file() {
  cd $report_form_bip_converted
  for converted_bip in $report_form_bip_converted/*.bip; do
    extracted_converted_bip_filename=$(basename -- "$converted_bip")
    before_coverte_bip_online_filename=$before_coverte_bip_online/$extracted_converted_bip_filename
    before_coverte_bip_batch_filename=$before_coverte_bip_batch/$extracted_converted_bip_filename
    if [ ! -e $before_coverte_bip_online_filename ] && [ ! -e $before_coverte_bip_batch_filename ]; then
      #削除された判断
      outputMsg "INFO" "$extracted_converted_bip_filenameが削除されました。"
      #todo 削除コメント取得
      #commit bip filname
      commit_comment="\"$branch/src-report/form ブランチと同期する。\""
      echo $commit_comment >> $logfilename
      java -jar $svnw_path delete $svn_option_auth_admin$svn_option_other $report_form_bip_converted/$extracted_converted_bip_filename
      commitresult=$?
      if [ ! "$commitresult" = "0" ]; then
        outputMsg "Error" "ファイル削除(delete)が失敗しました。$report_form_bip_converted/$extracted_converted_bip_filename"
      else
        #commit_command="java -jar $svnw_path commit $svn_option_auth_admin$svn_option_other $report_form_bip_converted_svn_checkout -m $commit_comment"
        commit_command="java -jar $svnw_path commit $svn_option_auth_admin$svn_option_other $report_form_bip_converted/$extracted_converted_bip_filename -m $commit_comment"
        outputMsg "INFO" "run command: "$commit_command
        $commit_command
        commitresult=$?
        if [ ! "$commitresult" = "0" ]; then
          outputMsg "Error" "ファイル削除(delete)が失敗しました。$report_form_bip_converted/$extracted_converted_bip_filename"
        else
          modify_count=$((modify_count + 1))
          outputMsg "COMMIT" "$report_form_bip_converted/$extracted_converted_bip_filenameをコミットしました。"
        fi
      fi
    fi
  done
}

#比較実施main
loop_all_bip_files $coverted_bip_online "online"
loop_all_bip_files $coverted_bip_batch "batch"
check_deleted_bip_file

outputMsg "サマリ" "エラー(Error)件数：$error_count"
outputMsg "サマリ" "同期(COMMIT)件数：$modify_count"
