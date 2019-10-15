#!/bin/sh
xcodebuild -project BarMagnet.xcodeproj -scheme BarMagnet -sdk iphoneos -configuration Release CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
