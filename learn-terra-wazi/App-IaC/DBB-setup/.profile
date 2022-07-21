#!/bin/sh
PS1='$LOGNAME':'$PWD':' >'
export DBB_HOME=/u/ibmuser/waziDBB
export DBB_CONF=$DBB_HOME/conf
export GROOVY_HOME=$DBB_HOME/groovy
export GROOVY_CONF="$GROOVY_HOME/conf/groovy-starter.conf"
export GIT_HOME=/rsusr/ported
export JAVA_HOME=/usr/lpp/java/J8.0_64
export PATH=$GIT_HOME/bin:$GROOVY_HOME/bin:$DBB_HOME/bin:/bin:/usr/sbin:$PATH
export CLASSPATH=/usr/lpp/IBM/dbb/lib/*:$DBB_HOME/groovy-2.4.12/lib/*:/usr/include/java_classes/isfjcall.jar:$CLASSPATH
export LIBPATH=/usr/lpp/IBM/dbb/lib:/usr/lib/java_runtime64:/lib:/usr/lib:.:$LIBPATH 
export _BPXK_AUTOCVT=ON
export _CEE_RUNOPTS="FILETAG(AUTOCVT,AUTOTAG) POSIX(ON)"

export ZOAU_HOME=/usr/lpp/IBM/zoautil
export PATH=$PATH:/usr/lpp/IBM/zoautil/bin
export LIBPATH=$LIBPATH:/usr/lpp/IBM/zoautil/lib
echo '.profile started DBBHOME=$DBB_HOME  ZAPPBUILD=$DBB_HOME/dbb-zappbuild '