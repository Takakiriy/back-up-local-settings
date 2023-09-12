#!/bin/bash
if echo "$0" | grep "/" | grep -E -v "bash-debug|systemd" > /dev/null; then  cd "${0%/*}"  ;fi  # cd this file folder
GitWorkingFolder="$( readlink -f "${PWD}/.." )"
Bin="${GitWorkingFolder}/bin"
BinEx="${GitWorkingFolder}/bin_extra"
Lib="${GitWorkingFolder}/bin"
WorkBin="${GitWorkingFolder}/_work/bin"
WorkLib="${GitWorkingFolder}/_work/bin"

function  Main() {
    Test1Direct
    TestExampleProjectDirect
    TestExampleProjectScriptSimple
    TestExampleProjectScriptParentIni
    TestGitPush
    TestBrebase
    TestMultiIni
    TestNestedMkdir
    TestSameFolderError
    rm -rf  "${GitWorkingFolder}/back_up/.git"
    echo  "Pass"
}

function  Test1Direct() {
    echo  ""
    echo  "### Test1Direct --------------------------------"
    test1Sub  "Test1Direct"
}

function  TestExampleProjectDirect() {
    testExampleProjectSub  "TestExampleProjectDirect"
}

function  TestExampleProjectScriptSimple() {
    testExampleProjectSub  "TestExampleProjectScriptSimple"
}

function  TestExampleProjectScriptParentIni() {
    testExampleProjectSub  "TestExampleProjectScriptParentIni"
}

function  TestGitPush() {
    echo  ""
    echo  "### TestGitPush --------------------------------"
    cd  "${GitWorkingFolder}"

    #// Set up
        #// Make new reposisoty in "${GitWorkingFolder}/_repository.git"
        rm -rf  "${GitWorkingFolder}/_repository.git"
        git init --bare --shared=true  "${GitWorkingFolder}/_repository.git"

        #// Make a Git working in "${GitWorkingFolder}/back_up"
        ResetBackUpTestFolder  "${GitWorkingFolder}/back_up"
        cd  "${GitWorkingFolder}/back_up"
        git checkout  -b "feature"
        git add  "."
        git commit -m "First commit"
        git remote add origin  file://${GitWorkingFolder}/_repository.git
        git push --set-upstream origin  "feature"
        local  oldCommitID="$( git rev-parse --short "feature" )"

        #// Set current branch
        cd  "${GitWorkingFolder}"
        SetVariableValue  "BackUpGitBranch"  "feature"  "test/3_git_push/.back_up_files.ini"
        SetVariableValue  "GitPush"          "true"     "test/3_git_push/.back_up_files.ini"

    #// Back up and Git push
        #// Main. Back up from "${GitWorkingFolder}/test/3_git_push"
        cd  "${GitWorkingFolder}"
        echo  '$ back-up-files  "test/3_git_push/.back_up_files.ini"'

        ${Bin}/back-up-files  "test/3_git_push/.back_up_files.ini"  ||  Error

        #// Check
        cd  "${GitWorkingFolder}/back_up"
        local  currentCommitID="$( git rev-parse --short "feature" )"
        if [ "${currentCommitID}" == "${oldCommitID}" ]; then  Error  ;fi

    #// Check clean status in Git working
        echo  "editing"  >  "${GitWorkingFolder}/back_up/a"
        cd  "${GitWorkingFolder}"
        echo  '$ back-up-files  "test/3_git_push/.back_up_files.ini"'

        ${Bin}/back-up-files  "test/3_git_push/.back_up_files.ini"  &&  Error
        cp  "${GitWorkingFolder}/test/3_git_push/a"  "${GitWorkingFolder}/back_up/a"

    #// ProtectedBranches
        #// Set up
        cd  "${GitWorkingFolder}"
        SetVariableValue  "BackUpGitBranch"  "develop"  "test/3_git_push/.back_up_files.ini"
        SetVariableValue  "GitPush"          "true"     "test/3_git_push/.back_up_files.ini"
        cd  "${GitWorkingFolder}/back_up"
        git checkout  -b "develop"
        git push --set-upstream origin  "develop"
        local  oldCommitID="$( git rev-parse --short "develop" )"

        #// Main
        cd  "${GitWorkingFolder}"
        echo  '$ back-up-files  "test/3_git_push/.back_up_files.ini"'

        ${Bin}/back-up-files  "test/3_git_push/.back_up_files.ini"  &&  Error

        #// Check
        cd  "${GitWorkingFolder}/back_up"
        local  currentCommitID="$( git rev-parse --short "develop" )"
        local  currentRemoteCommitID="$( git rev-parse --short "origin/develop" )"

        if [ "${currentCommitID}" == "${oldCommitID}" ]; then  Error  ;fi
        if [ "${currentRemoteCommitID}" != "${oldCommitID}" ]; then  Error  ;fi
        cat ".back_up_files.ini" | grep -E 'GitPush = \"false\"' > /dev/null  ||  Error  "ERROR: GitPush must be false"
        cd  "${GitWorkingFolder}"
        cat "test/3_git_push/.back_up_files.ini" | grep -E 'GitPush = \"false\"' > /dev/null  ||  Error  "ERROR: GitPush must be false"

    #// Test of not clean status error
        #// Set up
        echo  "dirty"  >  "${GitWorkingFolder}/back_up/git push test"

        #// Main
        cd  "${GitWorkingFolder}"
        echo  '$ back-up-files  "test/3_git_push/.back_up_files.ini"'

        ${Bin}/back-up-files  "test/3_git_push/.back_up_files.ini"  &&  Error
        AssertContents  "${GitWorkingFolder}/back_up/git push test"  "dirty"

    #// Clean
    cd  "${GitWorkingFolder}"
    SetVariableValue  "BackUpGitBranch"  "feature"  "test/3_git_push/.back_up_files.ini"
    SetVariableValue  "GitPush"          "true"     "test/3_git_push/.back_up_files.ini"
    rm -rf  "${GitWorkingFolder}/_repository.git"
    ResetBackUpTestFolder  "${GitWorkingFolder}/back_up"
}

function  TestBrebase() {
    echo  ""
    echo  "### TestBrebase --------------------------------"
    cd  "${GitWorkingFolder}"

    #// Set up
        #// Make new reposisoty in "${GitWorkingFolder}/_repository.git"
        rm -rf  "${GitWorkingFolder}/_repository.git"
        git init --bare --shared=true  "${GitWorkingFolder}/_repository.git"

        #// Make a Git working in "${GitWorkingFolder}/back_up"
        local  firstBranchName="my-feature"  #// as brebase main feature branch
        ResetBackUpTestFolder  "${GitWorkingFolder}/back_up"
        echo  "brebase"  >  "${GitWorkingFolder}/test/brebase/a.txt"
        cd  "${GitWorkingFolder}/back_up"
        git checkout  -b "${firstBranchName}"
        git add  "."
        git commit -m "First commit"
        git remote add origin  file://${GitWorkingFolder}/_repository.git
        git push --set-upstream origin  "${firstBranchName}"
        local  oldCommitID="$( git rev-parse --short "${firstBranchName}" )"

    #// Back up and Git push
        #// Main. Back up from "${GitWorkingFolder}/test/brebase"
        cd  "${GitWorkingFolder}"
        echo  "brebase"  >  "${GitWorkingFolder}/test/brebase/a.txt"
        echo  ""
        echo  "## Back up and Git push"
        echo  '$ back-up-files  "test/brebase/.back_up_files.ini"  #// by test'

        PATH="${PWD}/bin:${PATH}" \
            ${Bin}/back-up-files  "test/brebase/.back_up_files.ini"  ||  Error
        cd  "${GitWorkingFolder}/back_up"
        local  mainFeatureBranch="${firstBranchName}"
        local  subFeatureBranch="my-feature-1"
        local  currentMainFeatureCommitID="$( git rev-parse --short "${mainFeatureBranch}" )"
        test  "${currentMainFeatureCommitID}" != "${oldCommitID}"  ||  Error
        $assert  git branch -r  |  grep "${subFeatureBranch}" > /dev/null  &&  Error  #// subFeatureBranch is not run "git push" command

    #// Edit and back up and Git push
        cd  "${GitWorkingFolder}"
        echo  "Updated"  >  "${GitWorkingFolder}/test/brebase/a.txt"
        echo  ""
        echo  "## Edit and back up and Git push"
        echo  '$ back-up-files  "test/brebase/.back_up_files.ini"  #// by test'
        cd  "${GitWorkingFolder}/back_up"
        local  oldMainFeatureCommitID="$( git rev-parse --short "${mainFeatureBranch}" )"
        local  oldSubFeatureCommitID="$( git rev-parse --short "${subFeatureBranch}" )"
        cd  "${GitWorkingFolder}"

        PATH="${PWD}/bin:${PATH}" \
            ${Bin}/back-up-files  "test/brebase/.back_up_files.ini"  ||  Error
        cd  "${GitWorkingFolder}/back_up"
        local  currentMainFeatureCommitID="$( git rev-parse --short "${mainFeatureBranch}" )"
        local  currentSubFeatureCommitID="$( git rev-parse --short "${subFeatureBranch}" )"
        test  "${currentMainFeatureCommitID}" != "${oldMainFeatureCommitID}"  ||  Error
        test  "${currentSubFeatureCommitID}" != "${oldSubFeatureCommitID}"  ||  Error
        $assert  git branch -r  |  grep "${subFeatureBranch}" > /dev/null  &&  Error  #// subFeatureBranch is not run "git push" command

    #// Back up and run Git commit but behind from main feature breanch
        echo  ""
        echo  "## Back up and Git push but behind from main feature breanch"
        echo  "Edit a.txt in \"${firstBranchName}\" branch"
        cd  "${GitWorkingFolder}/back_up"
        git checkout "${mainFeatureBranch}"
        echo  "Updated by theirs"  >  "a.txt"
        echo  "$ git push  \"${firstBranchName}\"  #// by test"
        git add  "."
        git commit -m "Updated by theirs"
        git push
        cd  "${GitWorkingFolder}/back_up"
        local  oldMainFeatureCommitID="$( git rev-parse --short "${mainFeatureBranch}" )"
        local  oldSubFeatureCommitID="$( git rev-parse --short "${subFeatureBranch}" )"
        cd  "${GitWorkingFolder}"
        echo  "Updated by ours"  >  "${GitWorkingFolder}/test/brebase/a.txt"
        echo  ""
        echo  '$ back-up-files  "test/brebase/.back_up_files.ini"  #// by test'

        PATH="${PWD}/bin:${PATH}" \
            ${Bin}/back-up-files  "test/brebase/.back_up_files.ini"  &&  Error
        cd  "${GitWorkingFolder}/back_up"
        local  currentMainFeatureCommitID="$( git rev-parse --short "${mainFeatureBranch}" )"
        local  currentSubFeatureCommitID="$( git rev-parse --short "${subFeatureBranch}" )"
        cd  "${GitWorkingFolder}"
        test  "${currentMainFeatureCommitID}" == "${oldMainFeatureCommitID}"  ||  Error
        test  "${currentSubFeatureCommitID}" != "${oldSubFeatureCommitID}"  ||  Error

    #// back-up-file --pull command. Conflict case
        echo  ""
        echo  "## back-up-file --pull command. Conflict case"
        echo  '$ back-up-files --pull  "test/brebase/.back_up_files.ini"  #// by test'

        PATH="${PWD}/bin:${PATH}" \
            ${Bin}/back-up-files --pull  "test/brebase/.back_up_files.ini"  &&  Error
        cd  "${GitWorkingFolder}/back_up"
        $assert  git status  |  grep  "rebase in progress" > /dev/null  &&  Error  #// Not rebase in progress
        $assert  git status  |  grep  "clean" > /dev/null  ||  Error
        local  conflictText="$( cat "a.txt" )"
        local  conflictTextWithoutHash="$( cat "a.txt"  |  sed -E 's/>>>>>>> [0-9a-f]* \(updated\)/>>>>>>> updated/' )"  #// Conflict tag in git 2.41.0 has a commit ID.
        local  conflictTextAnswer="$( echo -e '<<<<<<< HEAD\nUpdated by theirs\n=======\nUpdated by ours\n>>>>>>> updated\n' )"
        test  "${conflictTextWithoutHash}" == "${conflictTextAnswer}"  ||  Error
        cd  "${GitWorkingFolder}"
        AssertContents  "${GitWorkingFolder}/test/brebase/a.txt"  "${conflictText}"

    #// Back up and Git push merged files
        echo  ""
        echo  "## Back up and Git push merged files"
        echo  '$ back-up-files  "test/brebase/.back_up_files.ini"  #// by test'
        echo  "brebase"  >  "${GitWorkingFolder}/test/brebase/a.txt"
        cd  "${GitWorkingFolder}/back_up"
        local  oldMainFeatureCommitID="$( git rev-parse --short "${mainFeatureBranch}" )"
        local  oldSubFeatureCommitID="$( git rev-parse --short "${subFeatureBranch}" )"
        cd  "${GitWorkingFolder}"

        PATH="${PWD}/bin:${PATH}" \
            ${Bin}/back-up-files  "test/brebase/.back_up_files.ini"  ||  Error
        cd  "${GitWorkingFolder}/back_up"
        local  currentMainFeatureCommitID="$( git rev-parse --short "${mainFeatureBranch}" )"
        local  currentSubFeatureCommitID="$( git rev-parse --short "${subFeatureBranch}" )"
        cd  "${GitWorkingFolder}"
        test  "${currentMainFeatureCommitID}" != "${oldMainFeatureCommitID}"  ||  Error
        test  "${currentSubFeatureCommitID}" != "${oldSubFeatureCommitID}"  ||  Error

    #// back-up-file --pull command. Changed in theirs case
        echo  ""
        echo  "## back-up-file --pull command. Changed in theirs case"
        echo  "$ git push  \"${mainFeatureBranch}\""
        cd  "${GitWorkingFolder}/back_up"
        git checkout "${mainFeatureBranch}"
        echo  "Changed in theirs"  >  "a.txt"
        git add  "."
        git commit -m "Changed in theirs"
        git push
        cd  "${GitWorkingFolder}"

        echo  ""
        echo  '$ back-up-files --pull  "test/brebase/.back_up_files.ini"  #// by test'
        PATH="${PWD}/bin:${PATH}" \
            ${Bin}/back-up-files --pull  "test/brebase/.back_up_files.ini"  ||  Error
        cd  "${GitWorkingFolder}/back_up"
        $assert  git status  |  grep  "rebase in progress" > /dev/null  &&  Error
        $assert  git status  |  grep  "clean" > /dev/null  ||  Error
        cd  "${GitWorkingFolder}"
        AssertContents  "${GitWorkingFolder}/test/brebase/a.txt"  "Changed in theirs"

    #// back-up-file --pull command. Changed in ours (not clean) case
        echo  ""
        echo  "## back-up-file --pull command. Changed in ours (not clean) case"
        echo  "brebase"  > "${GitWorkingFolder}/test/brebase/a.txt"

        echo  ""
        cd  "${GitWorkingFolder}"
        echo  '$ back-up-files --pull  "test/brebase/.back_up_files.ini"  #// by test'

        PATH="${PWD}/bin:${PATH}" \
            ${Bin}/back-up-files --pull  "test/brebase/.back_up_files.ini"  &&  Error
        AssertContents  "${GitWorkingFolder}/test/brebase/a.txt"  "brebase"

    #// Clean
    echo  "brebase"  >  "${GitWorkingFolder}/test/brebase/a.txt"
    rm -rf  "${GitWorkingFolder}/_repository.git"
    ResetBackUpTestFolder  "${GitWorkingFolder}/back_up"
}

function  TestMultiIni() {
    echo  ""
    echo  "### TestMultiIni --------------------------------"
    cd  "${GitWorkingFolder}"
    ResetBackUpTestFolder  "./back_up"  "project-Z"
    rm -rf  "_work"
    mkdir   "_work"
    cp -ap  "test/project-X/"  "_work/project-X/"
    cp -ap  "test/project-X/"  "_work/project-Y/"
    cp -ap  "test/project-X/"  "_work/project-Z/"
    echo  "project-X"  >  "_work/project-X/a.txt"
    echo  "project-Y"  >  "_work/project-Y/a.txt"
    echo  "project-Z"  >  "_work/project-Z/a.txt"

    #// Back up
        #// Main
        ${BinEx}/back-up-multi-local-settings  ||  Error

        #// Check
        diff  "back_up/project-X/a.txt"               "_work/project-X/a.txt"               > /dev/null  ||  Error  "ERROR: different"
        diff  "back_up/project-Y/a.txt"               "_work/project-Y/a.txt"               > /dev/null  ||  Error  "ERROR: different"
        diff  "back_up/project-Z/a.txt"               "_work/project-Z/a.txt"               > /dev/null  ||  Error  "ERROR: different"
        diff  "back_up/project-X/.back_up_files.ini"  "_work/project-X/.back_up_files.ini"  > /dev/null  ||  Error  "ERROR: different"
        diff  "back_up/project-Y/.back_up_files.ini"  "_work/project-Y/.back_up_files.ini"  > /dev/null  ||  Error  "ERROR: different"
        diff  "back_up/project-Z/.back_up_files.ini"  "_work/project-Z/.back_up_files.ini"  > /dev/null  ||  Error  "ERROR: different"

    #// Restore
        #// Set up
        rm -rf  "_work"
        mkdir   "_work"
        mkdir   "_work/project-X"
        mkdir   "_work/project-Y"
        mkdir   "_work/project-Z"
        cp -ap  "back_up/project-X/.back_up_files.ini"  "_work/project-X/.back_up_files.ini"
        cp -ap  "back_up/project-Y/.back_up_files.ini"  "_work/project-Y/.back_up_files.ini"
        cp -ap  "back_up/project-Z/.back_up_files.ini"  "_work/project-Z/.back_up_files.ini"

        #// Main
        ${BinEx}/back-up-multi-local-settings  -r  ||  Error

        #// Check
        diff  "_work/project-X/a.txt"               "back_up/project-X/a.txt"               > /dev/null  ||  Error  "ERROR: different"
        diff  "_work/project-Y/a.txt"               "back_up/project-Y/a.txt"               > /dev/null  ||  Error  "ERROR: different"
        diff  "_work/project-Z/a.txt"               "back_up/project-Z/a.txt"               > /dev/null  ||  Error  "ERROR: different"
        diff  "_work/project-X/.back_up_files.ini"  "back_up/project-X/.back_up_files.ini"  > /dev/null  ||  Error  "ERROR: different"
        diff  "_work/project-Y/.back_up_files.ini"  "back_up/project-Y/.back_up_files.ini"  > /dev/null  ||  Error  "ERROR: different"
        diff  "_work/project-Z/.back_up_files.ini"  "back_up/project-Z/.back_up_files.ini"  > /dev/null  ||  Error  "ERROR: different"

    ResetBackUpTestFolder  "./back_up"
    rm -rf  "_work"
}

function  test1Sub() {
    local  testCase="$1"
    cd  "${GitWorkingFolder}"
    ResetBackUpTestFolder  "./back_up"
    rm -rf  "_work"
    cp -ap  "test/1_back_up_restore/"  "_work/"  ||  Error

    #// Back up
        #// Main 1st back up
        export  ExampleProjectBackUp="${GitWorkingFolder}/back_up"
        export  FilesFileInBackUp="${GitWorkingFolder}/back_up/.back_up_files.ini"
        ${Lib}/back-up-files  "test/1_back_up_restore/.back_up_files.ini"  ||  Error

        #// Check
        diff  "back_up/a"  "_work/a"  > /dev/null  ||  Error  "ERROR: different"

        #// Main 2nd back up
        ${Lib}/back-up-files  "_work/.back_up_files.ini"  ||  Error

        #// Check
        diff  "back_up/a"  "_work/a"  > /dev/null  ||  Error  "ERROR: different"

    #// Restore short option name
        #// Set up
        rm -rf    "_work"
        mkdir -p  "_work"
        cp -ap  "back_up/.back_up_files.ini"  "_work"

        #// Main 1st restore
        ${Lib}/back-up-files  "_work/.back_up_files.ini"  -r  ||  Error

        #// Check
        diff  "_work/a"  "back_up/a"  > /dev/null  ||  Error  "ERROR: different"

    #// Restore long option name
        #// Set up
        rm -f  "_work/a"

        #// Main 2nd restore
        ${Lib}/back-up-files  "_work/.back_up_files.ini"  --restore  ||  Error

        #// Check
        diff  "_work/a"  "back_up/a"  > /dev/null  ||  Error  "ERROR: different"

    ResetBackUpTestFolder  "./back_up"
    rm -rf  "_work"
}

function  testExampleProjectSub() {
    local  testCase="$1"
    echo  ""
    echo  "### ${testCase} --------------------------------"
    cd  "${GitWorkingFolder}"
    ResetBackUpTestFolder  "./back_up"
    rm -rf  "_work"
    cp -ap  "test/1_back_up_restore/"  "_work/"  ||  Error

    #// Back up
        #// Main 1st back up
        if [ "${testCase}" == "TestExampleProjectDirect" ]; then
            export  ExampleProject="${GitWorkingFolder}/example_project"
            export  ExampleProjectBackUp="${GitWorkingFolder}/back_up"
            export  FilesFileInBackUp="${GitWorkingFolder}/back_up/.back_up_files.ini"

            ${Lib}/back-up-files  "example_project/.back_up_files.ini"  ||  Error
        elif [ "${testCase}" == "TestExampleProjectScriptSimple" ]; then
            ${BinEx}/back-up-example  ||  Error
        elif [ "${testCase}" == "TestExampleProjectScriptParentIni" ]; then
            ${Bin}/back-up-local-settings  ||  Error
        fi

        #// Check
        diff  "back_up/.env_example"              "example_project/.env_example"             > /dev/null  ||  Error  "ERROR: different"
        diff  "back_up/sub_project/.env_example"  "example_project/sub_project/.env_example" > /dev/null  ||  Error  "ERROR: different"
        AssertExist  "back_up/.env_secret_example.zip"
        AssertExist  "back_up/.env_secret_example.hash"
        AssertExist  "back_up/sub_project/.env_secret_example.zip"
        AssertExist  "back_up/sub_project/.env_secret_example.hash"
        local  commitID_1="$( GetCommitID  "back_up" )"

        #// Main 2nd back up
        if [ "${testCase}" == "TestExampleProjectDirect" ]; then
            ${Lib}/back-up-files  "example_project/.back_up_files.ini"  ||  Error
        elif [ "${testCase}" == "TestExampleProjectScriptSimple" ]; then
            ${BinEx}/back-up-example  ||  Error
        elif [ "${testCase}" == "TestExampleProjectScriptParentIni" ]; then
            ${Bin}/back-up-local-settings  ||  Error
        fi

        #// Check
        diff  "back_up/.env_example"              "example_project/.env_example"             > /dev/null  ||  Error  "ERROR: different"
        diff  "back_up/sub_project/.env_example"  "example_project/sub_project/.env_example" > /dev/null  ||  Error  "ERROR: different"
        AssertExist  "back_up/.env_secret_example.zip"
        AssertExist  "back_up/.env_secret_example.hash"
        AssertExist  "back_up/sub_project/.env_secret_example.zip"
        AssertExist  "back_up/sub_project/.env_secret_example.hash"
        local  commitID_2="$( GetCommitID  "back_up" )"
        if [ "${commitID_2}" != "${commitID_1}" ]; then  Error  ;fi

        #// Commit 2 times
        echo  "s1__"  >  "example_project/.env_example"
        if [ "${testCase}" == "TestExampleProjectDirect" ]; then
            ${Lib}/back-up-files  "example_project/.back_up_files.ini"  ||  Error
        elif [ "${testCase}" == "TestExampleProjectScriptSimple" ]; then
            ${BinEx}/back-up-example  ||  Error
        elif [ "${testCase}" == "TestExampleProjectScriptParentIni" ]; then
            ${Bin}/back-up-local-settings  ||  Error
        fi
        echo  "s1"  >  "example_project/.env_example"
        if [ "${testCase}" == "TestExampleProjectDirect" ]; then
            ${Lib}/back-up-files  "example_project/.back_up_files.ini"  ||  Error
        elif [ "${testCase}" == "TestExampleProjectScriptSimple" ]; then
            ${BinEx}/back-up-example  ||  Error
        elif [ "${testCase}" == "TestExampleProjectScriptParentIni" ]; then
            ${Bin}/back-up-local-settings  ||  Error
        fi
        local  commitID_3="$( GetCommitID  "back_up" )"
        if [ "${commitID_3}" == "${commitID_2}" ]; then  Error  ;fi

    #// Restore short option name
        #// Set up
        rm -rf                 "_work"
        mkdir -p               "_work/example_project/sub_project"
        cp -ap  "back_up"      "_work/back_up"
        cp -ap  "bin"          "_work/bin"
        cp -ap  "bin_extra/"*  "_work/bin"
        cp -ap  "example_project/.back_up_files.ini"  "_work/example_project"
        echo  "THIS_FILE = __Secret__" > "_work/example_project/.env_secret_example"
        echo  "THIS_FILE = __Secret__" > "_work/example_project/sub_project/.env_secret_example"

        #// Main 1st restore
        if [ "${testCase}" == "TestExampleProjectDirect" ]; then
            ${WorkLib}/back-up-files  "_work/example_project/.back_up_files.ini"  -r  ||  Error
        elif [ "${testCase}" == "TestExampleProjectScriptSimple" ]; then
            ${WorkBin}/back-up-example  -r  ||  Error
        elif [ "${testCase}" == "TestExampleProjectScriptParentIni" ]; then
            ${WorkBin}/back-up-local-settings  -r  ||  Error
        fi

        #// Check
        diff  "_work/example_project/.env_example"                     "example_project/.env_example"                     > /dev/null  ||  Error  "ERROR: different"
        diff  "_work/example_project/sub_project/.env_example"         "example_project/sub_project/.env_example"         > /dev/null  ||  Error  "ERROR: different"
        diff  "_work/example_project/.env_secret_example"              "example_project/.env_secret_example"              > /dev/null  ||  Error  "ERROR: different"
        diff  "_work/example_project/sub_project/.env_secret_example"  "example_project/sub_project/.env_secret_example"  > /dev/null  ||  Error  "ERROR: different"

    #// Restore long option name
        #// Set up
        rm -rf    "_work/example_project"
        mkdir -p  "_work/example_project/sub_project"
        cp -ap  "example_project/.back_up_files.ini"  "_work/example_project"
        echo  "THIS_FILE = __Secret__" > "_work/example_project/.env_secret_example"
        echo  "THIS_FILE = __Secret__" > "_work/example_project/sub_project/.env_secret_example"

        #// Main 2nd restore
        if [ "${testCase}" == "TestExampleProjectDirect" ]; then
            ${WorkLib}/back-up-files  "_work/example_project/.back_up_files.ini"  --restore  ||  Error
        elif [ "${testCase}" == "TestExampleProjectScriptSimple" ]; then
            ${WorkBin}/back-up-example  --restore  ||  Error
        elif [ "${testCase}" == "TestExampleProjectScriptParentIni" ]; then
            ${WorkBin}/back-up-local-settings  --restore  ||  Error
        fi

        #// Check
        diff  "_work/example_project/.env_example"                     "example_project/.env_example"                     > /dev/null  ||  Error  "ERROR: different"
        diff  "_work/example_project/sub_project/.env_example"         "example_project/sub_project/.env_example"         > /dev/null  ||  Error  "ERROR: different"
        diff  "_work/example_project/.env_secret_example"              "example_project/.env_secret_example"              > /dev/null  ||  Error  "ERROR: different"
        diff  "_work/example_project/sub_project/.env_secret_example"  "example_project/sub_project/.env_secret_example"  > /dev/null  ||  Error  "ERROR: different"

    ResetBackUpTestFolder  "./back_up"
    rm -rf  "_work"
}

function  TestNestedMkdir() {
    echo  ""
    echo  "### TestNestedMkdir --------------------------------"
    cd  "${GitWorkingFolder}/test"

    #// Back up
        #// Set up
        mkdir -p    "nested_mkdir/work/a/b"
        echo  "a" > "nested_mkdir/work/a/b/c"
        rm -rf      "nested_mkdir/back_up/a"
        rm -f       "nested_mkdir/back_up/.back_up_files.ini"

        #// Main
        ${Bin}/back-up-files  "./nested_mkdir/.back_up_files.ini"

        #// Check
        if [ "$( cat  "nested_mkdir/back_up/a/b/c" )" != "a" ]; then  Error  ;fi
        if [ "$( cat  "nested_mkdir/back_up/.back_up_files.ini" )" != "$( cat  "nested_mkdir/.back_up_files.ini" )" ]; then  Error  ;fi

    #// Restore
        #// Set up
        mkdir -p    "nested_mkdir/back_up/a/b"
        echo  "a" > "nested_mkdir/back_up/a/b/c"
        rm -rf      "nested_mkdir/work/a"

        #// Main
        ${Bin}/back-up-files  "./nested_mkdir/.back_up_files.ini"  -r

        #// Check
        if [ "$( cat  "nested_mkdir/work/a/b/c" )" != "a" ]; then  Error  ;fi

    #// Clean
    rm -rf  "nested_mkdir/work/a"
    rm -rf  "nested_mkdir/back_up/a"
    rm -f   "nested_mkdir/back_up/.back_up_files.ini"
}

function  TestSameFolderError() {
    echo  ""
    echo  "### TestSameFolderError --------------------------------"
    cd  "${GitWorkingFolder}/test"
    rm -rf  "./error/same_back_up_folder/back_up"

    #// Main
    local  output="$( ${Bin}/back-up-files  "./error/same_back_up_folder/.back_up_files.ini" 2>&1 )"

    #// Check
    local  okCount=0
    if echo "${output}" | grep -E 'WorkingBaseFolder' > /dev/null; then  okCount="$(( okCount + 1 ))"  ;fi
    if echo "${output}" | grep -E 'BackUpBaseFolder' > /dev/null; then  okCount="$(( okCount + 1 ))"  ;fi
    if echo "${output}" | grep -E 'same_back_up_folder/.back_up_files.ini' > /dev/null; then  okCount="$(( okCount + 1 ))"  ;fi
    if [ "${okCount}" != 3 ]; then  Error  "ERROR: Bad okCount"  ;fi

    #// Clean
    rm -rf  "./error/same_back_up_folder/back_up"  #// Back up of ".back_up_files.ini" is not bad.
}

function  ResetBackUpTestFolder() {
    local  folder="$1"
    local  gitIgnoreContents="$2"
    pushd  "${GitWorkingFolder}"  > /dev/null

    rm -rf  "${folder}"
    mkdir   "${folder}"
    touch  "${folder}/ThisIsBackUp"
    if [ "${gitIgnoreContents}" != "" ]; then
        echo  "${gitIgnoreContents}"  >  "${folder}/.gitignore"
    fi
    cd  "${folder}"
    git init
    git config --local user.email "you@example.com"
    git config --local user.name "Your Name"
    git add  "."
    git commit -m "First commit"
    popd  > /dev/null
}

function  GetCommitID() {
    local  gitWorkingFolderPath="$1"
    pushd  "${gitWorkingFolderPath}"  > /dev/null  ||  Error

    git rev-parse --short HEAD
    popd  > /dev/null
}

function  SetVariableValue() {
    local  key_="$1"
    local  value="$2"
    local  filePath="$3"

    sed -i -E  's/('"${key_}"' *= *)"([^"]*)"/\1"'"${value}"'"/'  "${filePath}"
}

function  AssertExist() {
    local  path="$1"

    if [ ! -e "${path}" ]; then
        Error  "Not found \"${path}\""
    fi
}

function  AssertNotExist() {
    local  path="$1"

    if [ -e "${path}" ]; then
        Error  "Found \"${path}\""
    fi
}

function  AssertContents() {
    local  filePath="$1"
    local  expectedContents="$2"

    local  result="$(cat "${filePath}")"
    if [ "${result}" != "$( echo -e "${expectedContents}" )" ]; then
        Error  "ERROR: Not expected contents in ${filePath}: ${result}"
    fi
}

# pp
#     Debug print
# Example:
#     pp "$config"
#     pp "$config" config
#     pp "$array" array  ${#array[@]}  "${array[@]}"
#     pp "123"
#     $( pp "$config" >&2 )
function  pp() {
    local  value="$1"
    local  variableName="$2"
    if [ "${variableName}" != "" ]; then  variableName=" ${variableName} "  ;fi  #// Add spaces
    local  oldIFS="$IFS"
    IFS=$'\n'
    local  valueLines=( ${value} )
    IFS="$oldIFS"

    local  type=""
    if [ "${variableName}" != "" ]; then
        if [[ "$(declare -p ${variableName} 2>&1 )" =~ "declare -a" ]]; then
            local  type="array"
        fi
    fi
    if [ "${type}" == "" ]; then
        if [ "${#valueLines[@]}" == 1  -o  "${#valueLines[@]}" == 0 ]; then
            local  type="oneLine"
        else
            local  type="multiLine"
        fi
    fi

    if [[ "${type}" == "oneLine" ]]; then
        echo  "@@@${variableName}= \"${value}\" ---------------------------"  >&2
    elif [[ "${type}" == "multiLine" ]]; then
        echo  "@@@${variableName}---------------------------"  >&2
        echo  "\"${value}\"" >&2
    elif [[ "${type}" == "array" ]]; then
        echo  "@@@${variableName}---------------------------"  >&2
        local  count="$3"
        if [ "${count}" == "" ]; then
            echo  "[0]: \"$4\""  >&2
            echo  "[1]: ERROR: pp parameter is too few"  >&2
        else
            local  i=""
            for (( i = 0; i < ${count}; i += 1 ));do
                echo  "[$i]: \"$4\""  >&2
                shift
            done
        fi
    else
        echo  "@@@${variableName}? ---------------------------"  >&2
    fi
}

function  TestError() {
    local  errorMessage="$1"
    if [ "${errorMessage}" == "" ]; then
        errorMessage="a test error"
    fi
    if [ "${ErrorCountBeforeStart}" == "${NotInErrorTest}" ]; then

        echo  "ERROR: ${errorMessage}"
    fi
    LastErrorMessage="${errorMessage}"
    ErrorCount=$(( ${ErrorCount} + 1 ))
}
ErrorCount=0
LastErrorMessage=""

function  Error() {
    local  errorMessage="$1"
    local  exitCode="$2"
    if [ "${errorMessage}" == "" ]; then
        errorMessage="ERROR"
    fi
    if [ "${exitCode}" == "" ]; then  exitCode=2  ;fi

    echo  "${errorMessage}" >&2
    exit  "${exitCode}"
}
assert=""  #// This assert indicates to test the exit code

Main  "$@"
