/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Dont remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
  if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
    YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
bool terminate = false;
int nested_comments = 0;
int string_err = false;

bool check_string_length(int add_len)
{
  if (string_err) return false;
  if (string_buf_ptr - string_buf + add_len >= MAX_STR_CONST)
  {
    string_err = 1;
    return false;
  }
  return true;
}
%}

%option noyywrap

/*
 * Define names for regular expressions here.
 */

digit   [0-9]
id      [0-9a-zA-Z_]

  /* exclusive start conditions */
%x str
%x comment

%%

 /*
  * Define regular expressions for the tokens of COOL here. Make sure, you
  * handle correctly special cases, like:
  *   - Nested comments
  *   - String constants: They use C like systax and can contain escape
  *     sequences. Escape sequence \c is accepted for all characters c. Except
  *     for \n \t \b \f, the result is c.
  *   - Keywords: They are case-insensitive except for the values true and
  *     false, which must begin with a lower-case letter.
  *   - Multiple-character operators (like <-): The scanner should produce a
  *     single token for every such operator.
  *   - Line counting: You should keep the global variable curr_lineno updated
  *     with the correct line number
  */

 /* white space */
[\f\r\t\v ]+    ;
  /* new line */
\n              curr_lineno++;
  /* keywords */
(?i:class)      return CLASS;
(?i:else)       return ELSE;
(?i:if)         return IF;
(?i:fi)         return FI;
(?i:in)         return IN;
(?i:inherits)   return INHERITS;
(?i:isvoid)     return ISVOID;
(?i:let)        return LET;
(?i:loop)       return LOOP;
(?i:pool)       return POOL;
(?i:then)       return THEN;
(?i:while)      return WHILE;
(?i:case)       return CASE;
(?i:esac)       return ESAC;
(?i:new)        return NEW;
(?i:of)         return OF;
(?i:not)        return NOT;
  /* bool constants */
f(?i:alse)      { cool_yylval.boolean = false; return BOOL_CONST; }
t(?i:rue)       { cool_yylval.boolean = true; return BOOL_CONST; }
  /* operators and punctuation characters */
\+ |
\/ |
\- |
\* |
\= |
\< |
\. |
\~ |
\, |
\; |
\: |
\( |
\) |
\@ |
\{ |
\}              return yytext[0];
"<-"            return ASSIGN;
"=>"            return DARROW;
"<="            return LE;
"*)"            { cool_yylval.error_msg = "Unmatched *)"; return ERROR; }
  /* int constants */
{digit}+        { cool_yylval.symbol = inttable.add_string(yytext); return INT_CONST; }
  /* identifiers */
[A-Z]{id}*      { cool_yylval.symbol = idtable.add_string(yytext); return TYPEID; }
[a-z]{id}*      { cool_yylval.symbol = idtable.add_string(yytext); return OBJECTID; }
  /* string constants */
\"                      { BEGIN(str); memset(string_buf, 0, MAX_STR_CONST); string_buf_ptr = string_buf; string_err = 0; }
<str>\n                 { BEGIN(INITIAL); curr_lineno++; cool_yylval.error_msg = "Unterminated string constant"; return ERROR; }
<str>[^"\n\\\0]*        { int len = strlen(yytext); 
                          if (check_string_length(len)) {
                            strcpy(string_buf_ptr, yytext); 
                            string_buf_ptr += len; 
                          } 
                        }
<str>\\\n               { curr_lineno++; if (check_string_length(1)) {string_buf_ptr[0] = '\n'; string_buf_ptr += 1; } }
<str>\\\0               { string_err = 2; }
<str>\\[^\n\0]          { if (check_string_length(1)) {
                            switch (yytext[1]) {
                              case 'b': string_buf_ptr[0] = '\b'; break;
                              case 't': string_buf_ptr[0] = '\t'; break;
                              case 'n': string_buf_ptr[0] = '\n'; break;
                              case 'f': string_buf_ptr[0] = '\f'; break;
                              default: string_buf_ptr[0] = yytext[1];
                            }
                            string_buf_ptr += 1;
                          }
                        }
<str>\0                 { string_err = 2; }
<str><<EOF>>            { if (terminate) 
                            yyterminate();
                          else {
                            terminate = true;
                            cool_yylval.error_msg = "EOF in string constant";
                            return ERROR;
                          }
                        }
<str>\"                 { BEGIN(INITIAL);
                          if (string_err == 1) {
                            cool_yylval.error_msg = "String constant too long";
                            return ERROR;
                          } else if (string_err == 2) {
                            cool_yylval.error_msg = "String contains null character.";
                            return ERROR;
                          }
                          cool_yylval.symbol = stringtable.add_string(string_buf); return STR_CONST; 
                        }
<str>.                  ;
  /* comments */
--[^\n]*                /* eat this line */
"(*"                    { BEGIN(comment); nested_comments = 0; }
<comment>[^*(\n]*       /* eat anything that's not a '*' or '(' */
<comment>"*"+[^*()\n]*  /* eat up '*'s not followed by ')'s */
<comment>"("+[^*()\n]*  /* eat up '('s not followed by '*'s */
<comment>\n             curr_lineno++;
<comment>"("+"*"        nested_comments++;
<comment>"*"+")"        { nested_comments--; if (nested_comments < 0) BEGIN(INITIAL); }
<comment><<EOF>>        { if (terminate) 
                            yyterminate();
                          else {
                            terminate = true;
                            cool_yylval.error_msg = "EOF in comment";
                            return ERROR;
                          }
                        }
.                       { cool_yylval.error_msg = yytext; return ERROR;}

%%
