#include "node.h"

#include "memory.h"

#include <stdio.h>
#include <stdlib.h>

void freeNode(Node* node) {
	//don't free a NULL node
	if (node == NULL) {
		return;
	}

	switch(node->type) {
		case NODE_ERROR:
			//NO-OP
		break;

		case NODE_LITERAL:
			freeLiteral(node->atomic.literal);
		break;

		case NODE_UNARY:
			freeNode(node->unary.child);
		break;

		case NODE_BINARY:
			freeNode(node->binary.left);
			freeNode(node->binary.right);
		break;

		case NODE_GROUPING:
			freeNode(node->grouping.child);
		break;

		case NODE_BLOCK:
			for (int i = 0; i < node->block.count; i++) {
				freeNode(node->block.nodes + i);
			}
			//each sub-node gets freed individually
		break;

		case NODE_VAR_TYPES:
			for (int i = 0; i < node->varTypes.count; i++) {
				freeNode(node->varTypes.nodes + 1);
			}
			//each sub-node gets freed individually
		break;

		case NODE_VAR_DECL:
			freeLiteral(node->varDecl.identifier);
			freeNode(node->varDecl.varType);
			freeNode(node->varDecl.expression);
		break;
	}

	FREE(Node, node);
}

void emitNodeLiteral(Node** nodeHandle, Literal literal) {
	//allocate a new node
	*nodeHandle = ALLOCATE(Node, 1);

	(*nodeHandle)->type = NODE_LITERAL;
	(*nodeHandle)->atomic.literal = literal;
}

void emitNodeUnary(Node** nodeHandle, Opcode opcode) {
	//allocate a new node
	*nodeHandle = ALLOCATE(Node, 1);

	(*nodeHandle)->type = NODE_UNARY;
	(*nodeHandle)->unary.opcode = opcode;
	(*nodeHandle)->unary.child = NULL;
}

void emitNodeBinary(Node** nodeHandle, Node* rhs, Opcode opcode) {
	Node* tmp = ALLOCATE(Node, 1);

	tmp->type = NODE_BINARY;
	tmp->binary.opcode = opcode;
	tmp->binary.left = *nodeHandle;
	tmp->binary.right = rhs;

	*nodeHandle = tmp;
}

void emitNodeGrouping(Node** nodeHandle) {
	Node* tmp = ALLOCATE(Node, 1);

	tmp->type = NODE_GROUPING;
	tmp->grouping.child = NULL;

	*nodeHandle = tmp;
}

void emitNodeBlock(Node** nodeHandle) {
	Node* tmp = ALLOCATE(Node, 1);

	tmp->type = NODE_BLOCK;
	tmp->block.nodes = NULL;
	tmp->block.capacity = 0;
	tmp->block.count = 0;

	*nodeHandle = tmp;
}

void emitNodeVarTypes(Node** nodeHandle, unsigned char mask) {
	Node* tmp = ALLOCATE(Node, 1);

	tmp->type = NODE_VAR_TYPES;
	tmp->varTypes.mask = mask;
	tmp->varTypes.nodes = NULL;
	tmp->varTypes.capacity = 0;
	tmp->varTypes.count = 0;

	*nodeHandle = tmp;
}

void emitNodeVarDecl(Node** nodeHandle, Literal identifier, Node* varType, Node* expression) {
	Node* tmp = ALLOCATE(Node, 1);

	tmp->type = NODE_VAR_DECL;
	tmp->varDecl.identifier = identifier;
	tmp->varDecl.varType = varType;
	tmp->varDecl.expression = expression;

	*nodeHandle = tmp;
}

void printNode(Node* node) {
	if (node == NULL) {
		return;
	}

	switch(node->type) {
		case NODE_ERROR:
			printf("error");
		break;

		case NODE_LITERAL:
			printf("literal:");
			printLiteral(node->atomic.literal);
		break;

		case NODE_UNARY:
			printf("unary:");
			printNode(node->unary.child);
		break;

		case NODE_BINARY:
			printf("binary-left:");
			printNode(node->binary.left);
			printf(";binary-right:");
			printNode(node->binary.right);
			printf(";");
		break;

		case NODE_GROUPING:
			printf("(");
			printNode(node->grouping.child);
			printf(")");
		break;

		case NODE_BLOCK:
			printf("{\n");

			for (int i = 0; i < node->block.count; i++) {
				printNode(&(node->block.nodes[i]));
			}

			printf("}\n");
		break;

		case NODE_VAR_TYPES:
			printf("[\n");

			for (int i = 0; i < node->varTypes.count; i++) {
				printNode(&(node->varTypes.nodes[i]));
			}

			printf("]\n");
		break;

		case NODE_VAR_DECL:
			printf("vardecl(");
			printLiteral(node->varDecl.identifier);
			printf("; ");
			printNode(node->varDecl.varType);
			printf("; ");
			printNode(node->varDecl.expression);
			printf(")");
		break;
	}
}