#!/bin/bash


#$1:env=ut1 | it1 | it2 | etc
#$2:afc | ana
#$3 optional: nohup要(任意を指定する場合はインスタンス内のスキーマを一斉にimpdp、省略する場合はスキーマ順番で行う)

#統合テスト環境p_ahafcdb_ap"
jstg1_afc="user/pass@xxx.xxx.xx.xx:1711/p_ahafcdb_ap"
#統合テスト環境p_ahanadb_ap"
jstg1_ana="user/pass@xxx.xxx.xx.xx:1712/p_ahanadb_ap"
#結合テスト１  p_itafcdb1_ap"
it1_afc="user/pass@xxx.xxx.xx.xx:1713/p_itafcdb1_ap"
#結合テスト１  p_itanadb1_ap"
it1_ana="user/pass@xxx.xxx.xx.xx:1714/p_itanadb1_ap"
#結合テスト２  p_itafcdb2_ap"
it2_afc="user/pass@xxx.xxx.xx.xx:1715/p_itafcdb2_ap"
#結合テスト２  p_itanadb2_ap"
it2_ana="user/pass@xxx.xxx.xx.xx:1716/p_itanadb2_ap"
#開発①環境    p_dvafcdb1_ap"
ut1_afc="user/pass@xxx.xxx.xx.xx:1717/p_dvafcdb1_ap"
#開発①環境    p_dvanadb1_ap"
ut1_ana="user/pass@xxx.xxx.xx.xx:1718/p_dvanadb1_ap"
#結合テスト3 afc
it3_afc="user/pass@xxx.xxx.xx.xx:1729/p_itafcdb3_ap"
#結合テスト3 ana
it3_ana="user/pass@xxx.xxx.xx.xx:1730/p_itanadb3_ap"
#統合テスト環境２
jstg2_afc="user/pass@xxx.xxx.xx.xx:1726/p_ahafcdb2_ap"
#統合テスト環境２
jstg2_ana="user/pass@xxx.xxx.xx.xx:1727/p_ahanadb2_ap"


#データコピーのダンプ、ＰＡＲの保存ＤＩＲ
dmp_par_dir=/u01/app/oracle/oradata-local/DataCopy/impdp
dc_bin=/u01/app/oracle/oradata-local/DataCopy/bin

release_env=$1_$2
conn_info=`echo "${!release_env}"`
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
logname=$dmp_par_dir/${release_env}_$TIMESTAMP.log

outputMsg() {
  iMSG_DATE=$(date +%Y%m%d)
  iMSG_TIME=$(date +%H%M%S)
  cSCRIPT_NAME=$(basename $0)
  msg="${iMSG_DATE}: ${iMSG_TIME}: ${HOSTNAME}: $$: ${cSCRIPT_NAME}: $1: $2"
  echo $msg
  echo $msg >> $logname
}

#ディレクトリ作成
sqlplus $conn_info @$dc_bin/CREATE_DIRECTORY_DIR_DC_IMP_TEMP.sql >> $logname
result=`grep ORA $logname | wc -l`
if [[ $result -gt 0 ]] ; then
  outputMsg "ERROR" "$release_envにディレクトリ作成失敗"
  exit 10
else
  outputMsg "INFO" "$release_envにディレクトリ作成成功"
fi

#impdp
ALIAS_SID=${2^^}
cd $dmp_par_dir

#directory           = DIR_DC_IMP_TEMP
#dumpfile            = AFC.AFC.maskdata.dmp
#logfile             = it1.AFC.AFC.maskdata.import.log
#content             = data_only
#remap_schema        = DCUSR:AFC
#table_exists_action = truncate

for dumpfile in $ALIAS_SID.*.maskdata.dmp
do  
    #空白分けて、arrayへ代入
    IFS='.' eval 'array=($dumpfile)'
    schema=${array[1]}
    each_impdp_log=${release_env}_${schema}_$TIMESTAMP.maskdata.import.log
    impdp_option="directory=DIR_DC_IMP_TEMP dumpfile=$dumpfile logfile=$each_impdp_log"
    impdp_option=$impdp_option" content=data_only remap_schema=DCUSR:$schema table_exists_action=TRUNCATE"
    #impdp_option=$impdp_option" content=data_only table_exists_action=TRUNCATE"
    command="impdp ${conn_info} $impdp_option"
    echo $command
    outputMsg "INFO" "コマンド："$impdp_option
    if [ -n "$3" ]; then
      $command &
      outputMsg "INFO" "[$1環境の$2インスタンスの$schemaスキーマのインポートをバックグラウンドで起動しました,LOG=$each_impdp_log]"
    else
      outputMsg "INFO" "[$1環境の$2インスタンスの$schemaスキーマのインポートを起動しました,LOG=$each_impdp_log]"
      $command
      rc=$?
      impdp_result=`grep ORA $each_impdp_log`
      impdp_ORA_count=`echo $impdp_result | wc -l`
      if [[ ! "$impdp_ORA_count" = "0" ]] ; then
        outputMsg "ERROR" "$impdp_result"
      fi
      if [ $rc -ne 0 ]; then
          outputMsg "ERROR" "[$1環境の$2インスタンスの$schemaスキーマのインポートにエラーがありました"
          exit 10
      else
          outputMsg "INFO" "[$1環境の$2インスタンスの$schemaスキーマのインポートは完了しました]"
      fi
    fi
done

#ディレクトリ削除
if [ ! -n "$3" ]; then
  sqlplus $conn_info @$dc_bin/DROP_DIRECTORY_DIR_DC_IMP_TEMP.sql >> $logname
  result=`grep ORA $logname | wc -l`
  if [[ $result -gt 0 ]] ; then
    outputMsg "ERROR" "$release_envにディレクトリ削除失敗"
    exit 10
  else
    outputMsg "INFO" "$release_envにディレクトリ削除成功"
  fi
else
  outputMsg "WARN" "$release_envにディレクトリ削除をskipしました。impdp完了後手動で削除してください。"
fi