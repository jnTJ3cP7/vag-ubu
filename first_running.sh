#!/bin/bash

# params check
# arg 1 is USER on vagrant operation
case $# in
	0)
		echo 'USER NAME is not specified'
		exit 1
		;;
	1)
		USER_NAME=$1
		echo "Guest user is [ $USER_NAME ]"
		;;
	*)
		echo 'Unexpected params exist'
		exit 1
		;;
esac

update-locale LC_ALL=C.UTF-8
timedatectl set-timezone Asia/Tokyo

# pip for some apps, jre for DynamoDB, node, for dynamodb-admin and docker install preparation
apt update
apt install -y \
	python3-pip \
	unzip \
	openjdk-8-jre \
	nodejs \
	npm \
	apt-transport-https \
	ca-certificates \
	curl \
	software-properties-common

su -c 'pip3 install awscli aws-sam-cli docker-compose --upgrade --user' - $USER_NAME

# docker installation
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
	"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) \
	stable"
apt-get update
apt-get install -y docker-ce

# no sudo docker execution modification for vagrant operation USER
gpasswd -a $USER_NAME docker
service docker restart

HOME_DIR=`eval echo ~$USER_NAME`

# DynamoDB settings
DYNAMODB_BASE="${HOME_DIR}/.dynamodb"
su -c "mkdir ${DYNAMODB_BASE}" - $USER_NAME
su -c "curl  https://s3-ap-northeast-1.amazonaws.com/dynamodb-local-tokyo/dynamodb_local_latest.zip -o ${DYNAMODB_BASE}/dynamodb_local_latest.zip" - $USER_NAME
su -c "unzip ${DYNAMODB_BASE}/dynamodb_local_latest.zip -d ${DYNAMODB_BASE} && rm -f ${DYNAMODB_BASE}/dynamodb_local_latest.zip" - $USER_NAME
npm install -g dynamodb-admin
echo 'export DYNAMO_ENDPOINT=http://localhost:8000' >>  ${HOME_DIR}/.bashrc

# AWS settings for local
su -c "mkdir ${HOME_DIR}/.aws" - $USER_NAME
su -c "echo '[default]' > ${HOME_DIR}/.aws/config" - $USER_NAME
echo 'region=' >> ${HOME_DIR}/.aws/config
su -c "echo '[default]' > ${HOME_DIR}/.aws/credentials" - $USER_NAME
echo 'aws_access_key_id=' >> ${HOME_DIR}/.aws/credentials
echo 'aws_secret_access_key=' >> ${HOME_DIR}/.aws/credentials

# AWS CodeBuild settings to execute in local
su -c "git clone https://github.com/aws/aws-codebuild-docker-images.git --depth 1" - $USER_NAME
# example usage in vagrant
# codebuildimage python 3.6.5
cat <<-'EOF' >> $HOME_DIR/.bashrc
codebuildimage () {
  docker build -t aws/codebuild/$1:$2 $HOME/aws-codebuild-docker-images/ubuntu/$1/$2
}
EOF
docker pull amazon/aws-codebuild-local:latest --disable-content-trust=false
# example usage in vagrant
# codebuildexec python 3.6.5
cat <<-'EOF' >> $HOME_DIR/.bashrc
codebuildexec () {
  docker run \
    -it -v /var/run/docker.sock:/var/run/docker.sock \
    -e "IMAGE_NAME=aws/codebuild/$1:$2" \
    -e "ARTIFACTS=/tmp" \
    -e "SOURCE=$PWD" \
    amazon/aws-codebuild-local
}
EOF

# ToDo: use `which aws_completer`
echo 'complete -C "${HOME}/.local/bin/aws_completer" aws' >> $HOME_DIR/.bashrc

npm install -g json-server
apt install -y redis-tools
