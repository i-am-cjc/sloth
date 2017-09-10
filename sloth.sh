#!/bin/bash
mkdir -p .tmp
mkdir -p files
mkdir -p plugins
mkdir -p archive

if [ -z "$1" ]; then
	echo "[+] Getting newest Wordpress plugins list..."
	wget -q https://wordpress.org/plugins/browse/new/ -O .tmp/list.html
else
	echo "[+] Gettings Wordpress plugin results for $1..."
	wget -q https://wordpress.org/plugins/search.php?q=$1 -O .tmp/list.html
fi

for URL in $(grep entry-title .tmp/list.html | cut -d"\"" -f4); do
	PLUGIN=$(echo $URL | cut -d "/" -f 5)
    if grep -q $PLUGIN .list; then
        echo "[!] Already seen $PLUGIN not downloading"
    else
        echo "[+] Downloading $PLUGIN..."
        wget -q $URL -O .tmp/$PLUGIN.html
        DL=$(grep plugin-download .tmp/$PLUGIN.html | cut -d"\"" -f4)
        wget -q $DL -O files/$PLUGIN.zip
        echo $PLUGIN >> .list
    fi
done

cd files

echo "[+] Extracting any files"
for FILE in $(ls *.zip); do
	unzip $FILE > /dev/null 2>&1
done
cd ..

echo "[+] Cleaning up"
rm -rf .tmp > /dev/null 2>&1
mv files/*.zip archive > /dev/null 2>&1
rm -rf files/* > /dev/null 2>&1

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
            Yes ) echo "[+] Kept $PLUGIN"; mv $PLUGIN ../plugins; break;;
            No ) rm -rf $PLUGIN; echo "[!] Deleted $PLUGIN"; break;;
        esac
    done
done

cd ..

echo "[?] Spin up Wordpress?"
select yn in Yes No
do
	case $yn in
		Yes ) 
			echo "[+] Starting containers @ http://localhost:1337/"
			docker-compose up -d
			echo "[+] Hit enter when setup is done"
			read $sloth
			for PLUGIN in $(ls plugins); do
				echo "[+] Copying $PLUGIN to container"
				docker cp plugins/$plugin/ sloth_wordpress_1:/var/www/html/wp-content/plugins/
			done
			echo "[+] Plugins copied, press enter to kill containers"
			read $sloth
			docker-compose stop
			docker-compose rm
			break;;
		No )
			break;;
	esac
done
