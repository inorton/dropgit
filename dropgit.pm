#!/usr/bin/perl

# inb@ncipher.com

use Cwd;

package dropgit;

our $DGROOT = "~/DropGit";

my $FH;
open($FH,"<$ENV{HOME}/.dropgitrc") or die "Could not open .dropgitrc $!";

foreach my $l ( <$FH> ){
  if ( $l !~ /^#/ ){
    if ( $l =~ /DGROOT=/ ){
      my ( $extra, $path ) = split (/=/, $l );
      chomp $path;
      $path =~ s/~/$ENV{HOME}/;
      if ( -d $path ){
        $DGROOT = $path;
        print STDERR "Using DGROOT=$path\n";
      }
    }
  }
}

sub spinlock
{
  my $lockname = shift;
  while ( -f "$DGROOT/$lockname.dglock" ){
    sleep 0.5;
  }
}

sub spinunlock
{
  my $lockname = shift;
  unlink "$DGROOT/$lockname.dglock";
}


sub _system
{
  my @args = @_;
  my $cmd = join(" ", @args );
  print STDERR "calling : '$cmd'\n";
  return system(@args);
}

sub rel_filename ( $ ){
  my $filename = shift;
  print STDERR "Path: [$filename]\n";
  $filename =~ s/^$DGROOT//;
  $filename =~ s/^\///;
  return $filename;
}

sub event {
  return $main::ARGV[0];
}

sub save {
  spinlock("save");
  spinlock("pull");
  my $filename = shift;
  $filename = rel_filename( $filename );
  printf STDERR "$main::ARGV[0] '$filename'\n";
  my $pwd = Cwd::getcwd();
  chdir($DGROOT);

  if ( $filename !~ /^.git/ ){
    printf STDERR "Save '$filename'\n";
    # anything not in the git tree

    sleep 1; # back off so we can get as manage changes as is helpful in one commit
    _system("git","add","*");
    # any other parallel instances of this script will catch any we miss and 
    # git will ignore/noop any duplicate submissions
    _system("git","commit","-a","-m","routine save via DropGit");
    spinlock("push");
    _system("git","push","origin","master");
    spinunlock("push");
    
    unless ( -e $filename ){ # file has moved or deleted
      remove($filename); # if it was just renamed should make no odds
    }

  }

  chdir($pwd);
  spinunlock("pull");
  spinunlock("save");
}

sub remove
{
  my $filename = shift;
  spinlock("save");
  spinlock("pull");
  $filename = rel_filename($filename);
  printf STDERR "$main::ARGV[0] '$filename'\n";
  if ( $filename !~ /^.git/ ){
    my $event = event();
    if ( $event =~ /IN_DELETE|IN_MOVED_FROM/ ){
      my $pwd = Cwd::getcwd();
      chdir($DGROOT);
      if ( $event =~ /IN_MOVED_FROM/ ){
        sleep 1; # give a chance for things to settle down
      }
      unless ( -e $filename ){ # should be gone if it really is a delete and not a crazy rename/create
        _system("git","rm","-rf",$filename);
      }
      _system("git","add","*");

      sleep 1; # see save(); comment for same reason
        _system("git","commit","-a","-m","routine save/remove via DropGit");
      _system("git","push","origin","master");
      chdir($pwd);
    }
  }
  spinunlock("pull");
  spinunlock("save");
}

sub tidy
{
  my $pwd = Cwd::getcwd();
  chdir($DGROOT);
  my $rv = _system("git","status") / 256;

  if ( $rv != 0 ){
    ## must be a file that is not tracked
  }

  chdir($pwd);
}

sub pull
{
    spinlock("pull");
    my $pwd = Cwd::getcwd();
    chdir($DGROOT);
    _system("git","pull","origin","master");
    chdir($pwd);
    spinunlock("pull");
}

return $DGROOT;
