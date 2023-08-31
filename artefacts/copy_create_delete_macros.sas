%macro create_dir(dir);
   %local lastchar child parent;

	/* Examine the last character of the pathname - if it is a colon do nothing (the drive is assumed to exists) */
	%let lastchar = %substr(&DIR, %length(&DIR));
	%if (%bquote(&lastchar) eq %str(:)) %then
		%return;

	/* Check whether the last character is a path separator */
	%if (%bquote(&lastchar) eq %str(/)) or (%bquote(&lastchar) eq %str(\)) %then %do;

      /* If it is the whole path do nothing (root assumed to exist) */
      %if (%length(&DIR) eq 1) %then
         %return;

      /* Otherwise, strip off the final path separator */
      %let DIR = %substr(&DIR, 1, %length(&DIR)-1);

   %end;

   /* If the path already exists, there is nothing further to do */
   %if (%sysfunc(fileexist(%bquote(&DIR))) = 0) %then %do;

      /* Get the child directory name as the token after the last path separator or colon*/
      %let child = %scan(&DIR, -1, %str(/\:));

      /* If the child dir is the same as the whole path, no parents to create */
      /* otherwise, extract the parent dir and call this macro recursively */
      %if (%length(&DIR) gt %length(&child)) %then %do;
         %let parent = %substr(&DIR, 1, %length(&DIR)-%length(&child));
         %create_dir(&parent);
      %end;

      /* Create the child directory in the parent */
      %let dname = %sysfunc(dcreate(&child, &parent));
      %if (%bquote(&dname) eq ) %then %do;
          %put ERROR: Unable to create [&child] in [&parent] directory.;
         %return;
      %end;
   %end;

%mend create_dir;

%macro copy_file(src_path,tgt_path,fname);

	%if %sysfunc(fileexist(&tgt_path.))=0 %then %do;
		%create_dir(&tgt_path.);
	%end;
	%let orig_opt=%sysfunc(getoption(MSGLEVEL));
	
	options msglevel=i;
	filename src "&src_path./&fname.";
	filename trg "&tgt_path./&fname.";
		
	data _null_;
		length filein 8 fileid 8;
		filein = fopen("src",'I',1,'B');
		fileid = fopen("trg",'O',1,'B');
		rec = '20'x;
		do while(fread(filein)=0);
			rc = fget(filein,rec,1);
			rc = fput(fileid, rec);
			rc = fwrite(fileid);
		end;
		rc = fclose(filein);
		rc = fclose(fileid);
		call symput('copy_rc',rc);
	run;
	
	options msglevel=&orig_opt.;

%mend copy_file;

%macro delete_file(tgt_path,fname);

	%put DELETING &tgt_path./&fname.;
	%if %sysfunc(fileexist(&tgt_path./&fname.)) ge 1 %then %do;
	   %let rc=%sysfunc(filename(temp,&tgt_path./&fname.)); 
	   %let rc=%sysfunc(fdelete(&temp)); 
	%end;

%mend delete_file;


%macro delete_folder(fpath,localpath,content_only);

    %local rc _path filrf did noe filename fid i;
	%if %sysfunc(symexist(x_del_n))=0 %then %let x_del_n=0;

    %if %quote(&localpath) = %then
        %let _path=&fpath;
    %else 
        %let _path=&fpath/&localpath;

    %let x_del_n=%eval(&x_del_n+1);
    %let filrf=DIR&x_del_n;

	/* validate the path exists */
	%if %sysfunc(fileexist(&_path.)) ge 1 %then %do;

		/* assign fileref */
	    %let rc = %sysfunc(filename(filrf, &_path));
		%if &rc > 0 %then %put %sysfunc(sysmsg());
		%else %do;

			/* open the fileref */
		    %let did = %sysfunc(dopen(&filrf));
			%if &did = 0 %then %put %sysfunc(sysmsg());
			%else %do;

				/* get number of objects within the folder */
			    %let noe = %sysfunc(dnum(&did));

				/* loop through all objects within the folder */
			    %do i = 1 %to &noe;
			        %let filename = %bquote(%sysfunc(dread(&did, &i)));
			        %let fid = %sysfunc(mopen(&did, &filename));
			        %if &fid > 0 %then %do;
					/* if member object is a file - close and delete it */
						%let rc=%sysfunc(fclose(&fid));
						%delete_file(&_path.,&filename.);
			        %end;
			        %else %do;
					/* if member object is a folder - call delete_folder macro to delete members, then delete the folder */
			            %if %quote(&localpath) = %then
			                %delete_folder(&fpath, &filename);
			            %else 
			                %delete_folder(&fpath, &localpath/&filename);
						%delete_file(&_path.,&filename.);
			        %end;

			    %end;
				/* close the fileref */
			    %let rc=%sysfunc(dclose(&did));

			%end;

			/** delete the folder **/
			%if &content_only. eq or &content_only.=N %then %do;
				%delete_file(&_path.);
			%end;

		%end; /* if rc = 0 */

	%end; /* if _file exists */
	%else %do;
		%put NOTE: Cannot locate folder &_path. - no deletion will take place.;
	%end;

%mend;
