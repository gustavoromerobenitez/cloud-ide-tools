# chectl requires minikube to run using the docker driver and in rootless mode

# The entry 127.0.0.1 192.168.x.x.nip.io dex.192.168.x.x.nip.io
# is required in /etc/hosts
# and it is necessary to run 'minikube tunnel' and provide sudo password interactively
# in order for minikube to be able to route requests from ports <1024

# start a Minikube instance
minikube start --addons=ingress --driver=docker --memory=12288 --cpus=6

# deploy Eclipse Che
chectl server:deploy --platform=minikube

# configure network

# edit /etc/hosts
# echo "127.0.0.1	$(minikube ip).nip.io" | sudo tee -a /etc/hosts
# echo "127.0.0.1	dex.$(minikube ip).nip.io" | sudo tee -a /etc/hosts

## Add reverse entries in Core DNS
#
# I haven't seen this do anything 
#
kubectl get configmap coredns -n kube-system -o json | sed "s[hosts {[hosts {\\\\n       $(echo `kubectl run -it --rm coredns-fix --image=alpine --restart=Never -- sh -c 'getent hosts host.docker.internal'` | awk '{ print $1 }') $(minikube ip).nip.io[" | kubectl replace -f -
kubectl get configmap coredns -n kube-system -o json | sed "s[hosts {[hosts {\\\\n       $(echo `kubectl run -it --rm coredns-fix --image=alpine --restart=Never -- sh -c 'getent hosts host.docker.internal'` | awk '{ print $1 }') dex.$(minikube ip).nip.io[" | kubectl replace -f -

# export Eclipse Che Certificate Authority (to be imported in end-user browser)
chectl cacert:export

# pull the (huge) Docker image used by DevWorkspaces in the Minikube Docker daemon
eval $(minikube docker-env)
docker pull quay.io/devfile/universal-developer-image:ubi8-latest

# open the Eclipse Che dashboard
chectl dashboard:open

# start the Minikube tunnel and provide sudo password
minikube tunnel

