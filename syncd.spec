#
# spec file for package syncd
#

Name:           syncd
Version:        1
Release:        0
Summary: Syncd is a simple bash script that watches for file changes and rsyncs them to a remote machine.
License:  MIT License      
Group: system        
Url: https://github.com/drunomics/syncd           
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Requires: rsync inotify-tools

%description
Syncd is a simple bash script that watches for file changes and rsyncs them to a remote machine. It uses inotify to watch for file system changes and syncs the whole directory to a remote machine using rsync. The script makes sure to aggregate change events during a running rsync, such that after the initial sync a subsequent sync can be triggered (and so on).


%install
%{__rm} -rf $RPM_BUILD_ROOT
%{__mkdir} -p $RPM_BUILD_ROOT/etc/syncd
%{__mkdir} -p $RPM_BUILD_ROOT/var/log
%{__mkdir} -p $RPM_BUILD_ROOT/usr/share/syncd
#%{__mkdir} -p $RPM_BUILD_ROOT/usr/share/doc/syncd
%{__mkdir} -p $RPM_BUILD_ROOT/usr/lib/systemd/system
%{__cp} syncd.conf    $RPM_BUILD_ROOT/etc/syncd
%{__cp} syncd.service $RPM_BUILD_ROOT/usr/lib/systemd/system
%{__cp} syncd         $RPM_BUILD_ROOT/usr/share/syncd
%{__cp} watch.sh      $RPM_BUILD_ROOT/usr/share/syncd
#%{__cp} LICENSE       $RPM_BUILD_ROOT/usr/share/doc/syncd
#%{__cp} README.md     $RPM_BUILD_ROOT/usr/share/doc/syncd


%files
%defattr(-,root,root)
%dir /etc/syncd
%config(noreplace) %attr(600, root, root) /etc/syncd/syncd.conf
%attr(755, root, root) /usr/share/syncd/*
%attr(644, root, root) /usr/lib/systemd/system/syncd.service

%doc README.md LICENSE

%post
/usr/bin/systemctl preset syncd.service ||: 

%preun 
/usr/bin/systemctl stop syncd.service  ||: 

%postun 
/usr/bin/systemctl daemon-reload ||:

%changelog

