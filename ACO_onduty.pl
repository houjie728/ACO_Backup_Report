#!/usr/bin/perl -w
# ------------------------------------------------------
# File Name:         ACO_onduty.pl
# Description:       ACO Focus Onduty
#
# Modified By:       Jerry Hou 
#
# Change Log:
# 20130730 - finished testing, works well
# 20130730 - added into Git for version control 
# ------------------------------------------------------

# DBI allows use of the database connection
#use strict;
use warnings;
use POSIX 'strftime';
use DBI;
use Net::SMTP;
use MIME::Lite;

####### Variables ########
my ($SERVER_onduty,$BACKUP_onduty,$COMPLIANCE_onduty,$TICKET_onduty);

my $ACOSE1 = 'tang_tang@jabil.com';
my $ACOSE2 = 'jm_liu@jabil.com';
my $ACOSE3 = 'summy_pu@jabil.com';
my $ACOSE4 = 'leo_yan@jabil.com';
my $ACOSE5 = 'atul_gangwal@jabil.com';
my $ACOSE6 = 'tai_nguyen@jabil.com';

# Focus on-duty SE
my $YearMonth = strftime '%Y/%m', localtime();
my $month = strftime '%m', localtime();
if ($month eq "01" or $month eq "07"){
	 $SERVER_onduty = "$ACOSE1";
	 $BACKUP_onduty = "$ACOSE4";
	 $COMPLIANCE_onduty = "$ACOSE2; $ACOSE3";
	 $TICKET_onduty = "$ACOSE5; $ACOSE6";
} elsif ($month eq "02" or $month eq "08") {
	 $SERVER_onduty = "$ACOSE5";
	 $BACKUP_onduty = "$ACOSE2";
	 $COMPLIANCE_onduty = "$ACOSE1; $ACOSE6";
	 $TICKET_onduty = "$ACOSE3; $ACOSE4";
} elsif ($month eq "03" or $month eq "09") {
	 $SERVER_onduty = "$ACOSE3";
	 $BACKUP_onduty = "$ACOSE6";
	 $COMPLIANCE_onduty = "$ACOSE4; $ACOSE5";
	 $TICKET_onduty = "$ACOSE1; $ACOSE2";
} elsif ($month eq "04" or $month eq "10") {
	 $SERVER_onduty = "$ACOSE2";
	 $BACKUP_onduty = "$ACOSE1";
	 $COMPLIANCE_onduty = "$ACOSE3; $ACOSE6";
	 $TICKET_onduty = "$ACOSE4; $ACOSE5";
}	elsif ($month eq "05" or $month eq "11") {
	 $SERVER_onduty = "$ACOSE4";
	 $BACKUP_onduty = "$ACOSE3";
	 $COMPLIANCE_onduty = "$ACOSE1; $ACOSE5";
	 $TICKET_onduty = "$ACOSE2; $ACOSE6";
}	elsif ($month eq "06" or $month eq "12") {
	 $SERVER_onduty = "$ACOSE6";
	 $BACKUP_onduty = "$ACOSE5";
	 $COMPLIANCE_onduty = "$ACOSE2; $ACOSE4";
	 $TICKET_onduty = "$ACOSE1; $ACOSE3";
}

# recipients  
my $to1 = '_f7736@jabil.com';
my $SMTPSERVER = "corimc04.jabil.com";
my $from = 'ACO_Daily_Backup@jabil.com';

# focus onduty report for current month
my $subject = "Scheduled report: Reminder: ACO Focus On-Duty - $YearMonth \n";
$buffer .="<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n<html xmlns=\"http://www.w3.org/1999/xhtml\">\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n<style TYPE=\"text/css\">\n<!-- body {color: #000000;} table {width:85%;padding: 0;margin: 0;} td {border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;  } h3 {font: bold 11px Verdana, Arial, Helvetica, sans-serif; } th{font: bold 11px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: left; padding: 6px 6px 6px 12px; background: #4F81BD;}  .trAll { background: #F3F3F3;  } .trFail { background: #F4CCCC; } .trIncomplete { background: #FFF2CC; } .trFinish { background: #B6D7A8; } -->\n</style>\n</head>\n";
$buffer .="<body>\n";
$buffer .= "<h3 style=\"font: bold 11px Verdana, Arial, Helvetica, sans-serif;\">ACO Focus On-Duty - $YearMonth</h3>\n";
$buffer .="<table width=\"85%\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\">";
$buffer .="<tr align=\"center\">
					<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">Focus</th>
					<th style = \"font: bold 9px Verdana, Arial, Helvetica, sans-serif; color: #FFFFFF; border: 1px solid #C1DAD7; letter-spacing: 2px; text-transform: uppercase; text-align: center; padding: 6px 6px 6px 12px; background: #4F81BD;\">$YearMonth</th>
					</tr>";
$buffer .="<tr align=\"center\">
					<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">Server Monitoring</td>
					<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$SERVER_onduty</td>
					</tr>";
$buffer .="<tr align=\"center\">
					<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px; background: #DBE5F1;\">Backup Check</td>
					<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px; background: #DBE5F1;\">$BACKUP_onduty</td>
					</tr>";
$buffer .="<tr align=\"center\">
					<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">Compliance Control</td>
					<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px;\">$COMPLIANCE_onduty</td>
					</tr>";
$buffer .="<tr align=\"center\">
					<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px; background: #DBE5F1;\">Ticket Watch</td>
					<td style = \"border: 1px solid #C1DAD7; font-size:11px; padding: 6px 6px 6px 12px; background: #DBE5F1;\">$TICKET_onduty</td>
					</tr>";
					
$buffer .= "</table>";
$buffer .= "<br/>\n";
$buffer .= "<i>On-duty personnel need to focus on one of below tasks:<ul>
						<li>Daily quick check on site servers health and server room UPS, update the status to team and track issues if any</li>
						<li>Daily check on site backup status, and update the status to team and track the issues if any</li>
						<li>Track and manage the compliance control tasks in time till close and manage servers patching for the month</li>
						<li>Track IM/SR ticket status</li>
						</ul></i>\n";
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
        #Cc			=> $onduty, 
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
