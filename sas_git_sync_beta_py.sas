/* Git Setup */
%let git_url=%nrstr(https://github.com/hbarry1/hb_test.git);
%let git_user=%nrstr(hbarry1);
%let git_pwd=%nrstr({SAS002}EC9C252C510F886419E4875536D17B7227942F85579DF84B42F04CAE1187D9440E0ABAF329247CC14AEB9A1A48A771B123ADE11D08BBD9E705A88839);
%let git_branch=%nrstr(test);
/* %let tgt_dir=%nrstr(/ifb/warehouse/ifb_lei_solution); */
%let tgt_dir=%nrstr(/gelcontent/warehouseRepo);
%let mcr_dir=%nrstr(/gelcontent/myGitClone);

/* Internal macro variables */
%global git_rc;

/* Utility */
%macro returnCodeCheck(actualCode,expectedCode);
	%if &actualCode ne &expectedCode %then %do;
		%put ERROR: Expected return code was &expectedCode but got &actualCode.. Will abort;
		data _null_;
			abort abend 2;
		run;
	%end;
%mend;

/* Initialize git repo in work folder by creating a temp git dir below &sasworkdir */
%let sasworkdir=%sysfunc(getoption(work));
%put NOTE: &=sasworkdir;
options dlcreatedir;
libname _create "&sasworkdir./git";
libname _create clear;
%let devops_gitdir=&sasworkdir./git;

data _null_;
    rc = GIT_CLONE (
		"&git_url", 
		"&devops_gitdir", 
		"&git_user", 
		"&git_pwd");          
    call symput('git_rc',strip(put(rc,best32.)));
run;
%returnCodeCheck(&git_rc,0);

/* If &git_branch ne main (i.e. dev) then perform check out of the branch named the same */
%if %str(&git_branch) ne %str(main) %then %do;
	data _null_;
	    rc = GIT_BRANCH_CHKOUT (
			"&devops_gitdir", 
			"origin/&git_branch."); 
	    call symput('git_rc',strip(put(rc,best32.)));
	run;
	%returnCodeCheck(&git_rc,0);
%end;


/* Copy files from &devops_gitdir./artefacts to &tgt_dir./artefacts */
%let py_delRC=0;
%let py_cpyRC=0;
proc python restart;
submit;
import shutil, os

src=SAS.symget('devops_gitdir') + '/artefacts'
tgt=SAS.symget('tgt_dir') + '/artefacts'

# clear down target
for filename in os.listdir(tgt):
	fpath = os.path.join(tgt,filename)
	try:
		if os.path.isfile(fpath) or os.path.islink(fpath):
			os.unlink(fpath)
		elif os.path.isdir(fpath):
			shutil.rmtree(fpath)
	except Exception as e:
		print('Failed to delete %s. Reason: %s' % (fpath,e))
		SAS.symput('py_delRC',99)

endsubmit;
quit;
%returnCodeCheck(&py_delRC.,0);

proc python;
submit;
# copy from src to tgt
cpyRc = os.system('cp -R ' + src + '/* ' + tgt)
if cpyRc != 0:
	print('Failed to copy files to ' + tgt)
	SAS.symput('py_cpyRC',99)
endsubmit;
run;
%returnCodeCheck(&py_cpyRC.,0);

/* %let CopyCheck_Result=Failure; */
/* %let CopyCheck_Result=&CopyFilesPyResult; */
/* %put NOTE: DevOpsCopySrc.py reports: &CopyCheck_Result; */

