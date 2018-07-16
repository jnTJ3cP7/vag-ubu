#!/bin/bash

case $# in
	0)
		echo 'USER NAME is not specified'
		exit 1
		;;
	1|2)
		USER_NAME=$1
		HOME_DIR=`eval echo ~$USER_NAME`
		if [ $# -eq 1 ]; then
			DYNAMODB_MEMORY=$HOME_DIR
		else
			DYNAMODB_MEMORY=$2
			if [ ! -d $DYNAMODB_MEMORY ]; then
				echo "The directory that does not exist is specified [ $DYNAMODB_MEMORY ]"
				exit 1
			fi
		fi
		echo "The user that runs DynamoDB process is [ $USER_NAME ]"
		echo "DynamoDB memory is saved in [ $DYNAMODB_MEMORY ]"
		;;
	*)
		echo 'Unexpected params exist'
		exit 1
		;;
esac

DYNAMODB_BASE=`eval echo ~${USER_NAME}/.dynamodb`
su -c "java -Djava.library.path=${DYNAMODB_BASE}/DynamoDBLocal_lib -jar ${DYNAMODB_BASE}/DynamoDBLocal.jar -dbPath $DYNAMODB_MEMORY -sharedDb &" - $USER_NAME

su -c "dynamodb-admin &" - $USER_NAME
