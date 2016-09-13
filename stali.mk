ROOT=.

export STALISRC:=$(shell pwd)/../src/

include $(STALISRC)/config.mk

SUBDIRS = tinycc

world: all

include $(STALISRC)/mk/dir.mk
