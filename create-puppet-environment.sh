#!/bin/bash
# This script sets up a work environment in the PWD for reading and writing puppet modules. 
# This script will do the following
# 	1. checkout the repos from puppet01 that match the runuser's groups
# 	2. checkout the git hooks repo which includes pre/post commit actions 
#	3. symlink .git/hooks to the hooks git repo.

runuser=$(whoami)

while getopts "h?vu:" opt; do
    case "$opt" in
    h|\?)
        echo " USAGE: -u $USER"
        exit 0
        ;;
    u)  runuser=$OPTARG
        ;;
    esac
done

#clear OPTIND in case getopt is used elsewhere on this system. We use getopts since it's POSIX compliant
shift $((OPTIND-1))

if [ -d pe-puppet ]; then
   read -p $'WARNING: pe-puppet exists. This will remove it and create a fresh environment. Any local modifications will be discarded. \n Are you sure? ' -n 1 -r -e
   if [[ $REPLY =~ ^[Yy]$ ]]
   then
       rm -rf pe-puppet
   fi
fi

repo_checkout () {
    echo "Checking out $1 repo as $runuser"
    git clone $runuser@puppet01:/opt/git/$1.git
    cd $1 && git pull origin production
    git checkout -b production
    git branch -d master
    cd ..
    if [[ ! -d $(pwd)/hooks ]]; then 
      echo "Checking out hooks repo as $runuser"
      git clone $runuser@puppet01:/opt/git/hooks.git && repolist+="hooks "
      cd hooks && git pull origin production
    fi
    echo "Creating hooks symlink"
    #symlink .git/hooks to the hooks repo
    rm -rf $(pwd)/$1/.git/hooks && ln -s $(pwd)/hooks $(pwd)/$1/.git/hooks
}


if [ "$(id -u)" != "0" ]; then 
    mkdir pe-puppet && cd pe-puppet
    for group in $(id -Gn $runuser); do 
        case $group in
        "linux_admins")
	    repo_checkout linux_admins && repolist+="linux_admins "
	    ;;
        "linux_it")
	    repo_checkout linux_it && repolist+="linux_it "
	    ;;
        "linux_grove_dev")
	    repo_checkout linux_grove_dev && repolist+="linux_grove_dev "
	    ;;
	esac
     done
     echo "Successfully Cloned repos: " ${repolist[*]}
else
   echo "This must be exectued as a non-root user with access to the puppet repo"
fi
