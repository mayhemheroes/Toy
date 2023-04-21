toy-fuzz: toy-parser-fuzz.c
	clang -g -fsanitize=fuzzer,undefined,nullability -L. -ltoy -I../source -o toy-parser-fuzz toy-parser-fuzz.c