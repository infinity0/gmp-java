# Makefile for gmp-java
# a small java/jni library containing only BigInteger from gcc-java

# build variables, for users

# checksums are for the .tar.bz2 source archives
GCJ_VERSION ?= 4.6.1
CHECKSUM_MD5 ?= 32431ba42c1d18e64f2abfdfc834ef94
CHECKSUM_SHA256 ?= 728462275a0532714063803282d1ea815e35b5fd91a96f65a1f0a14da355765f

# rest of build script, for devs

SRC_HOME := gcc-$(GCJ_VERSION)/libjava/classpath
SRC_JAVA_0 := gnu/classpath/Pointer32.java \
              gnu/classpath/Pointer64.java \
              gnu/classpath/Pointer.java \
              gnu/java/math/GMP.java \
              gnu/java/math/MPN.java
SRC_JAVA_1 := java/math/BigInteger.java
SRC_JAVA := $(SRC_JAVA_0) gnu/$(SRC_JAVA_1)
ORIG_SRC_C := native/jni/classpath/jcl.c \
              native/jni/classpath/jcl.h \
              native/jni/java-math/gnu_java_math_GMP.c
SRC_C_ALL := $(notdir $(ORIG_SRC_C))
SRC_C := $(filter %.c,$(SRC_C_ALL))

INCLUDES := -I/usr/include -I$(JAVA_HOME)/include -I$(JAVA_HOME)/include/linux
LIBS := -lgmp
CFLAGS := -fPIC -Wall -shared
JAVA_FLAGS := -Xlint -cp .

.PHONY: all
all: libgmp-jni.so GMP.jar ;

.PHONY: test
test: Test.class libgmp-jni.so
	java -Djava.library.path=. -Dgnu.native.debug=true Test

GMP.jar: $(SRC_JAVA:.java=.class)
	jar cvf $@ $^

%.class: %.java src_java
	javac $(JAVA_FLAGS) $<

gnu_java_math_GMP.h: gnu/java/math/GMP.class
	javah -jni $(subst /,.,$(<:.class=))

libgmp-jni.so: $(SRC_C) gnu_java_math_GMP.h config.h
	gcc $(INCLUDES) -I. $(SRC_C) -o $@ $(LIBS) $(CFLAGS)

$(SRC_C_ALL): src_c

$(SRC_JAVA): src_java

src_java: $(SRC_HOME) Makefile java.diff
	cd $(SRC_HOME) && cp -t $(PWD) --parents $(SRC_JAVA_0)
	cd $(SRC_HOME) && cp -t $(PWD)/gnu --parents $(SRC_JAVA_1)
	patch -p0 < java.diff
	touch src_java

src_c: $(SRC_HOME) Makefile
	cd $(SRC_HOME) && cp -t $(PWD) $(ORIG_SRC_C)
	touch src_c

gcc-%/libjava/classpath: gcc-java-%.tar.bz2
	tar xf $<

gcc-java-%.tar.bz2:
	wget -SN "ftp://ftp.mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-$*/gcc-java-$*.tar.bz2"
	echo "$(CHECKSUM_MD5)  gcc-java-$*.tar.bz2" | md5sum -c || exit 1
	echo "$(CHECKSUM_SHA256)  gcc-java-$*.tar.bz2" | sha256sum -c || exit 1

.PHONY: clean
clean:
	-rm -f *.class gnu_java_math_GMP.h *.so *.jar
	-rm -f src_java src_c $(SRC_JAVA) $(SRC_C_ALL)
