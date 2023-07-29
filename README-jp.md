# back-up-local-settings, .gitignore back-up-files
<!-- Character Encoding: "WHITE SQUARE" U+25A1 is □. -->

`back-up-local-settings` コマンドは `.gitignore` されるファイルや
その他のファイルをバックアップ・リストアするためのコマンドです。
バックアップ先は **Git の ワーキング ディレクトリ** にすることができ、
バックアップを行うとコミットが追加されます。
バックアップするファイルのパスをそれぞれ指定することができます。
また、暗号化してバックアップすることもできます。

<!-- TOC depthFrom:1 -->
- [back-up-local-settings, .gitignore back-up-files](#back-up-local-settings-gitignore-back-up-files)
  - [基本的なバックアップ](#基本的なバックアップとリストア)
  - [バックアップの管理](#バックアップの管理)
  - [環境変数](#環境変数)
  - [Git リポジトリ対応](#git-リポジトリ対応)
  - [brebase 対応](#brebase-対応)
  - [シークレットのバックアップ](#シークレットのバックアップ)
  - [詳細仕様](#詳細仕様)
<!-- /TOC -->


## 基本的なバックアップとリストア

サンプルは [example_project](./example_project) フォルダーにあります。
その設定ファイルは [.back_up_files.ini](./example_project/.back_up_files.ini) にあります。
設定ファイルにはバックアップするファイルのパスの一覧などが書かれています。

バックアップを実行するときは、次のようにコマンドを入力します。

    bin/back-up-files  "./example_project/.back_up_files.ini"

リストアを実行するときは、次のように -r または --restore オプションを指定します。

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

リストアを実行するときは、次のように `-r` または `--restore` オプションを指定します。

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

    [BackUpFiles]
    BackUpBaseFolder = "${VariableA}"


## Git リポジトリ対応

設定ファイルに Git の設定を書くと、バックアップするときに内部で `git commit` コマンドも実行します。

- `BackUpGitWorkingFolder` と `BackUpGitBranch` の設定が無ければ `git` のコマンドは実行されません。
- リストアするときは `git` のコマンドは実行されません。
- `GitPush = "true"` なら、内部で `git push` コマンドも実行します。
- `BrebaseMainBranch` を設定すると、[brebase push コマンド にも対応](#brebase-対応)します。
- Git ワーキング フォルダー が clean 状態ではないときはエラーになりバックアップは行われません。手動で clean 状態に戻してください。

設定ファイルの最低限のサンプル:

    [Git]
    BackUpGitWorkingFolder = "../back_up"
    BackUpGitBranch = "develop"

設定ファイルのサンプル:

    [Git]
    BackUpGitWorkingFolder = "../back_up"
    BackUpGitBranch = "my-feature-1"
    BrebaseMainBranch = "my-feature"
    CommitMessage="updated"
    GitPush = "true"
    GitSSHCommand = "ssh -i ~/.ssh/id_rsa"
    ProtectedBranches = "master,main"


### ProtectedBranches

`ProtectedBranches` に含まれるブランチを `BackUpGitBranch` に設定するとエラーになります。
誤操作を避けるための機能です。


## brebase 対応

brebase に対応すると、
バックアップするファイルを複数のプロジェクトで共有しているときに、
バックアップするファイルをローカルで（リポジトリの外で）マージすることができるようになります。

`brebase` コマンドは、リモート リポジトリ に対する `git push|pull` コマンドのように、
ローカルにある別のブランチに対して push pull することで、ローカルで rebase git merge 戦略を行います。

https://github.com/Takakiriy/brebase


### 設定

`BrebaseMainBranch` に brebase の メイン フィーチャー ブランチ を設定すると、
内部で自動的に `brebase` コマンドを呼び出すようになります。

    [Git]
    BackUpGitWorkingFolder = "../back_up"
    BackUpGitBranch = "my-feature-1"
    BrebaseMainBranch = "my-feature"


### バックアップ時の動作 - brebase push コマンド

`brebase` コマンドを呼び出す設定をした `back-up-local-settings` コマンドでバックアップを実行すると、
内部で `git commit` を実行して サブ フィーチャー ブランチ を更新するだけでなく、
内部で `brebase push` コマンドを実行して メイン フィーチャー ブランチ も更新し、
メイン フィーチャー ブランチ を `git push` します。

    $ bin/back-up-files  "./example_project/.back_up_files.ini"
    ...
    Files were copied.
    $ git add "."  &&  git commit -m "updated"  &&  git push origin "my-feature-1"  #// in back-up-files command
    $ BREBASE_MAIN_BRANCH="my-feature" \
      brebase push  #// in back-up-files command
    $ git push origin "my-feature"  #// in back-up-files command

もし、メイン フィーチャー ブランチ が先行していたら、
バックアップと サブ フィーチャー ブランチの `git commit` まで実行しますが、
メイン フィーチャー ブランチ は更新されず、
更新されなかったと警告されます。
`--pull` オプションを使ってマージしてください。

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


### リストア時の --pull オプション - brebase pull コマンド

`back-up-local-settings` コマンドに `--pull` オプションを指定すると、内部で `brebase pull` コマンドが実行され、
`git rebase` してからリストアします。
このとき、メイン フィーチャー ブランチ とマージが行われます。

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

`back-up-local-settings` コマンドに `-r` (`--restore`) オプションを指定してリストアしたときは、
`brebase pull` コマンドは実行しません。サブ フィーチャー ブランチ の内容がリストアされます。

    bin/back-up-files  "./example_project/.back_up_files.ini"  -r

コンフリクトしてしまったときは、コンフリクトしたファイルにコンフリクトした内容と `<<<<<<<`, `=======`, `>>>>>>>` が書かれます。
コンフリクトしても `git rebase --continue` が実行され、Git 的にはコンフリクトが解決した状態になります。
もし、 `git rebase` する前の状態に戻したいときは
`git reflog` コマンドと `git reset --hard "HEAD@{____}"` コマンドで `git rebase` をキャンセルできます。
キャンセルしたらリストアしてください。

    git reflog 
    git reset --hard "HEAD@{3}"


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
