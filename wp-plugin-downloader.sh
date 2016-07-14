mkdir .tmp
mkdir files

if [ -z "$1" ]; then
	echo "[+] Getting newest Wordpress plugins list..."
	wget -q https://wordpress.org/plugins/browse/new/ -O .tmp/list.html
else
	echo "[+] Gettings Wordpress plugin results for $1..."
	wget -q https://wordpress.org/plugins/search.php?q=$1 -O .tmp/list.html
fi

for URL in $(cat .tmp/list.html | grep "plugin-icon" | cut -d "\"" -f 2); do
	PLUGIN=$(echo $URL | cut -d "/" -f 5)
	echo "[+] Downloading $PLUGIN..."
	wget -q $URL -O .tmp/$PLUGIN.html
	DL=$(cat .tmp/$PLUGIN.html | grep "downloadUrl" | cut -d "'" -f 4)
	wget -q $DL -O files/$PLUGIN.zip
done

cd files

for FILE in $(ls); do
	echo "[+] Extracting $FILE"
	unzip $FILE > /dev/null 2>&1
done
cd ..

echo "[+] Cleaning up"
rm -rf .tmp
rm files/*.zip

echo "[+] Generating reports"

cd files
for PLUGIN in $(ls); do
	cd $PLUGIN
	grep -R "\$_REQUEST" * > REPORT
	grep -R "\$_POST" * >> REPORT
	grep -R "\$_GET" * >> REPORT
	cd ..
done
