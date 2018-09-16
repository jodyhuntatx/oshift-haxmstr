#!/bin/bash
echo "Adding Lilah..."
curl -XPOST --data '{ "name": "Lilah" }' -H "Content-Type: application/json" localhost:8080/pet
echo "Adding Lev..."
curl -XPOST --data '{ "name": "Lev" }' -H "Content-Type: application/json" localhost:8080/pet
echo "Adding Tony..."
curl -XPOST --data '{ "name": "Tony" }' -H "Content-Type: application/json" localhost:8080/pet
echo "Adding Gus..."
curl -XPOST --data '{ "name": "Gus" }' -H "Content-Type: application/json" localhost:8080/pet
echo
echo "Listing all pets..."
curl localhost:8080/pets
echo
echo "Getting pet 3..."
curl localhost:8080/pet/3
echo
echo "Deleting 4 pets.."
curl -XDELETE localhost:8080/pet/1
curl -XDELETE localhost:8080/pet/2
curl -XDELETE localhost:8080/pet/3
curl -XDELETE localhost:8080/pet/4
echo
echo "Listing all pets..."
curl localhost:8080/pets
echo
echo "Contents of /etc/secrets.yml..."
docker-compose exec hello cat /etc/secrets.yml
echo
echo
echo "Opening web page where spring-apps/hello/secret is echoed..."
open http://localhost:8080
