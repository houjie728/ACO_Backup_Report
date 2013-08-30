#!/usr/bin/perl -w
# ------------------------------------------------------
# File Name:         ACO_Backup_Daily_Report.pl
# Description:       ACO Daily Backup Status Report
#
# Modified By:       Jerry Hou 
#
# Change Log:
# 20130830 - added final backup status summary
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
my ($CONDITION,$smtp,$buffer,$result,$servername,$backupstatus,$DSN,$dbh,$query,$sth,$i,$dbhost,$siteTotal,$successTotal,$successRate,$startDate,$endDate,$startTime,$endTime);
my ($finishTotal,$incompleteTotal,$failedTotal,$otherTotal,$allTotal,$a,$b,$c) = (0,0,0,0,0,0,0,0);
@ACOserver = ("shabus01","wuxbus01","wxibus10","slfbus10","txqbus10","gotbus01","gotbus02","hacfile01","hcmprt01","sgpbus01","rjnbus01","yanbus01","szhbus01");

# Focus on-duty SE
my $month = strftime '%m', localtime(time-86400);
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
# recipients  
my $to1 = 'Jerry_hou@jabil.com';
my $SMTPSERVER = "corimc04.jabil.com";
my $from = 'ACO_Daily_Backup@jabil.com';

# generate a daily backup job status report for last ### days
my $reportDays = 31; 
my $subject = "Scheduled report: ACO Backup Status Summary Report - Last $reportDays days \n";
$buffer .="<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n<html xmlns=\"http://www.w3.org/1999/xhtml\">\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n<style TYPE=\"text/css\">\n<!-- body {color: #000000;} table {width:85%;padding: 0;margin: 0;} td {border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;  } h3 {font: bold 11px Verdana, Arial, Helvetica, sans-serif; } th{font: bold 11px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: left; padding: 6px 6px 6px 12px; background: #4F81BD;}  .trAll { background: #F3F3F3;  } .trFail { background: #F4CCCC; } .trIncomplete { background: #FFF2CC; } .trFinish { background: #B6D7A8; } -->\n</style>\n</head>\n";
$buffer .="<body>\n";
$buffer .= "<h3 style=\"font: bold 11px Verdana, Arial, Helvetica, sans-serif;\">On-Duty SE ($month):  $onduty</h3>\n";
$buffer .="<h2 style=\"font: bold 16px Verdana, Arial, Helvetica, sans-serif;\">Status Summary - Last $reportDays days</h2>\n";
$buffer .= "<h3 style=\"font: bold 11px Verdana, Arial, Helvetica, sans-serif; color: #FF0000;\">Report 1: Backup Status (exclude: makeup jobs)</h3>\n";
$buffer .="<table width=\"85%\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\">";
$buffer .="<tr align=\"center\">
					<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">Date</th>
					<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">Total</th>
					<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">Success</th>
					<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">Failed</th>
					<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">Other</th>
					<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">Success Rate</th>
					</tr>";

while ($a++ < $reportDays) {
	
	$finishTotal=$incompleteTotal=$failedTotal=$otherTotal=$allTotal=0;
	# Date 86400 means one day
	$c = 86400*$a;
	$b = 86400*($a-1);
								
	# SQL Query Time Setting
	$startDate = strftime '%Y%m%d', localtime(time-$c);
	$endDate = strftime '%Y%m%d', localtime(time-$b);
										
	$startTime = $startDate." 00:00:01";
	$endTime = $endDate." 10:00:00";
					
	print "$startTime - $endTime\n";


	foreach $dbhost(@ACOserver) {  							
			print "--- $dbhost --- \n";			
			### DB Configure Info ###
			if ($dbhost eq "szhbus01"){
					$DSN = "driver={SQL Server};Server=$dbhost\\arcserve_db;Database=asdb;svcgdco_compliance;ImDqouGcmgmFI3I";
			} else {
					$DSN = "driver={SQL Server};Server=$dbhost;Database=asdb;UID=svcgdco_compliance;PWD=ImDqouGcmgmFI3I";
			}
						
			$dbh=DBI->connect("DBI:ODBC:$DSN") or die "couldn't open database: DBI->errstr";
				
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
										
			### SQL Query
			$query = "select a.NodeName, b.[Status],a.TimeDT from 
										(select NodeName, max(distinct ExecTime) As TimeDT from dbo.asnode 
										where  ExecTime between '$startTime' and '$endTime' 
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
								$finishTotal++;
							} elsif ($backupstatus == 2 or $backupstatus == 8 or $backupstatus == 5 or $backupstatus == 6 or $backupstatus > 8){
								$otherTotal++;
							} elsif ($backupstatus == 3 or $backupstatus == 7){
								$failedTotal++;
							} elsif ($backupstatus == 4 or $backupstatus < 0){
								$incompleteTotal++;
							} else {
							 	$otherTotal++;
							}
								
							$i++;
							$allTotal++;
			}
							
		} # while dbhost end
		print "--- $allTotal - $finishTotal - $failedTotal - $incompleteTotal - $otherTotal --- \n\n";	
		
		
		$successTotal = $finishTotal+$incompleteTotal;
		if ($successTotal !=0) {
			$successRate = sprintf "%.2f \n",($finishTotal+$incompleteTotal)/$allTotal*100;
		} else { $successRate = "---"; }
		
		$buffer .="<tr align=\"center\">
		<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$startDate</td>
		<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\"><b>$allTotal</b></td>
		<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\" bgcolor=\"#B6D7A8\">$successTotal</td>
		<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\" bgcolor=\"#F4CCCC\"><b>$failedTotal</b></td>
		<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$otherTotal</td>";
		
		if ($successRate > 90) {
			$buffer .="<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\" bgcolor=\"#B6D7A8\">$successRate %</td>";
		} else {
			$buffer .="<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\" bgcolor=\"#F4CCCC\">$successRate %</td>";
		}
				
		$buffer .="</tr>";
					
} # for end
					
$buffer .= "</table>";

### Part 2 start ###
$a = $b = $c = 0;
$dbhost = "";

$buffer .= "<h3 style=\"font: bold 11px Verdana, Arial, Helvetica, sans-serif; color: #FF0000;\">Report 2: Final Backup Status (include: makeup jobs)</h3>\n";
$buffer .="<table width=\"85%\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\">";
$buffer .="<tr align=\"center\">
					<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">Date</th>
					<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">Total</th>
					<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">Success</th>
					<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">Failed</th>
					<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">Other</th>
					<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">Success Rate</th>
					</tr>";

while ($a++ < $reportDays) {
	
	$finishTotal=$incompleteTotal=$failedTotal=$otherTotal=$allTotal=0;
	# Date 86400 means one day
	$c = 86400*$a;
	$b = 86400*($a-1);
								
	# SQL Query Time Setting
	$startDate = strftime '%Y%m%d', localtime(time-$c);
	$endDate = strftime '%Y%m%d', localtime(time-$b);
										
	$startTime = $startDate." 00:00:01";
	$endTime = $endDate." 15:30:00";
					
	print "$startTime - $endTime\n";


	foreach $dbhost(@ACOserver) {  							
			print "--- $dbhost --- \n";			
			### DB Configure Info ###
			if ($dbhost eq "szhbus01"){
					$DSN = "driver={SQL Server};Server=$dbhost\\arcserve_db;Database=asdb;svcgdco_compliance;ImDqouGcmgmFI3I";
			} else {
					$DSN = "driver={SQL Server};Server=$dbhost;Database=asdb;UID=svcgdco_compliance;PWD=ImDqouGcmgmFI3I";
			}
						
			$dbh=DBI->connect("DBI:ODBC:$DSN") or die "couldn't open database: DBI->errstr";
				
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
								$finishTotal++;
							} elsif ($backupstatus == 2 or $backupstatus == 8 or $backupstatus == 5 or $backupstatus == 6 or $backupstatus > 8){
								$otherTotal++;
							} elsif ($backupstatus == 3 or $backupstatus == 7){
								$failedTotal++;
							} elsif ($backupstatus == 4 or $backupstatus < 0){
								$incompleteTotal++;
							} else {
							 	$otherTotal++;
							}
								
							$i++;
							$allTotal++;
			}
							
		} # while dbhost end
		print "--- $allTotal - $finishTotal - $failedTotal - $incompleteTotal - $otherTotal --- \n\n";	
		
		
		$successTotal = $finishTotal+$incompleteTotal;
		if ($successTotal !=0) {
			$successRate = sprintf "%.2f \n",($finishTotal+$incompleteTotal)/$allTotal*100;
		} else { $successRate = "---"; }
		
		$buffer .="<tr align=\"center\">
		<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$startDate</td>
		<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\"><b>$allTotal</b></td>
		<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\" bgcolor=\"#B6D7A8\">$successTotal</td>";
		
		if (($failedTotal == 0)||($otherTotal == 0)) {
				$buffer .="<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\" bgcolor=\"#B6D7A8\"><b>$failedTotal</b></td>
							 <td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\"bgcolor=\"#B6D7A8\">$otherTotal</td>";
		} else {
			$buffer .="<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\" bgcolor=\"#F4CCCC\"><b>$failedTotal</b></td>
							 <td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$otherTotal</td>";
		}
		
		if ($successRate > 98) {
			$buffer .="<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\" bgcolor=\"#B6D7A8\">$successRate %</td>";
		} else {
			$buffer .="<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\" bgcolor=\"#F4CCCC\">$successRate %</td>";
		}
				
		$buffer .="</tr>";
					
} # for end
					
$buffer .= "</table>";

$buffer .="<h3 style=\"font: bold 11px Verdana, Arial, Helvetica, sans-serif;\">Jabil - Confidential</h3>\n";
$buffer .="</body>\n</html>\n";

### Email Function ###
$smtp = Net::SMTP->new($SMTPSERVER) or die print "Couldn't connect to SMTP Server $SMTPSERVER Error $smtp - $!\n";
$smtp->mail($from);
$smtp->to($to1);
#$smtp->cc($onduty);

my $msg = MIME::Lite->new(
        From    => $from,
        To      => $to1,
        Cc			=> $onduty, 
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
