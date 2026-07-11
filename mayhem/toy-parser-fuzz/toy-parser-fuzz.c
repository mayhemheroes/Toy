/*
 * mayhem/toy-parser-fuzz/toy-parser-fuzz.c — libFuzzer harness for the Toy parser.
 *
 * Preserves the fork's original `toy-parser-fuzz` target (lex + parse arbitrary input), ported to
 * the current upstream (v2) parser API: the v1 harness used Toy_initLexer/Toy_scanParser(&parser)
 * with a monolithic <toy.h> and Toy_freeASTNode; v2 uses Toy_bindLexer(const char*), a Toy_Bucket
 * arena, Toy_scanParser(&bucket, &parser) and Toy_freeBucket (see tests/units/test_parser.c).
 */
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "toy_lexer.h"
#include "toy_parser.h"
#include "toy_ast.h"
#include "toy_bucket.h"

int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {
    /* v2's lexer takes a NUL-terminated C string, so copy + terminate the fuzz input. */
    char *source = (char *)malloc(Size + 1);
    if (!source) return 0;
    memcpy(source, Data, Size);
    source[Size] = '\0';

    Toy_Lexer lexer;
    Toy_bindLexer(&lexer, source);

    Toy_Parser parser;
    Toy_bindParser(&parser, &lexer);

    Toy_Bucket *bucket = Toy_allocateBucket(TOY_BUCKET_IDEAL);
    Toy_Ast *ast = Toy_scanParser(&bucket, &parser);
    (void)ast;

    Toy_freeBucket(&bucket);
    free(source);
    return 0;
}
