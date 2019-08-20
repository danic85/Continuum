rm -rf mdapi_output_dir
sfdx force:source:convert --outputdir mdapi_output_dir --packagename 'Continuum'
# sed -i '' -e 's/<fullName>/<postInstallClass>PostInstall<\/postInstallClass><fullName>/' mdapi_output_dir/package.xml
sfdx force:mdapi:deploy --deploydir mdapi_output_dir --targetusername continuum-packaging -w 10
rm -rf mdapi_output_dir