#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <toy.h>

int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {
    //test init & quit
    Toy_Lexer lexer;
    Toy_Parser parser;

    Toy_initLexer(&lexer, Data);
    Toy_initParser(&parser, &lexer);

    Toy_ASTNode* node = Toy_scanParser(&parser);


    Toy_freeASTNode(node);
    Toy_freeParser(&parser);
}