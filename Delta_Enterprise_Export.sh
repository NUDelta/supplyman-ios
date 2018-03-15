#!/bin/bash
# original source from http://www.thecave.com/2014/09/16/using-xcodebuild-to-export-a-ipa-from-an-archive/

xcodebuild clean -project otgSM -configuration Release -alltargets
xcodebuild archive -project otgSM.xcodeproj -scheme otgSM -archivePath otgSM.xcarchive

xcodebuild -exportArchive -archivePath otgSM.xcarchive -exportOptionsPlist ipa_export.plist -exportPath build
