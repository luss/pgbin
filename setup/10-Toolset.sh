# PGBIN SETUP 


EMAIL="denis@lussier.io"
NAME="denis lussier"
git config --global user.email "$EMAIL"
git config --global user.name "$NAME"
git config --global push.default simple
git config --global credential.helper store
git config --global pull.rebase false

##set -x

uname=`uname`
uname=${uname:0:7}

if [ $uname == 'Linux' ]; then
  owner_group="$USER:$USER"
  yum --version > /dev/null 2>&1
  rc=$?
  if [ "$rc" == "0" ]; then
    YUM="y"
  else
    YUM="n"
  fi

  if [ "$YUM" == "n" ]; then
    sudo apt install wget curl git python3 openjdk-17-jdk
  fi

  if [ "$YUM" == "y" ]; then
    PLATFORM=`cat /etc/os-release | grep PLATFORM_ID | cut -d: -f2 | tr -d '\"'`
    if [ "$PLATFORM" == "el9" ]; then
      echo "## $PLATFORM ##"
      yum="dnf -y install"
      sudo $yum epel-release
      sudo dnf config-manager --set-enabled powertools
      sudo $yum wget python3 python3-devel
      sudo $yum java-11-openjdk-devel maven
      sudo dnf -y groupinstall 'development tools'
      sudo $yum zlib-devel bzip2-devel \
        openssl-devel libxslt-devel libevent-devel c-ares-devel \
        perl-ExtUtils-Embed sqlite-devel \
        pam-devel openldap-devel boost-devel unixODBC-devel
      sudo $yum curl-devel chrpath clang-devel llvm-devel \
        cmake libxml2-devel protobuf-c-devel libyaml-devel
      sudo $yum libedit-devel 
      sudo $yum *ossp-uuid*
      sudo $yum python2 python2-devel
      cd /usr/bin
      sudo ln -fs python2 python
      sudo $yum mongo-c-driver-devel freetds-devel proj-devel mysql-devel
      sudo $yum lz4-devel libzstd-devel
      sudo $yum geos-devel gdal-devel hiredis-devel
      sudo $yum krb5-devel
      sudo $yum libyaml libyaml-devel
      sudo $yum libcxx libcxx-devel
      sudo alternatives --config java
    fi
  fi

elif [ $uname == 'Darwin' ]; then
  owner_group="$USER:staff"
  if [ "$SHELL" != "/bin/bash" ]; then
    chsh -s /bin/bash
  fi
  brew --version > /dev/null 2>&1
  rc=$?
  if [ ! "$rc" == "0" ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  brew install pkg-config krb5 wget curl readline lz4 openssl@1.1 python@3.10 openldap ossp-uuid

elif [ $uname == "MINGW64" ]; then
  pacman -S --needed base-devel mingw-w64-x86_64-gcc gcc git curl vim wget python-devel sqlite3 perl perl-ExtUtils-MakeMaker
  pacman -S --needed  mingw-w64-x86_64-openldap mingw-w64-x86_64-zlib mingw-w64-x86_64-llvm  mingw-w64-x86_64-clang 

else
  echo "$uname is unsupported"
  exit 1
fi

$sudo mkdir -p /opt/pgbin-build
$sudo chown $owner_group /opt/pgbin-build
$sudo mkdir -p /opt/pgbin-build/pgbin/bin
$sudo mkdir -p /opt/pgcomponent
$sudo chown $owner_group /opt/pgcomponent
mkdir -p ~/dev
cd ~/dev
mkdir -p in
mkdir -p out
mkdir -p history

pip3 --version > /dev/null 2>&1
rc=$?
if [ ! "$rc" == "0" ]; then
  cd ~
  wget https://bootstrap.pypa.io/get-pip.py
  python3 get-pip.py
  rm get-pip.py
fi


aws --version > /dev/null 2>&1 
rc=$?
if [ ! "$rc" == "0" ]; then
  pip3 install --user awscli
  mkdir -p ~/.aws
  cd ~/.aws
  touch config
  # vi config
  chmod 600 config
fi

cd ~/dev/pgsql-io
if [ -f ~/.bashrc ]; then
  bf=~/.bashrc
else
  bf=~/.bash_profile
fi
grep IO $bf > /dev/null 2>&1
rc=$?
if [ ! "$rc" == "0" ]; then
  cat bash_profile >> $bf
fi

echo ""
echo "Goodbye!"
