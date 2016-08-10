#!/bin/bash
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
    if grep -q $PLUGIN .list; then
        echo "[!] Already seen $PLUGIN not downloading"
    else
        echo "[+] Downloading $PLUGIN..."
        wget -q $URL -O .tmp/$PLUGIN.html
        DL=$(cat .tmp/$PLUGIN.html | grep "downloadUrl" | cut -d "'" -f 4)
        wget -q $DL -O files/$PLUGIN.zip
        echo $PLUGIN >> .list
    fi
done

cd files

echo "[+] Extracting any files"
for FILE in $(ls); do
	unzip $FILE > /dev/null 2>&1
done
cd ..

echo "[+] Cleaning up"
rm -rf .tmp > /dev/null 2>&1
rm files/*.zip > /dev/null 2>&1

echo "[+] Generating reports"
cd files
for PLUGIN in $(ls); do
	cd $PLUGIN
	grep --exclude=REPORT -R "\$_REQUEST" * > REPORT
	grep --exclude=REPORT -R "\$_POST" * >> REPORT
	grep --exclude=REPORT -R "\$_GET" * >> REPORT
	cd ..
done

for PLUGIN in $(ls); do
    echo "------------------------------------------------------------------------------"
    echo "[+] REPORT For $PLUGIN"
    cat $PLUGIN/REPORT
    echo "[?] Keep $PLUGIN?"
    select yn in Yes No
    do
        case $yn in
            Yes ) echo "[+] Kept $PLUGIN"; break;;
            No ) rm -rf $PLUGIN; echo "[!] Deleted $PLUGIN"; break;;
        esac
    done
done
