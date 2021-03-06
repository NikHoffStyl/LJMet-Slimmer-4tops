#!/bin/bash

hostname
date

infilename=${1}
outfilename=${2}
inputDir=${3}
outputDir=${4}
idlist=${5}
ID=${6}
Year=${7}
scratch=${PWD}

source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=slc7_amd64_gcc700
scramv1 project CMSSW CMSSW_10_2_16_UL
cd CMSSW_10_2_16_UL
eval `scramv1 runtime -sh`
cd -

echo "setting macroDir to PWD"
macroDir=${PWD}
export PATH=$PATH:$macroDir
root -l -b -q compileStep1.C

XRDpath=root://cmseos.fnal.gov/$inputDir
if [[ $inputDir == /isilon/hadoop/* ]] ;
then
XRDpath=root://brux11.hep.brown.edu:1094/$inputDir
fi

# export PYTHONHOME=/cvmfs/cms.cern.ch/slc7_amd64_gcc700/external/python/2.7.14/

echo "Running step1 over list: ${idlist}"
rm filelist
for iFile in $idlist; do
    inFile=${iFile}
    if [[ $iFile == ext* ]] ;
    then
	inFile=${iFile:4}
    elif [[ $iFile == [ABCDEFWXYZ]* ]] ;
    then
	inFile=${iFile:1}
    fi

    echo "adding ${outfilename}_${iFile}.root to the list by reading ${infilename}_${inFile}"
    echo  $XRDpath/${infilename}_${inFile}.root,${outfilename}_${iFile}.root>> filelist
    # root -l -b -q makeStep1.C\(\"$macroDir\",\"$XRDpath/${infilename}_${inFile}.root\",\"${outfilename}_${iFile}.root\",${Year}\)
done

# root -l -b -q makeStep1.C\(\"$macroDir\",\"filelist\",${Year}\)
echo gROOT-\>LoadMacro\(\"makeStep1.C++\"\)\; makeStep1\(\"$macroDir\",\"filelist\",${Year}\)\; | root -b -l

echo "ROOT Files:"
ls -l *.root

# copy output to eos

NOM="nominal"
echo "xrdcp output for condor"
for SHIFT in nominal JECup JECdown JERup JERdown
  do
  haddFile=${outfilename}_${ID}${SHIFT}_hadd.root
  hadd ${haddFile} *${SHIFT}.root

  if [[ $outputDir == /pnfs/iihe/* ]] ;
  then # for qsub or cmsconnnect jobs
    echo scram unsetenv -sh
    eval `scram unsetenv -sh`
    echo "gfal-copy -f file://$PWD/${haddFile} srm://maite.iihe.ac.be:8443/${outputDir//$NOM/$SHIFT}/${haddFile//${SHIFT}_hadd/}"
    gfal-copy -f file://$PWD/${haddFile} srm://maite.iihe.ac.be:8443/${outputDir//$NOM/$SHIFT}/${haddFile//${SHIFT}_hadd/} 2>&1
    echo "cmsenv"
    cd CMSSW_10_2_16_UL
    eval `scramv1 runtime -sh`
    cd -
  else # for condor jobs on lpc
    echo "xrdcp -f ${haddFile} root://cmseos.fnal.gov/${outputDir//$NOM/$SHIFT}/${haddFile//${SHIFT}_hadd/}"
    xrdcp -f ${haddFile} root://cmseos.fnal.gov/${outputDir//$NOM/$SHIFT}/${haddFile//${SHIFT}_hadd/} 2>&1
  fi

  XRDEXIT=$?
  if [[ $XRDEXIT -ne 0 ]]; then
    rm *.root
    echo "exit code $XRDEXIT, failure in xrdcp (or gfal-copy)"
    exit $XRDEXIT
  fi
  rm *${SHIFT}.root
  rm ${haddFile}
  if [[ $haddFile == Single* || $haddFile == EGamma*  || $haddFile == JetHT* ]]; then break; fi;
done

echo "done"
