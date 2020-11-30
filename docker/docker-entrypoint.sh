#!/bin/bash
# inject config data into container
# auto find jar to bootup
# author jimminh@163.com

set -e

THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

if [[ -f /usr/share/zoneinfo/Asia/Shanghai ]];then
  echo "TZ set to Asia/Shanghai"
  ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
  export TZ="Asia/Shanghai"
else
  echo "warn: no tzdata"
fi


mkdir -p /cfg/
if [[ -f /cfg/env.txt ]]; then
    echo "/cfg/env.txt mounted"
    set -a # automatically export all variables
    . /cfg/env.txt
    set +a
    echo "import  $(wc -l /cfg/env.txt) env vars from /cfg/env.txt done"
else
    echo "/cfg/env.txt not found!"
fi
if [[ -f ${SCRIPT_DIR}/initdata/init.sh ]]; then
    echo "${SCRIPT_DIR}/initdata/init.sh"
    sh "${SCRIPT_DIR}/initdata/init.sh"
fi
if [[ -z ${HOSTNAME} ]];then
    HOSTNAME=no-name-service
fi

K8S_NS_FILE="/var/run/secrets/kubernetes.io/serviceaccount/namespace"
if [[ -f ${K8S_NS_FILE} ]];then
K8S_NS=`head -n 1 ${K8S_NS_FILE}`
else
K8S_NS="cant-get-ns"
fi
SVC_NAME=`echo ${K8S_NS}.${HOSTNAME} | rev | cut -d'-'  -f 3- | rev`
MY_K8S_NS=${K8S_NS}
MY_K8S_SVC_NAME=$(echo ${SVC_NAME} | awk -F. '{print $NF}')
echo "SVC_NAME=${SVC_NAME}"
echo "MY_K8S_NS=${MY_K8S_NS}"
echo "MY_K8S_SVC_NAME=${MY_K8S_SVC_NAME}"
export MY_K8S_NS
export MY_K8S_SVC_NAME

echo "please mount your yearning's conf.toml into container path: ${SCRIPT_DIR}/conf.toml"
if [[ ! -f ${SCRIPT_DIR}/conf.toml ]];then
echo "auto generate default conf.toml from Enviroment variable!"
cat >> ${SCRIPT_DIR}/conf.toml <<EOF
[Mysql]
Db = "${MYSQL_DB:-yearningdb}"
Host = "${MYSQL_HOST:-mysql}"
Port = "${MYSQL_PORT:-3306}"
Password = "${MYSQL_PASSWORD}"
User = "${MYSQL_USER:-yearning}"

[General]
SecretKey = "dbcjqheupqjsuwsm"
GrpcAddr = "127.0.0.1:50001"
EOF

fi

set -x
set +e
 /yearning -m
set -e
 /yearning -s -p "8080" -f admin -c ${SCRIPT_DIR}/conf.toml
