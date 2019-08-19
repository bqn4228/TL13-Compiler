typedef enum {
	typeProg,
	typeDecl,
	typeStatSeq,
	typeAsgn,
	typeIf,
	typeElse,
	typeWhile,
	typeWrite,
	typeExp,
	typeSimpExp,
	typeTerm,
	typeVar,
	typeNum,
	typeBool,
	typeFac

}nodeEnum;


typedef struct {
	
	struct nodeTypeTag *declarations;
	struct nodeTypeTag *statementSeq;
}gen_code;


typedef struct {
	
	char *name;
	char *var_type;
	struct nodeTypeTag *declarations;
}decl_node;


typedef struct {

	struct nodeTypeTag *statement;
	struct nodeTypeTag *statementSequence;
}stat_seq_node;

typedef struct {
	char *ident;
	struct nodeTypeTag *expression;
	int readValue;
}assign_node;

typedef struct {
	struct nodeTypeTag *expression;
	struct nodeTypeTag *statementSequence;
	struct nodeTypeTag *elseClause;
}if_node;

typedef struct {
	struct nodeTypeTag *statementSequence;
}else_node;

typedef struct {
	
	struct nodeTypeTag *expression;
	struct nodeTypeTag *statementSequence;
}while_node;

typedef struct {
	
	struct nodeTypeTag *expression;
}writeInt_node;

typedef struct {
	
	struct nodeTypeTag *simpleExpression1;
	struct nodeTypeTag *simpleExpression2;
	char *oper;
}exp_node;

typedef struct {
	
	struct nodeTypeTag *term1;
	struct nodeTypeTag *term2;
	char *oper;
}simpExp_node;

typedef struct {
	
	struct nodeTypeTag *factor1;
	struct nodeTypeTag *factor2;
	char *oper;
}term_node;

typedef struct {
	
	char *name;
}var_node;

typedef struct {
	
	int value;
}num_node;

typedef struct {
	
	int value;
}bool_node;

typedef struct {
	
	struct nodeTypeTag *expression;
}factor_node;

typedef struct nodeTypeTag {
	nodeEnum type;
	union {
		gen_code gen;
		decl_node decl;
		stat_seq_node statSeq;
		assign_node asgnNode;
		if_node ifNode;
		else_node elseNode;
		while_node whileNode;
		writeInt_node writeNode;
		exp_node expNode;
		simpExp_node simpExp;
		term_node term;
		var_node varNode;
		num_node numNode;
		bool_node boolNode;
		factor_node fac;
	};
}nodeType;