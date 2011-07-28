// normally this file would be created by ./configure et al, but we are using
// such a small subset of gcc-java that the overhead of autotools is wasteful.

// TODO: iirc __LP64__ is gcc-only, this could be detected better
#ifdef __LP64__
#define SIZEOF_VOID_P 8
#else
#define SIZEOF_VOID_P 4
#endif

// assume these, since we're building a GMP library, duh :)
#define WITH_GNU_MP
#define HAVE_GMP_H
