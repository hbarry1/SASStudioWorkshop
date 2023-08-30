/* Git Setup */
%let git_url=%nrstr(https://github.com/hbarry1/hb_test.git);
%let git_user=%nrstr(heather@barrytech.co.uk);
%let git_username=%nrstr(hbarry1);
%let git_pw=%nrstr({SAS002}EC9C252C510F886419E4875536D17B7227942F85579DF84B42F04CAE1187D9440E0ABAF329247CC14AEB9A1A48A771B123ADE11D08BBD9E705A88839);
%let git_branch=%nrstr(test);
%let tgt_dir=%nrstr(/ifb/warehouse/ifb_lei_solution);
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
		"&git_pw");          
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


/* 
	Copy ALL files from 
		&devops_gitdir./artefacts 
	to 
		&tgt_dir./artefacts (/ifb/warehouse/ifb_lei_solution/artefacts)
		
   	We may optimize this by calling GIT_DIFF_GET before the PULL to record
	exactly what file have changed since last pull and then only copy those 
	after the PULL.
*/

%include "&mcr_dir./copy_create_delete_macros.sas";

/* delete & build fresh */
%delete_folder(&tgt_dir./artefacts);
%create_dir(&tgt_dir./artefacts);

/* loop through git repo & copy over artefacts */
%macro list_files(dir);
  %local filrf rc did memcnt name i;
  %let rc=%sysfunc(filename(filrf,&dir));
  %let did=%sysfunc(dopen(&filrf));      

   %if &did eq 0 %then %do; 
    %put Directory &dir cannot be open or does not exist;
    %return;
  %end;

   %do i = 1 %to %sysfunc(dnum(&did));   
   %let name=%qsysfunc(dread(&did,&i));
		%put &dir/&name;
		%let tgt_subd=%sysfunc(tranwrd(&dir.,&devops_gitdir.,));
		%if %qscan(&name,2,.) = %then %do;
			%put creating DIR: &tgt_dir./&tgt_subd./&name.;
			%create_dir(&tgt_dir/&tgt_subd/&name);
			%list_files(&dir/&name);
		%end;
		%else %do;
			%put copying file &dir/&name --> &tgt_dir./&tgt_subd.,&name.;
			%copy_file(&dir.,&tgt_dir./&tgt_subd.,&name.);
		%end;
   %end;
   %let rc=%sysfunc(dclose(&did));
   %let rc=%sysfunc(filename(filrf));     

%mend list_files;
%list_files(&devops_gitdir./artefacts);

%let CopyCheck_Result=Failure;
%let CopyCheck_Result=&CopyFilesPyResult;
%put NOTE: DevOpsCopySrc.py reports: &CopyCheck_Result;

