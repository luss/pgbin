#!/bin/bash

##set -x

source ./versions.sh
buildOS=$OS
buildNumber=1

baseDir="`pwd`/.."
workDir="comp`date +%Y%m%d_%H%M`"
PGHOME=""

componentShortVersion=""
componentFullVersion=""
buildNumber=0

targetDir="/opt/pgbin-build/build"
sharedLibs="/opt/pgbin-build/pgbin/shared"

# Get PG Version from the provided pgBin directory
function getPGVersion {
	if [[ ! -f "$pgBin/bin/pg_config" ]]; then
		echo "pg_config is required for building components"
		echo "No such file or firectory : $pgBin/bin/pg_config "
		return 1
	fi
	pgFullVersion=`$pgBin/bin/pg_config --version | awk '{print $2}'`

        if [[ "${pgFullVersion/rc}" =~ 14.* ]]; then
                pgShortVersion="14"
        elif [[ "${pgFullVersion/rc}" =~ 13.* ]]; then
                pgShortVersion="13"
        elif [[ "${pgFullVersion/rc}" =~ 12.* ]]; then
                pgShortVersion="12"
        elif [[ "${pgFullVersion/rc}" =~ 11.* ]]; then
                pgShortVersion="11"
        elif [[ "${pgFullVersion/rc}" =~ 10.* ]]; then
                pgShortVersion="10"
	elif [[ "${pgFullVersion/rc}" == "$pgFullVersion" ]]; then
		pgShortVersion="`echo $pgFullVersion | awk -F '.' '{print $1$2}'`"
        else
                pgShortVersion="`echo $pgFullVersion | awk -F '.' '{print $1$2}'`"
                pgShortVersion="`echo ${pgShortVersion:0:2}`"
        fi

	#pgShortVersion=`echo $pgFullVersion | awk -F '.' '{print$1$2}'`
}


function prepComponentBuildDir {
	buildLocation=$1
	rm -rf $buildLocation
	mkdir -p $buildLocation
	mkdir -p $buildLocation/bin
        mkdir -p $buildLocation/share
	mkdir -p $buildLocation/lib/postgresql/pgxs
	cp $PGHOME/bin/pg_config $buildLocation/bin/
	cp $PGHOME/bin/postgres  $buildLocation/bin/
	cp -r $PGHOME/include $buildLocation/
	cp -r $PGHOME/lib/postgresql/pgxs/* $buildLocation/lib/postgresql/pgxs/
	cp $PGHOME/lib/libpq* $buildLocation/lib/
	cp $PGHOME/lib/libssl.so* $buildLocation/lib/
	cp $PGHOME/lib/libpgport.a $buildLocation/lib/
	cp $PGHOME/lib/libpgcommon.a $buildLocation/lib/
	#cp $PGHOME/lib/libcrypt*.so* $buildLocation/lib/
        cp $PGHOME/lib/postgresql/plpgsql.so $buildLocation/lib/postgresql/
}


function cleanUpComponentDir {
	cd $1
	rm -rf bin/pg_config
	rm -rf bin/postgres
	rm -rf lib/postgresql/plpgsql.so
	rm -rf include
	rm -rf lib/postgresql/pgxs
	rm -rf lib/libpgport.a
	rm -rf lib/libpgcommon.a
    rm -rf lib/libssl*
    rm -rf lib/libpq*
    rm -rf lib/libcrypt*

	if [[ ! "$(ls -A bin)" ]]; then
		rm -rf bin
	fi

    if [ "$copyBin" == "false" ]; then
        ls -lR
    fi
}


function  packageComponent {
	bundle="$targetDir/$workDir/$componentBundle.tar.bz2"
	echo "$bundle"

	cd "$baseDir/$workDir/build/"
	tar -cjf "$componentBundle.tar.bz2" $componentBundle
	rm -rf "$targetDir/$workDir"
	mkdir -p "$targetDir/$workDir"
	mv "$componentBundle.tar.bz2" "$targetDir/$workDir/"

	if [ "$copyBin" == "true" ]; then
		cp -pv $bundle $IN/postgres/$compDir/.
	elif [ "$noTar" == "true" ]; then
		echo "NO TAR"
		cd $targetDir/$workDir/
		tar -xvf $componentBundle.tar.bz2
		echo "cd $targetDir/$workDir/$componentBundle/lib/postgresql"
	fi

}


function updateSharedLibs {
        comp=$1

        if [ `uname` == "Darwin" ]; then
          suffix="*dylib*"
        else
          suffix="*so*"
        fi

        libPathLog=$baseDir/$workDir/logs/libPath.log

        if [[ -d $buildLocation/bin ]]; then
          cd $buildLocation/bin
          for file in `ls -d *` ; do
            chrpath -r "\${ORIGIN}/../lib" "$file" >> $libPathLog 2>&1
      	  done
        fi

        cd $buildLocation/lib
        for file in `ls -d *so*  2>/dev/null` ; do
          chrpath -r "\${ORIGIN}/../lib" "$file" >> $libPathLog 2>&1
        done

        if [[ -d "$buildLocation/lib/postgresql" ]]; then
          cd $buildLocation/lib/postgresql
          for file in `ls -d *so*  2>/dev/null` ; do
            chrpath -r "\${ORIGIN}/../../lib" "$file" >> $libPathLog 2>&1
          done
        fi

        ##cat $libPathLog

	lib64=/usr/lib64
	shared_lib=$buildLocation/lib
        if [ "$comp" == "mongofdw" ]; then
          cp -Pv $lib64/libmongo*.so* $shared_lib/.
          cp -Pv $lib64/libbson*.so*  $shared_lib/.
          cp -Pv $lib64/libicu*.so*   $shared_lib/.
        elif [ "$comp" == "mysqlfdw" ]; then
          cp -Pv $lib64/mysql/libmysqlclient.* $shared_lib/.
	elif [ "$comp" == "decoderbufs" ]; then
          lib64=/usr/local/lib
          cp -Pv $lib64/libproto*.so* $shared_lib/.
	elif [ "$comp" == "postgis" ]; then
          lib64=/usr/local/lib
          cp -Pv $lib64/libgeos*.so*  $shared_lib/.
          cp -Pv $lib64/libgdal*.so*  $shared_lib/.
          cp -Pv $lib64/libproto*.so* $shared_lib/.
          cp -Pv $lib64/libproj*.so*  $shared_lib/.
        fi
}


function buildTSQLComponent {

	componentName="pgtsql$pgTSQLShortV-pg$pgShortVersion-$pgTSQLFullV-$pgTSQLBuildV-$buildOS"
    echo "#   compNm: $componentName"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir pgtsql && tar -xf $tsqlSource --strip-components=1 -C pgtsql
	cd pgtsql

	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation


	PATH=$buildLocation/bin:$PATH
	USE_PGXS=1 make > $baseDir/$workDir/logs/pgtsql_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		 USE_PGXS=1 make install > $baseDir/$workDir/logs/pgtsql_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "TSQL install failed, check logs for details."
		fi
	else
		echo "TSQL Make failed, check logs for details."
		return 1
	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateSharedLibs
	packageComponent $componentBundle
}


function buildSetUserComponent {

	componentName="setuser$setUserShortVersion-pg$pgShortVersion-$setUserFullVersion-$setUserBuildV-$buildOS"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir setuser && tar -xf $setUserSource --strip-components=1 -C setuser
	cd setuser

	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation

	PATH=$buildLocation/bin:$PATH
	USE_PGXS=1 make > $baseDir/$workDir/logs/setuser_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		 USE_PGXS=1 make install > $baseDir/$workDir/logs/setuser_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "SetUser install failed, check logs for details."
		fi
	else
		echo "SetUser Make failed, check logs for details."
		return 1
	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateSharedLibs
	packageComponent $componentBundle
}


function configureComp {
    rc=0

    if [ "$comp" == "mongofdw" ]; then
        echo "# configure mongofdw..."
        export MONGOC_INSTALL_DIR=$buildLocation
        export JSONC_INSTALL_DIR=$buildLocation
        ./autogen.sh --with-master >> $make_log 2>&1
        rc=$?
    fi

    if [ "$comp" == "citus" ]; then
        echo "# configure citus..."
        ./configure --prefix=$buildLocation >> $make_log 2>&1 
        rc=$?
    fi

    if [ "$comp" == "pgtop" ]; then
        echo "# configure pgtop..."
        ./autogen.sh >> $make_log 2>&1
        ./configure --prefix=$buildLocation >> $make_log 2>&1 
        rc=$?
    fi

    if [ "$comp" == "backrest" ]; then
        echo "# configure backrest..."
        export LD_LIBRARY_PATH=$buildLocation/lib
        cd src
        ./configure --prefix=$buildLocation LDFLAGS="$LDFLAGS -Wl,-rpath,$sharedLibs" >> $make_log 2>&1 
        rc=$?
    fi

    if [ "$comp" == "psqlodbc" ]; then
        echo "# bootstrap psqlodbc..."
        ./bootstrap >> $make_log 2>&1
        rc=$?
        echo "# configure psqlodbc..."
        ./configure --prefix=$buildLocation >> $make_log 2>&1 
        rc=$?
    fi

    if [ "$comp" == "bouncer" ]; then
        echo "# configure bouncer..."
        opt="--prefix=$buildLocation --disable-rpath --with-cares --with-pam"
        opt="$opt --with-libevent=$sharedLibs/../ --with-openssl=$sharedLibs/../"
        echo "#    $opt"
        ./configure $opt LDFLAGS="$LDFLAGS -Wl,-rpath,$sharedLibs/lib" > $make_log 2>&1
        rc=$?
    fi

    if [ "$comp" == "agent" ]; then
        echo "# configure agent..."
        config="ccmake -DCMAKE_INSTALL_PREFIX=$buildLocation --config cfg ."
        echo "#   $config"
        $config > $make_log 2>&1
        rc=$?
    fi

    if [ "$comp" == "postgis" ]; then
        echo "# configure postgis..."
	export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
        ##./configure --without-protobuf LDFLAGS="$LDFLAGS -Wl,-rpath,$sharedLibs" > $make_log 2>&1
        ./configure LDFLAGS="$LDFLAGS -Wl,-rpath,$sharedLibs" > $make_log 2>&1
        rc=$?
    fi

    if [ ! "$rc" == "0" ]; then
       echo " "
       echo "ERROR: configureComp() failed, check make_log"
       echo " "
       tail -20 $make_log
       exit 1
    fi
}


function buildComp {
        comp="$1"
        ##echo "#        comp: $comp"
        shortV="$2"
        ##echo "#      shortV: $shortV"
        fullV="$3"
        ##echo "#       fullV: $fullV"
        buildV="$4"
        ##echo "#      buildV: $buildV"
        src="$5"
        ##echo "#         src: $src"

        if [ "$comp" == "bouncer" ] || [ "$comp" == "agent" ] || 
           [ "$comp" == "backrest" ] || [ "$comp" == "psqlodbc" ]; then
            componentName="$comp$shortV-$fullV-$buildV-$buildOS"
        else
            componentName="$comp$shortV-pg$pgShortVersion-$fullV-$buildV-$buildOS"
        fi
        echo "#      compNm: $componentName"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        rm -rf $comp
        mkdir $comp 
        cmd="tar -xf $src --strip-components=1 -C $comp"
        ##echo "# $cmd"
        $cmd
        cd $comp

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation

        PATH=$buildLocation/bin:$PATH
        log_dir="$baseDir/$workDir/logs"
        ##echo "#     log_dir: $log_dir"
        make_log="$log_dir/$comp-make.log"
        echo "#    make_log: $make_log"
        install_log="$log_dir/$comp-install.log"
        echo "# install_log: $install_log"

        configureComp

        if [ "$comp" == "hivefdw" ]; then
           buildLib=$buildLocation/lib
           ln -s /etc/alternatives/jre_11/lib/server/libjvm.so $buildLib/libjvm.so
        fi

        make_install="make install"
        if [ "$comp" == "multicorn2" ]; then
            sudo mkdir -p /usr/local/lib64/python3.6/site-packages
            make_install="sudo env "PATH=$PATH" make install"
            export PYTHON_OVERRIDE=python3.6
        fi

        echo "# make..."
        USE_PGXS=1 make >> $make_log 2>&1
        if [[ $? -eq 0 ]]; then
                echo "# make install..."
                USE_PGXS=1 $make_install > $install_log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo " "
                        echo "ERROR: Install failed, check install_log"
                        tail -20 $install_log
                        echo ""
                        return 1
                fi
        else
                echo " "
                echo "ERROR: Make failed, check make_log"
                echo " "
                tail -20 $make_log
                return 1
        fi

        if [ "$comp" == "multicorn2" ]; then
          sudo chown $USER:$USER $buildLocation/lib/postgresql/multicorn.so
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
        updateSharedLibs $comp
        packageComponent $componentBundle
}


function buildPgMpComponent {

        componentName="pgmp$pgmpShortVersion-pg$pgShortVersion-$pgmpFullVersion-$pgmpBuildV-$buildOS"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir pgmp  && tar -xf $pgmpSource --strip-components=1 -C pgmp
        cd pgmp

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation


        PATH=$buildLocation/bin:$PATH
        make > $baseDir/$workDir/logs/pgmp_make.log 2>&1
        if [[ $? -eq 0 ]]; then
                make docs    > $baseDir/$workDir/logs/pgmp_docs.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "pgmp docs failed, check logs for details."
                fi
        else
                echo "pgmp Make failed, check logs for details."
                return 1
        fi
        if [[ $? -eq 0 ]]; then
                make install > $baseDir/$workDir/logs/pgmp_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "pgmp install failed, check logs for details."
                fi
        else
                echo "pgmp Make failed, check logs for details."
                return 1
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
        updateSharedLibs
        packageComponent $componentBundle
}


function buildPlRComponent {

	componentName="plr$plRShortVersion-pg$pgShortVersion-$plRFullVersion-$plRBuildV-$buildOS"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir plr && tar -xf $plrSource --strip-components=1 -C plr
	cd plr

	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation
	export R_HOME=/opt/pgbin-build/pgbin/shared/linux_64/R323/lib64/R
	PATH=$buildLocation/bin:$PATH
	USE_PGXS=1 make > $baseDir/$workDir/logs/plr_make.log 2>&1
	if [[ $? -eq 0 ]]; then
		 USE_PGXS=1 make install > $baseDir/$workDir/logs/plr_install.log 2>&1
		if [[ $? -ne 0 ]]; then
			echo "MySQL FDW install failed, check logs for details."
		fi
	else
		echo "MySQL FDW Make failed, check logs for details."
		return 1
	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateSharedLibs
	packageComponent $componentBundle
}

function buildPlJavaComponent {
	echo "# buildPlJavaComponent()"
	componentName="pljava$pljavaShortV-pg$pgShortVersion-$pljavaFullV-$pljavaBuildV-$buildOS"
	echo "# ComponentName = $componentName"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	echo "#        Source = $Source"
	mkdir pljava && tar -xf $Source --strip-components=1 -C pljava
	cd pljava
	buildLocation="$baseDir/$workDir/build/$componentName"
	prepComponentBuildDir $buildLocation
	PATH=/opt/pgbin-build/pgbin/shared/maven/bin:$buildLocation/bin:$PATH
	log=$baseDir/$workDir/logs/pljava_make.log
	echo "#      Make Log = $log"
	mvn clean install >> $log 2>&1
	rc=$?
 	if [ $rc == "0" ]; then
		log=$baseDir/$workDir/logs/pljava_install.log
		echo "#   Install Log = $log"
		jar="pljava-packaging/target/pljava-pg`echo $pgFullVersion | awk -F '.' '{print $1"."$2}'`-amd64-Linux-gpp.jar"
		echo "#           Jar = $jar"
 		java -jar $jar > $log 2>&1 > $log 2>&1
 		if [[ $? -ne 0 ]]; then
 			echo "Pl/Java install failed, check logs for details."
 		fi
 	else
                 mkdir -p pljava-packaging/target
                 cp "/tmp/pljava-pg`echo $pgFullVersion | awk -F '.' '{print $1}'`-amd64-Linux-gpp.jar" pljava-packaging/target/
                 java -jar "pljava-packaging/target/pljava-pg`echo $pgFullVersion | awk -F '.' '{print $1}'`-amd64-Linux-gpp.jar" > $baseDir/$workDir/logs/pljava_install.log 2>&1
 	fi

	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateSharedLibs
	packageComponent $componentBundle
}


function buildPlProfilerComponent {

	componentName="plprofiler$plProfilerShortVersion-pg$pgShortVersion-$plProfilerFullVersion-$plprofilerBuildV-$buildOS"
	mkdir -p "$baseDir/$workDir/logs"
	cd "$baseDir/$workDir"
	mkdir plprofiler && tar -xf $plProfilerSource --strip-components=1 -C plprofiler
	cd plprofiler

	buildLocation="$baseDir/$workDir/build/$componentName"

	prepComponentBuildDir $buildLocation

	PATH=$buildLocation/bin:$PATH
	USE_PGXS=1 make > $baseDir/$workDir/logs/plprofiler_make.log 2>&1
        if [[ $? -eq 0 ]]; then
        	USE_PGXS=1 make install > $baseDir/$workDir/logs/plprofiler_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                                echo "Failed to install PlProfiler ..."
                fi
                mkdir -p $buildLocation/python/site-packages
                cd python-plprofiler
        	cp -R plprofiler $buildLocation/python/site-packages
        	#cp plprofiler-bin.py $buildLocation/bin/plprofiler
        	cd $buildLocation/python/site-packages
        	#tar -xf $psycopgSource
        else
        	echo "Make failed for PlProfiler .... "
        fi
        rm -rf build
	componentBundle=$componentName
	cleanUpComponentDir $buildLocation
	updateSharedLibs
	packageComponent $componentBundle
}


function buildBackgroundComponent {

        componentName="background$backgroundShortVersion-pg$pgShortVersion-$backgroundFullVersion-$backgroundBuildV-$buildOS"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir background && tar -xf $backgroundSource --strip-components=1 -C background
        cd background

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation


        PATH=$buildLocation/bin:$PATH
        USE_PGXS=1 make > $baseDir/$workDir/logs/background_make.log 2>&1
        if [[ $? -eq 0 ]]; then
                 USE_PGXS=1 make install > $baseDir/$workDir/logs/background_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "Background install failed, check logs for details."
                fi
        else
                echo "Background Make failed, check logs for details."
                return 1
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
        updateSharedLibs
        packageComponent $componentBundle
}


function buildCstoreFDWComponent {

        componentName="cstore_fdw$cstoreFDWShortVersion-pg$pgShortVersion-$cstoreFDWFullVersion-$cstoreFDWBuildV-$buildOS"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir cstore_fdw && tar -xf $cstoreFDWSource --strip-components=1 -C cstore_fdw
        cd cstore_fdw

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation


        PATH=$buildLocation/bin:$PATH:/opt/pgbin-build/pgbin/shared/linux_64/bin
        make_log=$baseDir/$workDir/logs/cstore_make.log
        USE_PGXS=1 make > $make_log 2>&1
        if [[ $? -eq 0 ]]; then
                 USE_PGXS=1 make install > $baseDir/$workDir/logs/cstore_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "CSTORE FDW install failed, check logs for details."
                fi
        else
                echo "CSTORE FDW Make failed, check logs for details."
                cat $make_log
                return 1
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
        updateSharedLibs
        packageComponent $componentBundle
}



function buildTimeScaleDBComponent {

        componentName="timescaledb-pg$pgShortVersion-$timescaledbFullV-$timescaledbBuildV-$buildOS"
        echo "#   compNm: $componentName"
        mkdir -p "$baseDir/$workDir/logs"
        cd "$baseDir/$workDir"
        mkdir timescaledb && tar -xf $timescaleDBSource --strip-components=1 -C timescaledb
        cd timescaledb

        buildLocation="$baseDir/$workDir/build/$componentName"

        prepComponentBuildDir $buildLocation

        PATH=/opt/pgbin-build/pgbin/bin:$buildLocation/bin:$PATH

	bootstrap_log=$baseDir/$workDir/logs/timescaledb_bootstrap.log
	##./bootstrap -DAPACHE_ONLY=1 -DREGRESS_CHECKS=OFF > $bootstrap_log 2>&1
	./bootstrap -DREGRESS_CHECKS=OFF > $bootstrap_log 2>&1
        if [[ $? -ne 0 ]]; then
                echo "timescaledb Bootstrap failed, check logs for details."
                echo "  $bootstrap_log"
                return 1
        fi

	cd build
        make_log=$baseDir/$workDir/logs/timescaledb_make.log
        USE_PGXS=1 make -d > $make_log 2>&1
        if [[ $? -eq 0 ]]; then
                USE_PGXS=1 make install > $baseDir/$workDir/logs/timescaledb_install.log 2>&1
                if [[ $? -ne 0 ]]; then
                        echo "timescaledb install failed, check logs for details."
                fi
        else
                echo "timescaledb Make failed, check logs for details."
                echo "  $make_log"
                return 1
        fi

        componentBundle=$componentName
        cleanUpComponentDir $buildLocation
        updateSharedLibs
        packageComponent $componentBundle
}

TEMP=`getopt -l no-tar, copy-bin,no-copy-bin,with-pgver:,with-pgbin:,build-hypopg:,build-postgis:,build-bouncer:,build-hvefdw:,build-cassandrafdw:,build-pgtsql:,build-tdsfdw:,build-mongofdw:,build-mysqlfdw:,build-pgredis:,build-oraclefdw:,build-orafce:,build-audit:,build-set-user:,build-partman:,build-pldebugger:,build-plr:,build-pljava:,build-plv8:,build-plprofiler:,build-background:,build-bulkload:,build-backrest:,build-psqlodbc:,build-cstore-fdw:,build-parquets3fdw:,build-repack:,build-spock:,build-pglogical:,build-hintplan:,build-statkcache:,build-qualstats:,build-archivist:,build-waitsampling:,build-timescaledb:,build-cron:,build-multicorn2:,build-pgmp:,build-fixeddecimal:,build-anon,build-ddlx:,build-http:,build-pgtop:,build-proctab:,build-agent:,build-citus:,build-number: -- "$@"`

if [ $? != 0 ] ; then
	echo "Required parameters missing, Terminating..."
	exit 1
fi

copyBin=false
compDir="$8"

while true; do
  case "$1" in
    --with-pgver ) pgVer=$2; shift; shift; ;;
    --with-pgbin ) pgBinPassed=true; pgBin=$2; shift; shift; ;;
    --target-dir ) targetDirPassed=true; targetDir=$2; shift; shift ;;
    --build-postgis ) buildPostGIS=true; Source=$2; shift; shift ;;
    --build-bouncer ) buildBouncer=true; Source=$2; shift; shift; ;;
    --build-hivefdw ) buildHiveFDW=true; Source=$2; shift; shift ;;
    --build-cassandrafdw ) buildCassandraFDW=true; Source=$2; shift; shift; ;;
    --build-pgtsql ) buildTSQL=true; tsqlSource=$2; shift; shift ;;
    --build-tdsfdw ) buildTDSFDW=true; Source=$2; shift; shift ;;
    --build-mongofdw ) buildMongoFDW=true Source=$2; shift; shift ;;
    --build-wal2json ) buildWal2json=true Source=$2; shift; shift ;;
    --build-decoderbufs ) buildDecoderBufs=true Source=$2; shift; shift ;;
    --build-mysqlfdw ) buildMySQLFDW=true; Source=$2; shift; shift ;;
    --build-pgredis ) buildPgRedis=true; Source=$2; shift; shift ;;
    --build-oraclefdw ) buildOracleFDW=true; Source=$2; shift; shift ;;
    --build-orafce ) buildOrafce=true; Source=$2; shift; shift ;;
    --build-fixeddecimal ) buildFD=true; Source=$2; shift; shift ;;
    --build-audit ) buildAudit=true; Source=$2; shift; shift ;;
    --build-set-user ) buildSetUser=true; setUserSource=$2; shift; shift ;;
    --build-hypopg ) buildHypopg=true; Source=$2; shift; shift ;;
    --build-pldebugger ) buildPLDebugger=true; Source=$2; shift; shift ;;
    --build-partman ) buildPartman=true; Source=$2; shift; shift ;;
    --build-plr ) buildPlr=true; plrSource=$2; shift; shift ;;
    --build-plv8 ) buildPlV8=true; Source=$2; shift; shift ;;
    --build-pljava ) buildPlJava=true; Source=$2; shift; shift ;;
    --build-plprofiler ) buildPlProfiler=true; plProfilerSource=$2; shift; shift ;;
    --build-background ) buildBackground=true; backgroundSource=$2; shift; shift ;;
    --build-bulkload ) buildBulkLoad=true; Source=$2; shift; shift ;;
    --build-psqlodbc ) buildODBC=true; Source=$2; shift; shift ;;
    --build-backrest ) buildBackrest=true; Source=$2; shift; shift ;;
    --build-cstore-fdw ) buildCstoreFDW=true; cstoreFDWSource=$2; shift; shift ;;
    --build-parquets3fdw ) buildParquetS3FDW=true; Source=$2; shift; shift ;;
    --build-repack ) buildRepack=true; Source=$2; shift; shift ;;
    --build-pglogical ) buildPgLogical=true; Source=$2; shift; shift ;;
    --build-spock ) buildSpock=true; Source=$2; shift; shift ;;
    --build-hintplan ) buildHintPlan=true; Source=$2; shift; shift ;;
    --build-archivist ) buildArchiv=true; Source=$2; shift; shift ;;
    --build-qualstats ) buildQualStats=true; Source=$2; shift; shift ;;
    --build-waitsampling ) buildWaitSampling=true; Source=$2; shift; shift ;;
    --build-statkcache ) buildStatKcache=true; Source=$2; shift; shift ;;
    --build-timescaledb ) buildTimeScaleDB=true; timescaleDBSource=$2; shift; shift ;;
    --build-cron ) buildCron=true; Source=$2; shift; shift ;;
    --build-multicorn2 ) buildMulticorn2=true; Source=$2; shift; shift ;;
    --build-pgmp ) buildPgMp=true; pgmpSource=$2; shift; shift ;;
    --build-anon ) buildAnon=true; Source=$2; shift; shift ;;
    --build-ddlx ) buildDdlx=true; Source=$2; shift; shift ;;
    --build-http ) buildHttp=true; Source=$2; shift; shift ;;
    --build-pgtop ) buildPgTop=true; Source=$2; shift; shift ;;
    --build-proctab ) buildProctab=true; Source=$2; shift; shift ;;
    --build-agent ) buildAgent=true; Source=$2; shift; shift ;;
    --build-citus ) buildCitus=true; Source=$2; shift; shift ;;
    --copy-bin ) copyBin=true; shift; shift; ;;
    --no-copy-bin ) copyBin=false; shift; shift; ;;
    --no-tar ) copyBin=false; noTar=true; shift; shift; ;;
    -- ) shift; break ;;
    -* ) echo "Invalid Option Passed"; exit 1; ;;
    * ) break ;;
  esac
done

if [[ $pgBinPassed != "true" ]]; then
	echo "Please provide a valid PostgreSQL version to build ..."
	exit 1
fi

getPGVersion

PGHOME=$pgBin

if [[ $buildCassandraFDW == "true" ]]; then
	buildComp cassandrafdw "$cassShortV" "$cassFullV" "$cassBuildV" "$Source"
fi

if [[ $buildHiveFDW == "true" ]]; then
	buildComp hivefdw "$hivefdwShortV" "$hivefdwFullV" "$hivefdwBuildV" "$Source"
fi

if [[ $buildOrafce == "true" ]]; then
	buildComp orafce "$orafceShortV" "$orafceFullV" "$orafceBuildV" "$Source"
fi

if [[ $buildMongoFDW == "true" ]]; then
	buildComp mongofdw "$mongofdwShortV" "$mongofdwFullV" "$mongofdwBuildV" "$Source"
fi

if [[ $buildDecoderBufs == "true" ]]; then
	export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
	buildComp decoderbufs "$decoderbufsShortV" "$decoderbufsFullV" "$decoderbufsBuildV" "$Source"
fi

if [[ $buildWal2json == "true" ]]; then
	buildComp wal2json "$wal2jsonShortV" "$wal2jsonFullV" "$wal2jsonBuildV" "$Source"
fi

if [[ $buildTDSFDW == "true" ]]; then
	buildComp tdsfdw "$tdsfdwShortV" "$tdsfdwFullV" "$tdsfdwBuildV" "$Source"
fi

if [[ $buildOracleFDW == "true" ]]; then
	echo "ORACLE_HOME=$ORACLE_HOME"
	if [ ! "$ORACLE_HOME" > " " ]; then
		echo "FATAL ERROR: ORACLE_HOME is not set"
		exit 1
	fi
	buildComp oraclefdw "$oraclefdwShortV" "$oraclefdwFullV" "$oraclefdwBuildV" "$Source"
fi

if [[ $buildMySQLFDW == "true" ]]; then
	buildComp mysqlfdw "$mysqlfdwShortV" "$mysqlfdwFullV" "$mysqlfdwBuildV" "$Source"
fi

if [[ $buildPgRedis == "true" ]]; then
	buildComp pgredis "$pgredisShortV" "$pgredisFullV" "$pgredisBuildV" "$Source"
fi

if [[ $buildPostGIS ==  "true" ]]; then
	buildComp postgis "$postgisShortV" "$postgisFullV" "$postgisBuildV" "$Source"
fi
if [[ $buildAudit == "true" ]]; then
	buildComp audit "$auditShortV" "$auditFull14V" "$auditBuildV" "$Source"
fi
if [[ $buildSetUser == "true" ]]; then
	buildSetUserComponent
fi
if [ "$buildHypopg" == "true" ]; then
	buildComp hypopg "$hypopgShortV" "$hypopgFullV" "$hypopgBuildV" "$Source"
fi
if [ "$buildCron" == "true" ]; then
	buildComp cron  "$cronShortV" "$cronFullV" "$cronBuildV" "$Source"
fi
if [ "$buildMulticorn2" == "true" ]; then
	buildComp multicorn2  "$multicorn2ShortV" "$multicorn2FullV" "$multicorn2BuildV" "$Source"
fi
if [[ $buildRepack == "true" ]]; then
	buildComp repack  "$repackShortV" "$repackFullV" "$repackBuildV" "$Source"
fi
if [[ $buildPgLogical == "true" ]]; then
	buildComp pglogical  "$pgLogicalShortV" "$pgLogicalFullV" "$pgLogicalBuildV" "$Source"
fi

if [[ $buildPLDebugger == "true" ]]; then
	buildComp pldebugger  "$debugShortV" "$debugFullV" "$debugBuildV" "$Source"
fi

if [[ $buildPartman == "true" ]]; then
	buildComp partman "$partmanShortV" "$partmanFullV" "$partmanBuildV" "$Source"
fi

if [[ $buildPlr == "true" ]]; then
	buildPlRComponent
fi
if [[ $buildPlJava == "true" ]]; then
	buildPlJavaComponent
fi
if [[ $buildPlV8 == "true" ]]; then
    buildComp plv8  "$plv8ShortV" "$plv8FullV" "$plv8BuildV" "$Source"
fi
if [[ $buildTSQL == "true" ]]; then
	buildTSQLComponent
fi
if [[ $buildPlProfiler == "true" ]]; then
	buildPlProfilerComponent
fi
if [[ $buildBackground == "true" ]]; then
	buildBackgroundComponent
fi
if [[ $buildBulkLoad == "true" ]]; then
	buildComp bulkload "$bulkloadShortV" "$bulkloadFullV" "$bulkloadBuildV" "$Source"
fi
if [[ $buildODBC == "true" ]]; then
	buildComp psqlodbc "$odbcShortV" "$odbcFullV" "$odbcBuildV" "$Source"
fi
if [[ $buildBackrest == "true" ]]; then
	buildComp backrest "$backrestShortV" "$backrestFullV" "$backrestBuildV" "$Source"
fi
if [[ $buildCstoreFDW == "true" ]]; then
	buildCstoreFDWComponent
fi
if [[ $buildParquetS3FDW == "true" ]]; then
	buildComp parquets3fdw "$parquetShortV" "$parquetFullV" "$parquetBuildV" "$Source"
fi
if [[ $buildHintPlan == "true" ]]; then
	buildComp hintplan "$hintplanShortV" "$hintplanFullV" "$hintplanBuildV" "$Source"
fi
if [[ $buildArchiv == "true" ]]; then
	buildComp archivist "$archivShortV" "$archivFullV" "$archivBuildV" "$Source"
fi
if [[ $buildQualStats == "true" ]]; then
	buildComp qualstats "$qstatShortV" "$qstatFullV" "$qstatBuildV" "$Source"
fi
if [[ $buildWaitSampling == "true" ]]; then
	buildComp waitsampling "$waitsShortV" "$waitsFullV" "$waitsBuildV" "$Source"
fi
if [[ $buildStatKcache == "true" ]]; then
	buildComp statkcache "$statkShortV" "$statkFullV" "$statkBuildV" "$Source"
fi
if [[ $buildTimeScaleDB == "true" ]]; then
	buildTimeScaleDBComponent
fi
if [[ $buildPgMp == "true" ]]; then
	buildPgMpComponent
fi
if [[ $buildBouncer == "true" ]]; then
	buildComp bouncer "$bouncerShortV" "$bouncerFullV" "$bouncerBuildV" "$Source"
fi
if [[ $buildFD == "true" ]]; then
	buildComp fixeddecimal "$fdShortV" "$fdFullV" "$fdBuildV" "$Source"
fi
if [[ $buildAnon == "true" ]]; then
	buildComp anon "$anonShortV" "$anonFullV" "$anonBuildV" "$Source"
fi
if [[ $buildDdlx == "true" ]]; then
	buildComp ddlx "$ddlxShortV" "$ddlxFullV" "$ddlxBuildV" "$Source"
fi
if [[ $buildHttp == "true" ]]; then
	buildComp http "$httpShortV" "$httpFullV" "$httpBuildV" "$Source"
fi
if [[ $buildPgTop == "true" ]]; then
	buildComp pgtop "$pgtopShortV" "$pgtopFullV" "$pgtopBuildV" "$Source"
fi
if [[ $buildProctab == "true" ]]; then
	buildComp proctab "$proctabShortV" "$proctabFullV" "$proctabBuildV" "$Source"
fi
if [ "$buildAgent" == "true" ]; then
	buildComp agent "$agentShortV" "$agentFullV" "$agentBuildV" "$Source"
fi
if [ "$buildCitus" == "true" ]; then
	buildComp citus "$citusShortV" "$citusFullV" "$citusBuildV" "$Source"
fi

destDir=`date +%Y-%m-%d`
fullDestDir=/opt/pgbin-builds/$destDir

exit 0

