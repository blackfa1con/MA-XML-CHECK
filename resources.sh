#!/bin/bash
# Copyright (c) 2013 - 2015, Redmaner
# This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International license
# The license can be found at http://creativecommons.org/licenses/by-nc-sa/4.0/

# Variables
RES_GIT="git@github.com:Redmaner/MA-XML-CHECK-RESOURCES.git"
RES_BRANCH="master"

# Resource variables
LANG_XML=$RES_DIR/languages.xml
LANGS_ALL=$RES_DIR/languages_all.mxcr
LANGS_ON=$RES_DIR/languages_enabled.mxcr

#########################################################################################################
# SYNC RESOURCES
#########################################################################################################
sync_resources () {
echo -e "${txtblu}\nSyncing resources${txtrst}"
if [ "$RES_GIT" != "" ]; then
	if [ -d $RES_DIR/.git ]; then
		OLD_GIT=$(grep "url = *" $RES_DIR/.git/config | cut -d' ' -f3)
		if [ "$RES_GIT" != "$OLD_GIT" ]; then
			echo -e "${txtblu}\nNew resources repository detected, removing old repository...\n$OLD_GIT ---> $RES_GIT${txtrst}"
			rm -rf $RES_DIR
		fi
	fi
	if [ -d $RES_DIR/.git ]; then
		OLD_BRANCH=$(grep 'branch "' $RES_DIR/.git/config | cut -d'"' -f2 | cut -d'[' -f2 | cut -d']' -f1)
		if [ "$RES_BRANCH" != "$OLD_BRANCH" ]; then
			echo -e "${txtblu}\nNew resources branch detected, removing old repository...\n$OLD_BRANCH ---> $RES_BRANCH${txtrst}"
			rm -rf $RES_DIR
		fi
	fi
	if [ -d $RES_DIR ]; then
		cd $RES_DIR
		git pull origin $RES_BRANCH
		cd $MAIN_DIR
	else
		git clone $RES_GIT -b $RES_BRANCH $RES_DIR
	fi
fi
check_mxcr
}

#########################################################################################################
# MXCR FILES
#########################################################################################################
check_mxcr () {
if [ ! -e $RES_DIR/resources.md5 ]; then
	sync_mxcr; create_md5sum_signature "$RES_DIR/resources.md5"
else
	create_md5sum_signature "$RES_DIR/resources.diff.md5"
	diff $RES_DIR/resources.md5 $RES_DIR/resources.diff.md5 > $RES_DIR/resources.result
	if [ -s $RES_DIR/resources.result ]; then
		sync_mxcr; create_md5sum_signature "$RES_DIR/resources.md5"
	fi
fi
}

create_md5sum_signature () {
SIG_FILE=$1
rm -f $SIG_FILE
md5sum $LANG_XML >> $SIG_FILE
md5sum $RES_DIR/MIUI6_auto_ignorelist.xml >> $SIG_FILE
md5sum $RES_DIR/MIUI6_ignorelist.xml >> $SIG_FILE
if [ "$MIUIV5" == "true" ]; then
	md5sum $RES_DIR/MIUIv5_auto_ignorelist.xml >> $SIG_FILE
	md5sum $RES_DIR/MIUIv5_ignorelist.xml >> $SIG_FILE
fi
}

sync_mxcr () {
echo -e "${txtblu}\nGenerating MXCR files${txtrst}"
# Parse languages.xml to mxcr
rm -f $RES_DIR/languages_all.mxcr $RES_DIR/languages_enabled.mxcr $RES_DIR/MIUIv5_auto_ignorelist.mxcr $RES_DIR/MIUIv5_ignorelist.mxcr $RES_DIR/MIUI6_auto_ignorelist.mxcr $RES_DIR/MIUI6_ignorelist.mxcr
cat $LANG_XML | grep 'language check=' | while read language; do
	LANG_VERSION=$(echo $language | awk '{print $3}' | cut -d'"' -f2)
	LANG_NAME=$(echo $language | awk '{print $4}' | cut -d'"' -f2)
	LANG_ISO=$(echo $language | awk '{print $5}' | cut -d'"' -f2)
	LANG_URL=$(echo $language | awk '{print $6}' | cut -d'"' -f2) 
	LANG_GIT=$(echo $language | awk '{print $7}' | cut -d'"' -f2)
	LANG_BRANCH=$(echo $language | awk '{print $8}' | cut -d'"' -f2)
	echo ''$LANG_VERSION' '$LANG_NAME' '$LANG_ISO' normal '$LANG_URL' '$LANG_GIT' '$LANG_BRANCH'' 
done > $LANGS_ALL
cat $LANG_XML | grep 'language check=' | grep -v '<language check="false"' | while read language; do
	LANG_CHECK=$(echo $language | awk '{print $2}' | cut -d'"' -f2)
	LANG_VERSION=$(echo $language | awk '{print $3}' | cut -d'"' -f2)
	LANG_NAME=$(echo $language | awk '{print $4}' | cut -d'"' -f2)
	LANG_ISO=$(echo $language | awk '{print $5}' | cut -d'"' -f2)
	LANG_URL=$(echo $language | awk '{print $6}' | cut -d'"' -f2) 
	LANG_GIT=$(echo $language | awk '{print $7}' | cut -d'"' -f2)
	LANG_BRANCH=$(echo $language | awk '{print $8}' | cut -d'"' -f2)
	echo ''$LANG_VERSION' '$LANG_NAME' '$LANG_ISO' '$LANG_CHECK' '$LANG_URL' '$LANG_GIT' '$LANG_BRANCH''
done > $LANGS_ON

# Parse ignorelists to mxcr
parse_ignorelist_mxcr "$RES_DIR/MIUI6_ignorelist.xml" "$RES_DIR/MIUI6_ignorelist.mxcr"
if [ "$MIUIV5" == "true" ]; then
	parse_ignorelist_mxcr "$RES_DIR/MIUIv5_ignorelist.xml" "$RES_DIR/MIUIv5_ignorelist.mxcr"
fi
}

parse_ignorelist_mxcr () {
TARGET_FILE=$1
NEW_FILE=$2
cat $TARGET_FILE | grep '<item ' | while read ignore_string; do
	ITEM_FOLDER=$(echo $ignore_string | awk '{print $2}' | cut -d'"' -f2)
	ITEM_APP=$(echo $ignore_string | awk '{print $3}' | cut -d'"' -f2)
	ITEM_FILE=$(echo $ignore_string | awk '{print $4}' | cut -d'"' -f2)
	ITEM_NAME=$(echo $ignore_string | awk '{print $5}' | cut -d'"' -f2)
	echo ''$ITEM_FOLDER' '$ITEM_APP' '$ITEM_FILE' '$ITEM_NAME' '
done > $NEW_FILE
}

#########################################################################################################
# READ MXCR FILES
#########################################################################################################
init_lang () {
LANG_VERSION=$1
LANG_NAME=$2
LANG_ISO=$3
LANG_CHECK=$4
LANG_URL=$5
LANG_GIT=$6
LANG_BRANCH=$7
LANG_TARGET=""$LANG_NAME"_"$LANG_VERSION""
IGNORELIST=$RES_DIR/MIUI"$LANG_VERSION"_ignorelist.mxcr
AUTO_IGNORELIST=$RES_DIR/MIUI"$LANG_VERSION"_auto_ignorelist.xml
}

init_ignorelist () {
ITEM_FOLDER=$1
ITEM_APP=$2
ITEM_FILE=$3
ITEM_NAME=$4
}

init_array_count () {
DIFF_ARRAY_COUNT=$3
}
