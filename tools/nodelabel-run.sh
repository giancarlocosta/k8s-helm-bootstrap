#!/bin/bash

# Beefed up version of  https://github.com/iameli/kube-node-labeller

# Separate Kube taints and labels using a semicolon ;
# k8snode/taints=taint1=1:NoSchedule;taint1=2:NoSchedule
# k8snode/labels=label1=1;label2=2

# Dockerfile
#
# FROM lachlanevenson/k8s-kubectl:latest
#
# RUN apk --no-cache add bash py-pip python jq curl && \
#     pip install --upgrade pip awscli
# ENTRYPOINT ["/nodelabel-run.sh"]
# ADD nodelabel-run.sh /nodelabel-run.sh
# RUN chmod 777 /nodelabel-run.sh
#
# CMD /nodelabel-run.sh

set -o errexit
set -o nounset
set -o pipefail

COPY_ALL_AWS_TAGS=${COPY_ALL_AWS_TAGS:-"false"}
EXECUTION_INTERVAL_SECS=${EXECUTION_INTERVAL_SECS:-300}

run () {
  echo "Running labeller..."

  # Get this node's information
  region=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e "s/.$//")
  local_hostname=$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
  instance_id=$(curl --silent http://169.254.169.254/latest/meta-data/instance-id)
  node=${KUBERNETES_NODE_NAME:-$local_hostname}

  echo "AWS Region: ${region}"
  echo "AWS Instance: ${instance_id}"
  echo "Kubernetes Node: ${node}"
  echo

  # Grab the tags for the AWS instance this node is running on
  tags="$( \
    aws ec2 describe-tags \
    --region ${region} \
    --filters "Name=resource-id,Values=${instance_id}" | \
    jq -c '.Tags[]'
  )"
  echo "AWS Tags found for instance ${instance_id} :"
  echo
  echo "${tags}"
  echo

  # Add the AWS tags to the node's labels and taints
  for tag in $tags; do

    # Keys may not contain colons, replace with dashes
    key="$(echo ${tag} | jq -r '.Key' | sed s/:/-/g)"
    # Values may not be more than 63 chars
    echo "Handling AWS Tag with key: ${key}"

    if [[ "${key}" == "k8snode/taints" ]]; then
      value="$(echo $tag | jq -r '.Value' | cut -c 1-63)"
      parsed_taints=$(echo "${value}" | sed 's/;/\ /g')
      for taint in ${parsed_taints}; do
        echo "Adding taint \"${taint}\" to Kubenetes node \"${node}\""
        kubectl taint node ${node} ${taint} --overwrite;
      done
    elif [[ "${key}" == "k8snode/labels" ]]; then
      value="$(echo $tag | jq -r '.Value' | cut -c 1-63)"
      parsed_labels=$(echo "${value}" | sed 's/;/\ /g')
      for label in ${parsed_labels}; do
        echo "Adding label \"${label}\" to Kubenetes node \"${node}\""
        kubectl label node ${node} ${label} --overwrite;
      done
    elif [[ "${COPY_ALL_AWS_TAGS}" == "true" ]]; then
      echo "Copying AWS tag to Kube node label"
      value="$(echo ${tag} | jq -r '.Value' | cut -c 1-63 | sed s/:/-/g | sed s/\\\//-/g)"
      patch="$(jq -n ".metadata.labels[\"${key}\"] = \"${value}\"")"
      kubectl patch node "${node}" -p "${patch}"
    else
      echo "Skipping AWS Tag with key: ${key}"
    fi

  done
}

while true; do
  run
  sleep ${EXECUTION_INTERVAL_SECS}
done
