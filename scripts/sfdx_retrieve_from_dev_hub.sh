cd .. 
sfdx force:mdapi:retrieve -u continuum-dev-hub -r src -k scripts/package.xml
cd src
unzip unpackaged.zip
cd ..
sfdx force:mdapi:convert -r src/unpackaged -d force-app
rm -rf src