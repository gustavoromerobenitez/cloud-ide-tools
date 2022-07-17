#!/usr/bin/bash

# AWS EC2 specific directory
cd ${HOME}/environment

# EC2-specific directory
PETCLINIC_DIR=${HOME}/environment/spring-petclinic

PETCLINIC_PS=$(ps -ef | grep java | grep petclinic | grep -v grep)

if [[ "${PETCLINIC_PS}" != "" ]]; then

	echo "#"
	echo "# The petclinic application seems to be already running."
	echo "#   Stop the application by killing the java process:"
	echo "#"
	echo "#   Find the java process: "
	echo "#"
	echo "#   $ ps -ef | grep petclinic | grep -v grep"
	echo "#"
	echo "#   Grab the PID of the parent java process and kill it:"
	echo "#"
	echo "#   $ kill -9 <PID>"
	echo "#"
	
	exit 1
	
fi


DOCKER_COMPOSE_PS=$(ps -ef | grep docker-compose | grep -v grep)

if [[ "${DOCKER_COMPOSE_PS}" != "" ]]; then

	echo "#"
	echo "# The docker-compose services seem to be already running."
	echo "#   Stop the the services by running:"
	echo "#"
	echo "#   $ cd ${PETCLINIC_DIR} && docker-compose stop"
	echo "#"
	echo "#   Or, if the spring-petclinic directory does not exist,"
	echo "#     find the docker-compose process:"
	echo "#"
	echo "#   $ ps -ef | grep docker-compose | grep -v grep"
	echo "#"
	echo "#   Grab the PID of the docker-compose process and kill it:"
	echo "#"
	echo "#   $ kill -9 <PID>"
	echo "#"
	
	exit 2
	
fi


# Download the springboot petclinic application
echo "#########################################################################"
echo "#"
echo "# Springboot Petclinic application set up"
echo "#"
echo "#########################################################################"
echo ""

PETCLINIC_REPO=https://github.com/spring-projects/spring-petclinic.git

# Delete the previous configuration if it exists
if [ -d "${PETCLINIC_DIR}" ]; then

	rm -rf ${PETCLINIC_DIR} || true
	
fi
    
echo "#"
echo "# Cloning ${PETCLINIC_REPO}..."
echo "#"
git clone ${PETCLINIC_REPO}

cd ${PETCLINIC_DIR}

# Backup the original docker-compose.yml in case it is modified later
cp docker-compose.yml docker-compose.yml.bkp


echo "#####################################################"
echo "#"
echo "# Which database backend would you like to use..."
echo "#"
echo "# 1. In-memory"
echo "# 2. MySQL on Docker"
echo "# 3. Postgres on Docker"
echo ""
echo "Please enter an option [1-3]:"
echo ""
read DATABASE_CHOICE

NUMBERS_RE="^[0-9]+$"
while ! [ "${DATABASE_CHOICE}"=~"${NUMBERS_RE}" ] || [ "${DATABASE_CHOICE}" -lt 1 ] || [ "${DATABASE_CHOICE}" -gt 3 ]
do
  read -rp "Please enter a valid option [1-3]:" DATABASE_CHOICE
done


echo "#"
echo "# Running mvnw package (logs: tail -f ${PETCLINIC_DIR}/mvnw_package.log) ..."
echo "#"
./mvnw package > mvnw_package.log

if [[ "${DATABASE_CHOICE}" -gt 1 ]]; then

    # Check for the existence of docker-compose
    DOCKER_COMPOSE_PATH=/usr/local/bin/docker-compose
	if [[ ! -f "${DOCKER_COMPOSE_PATH}" ]]; then

        echo "#"
        echo "# Downloading docker-compose..."
        echo "#"
		# Download Docker-compose
		sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o ${DOCKER_COMPOSE_PATH}

		# Make docker-compose executable
		sudo chmod 755 ${DOCKER_COMPOSE_PATH}
		
	fi
	
	# Check for the existence of yq
    YQ_PATH=/usr/bin/yq
    if [[ ! -f "${YQ_PATH}" ]]; then

    	echo "#"
        echo "# Downloading yq..."
        echo "#"
	    YQ_VERSION=v4.25.3
	    YQ_BINARY=yq_linux_amd64
	    wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}.tar.gz -O - | tar xz && sudo mv ${YQ_BINARY} ${YQ_PATH}
	    
	 fi

	# Restore the original file in case it was modifed on a previous run
	if [[ -f docker-compose.yml.bkp ]]; then	
	  cp docker-compose.yml.bkp docker-compose.yml
	fi
	
	CHOSEN_DB=
	# Remove the other db from the docker-compose.yml file
	# yq does not read environment variables correctly, hence this if..then..else
	if [[ "${DATABASE_CHOICE}" -eq 2 ]]; then
	
	  CHOSEN_DB="mysql"
	  yq 'del(.services.postgres)' docker-compose.yml > docker-compose.amended
	
	else
	
	  CHOSEN_DB="postgres"
	  yq 'del(.services.mysql)' docker-compose.yml > docker-compose.amended
	
	fi
	
	# Replace docker-compose.yml
	mv docker-compose.amended docker-compose.yml
	
	# Start database services in the background
	echo "#"
    echo "# Starting docker-compose..."
    echo "#"
	nohup docker-compose up 2>&1 > docker-compose.log &

	# Run the petclinic app with the chosen DB backend
	echo "#"
    echo "# Starting the petclinic application with the ${CHOSEN_DB} databse backend..."
    echo "#"
	nohup ./mvnw spring-boot:run -Dspring-boot.run.profiles=${CHOSEN_DB} 2>&1 > petclinic.log &

else

    # Start the application without changes (docker-compose is not required)
    echo "#"
    echo "# Starting the petclinic application with the H2 in-memory databse backend..."
    echo "#"
    nohup ./mvnw spring-boot:run 2>&1 > petclinic.log &
    
fi

sleep 10

echo "############################################################"
echo "#"
echo "# The Petclinic application is starting..."
echo "#   the URL will be displayed shortly on your IDE"
echo "#     or you may use the Preview functionality"
echo "#"
echo "# Application logs: tail -f ${PETCLINIC_DIR}/petclinic.log"
echo "# Docker-compose logs: tail -f ${PETCLINIC_DIR}/docker-compose.log"
echo "#"
echo "# Database Backend console available at <PET_CLINIC_URL>/h2-console"
echo "#   - Select H2, Postgres or MySQL profile"
echo "#   - Username/password : petclinic/petclinic"
echo "#   - DB URLs:"
echo "#     - MySQL: jdbc:mysql://localhost/petclinic"
echo "#     - Postgres: jdbc:postgresql://localhost/petclinic"
echo "#     - H2: Check Application logs"
echo "#"
echo "# Activate Enhanced Java Support in User Preferences."
echo "#   https://docs.aws.amazon.com/cloud9/latest/user-guide/enhanced-java.html"
echo "#     (Refresh tab after enabling it to activate):"
echo "#"


