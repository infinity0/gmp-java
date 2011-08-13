# Makefile for gmp-java
# a small java/jni library containing only BigInteger from gcc-java

########################################################################
# build variables, for users
########################################################################

# checksums are for the .tar.bz2 source archives
GCJ_VERSION ?= 4.6.1
SUM_MD5 ?= 32431ba42c1d18e64f2abfdfc834ef94
SUM_SHA256 ?= 728462275a0532714063803282d1ea815e35b5fd91a96f65a1f0a14da355765f

# system library directories

JVM_DIR ?= /usr/lib/jvm
JAR_DIR ?= /usr/share/java

GCJ_JAR ?= $(JAR_DIR)/libgcj-4.6.jar
GCJ_JNI ?= $(JVM_DIR)/java-gcj-4.6/lib
GCJ_JSRC ?= $(JAR_DIR)/libgcj-src-4.6.zip

JUNIT_JAR ?= $(JAR_DIR)/junit.jar

# installation directories

DESTDIR ?= gmp-java

prefix ?= /usr/local
exec_prefix ?= $(prefix)

datarootdir ?= $(prefix)/share
libdir ?= $(exec_prefix)/lib

jardir ?= $(datarootdir)/java
jnidir ?= $(libdir)/jni
jvmdir ?= $(libdir)/jvm

########################################################################
# rest of build script, for devs
########################################################################

PACKAGE := gmp-java
VERSION := 0.1

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

TMP_MF := META-INF/MANIFEST.MF.1

TEST_STD = Test
TEST_LONG = Benchmark
TEST_RUN = $(TEST_STD) $(TEST_LONG)


.DELETE_ON_ERROR:

# dist targets

.PHONY: all
all: gmp.jar gmp-nogcj.jar libgmp-jni.so ;

gmp.jar: $(ABS_JBIN_D) $(DIR_JBIN_D)/$(TMP_MF)
	cd $(DIR_JBIN_D) && jar cvmf $(TMP_MF) $(CURDIR)/$@ $(TGT_JBIN_D)

$(DIR_JBIN_D)/$(TMP_MF): | $(DIR_JBIN_D)
	mkdir -p $(dir $@)
	echo "Class-Path: $(notdir $(GCJ_JAR))" >> $@

gmp-nogcj.jar: $(ABS_JBIN_S)
	cd $(DIR_JBIN_S) && jar cvf $(CURDIR)/$@ $(TGT_JBIN_S)

libgmp-jni.so: $(ABS_CSRC_A)
	gcc $(ABS_CSRC_C) -o $@ $(CFLAGS) $(INCLUDES) -I$(DIR_C) $(LIBS)

.PHONY: install
install: all
	mkdir -p $(DESTDIR)$(jardir) $(DESTDIR)$(jnidir)
	install -t $(DESTDIR)$(jardir) -m 0644 gmp.jar
	install -t $(DESTDIR)$(jardir) -m 0644 gmp-nogcj.jar
	install -t $(DESTDIR)$(jnidir) libgmp-jni.so
	ln -sf $(GCJ_JNI)/libjavamath.so $(DESTDIR)$(jnidir)

## test targets

.PHONY: check check_d check_s installcheck_d installcheck_s
check: check_d check_s ;

RUN_TESTS = \
	for i in $(TEST_RUN); do \
		java $(TEST_FLAGS) -cp $(CP_JBIN_T):$$CP $$LP junit.textui.TestRunner $$i; \
	done

check_d: $(DIR_JBIN_T) $(ABS_JBIN_D)
	CP=$(CP_JBIN_D); LP=$(LP_JBIN_D); $(RUN_TESTS)

check_s: $(DIR_JBIN_T) $(ABS_JBIN_S) libgmp-jni.so
	CP=$(CP_JBIN_S); LP=$(LP_JBIN_S); $(RUN_TESTS)

# test installed system jar; any .so should already be on library path
installcheck: $(DIR_JBIN_T)
	CP=$(JAR_DIR)/gmp.jar; $(RUN_TESTS)

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
_COPY = cd $(ORIG) && cp -t $(CURDIR)/$(DIR_JSRC_D)/gnu --parents $*
endif

$(TGT_JSRC_1:%=$(DIR_JSRC_D)/gnu/%): \
$(DIR_JSRC_D)/gnu/%: $(_ORIG_D) Makefile java1.diff | $(DIR_JSRC_D)/gnu
	$(_COPY)
	patch -d $(DIR_JSRC_D) -p1 < java1.diff

## DIR_JSRC_S - sources, copied from gcj source

$(TGT_JSRC_0:%=$(DIR_JSRC_S)/%): \
$(DIR_JSRC_S)/%: $(ORIG) Makefile | $(DIR_JSRC_S)
	cd $(ORIG) && cp -t $(CURDIR)/$(DIR_JSRC_S) --parents $*

$(TGT_JSRC_1:%=$(DIR_JSRC_S)/gnu/%): \
$(DIR_JSRC_S)/gnu/%: $(ORIG) Makefile java1.diff java2.diff | $(DIR_JSRC_S)/gnu
	cd $(ORIG) && cp -t $(CURDIR)/$(DIR_JSRC_S)/gnu --parents $*
	patch -d $(DIR_JSRC_S) -p1 < java1.diff
	patch -d $(DIR_JSRC_S) -p1 < java2.diff

## DIR_C - sources and headers, copied from gcj source

$(DIR_C)/gnu_java_math_GMP.h: $(DIR_JBIN_S)/$(TGT_JBIN_GMP) | $(DIR_C)
	javah -force -jni -d $(DIR_C) -classpath $(DIR_JBIN_S) $(subst /,.,$(TGT_JBIN_GMP:.class=))

$(DIR_C)/config.h: config.h Makefile | $(DIR_C)
	cp $< $@

$(ABS_CSRC_0): \
$(DIR_C)/%: $(ORIG) Makefile | $(DIR_C)
	cd $(ORIG_C) && cp -t $(CURDIR)/$(DIR_C) $$(find $(ORIG_C_P) -name $*)

## misc structural

$(DIR_JSRC_S) $(DIR_JSRC_S)/gnu $(DIR_JBIN_S) \
$(DIR_JSRC_D) $(DIR_JSRC_D)/gnu $(DIR_JBIN_D) \
$(DIR_C):
	mkdir -p $@

gcc-%/libjava/classpath: gcc-java-%.tar.bz2
	tar xf $< $@
	touch $@

gcc-java-%.tar.bz2:
	wget -c -SN "ftp://ftp.mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-$*/gcc-java-$*.tar.bz2"
	echo "$(SUM_MD5)  gcc-java-$*.tar.bz2" | md5sum -c
	echo "$(SUM_SHA256)  gcc-java-$*.tar.bz2" | sha256sum -c

.PHONY: clean
clean:
	rm -f *.so *.jar
	rm -fr $(DIR_C) $(DIR_JSRC_S) $(DIR_JBIN_S) $(DIR_JSRC_D) $(DIR_JBIN_D) $(DIR_JBIN_T)

.PHONY: dist
dist:
	tar --transform='s|^|$(PACKAGE)_$(VERSION)/|g' \
	  -czf $(PACKAGE)_$(VERSION).tar.gz Makefile README *.h *.diff test

.PHONY: debug
debug:
	$(MAKE) clean all check && $(MAKE) all check

