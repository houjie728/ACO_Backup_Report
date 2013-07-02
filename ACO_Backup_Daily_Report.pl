#!/usr/bin/perl -w
# ------------------------------------------------------
# File Name:         ACO_Backup_Daily_Report.pl
# Description:       ACO Daily Backup Status Report
#
# Modified By:    Date:                Description
# Jerry Hou       07/2013           Initial Development
# Change Log:
# - modified SQL query
# - added into Git for version control
# ------------------------------------------------------

# DBI allows use of the database connection
#use strict;
use warnings;
use POSIX 'strftime';
use DBI;
use Net::SMTP;
use MIME::Lite;

####### Variables ########
@ACOserver = ("shabus01","wuxbus01","wxibus10","slfbus10","txqbus10","gotbus01","gotbus02","hacfile01","hcmprt01","sgpbus01","rjnbus01","yanbus01","szhbus01");
#@ACOserver = ("wuxbus01","wxibus10");
# recipients  
my $to1 = 'Jerry_hou@jabil.com';
my $to2 = 'jm_liu@jabil.com';
my $to3 = 'leo_yan@jabil.com';
my $to4 = 'summy_pu@jabil.com';
my $to5 = 'tang_tang@jabil.com';
my $SMTPSERVER = "corimc04.jabil.com";
my $from = 'noreply@jabil.com';
# Date 86400 means one day
my $datestring = strftime '%Y/%m/%d', localtime();
my $subject = "Scheduled report: - V5 Details - ACO Daily Backup Status Summary Report - $datestring \n";
# SQL Query Time Setting
my $startTime = "CONVERT(varchar,getdate()-4,112) +\' 13:29:59\'";
my $endTime = "CONVERT(varchar,getdate()-3,112) +\' 13:29:59\'";
my $CONDITION = "";
my $smtp = '';
my $buffer = '';
my $result = '';
my $servername = '';
my $backupstatus = ''; 
my $DSN = '';
my $dbh = '';
my $query = '';
my $sth = '';
my $i = '';
my $dbhost ='';
my $finishTotal = 0;
my $incompleteTotal = 0;
my $failedTotal = 0;
my $otherTotal = 0;
my $allTotal = 0;
my $siteTotal = "";

$buffer .="<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n<html xmlns=\"http://www.w3.org/1999/xhtml\">\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n<style TYPE=\"text/css\">\n<!-- body {color: #000000;} table {width:85%;padding: 0;margin: 0;} td {border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;  } h3 {font: bold 11px Verdana, Arial, Helvetica, sans-serif; } th{font: bold 11px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: left; padding: 6px 6px 6px 12px; background: #4F81BD;}  .trAll { background: #F3F3F3;  } .trFail { background: #F4CCCC; } .trIncomplete { background: #FFF2CC; } .trFinish { background: #B6D7A8; } -->\n</style>\n</head>\n";
$buffer .="<body>\n";
$buffer .= "<i>* Testing! Please help verify! And let me know if there is any mistakes</i>";
$buffer .= "<h3 style=\"font: bold 11px Verdana, Arial, Helvetica, sans-serif;\">Daily Backup Status Details - $datestring</h3>\n";
$buffer .= "<table width=\"85%\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\">\n";
$buffer .= "<tr>\n";
$buffer .= "<th style = \"font: bold 11px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: left; padding: 6px 6px 6px 12px; background: #4F81BD;rowspan: 2; align: center;\">Server</th>\n";
$buffer .= "<th style = \"font: bold 11px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: left; padding: 6px 6px 6px 12px; background: #4F81BD;rowspan: 2; align: center;\">Status</th>\n";
$buffer .= "</tr>\n";

while ($dbhost = shift(@ACOserver)) {  				
			
			print "--- $dbhost --- \n";			
			$siteTotal = 0;
			### DB Configure Info ###
			if ($dbhost eq "szhbus01"){
				$DSN = "driver={SQL Server};Server=$dbhost\\arcserve_db;Database=asdb;svcgdco_compliance;ImDqouGcmgmFI3I";
			} else {
				$DSN = "driver={SQL Server};Server=$dbhost;Database=asdb;UID=svcgdco_compliance;PWD=ImDqouGcmgmFI3I";
			}
	
			if ($dbhost eq "shabus01"){
				$CONDITION = "and jobno IN (8,7,9)";				
			} elsif ($dbhost eq "wuxbus01") {				
				$CONDITION = "and jobno IN (4,5,8)";
			} elsif ($dbhost eq "wxibus10") {			
				$CONDITION = "and jobno IN (3,10)";
			} elsif ($dbhost eq "slfbus10") {			
				$CONDITION = "and jobno IN (2,14)";
			} elsif ($dbhost eq "txqbus10") {				
				$CONDITION = "and jobno IN (3,5,6,7,8)";
			} elsif ($dbhost eq "gotbus01") {				
				$CONDITION = "and jobno IN (3,4,5,6,7,8,9)";
			} elsif ($dbhost eq "gotbus02") {				
				$CONDITION = "and jobno IN (4,7,9,10,11,12,13)";
			} elsif ($dbhost eq "hacfile01") {				
				$CONDITION = "and jobno IN (5)";
			} elsif ($dbhost eq "hcmprt01") {				
				$CONDITION = "and jobno IN (2)";
			} elsif ($dbhost eq "sgpbus01") {				
				$CONDITION = "and jobno IN (4)";
			} elsif ($dbhost eq "rjnbus01") {				
				$CONDITION = "and jobno IN (6,7)";
			} elsif ($dbhost eq "yanbus01") {				
				$CONDITION = "and jobno IN (2)";
			} elsif ($dbhost eq "szhbus01") {				
				$CONDITION = "and jobno IN (2,8)";
			} else {
				$CONDITION = "";
			}
			
			$dbh=DBI->connect("DBI:ODBC:$DSN") or die "couldn't open database: DBI->errstr";
			 ### SQL Query
			if ($dbhost eq "hacfile01"){
				$query = "select nodename,status from dbo.asnode where exectime > getdate()-1";
			} else {
				$query = "select a.NodeName, b.[Status],a.TimeDT from 
								(select NodeName, max(distinct ExecTime) As TimeDT from dbo.asnode 
								where  ExecTime between $startTime and $endTime 
								$CONDITION								
								Group by NodeName) 
								a JOIN dbo.asnode b ON 
								a.NodeName=b.NOdeName and 
								a.TimeDT=b.ExecTime 
								Order by a.NodeName";
			}
			
			$sth=$dbh->prepare($query) or die "Couldn't prepare statement: ". $dbh->errstr;
			$sth->execute() or die "Execute error: " . $dbh->errstr;						
			$result = $sth->fetchall_arrayref();
			
			$i = 0;
			$buffer .= "<tr>\n";
			
			while ($result->[$i][0]) {	
					$servername = $result->[$i][0];
					$backupstatus = $result->[$i][1];
					if ($backupstatus == 1){
						$buffer .= "<tr class=\"trFinish\">\n";
						$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$servername</td>\n";
						$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">Finished</td>\n";
						$buffer .= "</tr>\n";
						$finishTotal++;
					} elsif ($backupstatus == 2){
						$buffer .= "<tr bgcolor=\"#F3F3F3\">\n";
						$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$servername</td>\n";
						$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\"><b>Canceled</b></td>\n";
						$buffer .= "</tr>\n";
						$otherTotal++;
					} elsif ($backupstatus == 3 or $backupstatus == 7){
						$buffer .= "<tr bgcolor=\"#F4CCCC\">\n";
						$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$servername</td>\n";
						$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\"><b> > Failed < </b></td>\n";
						$buffer .= "</tr>\n";
						$failedTotal++;
					} elsif ($backupstatus == 4){
						$buffer .= "<tr class=\"trIncomplete\">\n";
						$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$servername</td>\n";
						$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">Incomplete</td>\n";
						$buffer .= "</tr>\n";
						$incompleteTotal++;
					} elsif ($backupstatus == 5 or $backupstatus == 6 or $backupstatus > 8 ){
						$buffer .= "<tr bgcolor=\"#F3F3F3\">\n";
						$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$servername</td>\n";
						$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\"><b>Unknown</b></td>\n";
						$buffer .= "</tr>\n";
						$otherTotal++;
					}	elsif ($backupstatus == 8 ){
						$buffer .= "<tr bgcolor=\"#F3F3F3\">\n";
						$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$servername</td>\n";
						$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\"><b>Not Attempted</b></td>\n";
						$buffer .= "</tr>\n";
						$otherTotal++;
					} elsif ($backupstatus < 0){
						$buffer .= "<tr bgcolor=\"#F3F3F3\">\n";
						$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$servername</td>\n";
						$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\"><b>Active</b></td>\n";
						$buffer .= "</tr>\n";
						$incompleteTotal++;
					} else {
					 	$buffer .= "<tr bgcolor=\"#f3f3f3\">\n";
					 	$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$servername</td>\n";
					 	$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\"><b>Unknown</b></td>\n";
					 	$buffer .= "</tr>\n";
					 	$otherTotal++;
					}
						
					$i++;
					$allTotal++;
					$siteTotal++;
			}
			$buffer .= "<tr bgcolor=\"#f3f3f3\">\n";
			$buffer .= "<td style = \"font: bold 11px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: left; padding: 6px 6px 6px 12px; background: #4F81BD;rowspan: 2; align: center;\">$dbhost</td>\n";
			$buffer .= "<td style = \"font: bold 11px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: left; padding: 6px 6px 6px 12px; background: #4F81BD;rowspan: 2; align: center;\"><b>$siteTotal</b></td>\n";
			$buffer .= "</tr>\n";
			
			$buffer .= "</tr>\n";		
}

my $successTotal = $finishTotal+$incompleteTotal;
my $successRate = sprintf "%.2f \n",($finishTotal+$incompleteTotal)/$allTotal*100;

$buffer .="</table><br>\n";
$buffer .="<h3 style=\"font: bold 11px Verdana, Arial, Helvetica, sans-serif;\">Status Summary - $datestring</h3>\n";
$buffer .="<table width=\"85%\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\">
<tr align=\"center\">
<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">Total</th>
<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">Success</th>
<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">Failed</th>
<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">Other</th>
<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">Success Rate</th>
</tr>
<tr align=\"center\">
<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\"><b>$allTotal</b></td>
<td bgcolor=\"#B6D7A8\">$successTotal</td>
<td bgcolor=\"#F4CCCC\"><b>$failedTotal</b></td>
<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$otherTotal</td>
<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$successRate %</td>
</tr>
</table>";
$buffer .="<h3 style=\"font: bold 11px Verdana, Arial, Helvetica, sans-serif;\">Jabil - Confidential</h3>\n";
$buffer .="</body>\n</html>\n";

### Email Function ###
$smtp = Net::SMTP->new($SMTPSERVER) or die print "Couldn't connect to SMTP Server $SMTPSERVER Error $smtp - $!\n";
$smtp->mail($from);
$smtp->to($to1);
#$smtp->cc($to3,$to5);

my $msg = MIME::Lite->new(
        From    => $from,
        To      => $to1,
        #Cc	=> [$to2,$to3,$to4,$to5], 
        Subject => $subject,
        Type    =>'multipart/related',
        )or print "Error creating MIME body: $!\n";

$msg->attach(
          Type     => 'text/html',      
          Data     => $buffer,      
          );

my $str = $msg->as_string() or print "Convert the message as a string: $!\n";

$smtp->data();
$smtp->datasend("$str");
$smtp->dataend();
$smtp->quit;

exit(0);