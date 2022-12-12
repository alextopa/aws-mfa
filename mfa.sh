#!/bin/bash

# Create ~/.aws directory if it does not exist

if [[ ! -e ~/.aws ]]
then
        mkdir ~/.aws
fi

cd ~/.aws

function credentials {

	varl=()
	if ! [[ $1 == "" ]]
	then
        	varl=(".$1")
	fi

	touch credentials$valr
	echo "[default]" >> credentials$varl
	echo -n "aws_access_key_id = " >> credentials$varl
	read -p "Please provide Aws Access Key Identifier = " ak
	echo $ak >> credentials$varl
	echo -n "aws_secret_access_key = " >> credentials$varl
	read -p "Please provide Secret Aws Access Key Identifier = " sak
	echo $sak >> credentials$varl

}


if [[ ! -f ~/.aws/credentials ]]
then
	credentials
fi


arr=( $(ls ~/.aws | grep credentials | grep -v bak | grep -v original | grep -v credentials$ | awk -F'[.]' '{ print $2}') )

#echo ${arr[@]}

if [ $# -eq 0 ]
then
	if [[ ${#arr[@]} -lt 2 ]]
	then
		company="default"
		if [[ ${#arr[@]} -eq 0 ]]
		then
        		cp credentials credentials.$company		
		fi
	else
        	for (( i=0; i<${#arr[@]}; i++ ));
        	do
                	j=$(( $i+1 ))
                	echo $j"."${arr[$i]}
        	done

        	while true
        	do
			read -p 'Please provide the company: ' company_index
                	if ! [[ "$company_index" =~ ^[0-9]+$ ]] ;
                	then
                        	echo "Select a valid option between 1 and ${#arr[@]}" 
                	else
                        	if [ $((10#$company_index)) -gt 0 ] && [ $((10#$company_index)) -lt $(( ${#arr[@]}+ 1 )) ]
                        	then
                                	break
                        	fi
                	fi
        	done

		company="${arr[$(( $((10#$company_index)) - 1 ))]}"
        	echo "You have selected $company"

	fi
fi

while test $# -gt 0; 
do
	case "$1" in
		-h|--help)
			
			echo "-h, --help                show brief help"
      			echo "-a, --company [name]	add a new company"
			echo "Using the script without a flag will run as default"
			
			exit 0
      			;;
		
		-a|--company)
			shift
			if [[ $1 == "" ]]
			then
				echo "Please provide a company after [-a] or [--company]"
				exit 1
			fi
			company=$1
			arrt=( $(ls ~/.aws | grep credentials | grep -v bak | grep -v original | grep -v credentials$ | awk -F'[.]' '{ print $2}' | grep ^$company | grep $company$) )
			if [[ ${#arrt[@]} -eq 0 ]]
			then
        			echo 'Company is not present'
				credentials $company        			
			fi

			shift

			;;

		*)
			echo 'The argument provided does not coincide with the script'
			exit 1
			;;
	esac
done  
function mfa {

while true
do
	read -p "Please provide the MFA token [0-9]: " token
        if ! [[ "$token" =~ ^[0-9]{6}$ ]] ;
        then
        	echo "The MFA security token is a number";
       	else
               	break
        fi
done



echo "Backing up credentials file in case you did not read the README file"
if [[ ! -f credentials.$company.bak ]]
then
        cp $PWD/credentials.$company $PWD/credentials.$company.bak
fi

if [[ -f credentials.$company.original ]]
then
        cp $PWD/credentials.$company.original $PWD/credentials
else
        cp $PWD/credentials.$company $PWD/credentials.$company.original
        cp $PWD/credentials.$company $PWD/credentials
fi
device=`aws iam list-mfa-devices --query 'MFADevices[*].SerialNumber' --output text`
$(which aws) sts get-session-token --serial-number $device --token-code $token \
--query "Credentials.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey,SessionToken:SessionToken}"  > json


if [[ ! -s json ]];
then
        echo "Probably the retrieval of session token failed. Exiting"
        exit 0
else
OS="$(uname -s)"
case "${OS}" in
        Darwin*)
                echo "Working on MacOS"
                sed -i '' '/^{/ d' json
                sed -i '' '/^}/ d' json
            sed -i '' 's/^[ \t]*//g' json
                sed -i '' 's/\",//g' json
                sed -i '' 's/\"$//g' json
                sed -i '' 's/\"SecretAccessKey\": \"/aws_secret_access_key = /g' json
                sed -i '' 's/\"SessionToken\": \"/aws_session_token = /g' json
                sed -i '' 's/\"AccessKeyId\": \"/aws_access_key_id = /g' json
                sed -i '' '
                   /^\[default/,/\$/ {
                    s/^\[default.*//p;d
                  }
                                ' credentials
                sed -i '' $'s/\r//' credentials
                echo "[default]" >> credentials
                ;;
Linux*)
                echo "Working on Linux. You're awesome"
                sed -i '/^{/ d' json
                sed -i '/^}/ d' json
                sed -i 's/^[ \t]*//g' json
                sed -i 's/\",//g' json
                sed -i 's/\"$//g' json
                sed -i 's/\"SecretAccessKey\": \"/aws_secret_access_key = /g' json
                sed -i 's/\"SessionToken\": \"/aws_session_token = /g' json
                sed -i 's/\"AccessKeyId\": \"/aws_access_key_id = /g' json
                sed -i '
                        /^\[default/,/\$/ {
                    s/^\[default.*//p;d
                        }
                ' credentials

                sed -i '${/^$/d}' credentials
                echo "[default]" >> credentials
                ;;
        *)
                echo "OS not supported. Please use a decent OS."
      esac
   cat json >> credentials

   cat credentials
   rm json
fi


}

mfa

