# ------------------------------------------------------------------------------
# GNU gmake file.

# Change these lines to fit your system. fortranint should be 4 or 8 bytes. This
# was established when you compiled LAPACK and BLAS.
fortranint = 4
BLASLIB = -lblas
LAPACKLIB = -llapack
FORTRANLIB = -lgfortran

CPP = g++
MPICPP = mpic++
FORTRAN = gfortran

# Set the optimization level. I prefer '-O3'.
#opt = 
#opt = -g
opt = -O3

# Choose serial, OpenMP-parallelized, MPI-parallized versions, or hybrid
# MPI-OpenMP. I prefer OpenMP to MPI if I'm running on one shared-memory
# machine. Compression cannot be run as hybrid; only the MVP can.
#mode = s
mode = omp
#mode = mpi
#mode = hybrid

# Probably does not need to be changed:
ifeq ($(mode),s)
	MODE_FLAGS =
	ext = omp
endif
ifeq ($(mode),omp)
	MODE_FLAGS = -fopenmp -DUTIL_OMP
	ext = omp
endif
ifeq ($(mode),mpi)
	CPP = $(MPICPP)
	MODE_FLAGS = -DUTIL_MPI
	ext = mpi
endif
ifeq ($(mode),hybrid)
	CPP = $(MPICPP)
	MODE_FLAGS = -fopenmp -DUTIL_OMP -DUTIL_MPI
	ext = mpi
endif

# ------------------------------------------------------------------------------
# The rest should not have to be changed.

INCLUDE = -I .
LIBS = $(LAPACKLIB) $(BLASLIB) $(FORTRANLIB)
LIBDIRS =
OPTFLAGS = $(opt)
CPPFLAGS = $(OPTFLAGS) $(MODE_FLAGS) -DFORTRAN_INT_$(fortranint)
LDFLAGS = $(MODE_FLAGS)

.SUFFIXES:
.SUFFIXES: .cpp .f90 .o

CPPSRCS = src/Hd.cpp src/Compress.cpp src/Hmat.cpp src/HmatIo.cpp \
src/KeyValueFile.cpp src/CodeAnalysis.cpp src/Mpi.cpp src/CHmat.cpp \
src/SFHmat.cpp

OBJECTS = $(patsubst %.cpp,%.o,$(CPPSRCS))

%.o : %.cpp
	$(CPP) $(CPPFLAGS) $(INCLUDE) -c $< -o $@

%.o : %.f90
	$(FORTRAN) $(FFLAGS) -c $< -o $@

all: libhmmvp build mvp cmvp fmvp

# Library to compress and apply an H-matrix.
libhmmvp: $(OBJECTS)
	ar rucs lib/libhmmvp_$(mode).a $(OBJECTS)
	rm -f src/*.o

# A driver to compress an H-matrix.
build: libhmmvp
	$(CPP) src/hmmvpbuild.cpp $(INCLUDE) $(LDFLAGS) $(LIBFLAGS) $(LIBDIRS) lib/libhmmvp_$(mode).a $(LIBS) -o bin/hmmvpbuild_$(mode)
	rm -f src/*.o

# C++ examples.
mvp:
	$(CPP) examples/mvp_$(ext).cpp $(INCLUDE) $(LDFLAGS) $(LIBFLAGS) $(LIBDIRS) lib/libhmmvp_$(mode).a $(LIBS) -o examples/mvp_$(mode)

# C example.
cmvp:
	$(CPP) examples/cmvp_$(ext).c $(INCLUDE) $(LDFLAGS) $(LIBFLAGS) $(LIBDIRS) lib/libhmmvp_$(mode).a $(LIBS) -o examples/cmvp_$(mode)

# Fortran 90 example.
fmvp:
	$(FORTRAN) examples/fmvp_$(ext).f90 $(INCLUDE) $(LDFLAGS) lib/libhmmvp_$(mode).a $(LIBS) -lstdc++ -o examples/fmvp_$(mode)

clean:
	rm -f src/*.o lib/*.a bin/*
