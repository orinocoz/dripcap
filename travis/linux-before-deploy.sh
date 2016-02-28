npm run dpkg
fakeroot alien --to-rpm -k --scripts dripcap-linux-amd64.deb
mv *.rpm dripcap-linux-amd64.rpm
zip -j paperfilter-linux-amd64.zip .build/node_modules/paperfilter/bin/paperfilter
