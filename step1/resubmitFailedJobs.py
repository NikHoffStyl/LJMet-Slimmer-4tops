#!/usr/bin/python

import os,sys,pickle

inputDir = '/uscms_data/d3/ssagir/FWLJMET102X_1lep2017_4t_071919_step1/'
inputRdir = '/eos/uscms/store/user/lpcljm/FWLJMET102X_1lep2017_4t_071919_step1/'

samplesDone = []
if os.path.exists(os.getcwd()+'/samplesDone.p'): pickle.load(open('samplesDone.p','rb'))
i=0
samples = [x for x in os.walk(inputDir).next()[1]]
for sample in samples:
	#if 'Single' not in sample: continue
	print "SAMPLE:",sample
	if sample in samplesDone: continue
	files = [x for x in os.listdir(inputDir+'/'+sample) if '.job' in x]
	sampleDone = True
	for file in files:
		jFile = inputDir+'/'+sample+'/'+file
		lFile = inputDir+'/'+sample+'/'+file.replace('.job','.log')
		eFile = inputDir+'/'+sample+'/'+file.replace('.job','.err')
		oFile = inputDir+'/'+sample+'/'+file.replace('.job','.out')
		
		isOutFileExist = False
		isOutFileOK = False
		isErrFileExist = False
		isThereError = False
		isLogFileExist = False
		isJobDone = False
		isJobFailed = False
		
		if os.path.exists(oFile): isLogFileExist = True
		if isLogFileExist: 
			logFdata = open(lFile).read()
			if 'Normal termination' in logFdata: 
				isJobDone = True
				if 'Normal termination (return value 0)' not in logFdata: isJobFailed = True
				
		if os.path.exists(oFile): isOutFileExist = True
		if isOutFileExist: 
			outFdata = open(oFile).read()
			if 'Npassed_ALL' in outFdata and 'done' in outFdata and 'error' not in outFdata: isOutFileOK = True
		
		if os.path.exists(eFile): isErrFileExist = True
		if isErrFileExist: 
			errFdata = open(eFile).read()
			if 'error' in errFdata or 'Error' in errFdata: isThereError = True
			statement33 = "Permission denied" in errFdata
		statement = isOutFileExist and isOutFileOK
		statement = statement and isErrFileExist and not isThereError 
		statement = statement and isLogFileExist and isJobDone and not isJobFailed
		if not statement or statement33:
			sampleDone = statement
			print "        FILE:",file
			if not (isLogFileExist and isJobDone):
				print "              --Job still running!"
# 				print "                RESUBMITTING ..."
# 				os.chdir(inputDir+'/'+sample)
# 				os.system('rm ' + lFile)
# 				os.system('rm ' + eFile)
# 				os.system('rm ' + oFile)
# 				os.system('condor_submit ' + jFile)
			elif isJobFailed:
				print "              --Job failed!"
# 				print "                RESUBMITTING ..."
# 				os.chdir(inputDir+'/'+sample)
# 				os.system('rm ' + lFile)
# 				os.system('rm ' + eFile)
# 				os.system('rm ' + oFile)
# 				os.system('condor_submit ' + jFile)
			elif not (isOutFileExist and isOutFileOK):
				print "              --Problem in out file!"
# 				print "                RESUBMITTING ..."
# 				os.chdir(inputDir+'/'+sample)
# 				os.system('rm ' + lFile)
# 				os.system('rm ' + eFile)
# 				os.system('rm ' + oFile)
# 				os.system('condor_submit ' + jFile)
			elif not (isErrFileExist and not isThereError):
				print "              --There is error!"
# 				print "                RESUBMITTING ..."
# 				os.chdir(inputDir+'/'+sample)
# 				os.system('rm ' + lFile)
# 				os.system('rm ' + eFile)
# 				os.system('rm ' + oFile)
# 				os.system('condor_submit ' + jFile)
			i+=1
	if sampleDone: samplesDone.append(sample)

pickle.dump(samplesDone,open(os.getcwd()+'/samplesDone.p','wb'))
print i, "jobs resubmitted!!!"

