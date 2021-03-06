bash scripts to wrap around common tasks.
The contents of this directory are inspired by GitHub's [scripts-to-rule-them-all](https://github.com/github/scripts-to-rule-them-all).

These scripts have been written to be invoked inside the vagrant machine host OS environment. The instructions to prepare the vagrant host OS environment are:
```shell
# go to top-level project directory
vagrant up      # launches a new VM and install dependencies;
                # requires to download a vagrant box of 275MB and dependencies of 140MB
vagrant ssh
cd /home/ubuntu/ts
bash script/bootstrap
source ~/.bashrc
```


The correct order for invocation of the scripts is:    
```shell
cd /home/ubuntu/ts
bash script/setup     #download project dependencies
bash script/test      #run tests on the project
bash script/update    #pull from github repository and run setup, test tasks
bash script/server    #launch a server to answer queries
```
