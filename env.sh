
bundle=oscg
api=io
hubV=6.70

I14=14.3-1

P17=17.2-1

k8sV=1.22

walgV=2.0.0-rc1
goV=1.17.4

multicorn2V=2.3-1
esfdwV=0.11.1
bqfdwV=1.9

w2jV=2.4-1
odbcV=13.01-1
citusV=11.0.2-1

oraclefdwV=2.4.0-1
inclV=21.6
orafceV=3.21.0-1
ora2pgV=23.1
v8V=2.3.15-1

fdV=1.1.0-1
anonV=0.12.0-1
ddlxV=0.17-1
hypoV=1.3.1-1
timescaleV=2.7.0-1
logicalV=2.4.1-1
profV=4.1-1
bulkloadV=3.1.19-1
partmanV=4.6.1-1
repackV=1.4.7-1
hintV=1.4.0-1

waV=2.1-1

dbzV=1.8.1.Final
apicV=2.2.0
decbufsV=1.7.0-1

zooV=3.7.0
kfkV=3.9.0

adminV=5.5
omniV=2.17.0

audit17V=1.6.2-1
postgisV=3.2.1-1

pljavaV=1.6.2-1
debuggerV=1.4-1
cronV=1.4.1-1

badgerV=11.6
patroniV=2.1.1

HUB="$PWD"
SRC="$HUB/src"
zipOut="off"
isENABLED=false

pg="postgres"

OS=`uname -s`
OS=${OS:0:7}

if [[ $OS == "Linux" ]]; then
  if [ `arch` == "aarch64" ]; then
    OS=arm
    outDir=a64
  else
    OS=amd;
    outDir=l64
  fi
  sudo="sudo"
elif [[ $OS == "Darwin" ]]; then
  outDir=m64
  if [ `arch` == "aarch64" ]; then
    OS=arm
  else
    OS=amd;
  fi
  sudo="sudo"
elif [[ $OS = "MINGW64" ]]; then
  outDir=w64
  OS=osx
  sudo=""
else
  echo "ERROR: '$OS' is not supported"
  return
fi

plat=$OS
