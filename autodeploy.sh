#!/bin/bash
REPO_URL="https://github.com/AnchorFree/ansible-hss-u2"
USER=$(whoami)
INVETORY="inventory"
SET_TAG=""
now=$(date +%Y%m%d-%H%M)
PLAYBOOK="playbook-$now.retry"
GIT_KEY="/home/$USER/hssunified-ubuntu.key"
host=$1
#TODO сделать поддерку множественных хостнеймов
#TODO разобраться с поиском ключа
#TODO имена для логов и репозиториев
function deployment(){
  repodir=ansible-hss-u2-$now
  LOG_FILE=$repodir/deploy-$now.txt
  git clone $REPO_URL $repodir | tee -a $LOG_FILE
  cd $repodir
  git fetch --tags | tee -a $LOG_FILE
  LATEST_TAG=$(git describe --tags $(git rev-list --tags --max-count=1))
  echo "Latest tag:"$LATEST_TAG
  if [ -z "$SET_TAG" ];then
    $TAG=$LATEST_TAG
  else
    echo "Select tag/branch: $SET_TAG"
    $TAG=$SET_TAG
  fi
  git checkout $TAG | tee -a $LOG_FILE
  git submodule update --init --recursive | tee -a $LOG_FILE
  git-crypt unlock $GIT_KEY | tee -a $LOG_FILE
  # show latest commit
  git log -1 | tee -a $LOG_FILE
  cd roles/common
  git log -1 | tee -a $LOG_FILE
  git-crypt unlock $GIT_KEY | tee -a $LOG_FILE
  cd ../../
  sed '/serial:.*/d' playbook.yml > $PLAYBOOK
  ansible-playbook -i $INVETORY --skip packer $PLAYBOOK  -e "ansible_user=$USER" --limit=$HOST  | tee -a $LOG_FILE
}

while [[ $# -gt 0 ]];do
  case $1 in
    -u|--user)
        USER=$2
        shift 2
        ;;
    -i|--inventory)
        INVETORY=$2
        shift 2
        ;;
    -t|--tag)
        SET_TAG=$2
        shift 2
        ;;
    *)
        HOST=$1
        shift
        ;;
  esac
done

deployment
