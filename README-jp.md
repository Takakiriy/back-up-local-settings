# back-up-local-settings, .gitignore back-up-files
<!-- Character Encoding: "WHITE SQUARE" U+25A1 is □. -->

`back-up-local-settings` コマンドは `.gitignore` されるファイルや
その他のファイルをバックアップ・リストアするためのコマンドです。
バックアップするファイルのパスをそれぞれ指定することができます。
また、暗号化してバックアップすることもできます。

<!-- TOC depthFrom:1 -->
- [back-up-local-settings, .gitignore back-up-files](#back-up-local-settings-gitignore-back-up-files)
  - [基本的なバックアップ](#基本的なバックアップ)
  - [バックアップの管理](#バックアップの管理)
  - [環境変数](#環境変数)
  - [Git リポジトリ対応](#git-リポジトリ対応)
  - [シークレットのバックアップ](#シークレットのバックアップ)
  - [詳細仕様](#詳細仕様)
<!-- /TOC -->


## 基本的なバックアップ

サンプルは [example_project](./example_project) フォルダーにあります。
その設定ファイルは [.back_up_files.ini](./example_project/.back_up_files.ini) にあります。
設定ファイルにはバックアップするファイルのパスの一覧などが書かれています。

バックアップを実行するときは、次のようにコマンドを入力します。

    bin/back-up-files  "./example_project/.back_up_files.ini"

リストアを実行するときは、次のように -r オプションを指定します。

    bin/back-up-files  "./example_project/.back_up_files.ini"  -r

設定ファイルのサンプル:

    # back-up-files setting
    ThisFileInWorking = ".back_up_files.ini"
    ThisFileInBackUp  = "../back_up/.back_up_files.ini"

    [BackUpFiles]
    WorkingBaseFolder = "."
    BackUpBaseFolder = "../back_up"
    File = ".env"
    File = "sub/.env"

設定ファイルは通常、プロジェクトの中に入れて、`.gitignore` されるようにします。


## バックアップの管理

複数のプロジェクトを一度にバックアップするときは、バックアップ管理ファイル
[back-up-local-settings.ini](bin/back-up-local-settings.ini) を作り、次のようにコマンドを入力します。
設定ファイルに対するコマンドと同じです。

バックアップを実行するときは、次のようにコマンドを入力します。

    bin/back-up-files  "./bin/back-up-local-settings.ini"

リストアを実行するときは、次のように `-r` オプションを指定します。

    bin/back-up-files  "./bin/back-up-local-settings.ini"  -r

バックアップ管理ファイルは、プロジェクトの外に配置します。

バックアップを実行するスクリプト [back-up-local-settings](bin/back-up-local-settings)
を作ると簡単に実行でき、バックアップをきちんと行うようになるでしょう。

    back-up-local-settings


## 環境変数

設定ファイルとバックアップ管理ファイルには、環境変数の値を参照する設定を書くことができます。 `${ }` 形式で書きます。

    ${BackUpRootFolder}

環境変数の定義をバックアップ管理ファイルの `Variables` セクションに書くことができます。
ここで定義した環境変数は、設定ファイルやバックアップ管理ファイルから参照することができます。

    [Variables]
    VariableA = "aaa"
    VariableB = "bbb"


## Git リポジトリ対応

設定ファイルに Git の設定を書くと、バックアップするときに `git commit` も行います。

設定ファイルの最低限のサンプル:

    [Git]
    BackUpGitWorkingFolder = "../back_up"
    BackUpGitBranch = "develop"

設定ファイルのサンプル:

    [Git]
    BackUpGitWorkingFolder = "../back_up"
    BackUpGitBranch = "develop"
    CommitMessage="updated"
    GitPush = "true"
    GitSSHCommand = "ssh -i ~/.ssh/id_rsa"
    ProtectedBranches = "master,main"

ProtectedBranches に含まれるブランチを BackUpGitBranch に設定するとエラーになります。
誤操作を避けるための機能です。


## シークレットのバックアップ

公開リポジトリに配置できないパスワードや API キー をバックアップするために、暗号化した
.zip ファイルに変換してからバックアップすることができます。
.zip ファイルのハッシュ値も作られます。

暗号化するファイルのパスを設定ファイルの `File` パラメーターの代わりに `SecretFile` パラメーターに書きます。

    SecretFile = "./.env"
    SecretFile = "./sub/.env"

バックアップするファイルには、`THIS_FILE` パラメーターに .zip ファイルのパスワードを書く必要があります。
`THIS_FILE` パラメーター はどの行に書いても構いません。

    THIS_FILE = __Secret__
    MY_API_KEY = 129aAn810j

リストアするときは、少なくとも `THIS_FILE` パラメーターが書かれたファイルをリストアする先に保存してからリストアする必要があります。
リストアを実行すると `THIS_FILE` 以外の内容がリストアされます。

    THIS_FILE = __Secret__

**つまり、リストアするためには .zip ファイルのパスワードを別の方法で思い出す必要があります。**

バイナリ ファイル など `THIS_FILE` パラメーターを書けないファイルに関しては、このツールによる暗号化以外の方法で暗号化してください。
たとえば、暗号化する前のファイルの隣に暗号化したファイルを作り、暗号化したファイルだけをバックアップします。
リストアするときのパスワードは `THIS_FILE` に書いておき、別途復号化するスクリプトを書くといいでしょう。


## 詳細仕様

[specifications.yaml](specifications.yaml)
