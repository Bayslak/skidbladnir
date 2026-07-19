package parser 

import "core:fmt"
import "core:os"
import "core:strings"

parse_input :: proc(input: string) -> (result: bool, command: string) {
    if len(input) == 0 do return
 
    // here maybe we tokenize?
    tokenized, err := tokenize_input(input)

    if err != nil {
        fmt.printf("There were some problems with the input typed in. Please, try again. %v \n", err)
    }

    //for n in 0..<len(tokenized) {
    //    fmt.printf("%v, value: %v\n", tokenized[n].lexeme, tokenized[n].value)
    //}

    bi_exists, _ := get_built_in(tokenized[0].value)

    if bi_exists {
        // resolve builtins
        return resolve_built_ins(tokenized[:])
    }

    ex_result, ex_err := execute_command(&tokenized)

    if !ex_result {
        fmt.printf("There was a problem executing command %v: %v\n", tokenized[0].value, ex_err)
        return false, tokenized[0].value
    }

    return false, ""
}

tokenize_input :: proc(input: string) -> (result: [dynamic]Token, error: LexemeError) {
    
    tokenized_arguments: [dynamic]Token
    is_complex_arg := false 
    builder: strings.Builder
    strings.builder_init(&builder, context.temp_allocator)

    for n in 0..<len(input) {
        char := input[n]

        if is_complex_arg {
            if char == '"' {
                    is_complex_arg = false
                    complex_arg := strings.to_string(builder)
                    strings.builder_destroy(&builder)
    
                    token := Token {
                        lexeme = Lexeme.WORD,
                        value = complex_arg
                    }
    
                    append(&tokenized_arguments, token)
                    continue
                }

            strings.write_byte(&builder, char)
            continue
        }

        if char == '"' {
            is_complex_arg = true
            continue
        }

        if char == ' ' {
            arg := strings.to_string(builder)
            strings.builder_destroy(&builder)

            token := Token {
                lexeme = Lexeme.WORD,
                value = arg
            }

            append(&tokenized_arguments, token)
            continue
        }

        is_lexeme := lexeme_parser(char) or_return
        if is_lexeme != Lexeme.WORD {
            token := Token {
                lexeme = is_lexeme,
            }
            append(&tokenized_arguments, token)
            strings.builder_destroy(&builder)
            continue
        }

        strings.write_byte(&builder, char)
    }

    if strings.builder_len(builder) > 0 {
        last_string := strings.to_string(builder)
        token := Token {
            lexeme = Lexeme.WORD,
            value = last_string
        }
        
        append(&tokenized_arguments, token)
    }

    strings.builder_destroy(&builder)
    return tokenized_arguments, LexemeError.None
}