# back-up-local-settings, .gitignore back-up-files
<!-- Character Encoding: "WHITE SQUARE" U+25A1 is □. -->

( [Japanese](./README-jp.md) )

The `back-up-local-settings` command is to back up and restore `.gitignore` files and other files.
The backup destination can be the **Git's working directory**,
and a commit will be added when the backup is performed.
You can specify the path of each file to back up.
Also, you can encrypt before back up.

<!-- TOC depthFrom:1 -->
- [back-up-local-settings, .gitignore back-up-files](#back-up-local-settings-gitignore-back-up-files)
  - [Simple back up and restore](#simple-back-up-and-restore)
  - [Managing back up](#managing-back-up)
  - [Environment variables](#environment-variables)
  - [Support Git repository](#support-git-repository)
  - [Support brebase](#support-brebase)
  - [Back up secrets](#back-up-secrets)
  - [Detailed specifications](#detailed-specifications)
<!-- /TOC -->


## Simple back up and restore

There is an example in the [example_project](./example_project) folder.
There is a configuration file in [.back_up_files.ini](./example_project/.back_up_files.ini).
The configuration file contains a list of paths of files to be backed up.

When performing a backup, enter the command as follows:

    bin/back-up-files  "./example_project/.back_up_files.ini"

When performing a restore, specify the `-r` or `--restore` option as follows:

    bin/back-up-files  "./example_project/.back_up_files.ini"  -r

Example of configuration file:

    # back-up-files setting
    ThisFileInWorking = ".back_up_files.ini"
    ThisFileInBackUp  = "../back_up/.back_up_files.ini"

    [BackUpFiles]
    WorkingBaseFolder = "."
    BackUpBaseFolder = "../back_up"
    File = ".env"
    File = "sub/.env"

The configuration file should be put inside the project and be `.gitignore` target.


## Managing back up

When backing up multiple projects at once, create a backup management file
[back-up-local-settings.ini](bin/back-up-local-settings.ini) and enter the command as follows.
The command is same as the command for configuration file.

When performing a backup, enter the command as follows:

    bin/back-up-files  "./bin/back-up-local-settings.ini"

When performing a restore, specify the `-r` or `--restore` option as follows:

    bin/back-up-files  "./bin/back-up-local-settings.ini"  -r

The backup management file should be put out of the projects.

You can easily run the script [back-up-local-settings](bin/back-up-local-settings)
to do the backup by making it and it will do properly.

    back-up-local-settings


## Environment variables

Environment variable values can be referenced in configuration files or backup
management files by written `${ }` format.

    ${BackUpRootFolder}

Environment variable definitions can be written in the `Variables` section
of the backup management file. The environment variables defined here can be referenced
from the configuration file or backup management file.

    [Variables]
    VariableA = "aaa"
    VariableB = "bbb"

    [BackUpFiles]
    BackUpBaseFolder = "${VariableA}"


## Support Git repository

If you write Git settings in the configuration file,
back up command will also run `git commit` command.

- If `BackUpGitWorkingFolder` and `BackUpGitBranch` is not set, `git` commands will not be executed.
- If you restore, `git` commands will not be executed.
- If `GitPush = "true"`, also run `git push`.
- If `BrebaseMainBranch` is not set, `back-up-local-settings` command also [supports brebase push command](#support-brebase).
- If the Git working folder is not clean, an error will occur and the back up will not be performed. Please restore it to clean state manually.

Example of minimum configuration file:

    [Git]
    BackUpGitWorkingFolder = "../back_up"
    BackUpGitBranch = "develop"

Example of configuration file:

    [Git]
    BackUpGitWorkingFolder = "../back_up"
    BackUpGitBranch = "my-feature-1"
    BrebaseMainBranch = "my-feature"
    CommitMessage="updated"
    GitPush = "true"
    GitSSHCommand = "ssh -i ~/.ssh/id_rsa"
    ProtectedBranches = "master,main"


### ProtectedBranches

An error is raised, if you set `BackUpGitBranch` value contained in `ProtectedBranches`.
It is a function to prevent erroneous operation.


## Support brebase

With brebase support, you can merge back up files locally (outside the repository)
when the backed up files are shared by multiple projects.

The `brebase` command does a locally rebase git merge strategy by pushing and pulling to another branch locally,
like the `git push|pull` command to a remote repository.

https://github.com/Takakiriy/brebase


### Settings

Setting `BrebaseMainBranch` to brebase's main feature branch will automatically call the `brebase` command internally.

    [Git]
    BackUpGitWorkingFolder = "../back_up"
    BackUpGitBranch = "my-feature-1"
    BrebaseMainBranch = "my-feature"


### Back up behavior - brebase push command

If you run a back up with the `back-up-local-settings` command with settings that call the `brebase` command,
it will not only internally run `git commit` to update sub feature branch,
but it will also internally `brebase push` command to also update main feature branch
and `git push` main feature branch.

    $ bin/back-up-files  "./example_project/.back_up_files.ini"
    ...
    Files were copied.
    $ git add "."  &&  git commit -m "updated"  &&  git push origin "my-feature-1"  #// in back-up-files command
    $ BREBASE_MAIN_BRANCH="my-feature" \
      brebase push  #// in back-up-files command
    $ git push origin "my-feature"  #// in back-up-files command

If main feature branch is ahead (sub feature branch is behind),
it runs `git commit` sub feature branch
but the main feature branch will not be updated
and will warn you that it was not updated.
Please, merge using the `--pull` option.

    $ bin/back-up-files  "./example_project/.back_up_files.ini"
    ...
    Files were copied.
    $ git add "."  &&  git commit -m "updated"  &&  git push origin "my-feature-1"  #// in back-up-files command
    $ BREBASE_MAIN_BRANCH=my-feature
    brebase status
    * eb3f371  (origin/my-feature, my-feature) Updated by theirs Your Name 2023-07-29 10:24:43 +0900
    | * 6628022  (HEAD -> my-feature-1) updated Your Name 2023-07-29 10:24:43 +0900
    |/  
    * edf8f57  updated Your Name 2023-07-29 10:24:43 +0900
    * fca2560  updated Your Name 2023-07-29 10:24:43 +0900
    ERROR: git commit was successed but brebase push command was failed, because "my-feature-1" branch is behind "my-feature" main feature branch in git working "/home/user1/back-up-local-settings/back_up". Plesase merge by "back-up-files --pull" command and run "back-up-files" command again.


### --pull option restore up behavior - brebase pull command

`back-up-local-settings` command with the `--pull` option will internally run `brebase pull` command
to do a `git rebase` and then restore.
Restored files are merged from main feature branch.

    $ bin/back-up-files  "./example_project/.back_up_files.ini"  --pull
    Back up to check if brebase pull command can be executed.
    $ back-up-files  "/home/user1/back-up-local-settings/test/brebase/.back_up_files.ini"  #// back up (not restore) in back-up-files command
    $ BREBASE_MAIN_BRANCH="my-feature" \
      brebase pull
    $ git rebase "my-feature"
    CONFLICT (content): Merge conflict in a.txt
    $ git add "."
    $ git rebase --continue
    Resotring ...
    Git pull (merge) and restored

If you restore by `back-up-local-settings` command with `-r` (`--restore`) option,
`brebase pull` command is not executed. The contents of sub feature branch are restored.

    bin/back-up-files  "./example_project/.back_up_files.ini"  -r

If there are conflicts, the content of the conflict and `<<<<<<<`, `=======`, `>>>>>>>>` are written in the conflict file.
Even if there are conflicts, `git rebase --continue` will be executed, and the conflict will be resolved in Git.
If you want to go back to the files before `git rebase`,
you can cancel `git rebase` with `git reflog` command and `git reset --hard "HEAD@{____}"` command.
Please restore after canceling.

    git reflog 
    git reset --hard "HEAD@{3}"


## Back up secrets

To back up passwords and API keys that cannot be placed in public repositories,
you can encrypt them to encrypted .zip file before backing up.
A hash value of the .zip file is also created.

Write the path of the file to be encrypted in the `SecretFile` parameter
insted of `File` parameter of the configuration file.

    SecretFile = "./.env"
    SecretFile = "./sub/.env"

The file to be backed up should have the password of the .zip file written in the `THIS_FILE` parameter.
The `THIS_FILE` parameter can be written on any line.

    THIS_FILE = __Secret__
    MY_API_KEY = 129aAn810j

When restoring, at least the file with the `THIS_FILE` parameter must be saved before restoring.
When you run the restore, the contents other than `THIS_FILE` will be restored.

    THIS_FILE = __Secret__

**This means that you will have to remember the password for the .zip file in some other way in order to restore it.**

For files that cannot write the `THIS_FILE` parameter, such as binary files,
please use a method other than encryption by this tool.
For example, create an encrypted file next to the unencrypted file and
back up only the encrypted file.
To write the password for restoration in `THIS_FILE`
and write a separate decryption script is a good idea.

## Detailed specifications

[specifications.yaml](specifications.yaml)
