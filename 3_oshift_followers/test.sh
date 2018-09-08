ssh -i ~/.aws/jody-k8s.pem ec2-user@54.152.144.149 << EOF
docker exec -it $MASTER_CONTAINER_NAME
