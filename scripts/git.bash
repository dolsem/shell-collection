#!/usr/bin/env bash
###########################################################################
# Script Name	: git.bash
# Description	: git wrapper with a few useful commands
# Author      : Denis Semenenko
# Email       : dols3m@gmail.com
# Date written: September 2018
#
# Distributed under MIT license
# Copyright (c) 2019 Denis Semenenko
###########################################################################

source_util() { source "$(dirname $0)/.bash-utils/$1.bash" 2>/dev/null || util=$1 source /dev/stdin <<<"$(curl -fsSL 'https://github.com/dolsem/shell-collection/raw/master/source_utils.bash')" 1>&2; }
source_util os
source_util prompt

git=$(which -a git | tail -1)

#------< Helpers >------#
print_conflict_diff() {
  "$git" show "HEAD:$1" |
    diff - "$2" \
      --unchanged-group-format='%=' \
      --old-group-format="<<<<<<< Old%c'\\12'%<=======%c'\\12'>>>>>>> New%c'\\12'" \
      --new-group-format="<<<<<<< Old%c'\\12'=======%c'\\12'%>>>>>>>> New%c'\\12'" \
      --changed-group-format="<<<<<<< Old%c'\\12'%<=======%c'\\12'%>>>>>>>> New%c'\\12'"
}

rmdir_recursive() {
  cwd=$(pwd)
  iter=$2

  cd $1
  while (($iter > 0)); do
    dir=$(basename -- $(pwd))
    cd ..
    rmdir "$dir" 2>/dev/null
    if [[ ! $? -eq 0 ]]; then
      iter=0
    else
      ((iter--))
    fi
  done
}

diff_blame() {
  # Based on https://github.com/dmnd/git-diff-blame
  cat <<'EOF'
sub parse_hunk_header {
  my ($line) = @_;
  my ($o_ofs, $o_cnt, $n_ofs, $n_cnt) =
      $line =~ /^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@/;
  $o_cnt = 1 unless defined $o_cnt;
  $n_cnt = 1 unless defined $n_cnt;
  return ($o_ofs, $o_cnt, $n_ofs, $n_cnt);
}

sub get_blame_prefix {
  my ($line) = @_;
  $line =~ /^(\^?[0-9a-f]+\s+(\S+\s+)?\([^\)]+\))/ or die "bad blame output: $line";
  return $1;
}

$git_root = `git rev-parse --show-toplevel`;
$git_root =~ s/^\s+//;
$git_root =~ s/\s+$//;
chdir($git_root) or die "$!";

my ($source, $target) = @ARGV;
$source ||= 'HEAD';
my($oldrev) = ($source =~ /^([\w~\d]+):?/);
my($newrev) = ($target =~ /^([\w~\d]+):?/);
if ($target) {
  open($diff, '-|', 'git', '--no-pager', 'diff', $source, $target) or die;
} else {
  open($diff, '-|', 'git', '--no-pager', 'diff', $source) or die;
}

my ($pre, $post);
my $filename;
while (<$diff>) {
  if (m{^diff --git ./(.*) ./\1$}) {
    close $pre if defined $pre;
    close $post if defined $post;
    print;
    $prefilename = "./" . $1;
    $postfilename = "./" . $1;
    $delete = $create = 0;
  } elsif (m{^new file}) {
    $create = 1;
    $prefilename = '/dev/null';
  } elsif (m{^deleted file}) {
    $delete = 1;
    $postfilename = '/dev/null';
  } elsif (m{^--- $prefilename$}) {
    # ignore
    print;
  } elsif (m{^\+\+\+ $postfilename$}) {
    # ignore
    print;
  } elsif (m{^@@ }) {
    my ($o_ofs, $o_cnt, $n_ofs, $n_cnt)
      = parse_hunk_header($_);
    my $o_end = $o_ofs + $o_cnt - 1;
    my $n_end = $n_ofs + $n_cnt - 1;
    if (!$create) {
      open($pre, '-|', 'git', 'blame', '-M', "-L$o_ofs,$o_end",
          $oldrev, '--', $prefilename) or die;
    }
    if (!$delete) {
      if ($newrev) {
        open($post, '-|', 'git', 'blame', '-M', "-L$n_ofs,$n_end",
            $newrev, '--', $postfilename) or die;
      } else {
        open($post, '-|', 'git', 'blame', '-M', "-L$n_ofs,$n_end",
            '--', $postfilename) or die;
      }
    }
  } elsif (m{^ }) {
    print "    ", get_blame_prefix(scalar <$pre>), "\t", $_;
    scalar <$post>; # discard
  } elsif (m{^\-}) {
    print "[31m -  ", get_blame_prefix(scalar <$pre>), "\t", $_,"[m";
  } elsif (m{^\+}) {
    print "[32m +  ", get_blame_prefix(scalar <$post>), "\t", $_,"[m";
  }
}
EOF
}

#------< Commands >------#
cmd_readd() {
  exec "$git" add $("$git" diff --name-only --cached)
}

cmd_unpushed() {
  exec "$git" log --branches --not --remotes --no-walk --decorate --oneline
}

cmd_unstash() {
  exec "$git" checkout stash@{0} -- "$1"
}

cmd_retrospect() {
  git_dir=$(cd $("$git" rev-parse --git-dir); pwd -P)
  retrospect_dir="${git_dir}/retrospect"

  # list pending files: $ git retrospect
  if [[ -z $1 ]]; then
    if [[ ! -d "$retrospect_dir" ]]; then
      echo "No files are being retrospected"
    else
      printf "Files currently being retrospected:\n\n"
      cd "$retrospect_dir" && find * -type f
    fi
    exit
  fi

  # other commands: $ git retrospect <file> [--abort|--done]
  dir=$(dirname "$1" 2>/dev/null)
  if [[ ! $? -eq 0 ]]; then
    echo "'$2' is not a valid path"
    exit 1
  fi
  if [[ -d "$1" ]]; then
    echo "git retrospect does not work with directories"
    exit 1
  fi

  relative_dir=$(cd $dir && git rev-parse --show-prefix)
  if [[ -z $relative_dir ]]; then
    new_dir=$retrospect_dir
    depth=1
  else
    new_dir="${retrospect_dir}/${relative_dir}"
    depth=$(($(res="${relative_dir//[^\/]}"; echo ${#res})+1))
  fi

  mkdir -p "$new_dir"
  if [[ ! $? -eq 0 ]]; then
    exit $?
  fi

  filename=$(basename -- "$1")
  new_path="${new_dir}${filename}"

  # cancel and revert changes: $ git retrospect <file> --abort
  if [[ $2 == --abort ]]; then
    if [[ ! -f "$new_path" ]]; then
      echo "'$1' is not found in retrospect cache"
      exit 1
    fi
    mv "$new_path" "$1" && rmdir_recursive "$new_dir" $depth
    exit
  fi

  # other commands: $ git retropect <file> [--done]
  if [[ ! -f "$1" ]]; then
    echo "'$1' did not match any files"
    exit 1
  fi

  if grep -q "^<<<<<<<" "$1"; then
    echo "'$1' has unresolved conflicts that have to be resolved first"
    exit 1
  fi

  # add selected changes to commit and restore file: $ git retrospect <file> --done
  if [[ $2 == --done ]]; then
    "$git" add "$1" && mv "$new_path" "$1" && rmdir_recursive "$new_dir" $depth
    exit $?
  fi

  # start retrospection: $ git retrospect <file>
  if command "$git" diff --quiet "$1"; then
    echo "'$1' has no unstaged changes"
    exit 1
  fi

  if [[ -f "$new_path" ]]; then
    prompt_for_bool overwrite "Overwrite ${filename} in retrospect cache (all changes will be lost)?"
    if [[ $overwrite == false ]]; then
      exit
    fi
  fi

  cp "$1" "$new_path"
  print_conflict_diff "${relative_dir}${filename}" "$new_path" > "$1"
}

cmdhelp_rsync() {
  echo 'Usage: git rsync [-w|--watch] push|pull <path>'
}
cmd_rsync() {
  if [[ -n $2 ]]; then
    cmd_rsync_push() { rsync -aP --no-perms --no-user --no-group --delete --exclude='/.git' --filter="dir-merge,- .gitignore" "$(pwd)"/ "$1"; }
    cmd_rsync_pull() { rsync -aP --no-perms --no-user --no-group --delete --exclude='/.git' --filter="dir-merge,- .gitignore" "$1" "$(pwd)";  }
    case $1 in
      push) cmd_rsync_push "$2"; exit $?;;
      pull) cmd_rsync_pull "$2"; exit $?;;
      watch)
        set -eo pipefail
        trap 'exit=true' INT

        while [[ -z $exit ]]; do
          inotifywait -r -e modify,attrib,close_write,move,create,delete . >/dev/null 2>/dev/null
          if [[ -z $exit ]]; then
            cmd_rsync_push "$2" | tail -n +3 &
            if ! wait $!; then exit 1; fi
          fi
        done
        exit 0
      ;;
    esac
  fi

  cmdhelp_rsync
  exit 1
}

cmd_diffblame() {
  local pager=$(git config --get core.pager)
  exec perl <(diff_blame) $@ | ${pager:-cat}
}

#------< Main >------#
case $1 in
  s)   exec "$git" status -s ${@:2};;
  dc)  exec "$git" diff --cached "${2:-.}";;
  rbi) exec "$git" rebase -i ${@:2};;
  rbc) exec "$git" rebase --continue ${@:2};;
  +x)  exec "$git" update-index --chmod=+x ${@:2};;
  db)  exec git diff-blame ${@:2};;

  readd)      cmd_readd ${@:2};;
  unpushed)   cmd_unpushed ${@:2};;
  unstash)    cmd_unstash ${@:2};;
  retrospect) cmd_retrospect ${@:2};;
  rsync)      cmd_rsync ${@:2};;
  diff-blame) cmd_diffblame ${@:2};;

  *) eval "exec $(printf "'%s' " "$git" "$@")";;
esac
