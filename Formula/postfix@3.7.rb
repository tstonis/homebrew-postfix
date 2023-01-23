# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class PostfixAT37 < Formula
  desc "The Postfix mail server system"
  homepage "https://www.postfix.org"
  url "http://mirror.reverse.net/pub/postfix-release/official/postfix-3.7.3.tar.gz"
  sha256 "d22f3d37ef75613d5d573b56fc51ef097f2c0d0b0e407923711f71c1fb72911b"
  license ""

  # depends_on "cmake" => :build

  skip_clean "var/lib/postfix", "var/spool"

  def install
    # ENV.deparallelize  # if your formula fails when building in parallel
    # Remove unrecognized options if warned by configure
    # https://rubydoc.brew.sh/Formula.html#std_configure_args-instance_method
    # system "./configure", *std_configure_args, "--disable-silent-rules"
    # system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    args = %W[ 
        install_root=#{prefix}
        command_directory=/sbin
        daemon_directory=/libexec
        manpage_directory=/share/man
        config_dir=/etc/postfix
    ]
    (pkgshare/"src").mkpath
    system "make", "makefiles", "CCARGS='-DDEF_CONFIG_DIR=\""+etc+"/postfix\"'"
    etc.install_symlink "#{prefix}/#{etc}/postfix"
    system "make"
    system "make", "non-interactive-package", *args
    system "tar", "-cJf", (pkgshare/"src/src.tar.xz"), "."
    var.install_symlink prefix/"var/spool" 
    #var.install_symlink prefix/"var/lib/postfix"
    system sbin/"postconf", "config_directory"
    system sbin/"postconf", "command_directory="+sbin
    system sbin/"postconf", "daemon_directory="+prefix+"/libexec"
    system sbin/"postconf", "meta_directory="+etc+"/postfix"
    system sbin/"postconf", "data_directory="+var+"/postfix"
    system sbin/"postconf", "queue_directory="+var+"/spool/postfix"
    system sbin/"postconf", "mail_owner=_postfix"
    system sbin/"postconf", "setgid_group=_postdrop"
    (prefix/"set_perms.sh").write set_perms
  end

  #def post_install
  #  (var/"spool/postfix").mkpath
  #end

  def set_perms 
    <<~EOS
      #!/bin/sh

      ID=$(id -g)

      if [ ! $ID -eq 0 ]; then
        echo "This script must be run as root."
        exit 1
      fi

      group=_postdrop
      user=_postfix

      # TODO: Maybe able to use multi-instance tools to do all this...
      chown -R root #{etc}/postfix/
      chmod 755 #{etc}/postfix
      chmod -R 644 #{etc}/postfix/*
      chown -R $user #{var}/postfix/
      chmod 700 #{var}/postfix/
      
      chown -R root #{prefix}/libexec
      chmod 755 #{prefix}/libexec

      chown root #{var}/spool/postfix/
      chmod 755 #{var}/spool/postfix/
  
      chown -R $user #{var}/spool/postfix/*
      chmod -R 700 #{var}/spool/postfix/*
      chgrp $group #{var}/spool/postfix/public
      chmod 710 #{var}/spool/postfix/public
      chgrp $group #{var}/spool/postfix/maildrop
      chmod 730 #{var}/spool/postfix/maildrop
      chown root #{var}/spool/postfix/pid

      chown -R root #{prefix}/sbin
      chmod -R 755 #{prefix}/sbin
      chgrp $group #{prefix}/sbin/postqueue
      chmod 2755 #{prefix}/sbin/postqueue
      chgrp $group #{prefix}/sbin/postdrop
      chmod 2755 #{prefix}/sbin/postdrop
      chgrp $group #{prefix}/sbin/postlog
      chmod 2755 #{prefix}/sbin/postlog

    EOS
  end

  def blah
    <<~EOS
    #{prefix}
    EOS
  end

  def caveats
    <<~EOS
      Postfix will not run properly as installed, since it needs to run as root 
      and have special file ownership. Please run the following to complete the installation:

      sudo sh #{prefix}/set_perms.sh

    EOS
  end



  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test postfix@3.7`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    #system "false"
  end
end
