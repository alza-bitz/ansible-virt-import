#!/usr/bin/env bats

# dependencies of this test: bats, ansible, docker, grep
# control machine requirements for playbook under test: tar, qemu-img

readonly container_name=ansible-virt-import
readonly ova_path=~/Downloads/centos-7-amd64.ova

container_startup() {
  local _container_name=$1
  local _container_image=$2
  local _ssh_host=localhost
  local _ssh_port=5555
  local _ssh_public_key=~/.ssh/id_rsa.pub
  docker run --name $_container_name -d -p $_ssh_port:22 \
    -e USERNAME=test -e AUTHORIZED_KEYS="$(< $_ssh_public_key)" -v $_container_name:/var/cache/dnf $_container_image
  ansible localhost -m wait_for -a "port=$_ssh_port host=$_ssh_host search_regex=OpenSSH delay=10"
}

readonly ova_path=~/Downloads/centos-7-amd64.ova

setup() {
  container=$(container_startup fedora)
  hosts=$(tmp_file $(container_inventory $container))
  container_dnf_conf $container keepcache 1
  container_dnf_conf $container metadata_timer_sync 0
}

@test "Role can be applied to container" {
  ansible-playbook -i $hosts ${BATS_TEST_DIRNAME}/test.yml --extra-vars "ova_path=$ova_path"
  container_exec $container virsh -q list --all | grep "centos-7"
}

@test "Role is idempotent" {
  run ansible-playbook -i $hosts ${BATS_TEST_DIRNAME}/test.yml --extra-vars "ova_path=$ova_path"
  run ansible-playbook -i $hosts ${BATS_TEST_DIRNAME}/test.yml --extra-vars "ova_path=$ova_path"
  [[ $output =~ changed=0.*unreachable=0.*failed=0 ]]
}

teardown() {
  container_cleanup
}
