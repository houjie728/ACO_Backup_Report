#!/usr/bin/perl -w
# ------------------------------------------------------
# File Name:         ACO_Backup_Daily_Report.pl
# Description:       ACO Daily Backup Status Report
#
# Modified By:       Jerry Hou 
#
# Change Log:
# 20130821 - added as verify report to check daily & makeup job
# 20130710 - finished testing, works well
# 20130704 - changed start end time setting
# 20130703 - deployed on SHATEST
# 20130703 - modified SQL query, fixed EOM Daily job mix issue 
# 20130702 - added into Git for version control 
# ------------------------------------------------------

# DBI allows use of the database connection
#use strict;
use warnings;
use POSIX 'strftime';
use DBI;
use Net::SMTP;
use MIME::Lite;

####### Variables ########
my ($CONDITION,$smtp,$buffer,$result,$servername,$backupstatus,$DSN,$dbh,$query,$sth,$i,$dbhost,$siteTotal,$onduty);
my ($finishTotal,$incompleteTotal,$failedTotal,$otherTotal,$allTotal) = (0,0,0,0,0);
@ACOserver = ("shabus01","wuxbus01","wxibus10","slfbus10","txqbus10","gotbus01","gotbus02","hacfile01","hcmprt01","sgpbus01","rjnbus01","yanbus01","szhbus01");

# Focus on-duty SE
my $month = strftime '%m', localtime();
if ($month eq "01" or $month eq "07"){
	 $onduty = 'leo_yan@jabil.com';
} elsif ($month eq "02" or $month eq "08") {
	 $onduty = 'jm_liu@jabil.com';
} elsif ($month eq "03" or $month eq "09") {
	 $onduty = 'tai_nguyen@jabil.com';
} elsif ($month eq "04" or $month eq "10") {
	 $onduty = 'tang_tang@jabil.com';
}	elsif ($month eq "05" or $month eq "11") {
	 $onduty = 'summy_pu@jabil.com';
}	elsif ($month eq "06" or $month eq "12") {
	 $onduty = 'atul_gangwal@jabil.com';
}
# ACO Managers
my $to2 = 'jerry_hou@jabil.com';
my $to3 = 'senghoe_ong@jabil.com';

my $SMTPSERVER = "corimc04.jabil.com";
my $from = 'ACO_Daily_Backup@jabil.com';
# Date 86400 means one day
my $datestring = strftime '%Y/%m/%d', localtime();
my $subject = "Scheduled report: ACO Daily Backup Status Verify Report - $datestring \n";
# SQL Query Time Setting
my $startDate = strftime '%Y%m%d', localtime(time-86400);
my $endDate = strftime '%Y%m%d', localtime();
my $startTime = $startDate." 00:00:01";
my $endTime = $endDate." 15:30:00";

$buffer .="<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n<html xmlns=\"http://www.w3.org/1999/xhtml\">\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n<style TYPE=\"text/css\">\n<!-- body {color: #000000;} table {width:85%;padding: 0;margin: 0;} td {border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;  } h3 {font: bold 11px Verdana, Arial, Helvetica, sans-serif; } th{font: bold 11px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: left; padding: 6px 6px 6px 12px; background: #4F81BD;}  .trAll { background: #F3F3F3;  } .trFail { background: #F4CCCC; } .trIncomplete { background: #FFF2CC; } .trFinish { background: #B6D7A8; } -->\n</style>\n</head>\n";
$buffer .="<body>\n";
$buffer .= "<i>* Final verify report - to verify daily backup & makeup jobs</i>\n";
$buffer .= "<h3 style=\"font: bold 11px Verdana, Arial, Helvetica, sans-serif;\">On-Duty SE:  $onduty</h3>\n";
$buffer .= "<h3 style=\"font: bold 11px Verdana, Arial, Helvetica, sans-serif; color: #FF0000;\">For those not fixed issue! Please check right away!!!</h3>\n";
$buffer .= "<h3 style=\"font: bold 11px Verdana, Arial, Helvetica, sans-serif;\">Daily Backup Status: $startDate - $endDate</h3>\n";
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
	    
	    # CONDITION = exclude EOM backup jobs
			if ($dbhost eq "shabus01"){
				$CONDITION = "and jobno NOT IN (3,16)";				
			} elsif ($dbhost eq "wuxbus01") {				
				$CONDITION = "and jobno NOT IN (6,7,18)";
			} elsif ($dbhost eq "wxibus10") {			
				$CONDITION = "and jobno NOT IN (4,14)";
			} elsif ($dbhost eq "slfbus10") {			
				$CONDITION = "and jobno NOT IN (3)";
			} elsif ($dbhost eq "txqbus10") {				
				$CONDITION = "and jobno NOT IN (4,9,10,12,30)";
			} elsif ($dbhost eq "gotbus01") {				
				$CONDITION = "and jobno NOT IN (10)";
			} elsif ($dbhost eq "gotbus02") {				
				$CONDITION = "and jobno NOT IN (15)";
			} elsif ($dbhost eq "hacfile01") {				
				$CONDITION = "";
			} elsif ($dbhost eq "hcmprt01") {				
				$CONDITION = "and jobno NOT IN (3)";
			} elsif ($dbhost eq "sgpbus01") {				
				$CONDITION = "and jobno NOT IN (3)";
			} elsif ($dbhost eq "rjnbus01") {				
				$CONDITION = "and jobno NOT IN (3)";
			} elsif ($dbhost eq "yanbus01") {				
				$CONDITION = "and jobno NOT IN (3)";
			} elsif ($dbhost eq "szhbus01") {				
				$CONDITION = "and jobno NOT IN (3,4)";
			} else {
				$CONDITION = "";
			}
			
			$dbh=DBI->connect("DBI:ODBC:$DSN") or die "couldn't open database: DBI->errstr";
			### SQL Query
			$query = "select a.NodeName, b.[Status],a.TimeDT from 
								(select NodeName, max(distinct ExecTime) As TimeDT from dbo.asnode 
								where  ExecTime between '$startTime' and '$endTime'
								and jobtype not like 7 								
								$CONDITION
								Group by NodeName) 
								a JOIN dbo.asnode b ON 
								a.NodeName=b.NOdeName and 
								a.TimeDT=b.ExecTime 
								Order by a.NodeName";
			
			$sth=$dbh->prepare($query) or die "Couldn't prepare statement: ". $dbh->errstr;
			$sth->execute() or die "Execute error: " . $dbh->errstr;						
			$result = $sth->fetchall_arrayref();
			
			$i = 0;
			$buffer .= "<tr>\n";
			
			while ($result->[$i][0]) {	
					$servername = $result->[$i][0];
					$backupstatus = $result->[$i][1];
					if ($backupstatus == 1){
#						$buffer .= "<tr class=\"trFinish\">\n";
#						$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$servername</td>\n";
#						$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">Finished</td>\n";
#						$buffer .= "</tr>\n";
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
#						$buffer .= "<tr class=\"trIncomplete\">\n";
#						$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$servername</td>\n";
#						$buffer .= "<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">Incomplete</td>\n";
#						$buffer .= "</tr>\n";
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

#			if ($siteTotal == 0) {
#				$buffer .= "<tr bgcolor=\"#f3f3f3\">\n";
#				$buffer .= "<td style = \"font: bold 11px Verdana, Arial, Helvetica, sans-serif; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: left; padding: 6px 6px 6px 12px; background: #FFF2CC;rowspan: 2; align: center;\">$dbhost</td>\n";
#				$buffer .= "<td style = \"font: bold 11px Verdana, Arial, Helvetica, sans-serif; border: 1px solid #C1DAD7; letter-spacing: 2px; text-align: left; padding: 6px 6px 6px 12px; background: #FFF2CC;rowspan: 2; align: center;\"><b>No Data - please verify manually</b></td>\n";
#				$buffer .= "</tr>\n";
#			} else {
#				$buffer .= "<tr bgcolor=\"#f3f3f3\">\n";
#				$buffer .= "<td style = \"font: bold 11px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: left; padding: 6px 6px 6px 12px; background: #4F81BD;rowspan: 2; align: center;\">$dbhost</td>\n";
#				$buffer .= "<td style = \"font: bold 11px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: left; padding: 6px 6px 6px 12px; background: #4F81BD;rowspan: 2; align: center;\"><b>$siteTotal</b></td>\n";
#				$buffer .= "</tr>\n";
#			}
			
			$buffer .= "</tr>\n";		
}

my $successTotal = $finishTotal+$incompleteTotal;
my $successRate = sprintf "%.2f \n",($finishTotal+$incompleteTotal)/$allTotal*100;

$buffer .="</table><br>\n";
$buffer .="<h3 style=\"font: bold 11px Verdana, Arial, Helvetica, sans-serif;\">Status Summary: $startDate - $endDate</h3>\n";
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
<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\" bgcolor=\"#B6D7A8\">$successTotal</td>
<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\" bgcolor=\"#F4CCCC\"><b>$failedTotal</b></td>
<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$otherTotal</td>";
if ($successRate > 98) {
			$buffer .="<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\" bgcolor=\"#B6D7A8\">$successRate %</td>";
} else {
			$buffer .="<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\" bgcolor=\"#F4CCCC\">$successRate %</td>";
}				
$buffer .="</tr></table>";
$buffer .="<h3 style=\"font: bold 11px Verdana, Arial, Helvetica, sans-serif;\">Jabil - Confidential</h3>\n";
$buffer .="</body>\n</html>\n";

### Email Function ###
$smtp = Net::SMTP->new($SMTPSERVER) or die print "Couldn't connect to SMTP Server $SMTPSERVER Error $smtp - $!\n";
$smtp->mail($from);
$smtp->to($onduty);
$smtp->cc($to2);

my $msg = MIME::Lite->new(
        From    => $from,
        To      => $onduty,
        Cc			=> [$to2], 
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
