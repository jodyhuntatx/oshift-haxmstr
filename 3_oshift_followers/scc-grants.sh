oc login -u $OSHIFT_CLUSTER_ADMIN
oc adm policy remove-scc-from-user anyuid -z default
oc adm policy remove-scc-from-user anyuid -z $CONJUR_PROJECT_NAME
#oc adm policy add-scc-to-user anyuid -z default
#oc adm policy add-scc-to-user anyuid -z $CONJUR_PROJECT_NAME
