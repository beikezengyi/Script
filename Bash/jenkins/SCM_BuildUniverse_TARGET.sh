#親jobのSCM_BuildUniverseがコンパイルしたモジュールフォルダ
export compliedDist=/usr/share/tomcat/.jenkins/workspace/SCM_BuildUniverse/builduniverse
#jar,conf関連
ls -lurR $compliedDist/build/dist
ls -lurR $compliedDist/${target_dir}/report-conf
if [[ -e ${WORKSPACE}/dist ]]; then
  rm -rfv ${WORKSPACE}/dist/*
else
  mkdir dist
fi
if [[ -e ${WORKSPACE}/conf ]]; then
  rm -rfv ${WORKSPACE}/conf/*
else
  mkdir conf
fi
cp -R $compliedDist/build/dist/* ./dist
cp -R $compliedDist/${target_dir}/report-conf/* ./conf
#report関連
cp -f $compliedDist/bin/jenkins/defreeze.sh ${WORKSPACE}
#################################################
###########   WEB/AP(jar,conf)   ################
#################################################
whoami
pwd
#stop jboss
sudo /usr/local/script/infra/AlJbsOpe.sh stop
#copy jar resource
sudo cp -f buildUniverse-work/dist/*.*ar /opt/jboss-eap/standalone/deployments
sudo chown jboss:jboss /opt/jboss-eap/standalone/deployments/*
ls -lur /opt/jboss-eap/standalone/deployments/*.*ar
#copy conf file
sudo cp -f buildUniverse-work/conf/*.xml /nfsdata/LC_conf/
#所属をrootに変更
sudo chown root:root /nfsdata/LC_conf/report_online.xml /nfsdata/LC_conf/report_conversion_section_code.xml
#権限を644に変更
sudo chmod 644 /nfsdata/LC_conf/report_online.xml /nfsdata/LC_conf/report_conversion_section_code.xml
ls -lur /nfsdata/LC_conf/*.xml
#start jboss
sudo /usr/local/script/infra/AlJbsOpe.sh start
#################################################
###########    WEB/AP(report)    ################
#################################################
whoami
pwd
cd buildUniverse-work
pwd
sh -x defreeze.sh
rm -f dist/*
#################################################
###########        CSS/AP      ##################
#################################################
whoami
pwd
ls -lurR
#stop jboss
sudo /usr/local/script/infra/AlJbsOpe.sh stop
sudo cp -f buildUniverse-work/dist/*.*ar /opt/jboss-eap/standalone/deployments
sudo chown jboss:jboss /opt/jboss-eap/standalone/deployments/*
ls -lur /opt/jboss-eap/standalone/deployments
sudo cp -f buildUniverse-work/conf/*.xml /css/Batch/Gene/Bin/
sudo chown -R batuser01:batusers /css/Batch/Gene/Bin
sudo chmod 644 /css/Batch/Gene/Bin/*
sudo ls -laRur /css/Batch/Gene/Bin/
#start jboss
sudo /usr/local/script/infra/AlJbsOpe.sh start
#################################################
###########        ONL/AP      ##################
#################################################
whoami
pwd
ls -lurR
#stop jboss
sudo /usr/local/script/infra/AlJbsOpe.sh stop
sudo cp -f buildUniverse-work/dist/*.*ar /opt/jboss-eap/standalone/deployments
sudo chown jboss:jboss /opt/jboss-eap/standalone/deployments/*
ls -lur /opt/jboss-eap/standalone/deployments
#start jboss
sudo /usr/local/script/infra/AlJbsOpe.sh start
#################################################
###########        ONL/BAT     ##################
#################################################
whoami
pwd
ls -lurR
sudo cp -f build-work/conf/*.xml /usr/local/report/resource/
sudo chown root:root /usr/local/report/resource/*
sudo chmod 644 /usr/local/report/resource/*
ls -lur /usr/local/report/resource/
