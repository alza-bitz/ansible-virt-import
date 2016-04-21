#!/usr/bin/env bats

# testing requirements: docker, ansible, grep, (python/pip/shyaml)

readonly docker_image="alzadude/fedora-ansible-test:23"
readonly docker_container_name="ansible-virt-import"
readonly ova_path=~/Downloads/centos-7-amd64.ova

docker_exec() {
  docker exec -u test $docker_container_name $@
}

docker_exec_root() {
  docker exec $docker_container_name $@
}

setup() {
  local _ssh_public_key=~/.ssh/id_rsa.pub
  docker run --name $docker_container_name -d -p 5555:22 \
    -e USERNAME=test -e AUTHORIZED_KEYS="$(< $_ssh_public_key)" -v $docker_container_name:/var/cache/dnf $docker_image
#  docker_exec_root sed -i -e 's/keepcache=\(.*\)/keepcache=1/' /etc/dnf/dnf.conf
# metadata_timer_sync=0
# http://superuser.com/questions/590630/sed-how-to-replace-line-if-found-or-append-to-end-of-file-if-not-found
# also see 'library/firefox_addon' in ansible-firefox-addon
}

@test "Role can be applied to container" {
  ansible-playbook -i hosts test.yml --extra-vars "ova_path=$ova_path"
  docker_exec virsh -q list --all | grep "centos-7"
  false
}

#@test "Role is idempotent" {
#  run ansible-playbook -i hosts test.yml
#  run ansible-playbook -i hosts test.yml
#  [[ $output =~ changed=0.*unreachable=0.*failed=0 ]]
#}

#teardown() {
#  docker stop $docker_container_name > /dev/null
#  docker rm $docker_container_name > /dev/null
#}
