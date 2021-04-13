#!/bin/sh

# we require this script to be running in a container,
# and after the setup script is complete.

if [ ! -d /miniChRIS_state ]; then
  echo "usage: docker-compose up plugins"
  exit 1
fi
if [ ! -f /miniChRIS_state/.setup ]; then
  echo "Please try again later."
  exit
fi

GIT_REPO_WEBSITE=${GIT_REPO_WEBSITE:-https://github.com}


# 1. find the plugin's main script
# 2. produce the plugin's JSON description
# 3. upload the description to the ChRIS_store
# 4. register the plugin into the ChRIS backend
upload_docker_image()
{
  local dock_image=$1
  local script=$(docker inspect --format '{{ (index .Config.Cmd 0)}}' $dock_image)
  if [ "$?" != "0" ]; then
    docker pull -q $dock_image > /dev/null
    script=$(docker inspect --format '{{ (index .Config.Cmd 0)}}' $dock_image)
    local exit_code=$?
    [ "$exit_code" != "0" ] || return $exit_code
  fi
  local json_description="$(docker run --rm $dock_image $script --json 2> /dev/null)"

  # docker.io/fnndsc/pl-app:version --> pl-app
  local repo=$(echo $dock_image | sed 's/:.*//')
  local name=$(echo $repo       |  sed 's/.*\///')
  docker exec chris_store python plugins/services/manager.py add \
    --descriptorstring "$json_description" \
    $name chris "$GIT_REPO_WEBSITE/$repo" $dock_image 2> /dev/null
  docker exec chris python plugins/services/manager.py register \
    host --pluginname $name
  return $?
}

# search for the plugin name in chrisstore.co and choose the first result
upload_plugin_name()
{
  local pluginurl=$(
    curl -s "https://chrisstore.co/api/v1/plugins/search/?name_exact=$1" \
      | jq -r '.collection.items[0].href'
  )
  [ -n "$pluginurl" ] || return 1
  docker exec chris python plugins/services/manager.py register host --pluginurl $pluginurl
  return $?
}


# concatenate list of all plugins to upload, and remove comments
plugins=$(cat /plugins/*.txt | sed 's/#.*$//g')

count_errors=0
for plugin in $plugins; do
  # hint: using variables without wrapping them in double-quotes
  # causes sh to strip whitespace and exclude blanks
  case $plugin in
    http://*|https://*)
      docker exec chris python plugins/services/manager.py register host --pluginurl $plugin
      result=$?
      ;;
    */*)
      upload_docker_image $plugin
      result=$?
      ;;
    *)
      upload_plugin_name $plugin
      result=$?
      ;;
  esac
  error=ok
  [ "$result" = "0" ] || error=error count_errors=1
  printf "%-44s %s\n" "$plugin" "$error"
done
