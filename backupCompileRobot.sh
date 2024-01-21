#! /bin/bash
SRC_PATH="/home/ubuntu/battlecode2023-winter2024/src"
GRADLE_PATH="/home/ubuntu/battlecode2023-winter2024/"
EC2_SYNC_SUBMIT="/home/ubuntu/s3syncfolder"
S3_BUCKET_SUBMIT="s3://battlecodebucket/submissions/"
S3_BUCKET_REPLAY="s3://battlecodebucket/matches/"

submissions=($(aws s3 ls s3://battlecodebucket/submissions/ | awk '{print $(NF)}'))
submissions=("${submissions[@]:1}")
filename=("${submissions[@]%.zip}")
printf "%s " "${filename[@]}"
printf "\n"

aws s3 sync $S3_BUCKET_SUBMIT $EC2_SYNC_SUBMIT
echo "s3 ec2 sync finished"


echo "remove old submissions in src ${SRC_PATH}/*"
rm -r ${SRC_PATH}/*

echo "unzip from EC2_SYNC_SUBMIT to SRC"
for i in "${submissions[@]}"
do
    echo $i
    echo "$SRC_PATH/${i%.zip}/"
    unzip -d $SRC_PATH/${i%.zip}/ -j $EC2_SYNC_SUBMIT/$i
done

RUN_GAME_COMMAND="${GRADLE_PATH}gradlew run"
echo $RUN_GAME_COMMAND

for i in "${!filename[@]}"
do  
   for j in "${!filename[@]}"
   do
      if(($j>$i));then
	flag=" -PteamA=${filename[$i]} -PteamB=${filename[$j]} -Pmaps=CrownJewels"
	echo "running $RUN_GAME_COMMAND $flag"
	$RUN_GAME_COMMAND $flag
      fi
   done
done



