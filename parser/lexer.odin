package parser

Lexeme :: enum {
    NONE,
    WORD,
    PIPE,
    LESS,
    GREATER,
}

LexemeError :: enum { None, UndefinedLexeme }

Token :: struct {
    lexeme: Lexeme,
    value: string,
}

TokenizationError :: enum { None, UndefinedToken }

lexeme_parser :: proc(possible_lexeme: u8) -> (result: Lexeme, error: LexemeError) {
    switch {
        case possible_lexeme == '|':
            return Lexeme.PIPE, LexemeError.None
        case possible_lexeme == '<':
            return Lexeme.LESS, LexemeError.None
        case possible_lexeme == '>':
            return Lexeme.GREATER, LexemeError.None
        case possible_lexeme == '^':
            return Lexeme.NONE, LexemeError.UndefinedLexeme
        case:
            return Lexeme.WORD, LexemeError.None
    }
}