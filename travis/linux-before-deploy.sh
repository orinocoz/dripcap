npm run dpkg
fakeroot alien --to-rpm -k --scripts dripcap-linux-amd64.deb
mv *.rpm dripcap-linux-amd64.rpm
