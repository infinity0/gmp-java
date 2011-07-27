SRC_HOME := gcc-4.6.1/libjava/classpath
SRC_JAVA_0 := gnu/classpath/Pointer32.java \
              gnu/classpath/Pointer64.java \
              gnu/classpath/Pointer.java \
              gnu/java/lang/CPStringBuilder.java \
              gnu/java/math/GMP.java \
              gnu/java/math/MPN.java
SRC_JAVA_1 := java/math/BigInteger.java
SRC_HOME_VM := $(SRC_HOME)/vm/reference
SRC_JAVA_VM := gnu/java/lang/VMCPStringBuilder.java
SRC_JAVA := $(SRC_JAVA_VM) $(SRC_JAVA_0) gnu/$(SRC_JAVA_1)
SRC_C := native/jni/classpath/jcl.c \
         native/jni/classpath/jcl.h \
         native/jni/java-math/gnu_java_math_GMP.c
DST_C := $(notdir $(SRC_C))

INCLUDES := -I/usr/include -I$(JAVA_HOME)/include -I$(JAVA_HOME)/include/linux
LIBS := -lgmp -ljcl
CFLAGS := -fPIC -Wall -shared
JAVA_FLAGS := -Xlint -cp .

all: libgmp-jni.so GMP.jar

test: Test.class libgmp-jni.so
	LD_LIBRARY_PATH=. java -Djava.library.path=. -Dgnu.native.debug=true Test

GMP.jar: $(SRC_JAVA:.java=.class)
	jar cvf $@ $^

%.class: %.java src_java
	javac $(JAVA_FLAGS) $<

gnu_java_math_GMP.h: gnu/java/math/GMP.class
	javah -jni $(subst /,.,$(<:.class=))

libgmp-jni.so: gnu_java_math_GMP.c gnu_java_math_GMP.h libjcl.so
	gcc $(INCLUDES) -I. -L. $^ -o $@ $(LIBS) $(CFLAGS)

libjcl.so: jcl.c
	gcc $(INCLUDES) -I. $< -o $@ $(CFLAGS)

$(DST_C): src_c

$(SRC_JAVA): src_java

src_java: $(SRC_HOME) Makefile java.diff
	cd $(SRC_HOME_VM) && cp -t $(PWD) --parents $(SRC_JAVA_VM)
	cd $(SRC_HOME) && cp -t $(PWD) --parents $(SRC_JAVA_0)
	cd $(SRC_HOME) && cp -t $(PWD)/gnu --parents $(SRC_JAVA_1)
	patch -p0 < java.diff
	touch src_java

src_c: $(SRC_HOME) Makefile
	cd $(SRC_HOME) && cp -t $(PWD) $(SRC_C)
	touch src_c

gcc-%/libjava/classpath: gcc-java-%.tar.bz2
	tar xf $<

gcc-java-%.tar.bz2:
	wget "ftp://ftp.mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-$*/gcc-java-$*.tar.bz2"

clean:
	-rm -f *.class gnu_java_math_GMP.h *.so *.jar
	-rm -f src_java src_c $(SRC_JAVA) $(DST_C)
