#!/usr/bin/perl

use Getopt::Std;

my %opts;

my %options = (
  "l:" => {
    usage => "LOCALPATH",
    description => "Location of your Local DropGit folder - DGROOT",
  },
  "r:" => { 
    usage => "HOST:PATH", 
    description => "Server and location for new remote git repository (eg /var/cache/git/MyDropGit) " 
  },
  "h" => { 
    usage => "",
    description => "Show this message"
  },
);

my $optstr =  join("", sort keys %options ); 
getopts($optstr,\%opts);

if ( exists $opts{h} ){
  usage();
  exit(-1);
}

unless ( defined $opts{r} ){
  usage();
  exit(-1);
}

# setup local
my @hostpath = split(/:/,$opts{r});
my $host = shift @hostpath;
my $path = shift @hostpath;

open ( DGRC,">$ENV{HOME}/.dropgitrc" ) or die "couldnt write .dropgitrc $!";
print DGRC "DGROOT=$opts{l}\n";
close (DGRC);

system("mkdir -p $opts{l}");
chdir($opts{l});
unless ( -d "$opts{l}/.git" ){
  system("git init");
}

system("git remote add origin ssh://$host$path");
print ".. now setup your remote DropGit git repository at $host:$path \n";
print ".. transfer script to $host\n";
if ( create_script($host,$path,"Remote DroptGit Master") == 0 ){
  print ".. execute script on $host\n";
  system("ssh","$host","sh ~/.dropgit_setup_sh");
}

print ".. pull remote refstate\n";
system("git pull origin master");


my $files = `ls |wc -l`; chomp $files;
if ( $files > 0 ){
  print ".. push current state\n";
  system("git add *");
  system("git commit -a -m 'initial checkin for dropgit'");
  system("git push origin master");
}

sub create_script($$$)
{
  my $host = shift;
  my $path = shift;
  my $desc = shift;

  $desc =~ s/['";&<>\|]//g;

  my $script = qq|#!/bin/sh

set -e
mkdir -p '$path'
cd '$path'
git --bare init
echo '$desc' > description
|; 

  open(GITSCRIPT, ">.dropgit_setup_sh");
  print GITSCRIPT $script;
  close(GITSCRIPT);

  my $rv = system("scp",".dropgit_setup_sh","$host:.");
  unlink(".dropgit_setup_sh");

  return $rv / 256;

}





sub usage
{
  my $ustr = "Usage: $0 ";
  my $str = "";
  foreach my $opt ( sort keys %options ){
    my $arg = $opt;
    $arg =~ s/://;
    $str .= qq|   -$arg  |;
    my $usage = "$options{$opt}{usage}";
    $ustr .= "-$arg $usage ";
    $str .= sprintf("%-12s", $usage);
    $str .= sprintf("%-12s\n", $options{$opt}{description});
  } 

  print "$ustr\n\n$str\n";
}
