#! /bin/bash
SRC_PATH="/home/ubuntu/battlecode2023-winter2024/src"
GRADLE_PATH="/home/ubuntu/battlecode2023-winter2024/"

EC2_SYNC_SUBMIT="/home/ubuntu/s3syncfolder"
S3_BUCKET_SUBMIT="s3://battlecodebucket/submissions/"
S3_BUCKET_REPLAY="s3://battlecodebucket/matches/"
EC2_EXTRACTED="/home/ubuntu/extractedfolder"
EC2_REPLAY="/home/ubuntu/battlecode2023-winter2024/matches"

submissions=($(aws s3 ls s3://battlecodebucket/submissions/ | awk '{print $(NF)}'))
submissions=("${submissions[@]:1}")
filename=("${submissions[@]%.zip}")
printf "%s " "${filename[@]}"
printf "\n"

aws s3 sync $S3_BUCKET_SUBMIT $EC2_SYNC_SUBMIT
echo "s3 ec2 sync finished"


echo "remove old submissions in src ${SRC_PATH}/*"
rm -r ${SRC_PATH}/*

echo "remove old files in $EC2_EXTRACTED"
rm -r $EC2_EXTRACTED/*

echo "unzip from EC2_SYNC_SUBMIT to extractedfolder and change package name"
for i in "${submissions[@]}"
do
    original=($(unzip -qql ${EC2_SYNC_SUBMIT}/$i | head -n1 | awk '{print $4}'))
    original=(${original%/})
    echo $original

    unzip -d $EC2_EXTRACTED/${i%.zip}/ -j ${EC2_SYNC_SUBMIT}/$i
    current=${i%.zip}
    echo $current

    find $EC2_EXTRACTED/${i%.zip} -type f -name '*.java' -print -exec sed -i "s/^package\ *$original/package $current/g" {} \;
    cp -r $EC2_EXTRACTED/$current $SRC_PATH
done

# unzip -d $SRC_PATH/${i%.zip}/ -j $EC2_SYNC_SUBMIT/$i

RUN_GAME_COMMAND="${GRADLE_PATH}gradlew run"
echo $RUN_GAME_COMMAND

# : <<'END_COMMENT'
for i in "${!filename[@]}"
do  
   for j in "${!filename[@]}"
   do
      if(($j>$i));then
	flag="-PteamA=${filename[$i]} -PteamB=${filename[$j]} -Pmaps=CrownJewels"
	echo "running $RUN_GAME_COMMAND $flag"
	$RUN_GAME_COMMAND $flag
      fi
   done
done
#END_COMMENT

echo "syncing replays from EC2 to S3"
aws s3 sync $EC2_REPLAY $S3_BUCKET_REPLAY
