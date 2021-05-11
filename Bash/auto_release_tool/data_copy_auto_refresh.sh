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
#受入環境      p_atafcdb_ap"
it3_afc="user/pass@xxx.xxx.xx.xx:1729/p_itafcdb3_ap"
#受入環境      p_atanadb_ap" 
it3_ana="user/pass@xxx.xxx.xx.xx:1730/p_itanadb3_ap"
#統合テスト環境２
jstg2_afc="user/pass@xxx.xxx.xx.xx:1726/p_ahafcdb2_ap"
#統合テスト環境２
jstg2_ana="user/pass@xxx.xxx.xx.xx:1727/p_ahanadb2_ap"


#データコピーのダンプ、ＰＡＲの保存ＤＩＲ
dc_bin=/u01/app/oracle/oradata-local/DataCopy/bin
dmp_par_dir=/u01/app/oracle/oradata-local/DataCopy/impdp
_refresh_sql=${dc_bin}/dc_refresh_mview_$2.sql

release_env=$1_$2
conn_info=`echo "${!release_env}"`
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
logname=$dmp_par_dir/${release_env}_refresh_$TIMESTAMP.log

outputMsg() {
  iMSG_DATE=$(date +%Y%m%d)
  iMSG_TIME=$(date +%H%M%S)
  cSCRIPT_NAME=$(basename $0)
  msg="${iMSG_DATE}: ${iMSG_TIME}: ${HOSTNAME}: $$: ${cSCRIPT_NAME}: $1: $2"
  echo $msg
  echo $msg >> $logname
}

#ディレクトリ作成
outputMsg "INFO" "$release_env環境にマテビューリフレッシュ開始"
sqlplus $conn_info @$_refresh_sql >> $logname
result=`grep ORA $logname | wc -l`
if [[ $result -gt 0 ]] ; then
  outputMsg "ERROR" "$release_envにマテビューリフレッシュ失敗"
  exit 10
else
  outputMsg "INFO" "$release_envにマテビューリフレッシュ成功"
fi