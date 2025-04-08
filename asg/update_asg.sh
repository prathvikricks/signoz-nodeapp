#!/bin/bash

# =====================================
# Configuration Variables - EDIT THESE
# =====================================
LAUNCH_TEMPLATE_ID="lt-05ac0bc20a0fdd524"   # Your Launch Template ID
LAUNCH_TEMPLATE_NAME="ci-cd-temp" # Optional: Used for naming new LT versions
ASG_NAME="ci-cd-ASG"     # Name of the Auto Scaling Group

# =====================================
# Internal Settings (No need to edit)
# =====================================
export AWS_PAGER=""

# =====================================
# Function Definitions
# =====================================

handle_error() {
    echo "❌ Error: $1"
    exit 1
}

check_status() {
    if [ $? -ne 0 ]; then
        handle_error "$1"
    fi
}

wait_for_ami() {
    local ami_id=$1
    echo "⏳ Waiting for AMI $ami_id to be available..."
    aws ec2 wait image-available --image-ids "$ami_id" || handle_error "AMI creation failed or timed out"
}

get_instance_details() {
    echo "🔍 Fetching instance details from ASG: $ASG_NAME"

    INSTANCE_ID=$(aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-name "$ASG_NAME" \
        --query 'AutoScalingGroups[0].Instances[0].InstanceId' \
        --output text)

    if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
        handle_error "No instance found in ASG"
    fi

    INSTANCE_NAME=$(aws ec2 describe-tags \
        --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Name" \
        --query 'Tags[0].Value' \
        --output text)

    if [ -z "$INSTANCE_NAME" ] || [ "$INSTANCE_NAME" == "None" ]; then
        INSTANCE_NAME="asg-instance"
    fi

    echo "✅ Instance ID: $INSTANCE_ID"
    echo "✅ Instance Name: $INSTANCE_NAME"
}

wait_for_asg_instances() {
    local desired_count=$1
    local max_attempts=30
    local attempt=1
    echo "⏳ Waiting for ASG to reach $desired_count instance(s)..."

    while [ $attempt -le $max_attempts ]; do
        local running_count=$(aws autoscaling describe-auto-scaling-groups \
            --auto-scaling-group-name "$ASG_NAME" \
            --query 'AutoScalingGroups[0].Instances[?LifecycleState==`InService`].InstanceId' \
            --output text | wc -w)

        if [ "$running_count" -eq "$desired_count" ]; then
            echo "✅ ASG reached desired capacity"
            return 0
        fi

        echo "🔁 Attempt $attempt/$max_attempts: Running instances = $running_count"
        sleep 10
        attempt=$((attempt + 1))
    done

    handle_error "ASG did not reach desired capacity in time"
}

# =====================================
# Main Execution
# =====================================

if [ -z "$LAUNCH_TEMPLATE_ID" ] || [ -z "$ASG_NAME" ]; then
    handle_error "Missing required configuration values at the top of the script"
fi

echo "🚀 Starting ASG update process..."

CURRENT_DATE=$(date +%Y-%m-%d)
get_instance_details

echo "📸 Creating AMI from instance $INSTANCE_ID..."
AMI_ID=$(aws ec2 create-image \
    --instance-id "$INSTANCE_ID" \
    --name "${INSTANCE_NAME}_${CURRENT_DATE}" \
    --no-reboot \
    --query 'ImageId' \
    --output text)

check_status "Failed to create AMI"
echo "✅ AMI created: $AMI_ID"

wait_for_ami "$AMI_ID"
echo "✅ AMI is available"

echo "🆕 Creating new Launch Template version..."
aws ec2 create-launch-template-version \
    --launch-template-id "$LAUNCH_TEMPLATE_ID" \
    --version-description "${LAUNCH_TEMPLATE_NAME}_${CURRENT_DATE}" \
    --source-version "\$Latest" \
    --launch-template-data "{\"ImageId\":\"$AMI_ID\"}"

check_status "Failed to create new launch template version"

echo "✅ Setting new version as default..."
aws ec2 modify-launch-template \
    --launch-template-id "$LAUNCH_TEMPLATE_ID" \
    --default-version "\$Latest"

check_status "Failed to update launch template default version"

echo "📈 Scaling up ASG to 2 instances..."
aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name "$ASG_NAME" \
    --desired-capacity 2

check_status "Failed to scale up ASG"
wait_for_asg_instances 2

echo "📉 Scaling down ASG to 1 instance..."
aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name "$ASG_NAME" \
    --desired-capacity 1

check_status "Failed to scale down ASG"
wait_for_asg_instances 1

echo "🎉 ASG update complete!"
echo "🔹 AMI: $AMI_ID"
echo "🔹 Launch Template: $LAUNCH_TEMPLATE_ID"
echo "🔹 ASG: $ASG_NAME"
