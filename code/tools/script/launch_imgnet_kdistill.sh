platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
   platform='linux'
elif [[ "$unamestr" == 'Darwin' ]]; then
   platform='darwin'
fi


# 1-100: g3.4
# 101-200: p2
# AMI="ami-660ae31e"
AMI="ami-a577d6dd" #extract
#INSTANCE_TYPE="p2.xlarge"
INSTANCE_TYPE="g3.4xlarge"
#INSTANCE_TYPE="c3.2xlarge"
INSTANCE_COUNT=1
KEY_NAME="taskonomy"
SECURITY_GROUP="launch-wizard-1"
SPOT_PRICE=1.001
ZONE="us-west-2"
SUB_ZONES=( a b c )

# 11 - X
START_AT=1
EXIT_AFTER=1000

COUNTER=0
#for src in $SRC_TASKS; do
for idx in {0..198..2}; do
    COUNTER=$[$COUNTER +1]
    SUB_ZONE=${SUB_ZONES[$((COUNTER%3))]}
    if [ "$COUNTER" -lt "$START_AT" ]; then
        echo "Skipping at $COUNTER (starting at $START_AT)"
        continue
    fi
    echo "running $COUNTER"

    if [[ "$platform" == "linux" ]];
    then
        OPTIONS="-w 0"
        ECHO_OPTIONS="-d"
    else
        OPTIONS=""
        ECHO_OPTIONS="-D"
    fi

    USER_DATA=$(base64 $OPTIONS << END_USER_DATA
export INSTANCE_TAG="${idx}"
export HOME="/home/ubuntu"
export ACTION=IMAGENET_KDISTILL;

cd /home/ubuntu/task-taxonomy-331b
git stash
git remote add autopull https://alexsax:328d7b8a3e905c1400f293b9c4842fcae3b7dc54@github.com/alexsax/task-taxonomy-331b.git
git pull autopull perceptual-transfer
git pull autopull perceptual-transfer

END_USER_DATA
)
    echo "$USER_DATA" | base64 $ECHO_OPTIONS

    sleep 1
    aws ec2 request-spot-instances \
    --spot-price $SPOT_PRICE \
    --instance-count $INSTANCE_COUNT \
    --region $ZONE \
    --launch-specification \
        "{ \
            \"ImageId\":\"$AMI\", \
            \"InstanceType\":\"$INSTANCE_TYPE\", \
            \"KeyName\":\"$KEY_NAME\", \
            \"SecurityGroups\": [\"$SECURITY_GROUP\"], \
            \"UserData\":\"$USER_DATA\", \
            \"Placement\": { \
              \"AvailabilityZone\": \"us-west-2${SUB_ZONE}\" \
            } \
        }"

    if [ "$COUNTER" -ge "$EXIT_AFTER" ]; then
        echo "EXITING before $COUNTER (after $EXIT_AFTER)"
        break
    fi
    done


