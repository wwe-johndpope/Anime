
# ARCHS = armv7 armv7s arm64
#export ARCHS=armv7
#ARCHS=armv7
#export TARGET=iphone:clang:8.1:8.1


# http://stackoverflow.com/questions/15628108/enable-arc-for-theos-build-system
ARCHS=armv7 armv7s
#TARGET_IPHONEOS_DEPLOYMENT_VERSION = 6.0
#TARGET_CC = xcrun -sdk iphoneos clang
#TARGET_CXX = xcrun -sdk iphoneos clang++ 
#TARGET_LD = xcrun -sdk iphoneos clang++
#SHARED_CFLAGS = -fobjc-arc -D__arm__

HEADER_PATH_FLAGS := -I../Anime -I../Anime/Model -I../HTMLReader/Code

OBJCFLAGS := $(HEADER_PATH_FLAGS)
OBJCFLAGS += -fobjc-arc -fmodules

TARGET=iphone:clang:8.1:8.1

# To disable -Werror
GO_EASY_ON_ME = 1

include theos/makefiles/common.mk

rawfiles = ../Anime/AnimePlayer.m ../Anime/AppDelegate.m ../Anime/Episode.m ../Anime/EpisodePlayerItem.m ../Anime/EpisodeURLAsset.m ../Anime/main.m ../Anime/Model/DataStore.m ../Anime/Model/Recents.m ../Anime/Model/SeriesRequest.m ../Anime/PlayerViewController.m ../Anime/Series.m ../Anime/SeriesViewController.m ../Anime/ViewControllers/RecentViewController.m ../Anime/ViewControllers/SearchViewController.m


APPLICATION_NAME = Anime
#Anime_FILES = main.m AnimeApplication.mm RootViewController.mm
#Anime_FILES = $(find ../Anime | grep "\\.m" | xargs echo)
Anime_FILES = $(rawfiles) $(shell find ../HTMLReader/Code/*.m)
Anime_FRAMEWORKS = UIKit CoreGraphics



include $(THEOS_MAKE_PATH)/application.mk
