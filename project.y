%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include "node.h"
#include "uthash.h"

/*function prototypes*/
nodeType* prog(nodeType *decl, nodeType *statSeq);
nodeType* decl(char* name, char* type, nodeType *decl);
nodeType* statSeq(nodeType *statement, nodeType *statSeq);
nodeType* asgnNode(char *name, nodeType *expNode, int readint);
nodeType* ifNode(nodeType *expNode, nodeType *statSeq, nodeType *elseNode);
nodeType* elseNode(nodeType *statSeq);
nodeType* whileNode(nodeType *expNode, nodeType *statSeq);
nodeType* writeNode(nodeType *expNode);
nodeType* expNode(nodeType *simpExp1, char *oper, nodeType *simpExp2);
nodeType* simpExp(nodeType *term1, char *oper, nodeType *term2);
nodeType* term(nodeType *factor1, char *oper, nodeType *factor2);
nodeType* varNode(char *name);
nodeType* numNode(int value);
nodeType* boolNode(int value);
nodeType* fac(nodeType *expNode);
char* print_operator(int op);


/*variable representative in hash table*/
struct symtab {
	char *name;  /*symbol name*/
	char *type;  /*symbol type*/
	UT_hash_handle hh;
};

struct symtab *identifiers = NULL;

/*SYMBOL TABLE FUNCTIONS*/

void add_ident(char *name, char *type){
	struct symtab *i;
	HASH_FIND_STR(identifiers, name, i); /*lookup symbol to see if already exists*/
	
	/*add if not found already*/
	if (i==NULL){
		i = (struct symtab *)malloc(sizeof(*i));
		i -> name = name;
		

		HASH_ADD_KEYPTR(hh, identifiers, i->name, strlen(i->name),i);

		i -> type = type;
	}
	else{ /*ERROR CHECK #1*/
		yyerror("Duplicate found in hash table");		
	}
}

char *find_ident(char *name){
	struct symtab *i;
	HASH_FIND_STR(identifiers, name, i); /*lookup symbol to see if exists*/
	
	/*ERROR CHECK #2*/
	if(i==NULL){ 
		yyerror("Undefined variable");
		return name;
	}
	return i->name;

}

char *find_ident_type(char *name){
	struct symtab *i;
	HASH_FIND_STR(identifiers, name, i); /*lookup symbol to see if exists*/
	
	/*ERROR CHECK #2*/
	if(i==NULL){ 
		yyerror("Undefined variable");
		return name;
	}
	return i->type;

}


void delete_ident(struct symtab *ident){
	HASH_DEL(identifiers, ident);
	free(ident);
}

void delete_all(){
	struct symtab *current_id, *tmp;
	HASH_ITER(hh, identifiers, current_id, tmp){
		HASH_DEL(identifiers, current_id);
		free(current_id);
	}
}

void print_table(){
	struct symtab *i;
	printf("\n\n------SYMBOL TABLE------\n");
	for(i=identifiers; i !=NULL; i=i->hh.next){
		printf("Variable: %s, Type: %s\n", i->name, i->type);
	}
}



%}

%union
{
	int iVal; 
	int bVal;
	char *sVal;
	nodeType* nPtr;

};

%token <iVal> num
%token <bVal> boollit
%token <sVal> ident 
%token LP RP ASGN SC 
%token <sVal> OP2 OP3 OP4
%token IF THEN ELSE BEGIN_STMT END WHILE DO PROGRAM VAR AS 
%token <sVal> INT BOOL
%token WRITEINT READINT
%type <nPtr> program declarations statementSequence statement assignment ifStatement elseClause whileStatement writeInt expression simpleExpression term factor
%type <sVal> type
%start program

%%
program:
		PROGRAM declarations BEGIN_STMT statementSequence END {
																$$ = prog($2,$4);																
																print_code($$);
																print_table(); /*print symbol table*/
															  }
		;
declarations:
		VAR ident AS type SC declarations {	
											
											add_ident($2,$4);
					
											$$ = decl($2,$4,$6);
										  }
		| {$$ = NULL;}
		;
type:
		INT {$$ = "int";}
		| BOOL {$$ = "bool";}
		;
statementSequence:
		statement SC statementSequence {$$ = statSeq($1, $3);}
		| /*empty*/ {$$ = NULL;}
		;
statement:
		assignment			{$$ = $1;}
		| ifStatement		{$$ = $1;}
		| whileStatement	{$$ = $1;}
		| writeInt			{$$ = $1;}
		;
assignment:
		ident ASGN expression		{$$ = asgnNode(find_ident($1), $3, 0);}
		| ident ASGN READINT		{$$ = asgnNode(find_ident($1), NULL, READINT);}
		;
ifStatement:
		IF expression THEN statementSequence elseClause END  {$$ = ifNode($2, $4, $5);}
		;
elseClause:
		ELSE statementSequence {$$ = elseNode($2);}
		| {$$ = NULL;}
		;
whileStatement:
		WHILE expression DO statementSequence END {$$ = whileNode($2, $4);}
		;
writeInt:
		WRITEINT expression {$$ = writeNode($2);}
		;
expression:
		simpleExpression	{$$ = $1;}
		| simpleExpression OP4 simpleExpression {$$ = expNode($1, $2, $3);}
		;
simpleExpression:
		term OP3 term {$$ = simpExp($1, $2, $3);}
		| term	{$$ = $1;}
		;
term:
		factor OP2 factor	{$$ = term($1,$2,$3);}
		| factor			{$$ = $1;}
		;
factor:
		ident  {$$ = varNode(find_ident($1));}
		| num  {	
					/*ERROR CHECK #3*/
					if($1 <= -2147483647 && $1 >= 2147483647){
						yyerror("Integer overflow");
					}
					$$ = numNode($1);
			   }
		| boollit {$$ = boolNode($1);}
		| LP expression RP {$$ = fac($2);}
		;
%%

nodeType* prog(nodeType *decl, nodeType *statSeq){
	nodeType* pntr;
	if((pntr = malloc(sizeof(nodeType))) == NULL)
		yyerror("memory unavailable");

	pntr->type = typeProg;
	pntr->gen.declarations = decl;
	pntr->gen.statementSeq = statSeq;
	return pntr;

};
nodeType* decl(char* name, char* var_type, nodeType *decl){
	nodeType* pntr;
	if((pntr = malloc(sizeof(nodeType))) == NULL)
		yyerror("memory unavailable");
	pntr->type = typeDecl;
	pntr->decl.name = name;
	pntr->decl.var_type = var_type;
	pntr->decl.declarations = decl;
	return pntr;
};
nodeType* statSeq(nodeType *statement, nodeType *statSeq){
	nodeType* pntr;
	if((pntr = malloc(sizeof(nodeType))) == NULL)
		yyerror("memory unavailable");
	pntr->type = typeStatSeq;
	pntr->statSeq.statement = statement;
	pntr->statSeq.statementSequence = statSeq;
	return pntr;
};
nodeType* asgnNode(char *name, nodeType *expNode, int readint){
	nodeType* pntr;
	if((pntr = malloc(sizeof(nodeType))) == NULL)
		yyerror("memory unavailable");
	
	pntr->type = typeAsgn;
	pntr->asgnNode.ident = name;
	pntr->asgnNode.expression = expNode;
	pntr->asgnNode.readValue = readint;
	return pntr;
};
nodeType* ifNode(nodeType *expNode, nodeType *statSeq, nodeType *elseNode){
	nodeType* pntr;
	if((pntr = malloc(sizeof(nodeType))) == NULL)
		yyerror("memory unavailable");
	pntr->type=typeIf;
	pntr->ifNode.expression=expNode;
	pntr->ifNode.statementSequence=statSeq;
	pntr->ifNode.elseClause=elseNode;
	return pntr;
};
nodeType* elseNode(nodeType *statSeq){
	nodeType* pntr;
	if((pntr = malloc(sizeof(nodeType))) == NULL)
		yyerror("memory unavailable");
	pntr->type = typeElse;
	pntr->elseNode.statementSequence = statSeq;
	return pntr;
};
nodeType* whileNode(nodeType *expNode, nodeType *statSeq){
	nodeType* pntr;
	if((pntr = malloc(sizeof(nodeType))) == NULL)
		yyerror("memory unavailable");
	pntr->type=typeWhile;
	pntr->whileNode.expression = expNode;
	pntr->whileNode.statementSequence = statSeq;
	return pntr;
};
nodeType* writeNode(nodeType *expNode){
	nodeType* pntr;
	if((pntr = malloc(sizeof(nodeType))) == NULL)
		yyerror("memory unavailable");
	pntr->type=typeWrite;
	pntr->writeNode.expression = expNode;
	return pntr;
};
nodeType* expNode(nodeType *simpExp1, char* oper, nodeType *simpExp2){
	nodeType* pntr;
	if((pntr = malloc(sizeof(nodeType))) == NULL)
		yyerror("memory unavailable");
	pntr->type=typeExp;
	pntr->expNode.oper=oper;
	pntr->expNode.simpleExpression1=simpExp1;
	pntr->expNode.simpleExpression2=simpExp2;
	
	return pntr;
};

nodeType* simpExp(nodeType *term1, char *oper, nodeType *term2){
	nodeType* pntr;
	if((pntr = malloc(sizeof(nodeType))) == NULL)
		yyerror("memory unavailable");
	pntr->type = typeSimpExp;
	pntr->simpExp.term1=term1;
	pntr->simpExp.term2=term2;
	pntr->simpExp.oper=oper;
	return pntr;
};
nodeType* term(nodeType *factor1, char* oper, nodeType *factor2){
	nodeType* pntr;
	if((pntr = malloc(sizeof(nodeType))) == NULL)
		yyerror("memory unavailable");
	pntr->type = typeTerm;
	pntr->term.factor1=factor1;
	pntr->term.factor2=factor2;
	pntr->term.oper = oper;

	return pntr;
};
nodeType* varNode(char *name){
	nodeType* pntr;
	if((pntr = malloc(sizeof(nodeType))) == NULL)
		yyerror("memory unavailable");
	pntr->type=typeVar;
	pntr->varNode.name=name;
	return pntr;
};
nodeType* numNode(int value){
	nodeType* pntr;
	if((pntr = malloc(sizeof(nodeType))) == NULL)
		yyerror("memory unavailable");
	pntr->type = typeNum;
	pntr->numNode.value=value;
	return pntr;
};
nodeType* boolNode(int value){
	nodeType* pntr;
	if((pntr = malloc(sizeof(nodeType))) == NULL)
		yyerror("memory unavailable");
	pntr->type = typeBool;
	pntr->boolNode.value=value;
	return pntr;
};
nodeType* fac(nodeType *expNode){
	nodeType* pntr;
	if((pntr = malloc(sizeof(nodeType))) == NULL)
		yyerror("memory unavailable");
	pntr->type=typeFac;
	pntr->fac.expression=expNode;
	return pntr;

};

int print_code(nodeType *pntr){
	if(!pntr) return 1;
	switch(pntr->type){
		case typeProg:
							{
								printf("#include<stdio.h>\n");
								printf("#include<stlib.h>\n");
								printf("int main()\n{\n");								
								print_code(pntr->gen.declarations);
								print_code(pntr->gen.statementSeq);
								printf("}\n");
							}
							break;
		case typeDecl:
							{
								printf("%s %s;\n", pntr->decl.var_type, pntr->decl.name);
								print_code(pntr->decl.declarations);
							}
							break;

		case typeStatSeq:	{
								
								print_code(pntr->statSeq.statement);
								print_code(pntr->statSeq.statementSequence);

							}break;
		case typeAsgn:		{	
								
								
								if(pntr->asgnNode.readValue == 0){				/*assigned expression*/											
									printf("%s = ", pntr->asgnNode.ident);
									print_code(pntr->asgnNode.expression);
									printf(";\n");
								}
								else{											/*assigned READINT*/
									printf("scanf(\"%s\", &%s);\n","%d",pntr->asgnNode.ident);
									}
								
								/*ERROR CHECK #4*/
								nodeType *temp = pntr->asgnNode.expression;
								char* typeIdent1 = find_ident_type(pntr->asgnNode.ident);
								if((typeIdent1 == "int" && temp->type == typeBool) || (typeIdent1 == "bool" && temp->type == typeNum)){
									yyerror("Type mismatch");								
								}
								if(temp->type == typeVar){
									char* typeIdent2 = find_ident_type(temp->varNode.name);
									if(typeIdent1 != typeIdent2)
										yyerror("Type mismatch");

								}

							}break;
		case typeIf:		{	
								printf("if(");
								print_code(pntr->ifNode.expression);
								printf("){\n");
								print_code(pntr->ifNode.statementSequence);
								print_code(pntr->ifNode.elseClause);
								printf("}\n");
							}break;
		case typeElse:		{	
								printf("else{\n");
								print_code(pntr->elseNode.statementSequence);
								printf("}\n");
							}break;
		case typeWhile:		{	
								printf("while(");
								print_code(pntr->whileNode.expression);
								printf("){\n");
								print_code(pntr->whileNode.statementSequence);
								printf("}\n");
							}break;
		case typeWrite:		{	
								printf("printf(\"%s\",","%d"); 
								print_code(pntr->writeNode.expression);
								printf(");\n");
							}break;
		case typeExp:		{									
								
								
								print_code(pntr->expNode.simpleExpression1);
								printf("%s",pntr->expNode.oper);
								print_code(pntr->expNode.simpleExpression2);
							}break;

		case typeSimpExp:	{							
								print_code(pntr->simpExp.term1);
								printf("%s",pntr->simpExp.oper);
								print_code(pntr->simpExp.term2);
							}break;
		case typeTerm:		{								
								
								print_code(pntr->term.factor1);
								printf(" %s ",pntr->term.oper);																					
								print_code(pntr->term.factor2);
								/*ERROR CHECK #5: divide by 0 */
								nodeType *temp = pntr->term.factor2;
								if(temp->type == typeNum){
									if(temp->numNode.value == 0)
										yyerror("Divide by 0 not permitted");										
								}								
							}break;
		case typeVar:		{
								printf("%s", pntr->varNode.name);
								
							}break;
		case typeNum:		{
								printf("%d", pntr->numNode.value);	
								
							}
							 break;
		case typeBool:		{
								if(pntr->boolNode.value == 0)
									printf("false");
								else
									printf("true");
							}break;
		case typeFac:		{															
								printf("(");
								print_code(pntr->fac.expression);
								printf(")");
							}break;
		default:
			break;

	}
	

}

char* print_operator(int op){

	switch(op){
		case 0:
			return "*";
		case 1:
			return "/";
		case 2:
			return "%";
		case 3:
			return "+";
		case 4:
			return "-";
		case 5:
			return "==";
		case 6:
			return "!=";
		case 7:
			return "<";
		case 8:
			return ">";
		case 9:
			return "<=";
		case 10:
			return ">=";
		default:
			return "";
	}
}

int yyerror(char *s){
	printf("\nyyerror : %s\n", s);
	printf("Invalid input\n");
}

int main(void){
	yyparse();
}