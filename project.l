%option noyywrap
%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include "node.h"
#include "project.tab.h"
%}

%%
"%".*						/*ignore comments*/;
[ \t]+						/*ignore whitespace*/;
[1-9][0-9]*|0				{
								yylval.iVal = atoi(yytext);
								return num;
							}					
false|true					{
								if(yytext == "true")
									yylval.bVal = 1;
								else	
									yylval.bVal = 0;	
								return boollit;
							}
[A-Z][A-Z0-9]*				{
								yylval.sVal = (char *)malloc(yyleng+1);
								strcpy(yylval.sVal, yytext);
								return ident;
							}
"("							{
								return LP;
							}
")"							{
								return RP;
							}
":="						{
								return ASGN;
							}
";"							{
								return SC;
							}
"*"|"div"|"mod"				{
								yylval.sVal = (char *)malloc(yyleng+1);
								strcpy(yylval.sVal, yytext);
								return OP2;
							}
"+"|"-"						{
								yylval.sVal = (char *)malloc(yyleng+1);
								strcpy(yylval.sVal, yytext);
								return OP3;
							}
"="|"!="|"<"|">"|"<="|">="	{
								yylval.sVal = (char *)malloc(yyleng+1);
								strcpy(yylval.sVal, yytext);
								return OP4;
							}
"if"						{
								return IF;
							}
"then"						{
								return THEN;
							}
"else"						{
								return ELSE;
							}
"begin"						{
								return BEGIN_STMT;
							}
"end"						{
								return END;
							}
"while"						{
								return WHILE;
							}
"do"						{
								return DO;
							}
"program"					{
								return PROGRAM;
							}
"var"						{
								return VAR;
							}
"as"						{
								return AS;
							}
"int"						{
								return INT;
							}
"bool"						{
								return BOOL;
							}
"writeInt"					{
								return WRITEINT;
							}
"readInt"					{
								return READINT;
							}

%%
