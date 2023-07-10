#!/usr/bin/env bash

JDK=${JDK:-"17.0.7-tem"}
GIT_TAG=${GIT_TAG:=$(git tag -l --contains HEAD)}
GIT_BRANCH=${GIT_BRANCH:=$(git rev-parse --abbrev-ref HEAD)}
GIT_COMMIT=$(git rev-parse HEAD)
GIT_REF=${GIT_TAG:=$GIT_BRANCH}
GIT_REF=${GIT_REF:=$GIT_COMMIT}
DOCKER_REPO=${DOCKER_REPO:-"default"}
DOCKER_IMAGE=${DOCKER_IMAGE:-"$(basename `git rev-parse --show-toplevel`)"}
DOCKER_TAG=$(echo $GIT_REF | sed 's/[^a-zA-Z0-9]/-/g')
DOCKER_FULL=${DOCKER_REPO}/${DOCKER_IMAGE}:${DOCKER_TAG}
DOCKER_FILE=${DOCKER_FILE:-"Dockerfile"}
DOCKER_COMPOSE_FILE=${DOCKER_COMPOSE_FILE:-"docker-compose.yml"}
DOCKER_COMPOSE_WAIT_COMMAND=${DOCKER_COMPOSE_WAIT_COMMAND:-""}

print_values() {
  echo ""
  echo "Git ref: ${GIT_REF}"
  echo "Using JDK: ${JDK}"
  echo "Docker image: ${DOCKER_FULL}"
  echo ""
}

install_sdk() {
  if [ ! -f ~/.sdkman/bin/sdkman-init.sh ]; then rm ~/sdkman -rf && curl -s "https://get.sdkman.io" | bash; fi
  echo sdkman_auto_answer=true > ~/.sdkman/etc/config
  echo sdkman_auto_selfupdate=true >> ~/.sdkman/etc/config
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  sdk install java ${JDK} || true
  sdk use java ${JDK}
}

make_artifact() {
  if [ -f mvnw ]; then
    ./mvnw clean package
  elif [ -f pom.xml ]; then
    sdk install maven
    mvn package  
  elif [ -f gradlew ]; then
    ./gradlew build
  elif [ -f build.gradle ] || [ -f build.gradle.kts ]; then
    sdk install gradle
    gradle build
  fi 
}

build() {
  if [ -f ${DOCKER_COMPOSE_FILE} ]; then
    docker compose down
    while ! docker compose pull; do sleep .1; done
    docker compose up -d
    ${DOCKER_COMPOSE_WAIT_COMMAND}
    #until docker compose exec -T db psql -U postgres -c "select 1" -d postgres; do sleep 1; done
  fi

  make_artifact

  if [ -f ${DOCKER_COMPOSE_FILE} ]; then
    docker compose down
  fi
}

docker_build() {
  if [ -f ${DOCKER_FILE} ]; then
    docker build . -f $DOCKER_FILE --build-arg APP_VERSION=${GIT_TAG:latest} -t $DOCKER_FULL
  fi
}

docker_push() {
  docker inspect $DOCKER_FULL > /dev/null 2>&1 || return
  docker login
  docker push $DOCKER_FULL
}

print_values
install_sdk
build
docker_build
print_values

exit 0

