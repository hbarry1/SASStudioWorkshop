%let devops_gitdir=%nrstr(/gelcontent/warehouseRepo);
%let tgt_dir=%nrstr(/gelcontent/coreGitRepo);
%let py_delErr=;
%let py_cpyErr=;

proc python restart;
submit;
import shutil, errno, os

delErr = cpyErr = ''
src=SAS.symget('devops_gitdir') + '/artefacts'
tgt=SAS.symget('tgt_dir') + '/artefacts'
#print('macro var src = ' + src)
#print('macro var tgt = ' + tgt)

# clear down target
#try:
#	os.system('rm -rf ' + tgt + '/*')
#except Exception as e:
#	delErr='Failed to delete %s. Reason: %s' % (tgt,e)
#	print(delErr)
#	SAS.symput('py_delErr',delErr)
	
for filename in os.listdir(tgt):
	fpath = os.path.join(tgt,filename)
	try:
		if os.path.isfile(fpath) or os.path.islink(fpath):
			os.unlink(fpath)
		elif os.path.isdir(fpath):
			shutil.rmtree(fpath)
	except Exception as e:
		delErr='Failed to delete %s. Reason: %s' % (fpath,e)
		print(delErr)
		SAS.symput('py_delErr',delErr)

# copy from src to tgt
if delErr == '':
	cpyRc = os.system('cp -R ' + src + '/* ' + tgt)
	if cpyRc != 0:
		cpyErr='Failed to copy files to ' + tgt
		print(cpyErr)
		SAS.symput('py_cpyErr',cpyErr)

#try:
#	shutil.copytree(src,tgt)
#except OSError as err:
#	#error casued if src not a dir
#	if err.errno == errno.ENOTDIR:
#		shutil.copy2(src,tgt)
#	else:
#		cpyErr='Error: %s' % err
#		print(cpyErr)
#		SAS.symput('py_cpyErr',cpyErr)

endsubmit;
run;

%put &=py_delErr;
%put &=py_cpyErr;

