#!/bin/bash
#irods-chks.sh

oneTimeSetUp()
{
. /software/irods/etc/profile.irods
}

setUp()
{
export irodsEnvFile=~/.irods/.irodsEnv
export generictst="irods-tst"
touch $generictst
}

testBasicEnv()
{
ienv > /dev/null
exitcode=$?
assertEquals "ienv failed, check that the installation completed ok" 0 "$exitcode"
}

testiPwd()
{
ipwd > /dev/null
assertEquals "ipwd failed, check PATH and system is up" 0 "$exitcode"
}

testiLs()
{
ils > /dev/null
assertEquals "ils failed, check PATH and system is up" 0 "$exitcode"
}

testiPutdefault()
{
iput -K -f irods-tst > /dev/null
assertEquals "iput basic failed, check PATH, ienv, accounts and resources" 0 "$exitcode"
}

testiRM()
{
irm irods-tst > /dev/null
assertEquals "irm failed to remove irods-tst. If it's there then it's bust" 0 "$exitcode"
}

testiPutRed()
{
gp=`iadmin lrg|grep red|grep -v full`
if [ -z "$gp" ] ; then 
  gp=demoResc
fi
iput -K -f -R $gp $generictst > /dev/null
assertEquals "iput red failed to complete." 0 "$exitcode"

irm $generictst
}

testiPutGreen()
{
gp=`iadmin lrg|grep green|grep -v full`
if [ -z "$gp" ] ; then
  gp=demoResc
fi
iput -K -f -R $gp $generictst > /dev/null
assertEquals "iput green failed to complete" 0 "$exitcode"

irm $generictst
}

testRtoGreplication()
{
gp=`iadmin lrg|grep red|grep -v full`
iput -K -f -R $gp $generictst
numcopy=`ils -l $generictst | wc -l`
assertEquals "hmm $numcopy not 2 as intended" 2 "$numcopy"

irm $generictst
}

testGtoRreplication()
{
gp=`iadmin lrg|grep red|grep -v full`
iput -K -f -R $gp $generictst
numcopy=`ils -l $generictst | wc -l`
assertEquals "hmm $numcopy not 2 as intended" 2 "$numcopy"

irm $generictst
}

testiMetaAdd()
{
iput -K $generictst
sleep 2
imeta add -d $generictst testname testvalue testunit
assertEquals "Unable to add metadata" 0 "$exitcode"
}

testiMetaLs()
{
chkmeta=`imeta ls -d $generictst`
if [ -z "$chkmeta" ] ; then
  assertEquals "No metadata found :(. Did the add fail ?" 0 "$exitcode"
fi

irm $generictst
}

testAccountAddition()
{
iadmin mkuser testuseraccount rodsuser
assertEquals "unable to create an iRODS account" 0 "$exitcode"
}

testRemoveAccount()
{
iadmin rmuser testuseraccount
assertEquals "unable to delete iRODS account" 0 "$exitcode"
}


. /software/isg/shunit2-2.1.6/src/shunit2
