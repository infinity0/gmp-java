# Makefile for gmp-java
# a small java/jni library containing only BigInteger from gcc-java

## build variables, for users

# checksums are for the .tar.bz2 source archives
GCJ_VERSION ?= 4.6.1
SUM_MD5 ?= 32431ba42c1d18e64f2abfdfc834ef94
SUM_SHA256 ?= 728462275a0532714063803282d1ea815e35b5fd91a96f65a1f0a14da355765f

GCJ_JAR ?= /usr/share/java/libgcj.jar
GCJ_JNI ?= /usr/lib/jvm/java-gcj/lib/
GCJ_JSRC ?= /usr/share/java/libgcj-src-4.6.zip

JUNIT_JAR ?= /usr/share/java/junit.jar

## rest of build script, for devs

DIR_C := c
DIR_JSRC_S := src_s
DIR_JBIN_S := bin_s
DIR_JSRC_D := src_d
DIR_JBIN_D := bin_d
DIR_JSRC_T := test
DIR_JBIN_T := run

INCLUDES := -I/usr/include -I$(JAVA_HOME)/include -I$(JAVA_HOME)/include/linux
LIBS := -lgmp
CFLAGS := -fPIC -Wall -shared
JAVA_FLAGS := -Xlint
TEST_FLAGS := -Dgnu.native.debug=true

ORIG := gcc-$(GCJ_VERSION)/libjava/classpath

TGT_JSRC_0 := gnu/classpath/Pointer32.java \
              gnu/classpath/Pointer64.java \
              gnu/classpath/Pointer.java \
              gnu/java/math/GMP.java \
              gnu/java/math/MPN.java
TGT_JSRC_1 := java/math/BigInteger.java
TGT_JSRC_D := gnu/$(TGT_JSRC_1)
TGT_JSRC_S := $(TGT_JSRC_0) $(TGT_JSRC_D)
TGT_JBIN_D := $(TGT_JSRC_D:%.java=%.class)
TGT_JBIN_S := $(TGT_JSRC_S:%.java=%.class)
TGT_JSRC_GMP := gnu/java/math/GMP.java
TGT_JBIN_GMP := $(TGT_JSRC_GMP:.java=.class)

ABS_JSRC_D := $(TGT_JSRC_D:%=$(DIR_JSRC_D)/%)
ABS_JSRC_S := $(TGT_JSRC_S:%=$(DIR_JSRC_S)/%)
ABS_JBIN_D := $(TGT_JBIN_D:%=$(DIR_JBIN_D)/%)
ABS_JBIN_S := $(TGT_JBIN_S:%=$(DIR_JBIN_S)/%)
ABS_JSRC_T := $(shell find $(DIR_JSRC_T) -name *.java)

CP_JBIN_D := $(DIR_JBIN_D):$(GCJ_JAR)
CP_JBIN_S := $(DIR_JBIN_S)
CP_JBIN_T := $(DIR_JBIN_T):$(JUNIT_JAR)

LP_JBIN_D := -Djava.library.path=$(GCJ_JNI)
LP_JBIN_S := -Djava.library.path=.

ORIG_C_P := classpath java-math
ORIG_C := $(ORIG)/native/jni

TGT_CSRC_0 := jcl.c jcl.h gnu_java_math_GMP.c
TGT_CSRC_C := $(filter %.c,$(TGT_CSRC_0))
TGT_CSRC_A := $(TGT_CSRC_0) gnu_java_math_GMP.h config.h

ABS_CSRC_0 := $(TGT_CSRC_0:%=$(DIR_C)/%)
ABS_CSRC_C := $(TGT_CSRC_C:%=$(DIR_C)/%)
ABS_CSRC_A := $(TGT_CSRC_A:%=$(DIR_C)/%)

WILL_BUILD_D := $(filter all check check_d gmp.jar,$(MAKECMDGOALS))
GCJ_JSRC_E := $(wildcard $(GCJ_JSRC))


.DELETE_ON_ERROR:

# dist targets

.PHONY: all
all: gmp-nogcj.jar gmp.jar libgmp-jni.so ;

gmp.jar: $(ABS_JBIN_D)
	# TODO: fix Class-Path to point to GCJ_JAR
	cd $(DIR_JBIN_D) && jar cvf $(PWD)/$@ $(TGT_JBIN_D)

gmp-nogcj.jar: $(ABS_JBIN_S)
	cd $(DIR_JBIN_S) && jar cvf $(PWD)/$@ $(TGT_JBIN_S)

libgmp-jni.so: $(ABS_CSRC_A)
	gcc $(ABS_CSRC_C) -o $@ $(CFLAGS) $(INCLUDES) -I$(DIR_C) $(LIBS)

## test targets

.PHONY: check check_d check_s
check: check_d check_s ;

check_d: $(DIR_JBIN_T) $(ABS_JBIN_D)
	java $(TEST_FLAGS) -cp $(CP_JBIN_T):$(CP_JBIN_D) $(LP_JBIN_D) junit.textui.TestRunner Test
	java $(TEST_FLAGS) -cp $(CP_JBIN_T):$(CP_JBIN_D) $(LP_JBIN_D) junit.textui.TestRunner Benchmark

check_s: $(DIR_JBIN_T) $(ABS_JBIN_S) libgmp-jni.so
	java $(TEST_FLAGS) -cp $(CP_JBIN_T):$(CP_JBIN_S) $(LP_JBIN_S) junit.textui.TestRunner Test
	java $(TEST_FLAGS) -cp $(CP_JBIN_T):$(CP_JBIN_S) $(LP_JBIN_S) junit.textui.TestRunner Benchmark

## DIR_JBIN_T - classes, test

ifdef WILL_BUILD_D
_ABS_JBIN = $(ABS_JBIN_D)
_CP_JBIN = $(CP_JBIN_D)
else
_ABS_JBIN = $(ABS_JBIN_S)
_CP_JBIN = $(CP_JBIN_S)
endif

$(DIR_JBIN_T): $(DIR_JSRC_T) $(_ABS_JBIN)
	mkdir -p $(DIR_JBIN_T)
	javac $(JAVA_FLAGS) -d $(DIR_JBIN_T) -cp $(DIR_JSRC_T):$(_CP_JBIN):$(JUNIT_JAR) $(ABS_JSRC_T)

## DIR_JBIN_D - classes, linked to gcj jar

$(DIR_JBIN_D)/%.class: $(DIR_JSRC_D)/%.java $(ABS_JSRC_D) | $(DIR_JBIN_D)
	javac $(JAVA_FLAGS) -d $(DIR_JBIN_D) -cp $(CP_JBIN_D):$(DIR_JSRC_D) $<

## DIR_JBIN_S - classes, copied from gcj source

$(DIR_JBIN_S)/%.class: $(DIR_JSRC_S)/%.java $(ABS_JSRC_S) | $(DIR_JBIN_S)
	javac $(JAVA_FLAGS) -d $(DIR_JBIN_S) -cp $(CP_JBIN_S):$(DIR_JSRC_S) $<

## DIR_JSRC_D - sources, linked to gcj jar

ifdef GCJ_JSRC_E
_ORIG_D = $(GCJ_JSRC)
_COPY = cd $(DIR_JSRC_D)/gnu && unzip -o $(GCJ_JSRC) $*
else
_ORIG_D = $(ORIG)
_COPY = cd $(ORIG) && cp -t $(PWD)/$(DIR_JSRC_D)/gnu --parents $*
endif

$(TGT_JSRC_1:%=$(DIR_JSRC_D)/gnu/%): \
$(DIR_JSRC_D)/gnu/%: $(_ORIG_D) Makefile java1.diff | $(DIR_JSRC_D)/gnu
	$(_COPY)
	patch -d $(DIR_JSRC_D) -p1 < java1.diff

## DIR_JSRC_S - sources, copied from gcj source

$(TGT_JSRC_0:%=$(DIR_JSRC_S)/%): \
$(DIR_JSRC_S)/%: $(ORIG) Makefile | $(DIR_JSRC_S)
	cd $(ORIG) && cp -t $(PWD)/$(DIR_JSRC_S) --parents $*

$(TGT_JSRC_1:%=$(DIR_JSRC_S)/gnu/%): \
$(DIR_JSRC_S)/gnu/%: $(ORIG) Makefile java1.diff java2.diff | $(DIR_JSRC_S)/gnu
	cd $(ORIG) && cp -t $(PWD)/$(DIR_JSRC_S)/gnu --parents $*
	patch -d $(DIR_JSRC_S) -p1 < java1.diff
	patch -d $(DIR_JSRC_S) -p1 < java2.diff

## DIR_C - sources and headers, copied from gcj source

$(DIR_C)/gnu_java_math_GMP.h: $(DIR_JBIN_S)/$(TGT_JBIN_GMP) | $(DIR_C)
	javah -jni -d $(DIR_C) -classpath $(DIR_JBIN_S) $(subst /,.,$(TGT_JBIN_GMP:.class=))

$(DIR_C)/config.h: config.h Makefile | $(DIR_C)
	cp $< $@

$(ABS_CSRC_0): \
$(DIR_C)/%: $(ORIG) Makefile | $(DIR_C)
	cd $(ORIG_C) && cp -t $(PWD)/$(DIR_C) $$(find $(ORIG_C_P) -name $*)

## misc structural

$(DIR_JSRC_S) $(DIR_JSRC_S)/gnu $(DIR_JBIN_S) \
$(DIR_JSRC_D) $(DIR_JSRC_D)/gnu $(DIR_JBIN_D) \
$(DIR_C):
	mkdir -p $@

gcc-%/libjava/classpath: gcc-java-%.tar.bz2
	tar xf $<

gcc-java-%.tar.bz2:
	wget -SN "ftp://ftp.mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-$*/gcc-java-$*.tar.bz2"
	echo "$(SUM_MD5)  gcc-java-$*.tar.bz2" | md5sum -c
	echo "$(SUM_SHA256)  gcc-java-$*.tar.bz2" | sha256sum -c

.PHONY: clean
clean:
	rm -f *.so *.jar
	rm -fr $(DIR_C) $(DIR_JSRC_S) $(DIR_JBIN_S) $(DIR_JSRC_D) $(DIR_JBIN_D) $(DIR_JBIN_T)

.PHONY: debug
debug:
	$(MAKE) clean all check && $(MAKE) all check

