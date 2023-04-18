# back-up-local-settings, .gitignore back-up-files
<!-- Character Encoding: "WHITE SQUARE" U+25A1 is □. -->

( [Japanese](./README-jp.md) )

The `back-up-local-settings` command is to back up and restore `.gitignore` files and other files.
You can specify the path of each file to back up.
Also, you can encrypt before back up.

<!-- TOC depthFrom:1 -->
- [back-up-local-settings, .gitignore back-up-files](#back-up-local-settings-gitignore-back-up-files)
  - [Simple back up](#simple-back-up)
  - [Managing back up](#managing-back-up)
  - [Environment variables](#environment-variables)
  - [Support Git repository](#support-git-repository)
  - [Back up secrets](#back-up-secrets)
  - [Detailed specifications](#detailed-specifications)
<!-- /TOC -->


## Simple back up

There is an example in the [example_project](./example_project) folder.
There is a configuration file in [.back_up_files.ini](./example_project/.back_up_files.ini).
The configuration file contains a list of paths of files to be backed up.

When performing a backup, enter the command as follows:

    bin/back-up-files  "./example_project/.back_up_files.ini"

When performing a restore, specify the `-r` option as follows:

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

When performing a restore, specify the `-r` option as follows:

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


## Support Git repository

If you write Git settings in the configuration file,
back up command will also do `git commit`.

Example of minimum configuration file:

    [Git]
    BackUpGitWorkingFolder = "../back_up"
    BackUpGitBranch = "develop"

Example of configuration file:

    [Git]
    BackUpGitWorkingFolder = "../back_up"
    BackUpGitBranch = "develop"
    CommitMessage="updated"
    GitPush = "true"
    GitSSHCommand = "ssh -i ~/.ssh/id_rsa"
    ProtectedBranches = "master,main"

An error is raised, if you set 'BackUpGitBranch' value contained in 'ProtectedBranches'.
It is a function to prevent erroneous operation.


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
