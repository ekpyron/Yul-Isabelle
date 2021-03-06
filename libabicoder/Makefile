theories := $(wildcard ../*.thy)

all: libabicoder.a

export/abicoder.ML: $(theories) ../ROOT
	isabelle build -D ..
	isabelle export -O export -d .. -x "*:**" -p 2 SolidityAbi

export/abicoder.h: export/abicoder.ML abicoder.mlb mlton_export.sml
	mlton -stop tc -format archive -default-ann 'allowFFI true' -default-ann "redundantMatch ignore" -export-header export/abicoder.h abicoder.mlb

abicoderpp.o: abicoder.cpp abicoder.hpp export/abicoder.h
	${CXX} ${CXXFLAGS} -std=c++17 -c abicoder.cpp -o abicoderpp.o

libabicoder.a: export/abicoder.ML abicoder.mlb mlton_export.sml abicoderpp.o
	mlton -format archive -default-ann 'allowFFI true' -default-ann "redundantMatch ignore" abicoder.mlb
	rm -f abicoder.h
	ar -rs abicoder.a abicoderpp.o
	mv abicoder.a libabicoder.a

test.o: test.cpp abicoder.hpp
	${CXX} ${CXXFLAGS} -std=c++17 -c -I . -o test.o test.cpp

test: test.o libabicoder.a
	${CXX} ${CXXFLAGS} -o test -L . test.o -labicoder -lgmp

clean:
	echo "Remove the export directory to trigger a rebuild of the ML code exported from the Isabelle theories (requires an isabelle installation)."
	rm -rf libabicoder.a test.o test abicoderpp.o
