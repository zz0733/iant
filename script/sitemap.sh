#!/bin/bash
USER_PATH=~
SOURCE_FILE="$USER_PATH/.bash_profile"
if [[ -f $SOURCE_FILE ]]; then
   echo "source $SOURCE_FILE"
   source $SOURCE_FILE
fi
SOURCE_FILE="$USER_PATH/.profile"
if [[ -f $SOURCE_FILE ]]; then
   echo "source $SOURCE_FILE"
   source $SOURCE_FILE
fi
TEMP_FILE=sitemap.data
TEMP_PREFIX=sitemap_split
SITEMAP_XML=sitemap.xml
wget -O $TEMP_FILE '127.0.0.1/local/sitemap'
# cd $NGX_ROOT_PATH
split -l 10000 $TEMP_FILE $TEMP_PREFIX
rm -rf $TEMP_FILE
SITEMAP_FILES=`ls $TEMP_PREFIX*`
INDEX=1
echo '<?xml version="1.0" encoding="UTF-8"?>' > $SITEMAP_XML
echo '<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' >> $SITEMAP_XML
for mapfile in $SITEMAP_FILES
do
   DEST_FILE="sitemap$INDEX.xml"
   echo '<?xml version="1.0" encoding="utf-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n<url><loc>http://www.lezomao.com/</loc><priority>1.0</priority><changefreq>hourly</changefreq></url>' > $DEST_FILE
   cat $mapfile >> $DEST_FILE
   echo '</urlset>' >> $DEST_FILE
   rm -rf $mapfile
   gzip -q $DEST_FILE
   mv -f "$DEST_FILE.gz" "$NGX_ROOT_PATH/$DEST_FILE.gz"
   echo "data[`date`]move [$DEST_FILE.gz],[$NGX_ROOT_PATH/$DEST_FILE.gz]"
   echo "<sitemap><loc>http://www.lezomao.com/sitemap$INDEX.xml.gz</loc></sitemap>" >> $SITEMAP_XML
   INDEX=$(($INDEX + 1))
done
echo '</sitemapindex>' >> $SITEMAP_XML
rm -rf "$NGX_ROOT_PATH/$SITEMAP_XML"
mv -f $SITEMAP_XML "$NGX_ROOT_PATH/$SITEMAP_XML"
echo "data[`date`]move [$SITEMAP_XML],[$NGX_ROOT_PATH/$SITEMAP_XML]"