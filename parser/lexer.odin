package parser

Lexeme :: enum {
    NONE,
    WORD,
    PIPE,
    LESS,
    GREATER,
    APPEND
}

LexemeError :: enum { None, UndefinedLexeme }

Token :: struct {
    lexeme: Lexeme,
    value: string,
}

TokenizationError :: enum { None, UndefinedToken }

// This is thought for simple 1 char lexemes, for 2 chars lexeme it can be difficult. APPEND is outside of this.
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

is_append_lexeme :: proc(char_one: u8, char_two: u8) -> bool {
    return char_one == '>' && char_two == '>'
}