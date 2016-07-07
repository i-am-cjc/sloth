mkdir .tmp
mkdir files

echo "[+] Getting newest Wordpress plugins list..."
wget -q https://wordpress.org/plugins/browse/new/ -O .tmp/list.html

for URL in $(cat .tmp/list.html | grep "plugin-icon" | cut -d "\"" -f 2); do
	PLUGIN=$(echo $URL | cut -d "/" -f 5)
	echo "[+] Getting $PLUGIN..."
	wget -q $URL -O .tmp/$PLUGIN.html
	DL=$(cat .tmp/$PLUGIN.html | grep "downloadUrl" | cut -d "'" -f 4)
	wget -q $DL -O files/$PLUGIN.zip
done
echo "[+] Nuking tmp folder"
rm -rf .tmp
