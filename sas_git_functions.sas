%let branch=test;
%let repodir=/gelcontent/warehouseRepo;
%let gituser=hbarry1;
%let gitpwd={SAS002}EC9C252C510F886419E4875536D17B7227942F85579DF84B42F04CAE1187D9440E0ABAF329247CC14AEB9A1A48A771B123ADE11D08BBD9E705A88839;

data _null_;
   rc= git_fetch(
    "&repodir.",
	"&gituser.",
	"&gitpwd.",
    "",
    "",
    "&branch.");
   put rc=;
run;

filename gitlog "&repodir./.git/logs/refs/remotes/origin/&branch.";
data _null_;
infile gitlog;
length from_commit to_commit $40.;
input from_commit $ to_commit $ user $ email $ dttm description $;
call symput('last_commit',to_commit);
run;
%put &=last_commit;

data _null_;
rc=git_reset( 
	"&repodir.",
	"&last_commit.",
	"hard"
);
put rc=;
run;

/** STILL NOT FACTORING IN THE SPARSECHECKOUT OR FILEMODE CONFIG OPTIONS **/


