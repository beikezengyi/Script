#このシェルは直接叩くものではなく、jenkins job [SCM_BuildUniverse]に埋めるやつになる
echo $JAVA_HOME
export ANT_OPTS="-Xms1024m -Xmx1024m -Xss128m"
export ANT_HOME=/usr/local/apache-ant-1.10.5
export MAVEN_OPTS="-Dhttps.proxyHost= -Dhttps.proxyPort="
export workdir=$WORKSPACE/builduniverse/bin
whoami
java -version
cd $workdir
pwd
ls -l
#クリア
echo WORKSPACE=$WORKSPACE
if [[ -e $WORKSPACE/builduniverse/build ]]; then
  rm -rf $WORKSPACE/builduniverse/build
fi
#BL関連のZIP削除
rm -rfv $workdir/*.zip

converted_bip_folder=$WORKSPACE/builduniverse/src_$branch/report-form-bip-converted
if [ "$REPORT_BIP_COMMIT" ] && [ -d $converted_bip_folder ]; then
  rm -rf $converted_bip_folder/dist
fi

#ダウンロードソース
$ANT_HOME/bin/ant -f build-jboss7-dep-prefetch.xml -Dbranch=$branch -Dsrc=src_$branch fetch
#環境毎の設定ファイル
case "$target" in
"IT1")
  env_suffix=.test
  ;;
"IT2")
  env_suffix=.test
  ;;
"IT3")
  env_suffix=.test
  ;;
"IT1&IT2")
  env_suffix=.test
  ;;
"IT1&IT2&IT3")
  env_suffix=.test
  ;;
"UT1")
  env_suffix=.dev
  ;;
"UT2")
  env_suffix=.dev
  ;;
"STG1")
  env_suffix=.test
  ;;
"STG2")
  env_suffix=.test
  ;;
"STG1&STG2")
  env_suffix=.test
  ;;
"IT1&IT2&IT3&STG1&STG2")
  env_suffix=.test
  ;;
"BL")
  env_suffix=.prod
  ;;
esac
#コンパイル
$ANT_HOME/bin/ant -f build-jboss7.xml dist "-Denv.suffix=$env_suffix" -Dsrc=src_$branch

ls -l $WORKSPACE/builduniverse/build/dist

#大手町ZIP作成
if [ $target == 'BL' ]; then
  $ANT_HOME/bin/ant -f build-zip.xml -Dsrc=src_$branch
  ls -l $WORKSPACE/*.zip
  #copy file
  export TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
  export zip_target_dir=/share/release/$branch/${TIMESTAMP}_java
  if [ ! -d $zip_target_dir ]; then
    cd /share/release/
    mkdir -p $branch/${TIMESTAMP}_java
  fi
  echo 'copy ZIP file to \\172.29.0.111\common\release\'$branch'\'${TIMESTAMP}_java
  cp -f $WORKSPACE/*.zip $zip_target_dir/
  rm -f $WORKSPACE/*.zip
else
  #帳票サーバへ単独デプロイ
  if "$listWorks"; then
    curl --verbose --user admin:11eaa102c9c1fe311fceb4559003d4d56b -X POST "${JENKINS_URL}job/SCM_BuildUniverse_LW_REPORT/buildWithParameters?target_dir=src_$branch"
  fi

  #deploy function
  #${1} target 環境
  function deploy() {
    curl --verbose --user admin:11eaa102c9c1fe311fceb4559003d4d56b -X POST "${JENKINS_URL}job/SCM_BuildUniverse_${1}/buildWithParameters?target_dir=src_$branch"
  }

  if [[ $target == *"&"* ]]; then
    IFS='&' eval 'array=($target)'
    for i_env in "${array[@]}"; do
      :
      deploy $i_env
    done
  elif [[ ! $target = "NONE" ]]; then
    deploy $target
  fi

  #帳票サーバへ単独デプロイ
  if "$REPORT_BIP_COMMIT"; then
    #REPORT_BIP_COMMITをチェックすると、jenkinsが文字コードを変換した帳票BIPファイルを
    #ブランチ配下の/svr-listworksフォルダの.bipと同期して、コミットまで実施する。
    $workdir/jenkins/compare_and_commit_converted_bip.sh $branch
  fi
fi
