toy-fuzz: toy-parser-fuzz.c
	clang -g -fsanitize=fuzzer,address,undefined,nullability -L. -ltoy -I../source -o toy-parser-fuzz toy-parser-fuzz.c