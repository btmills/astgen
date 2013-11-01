include = (module) -> global[k] = v for k, v of require module

assert = require 'assert'
{ generate } = require 'escodegen'
{ parse } = require 'esprima'
compare = require './compare'
include '../builder'

test = (feature, actual, expected) ->
	unless compare actual, expected
		console.log "Error testing #{feature}: The syntax trees were not equivalent."
		console.log 'ACTUAL'
		console.log generate actual
		console.log JSON.stringify actual, null, 4
		console.log 'EXPECTED'
		console.log generate expected
		console.log JSON.stringify expected, null, 4
		#throw new Error 'The two syntax trees were not equivalent.'



# AssignmentExpression
test 'AssignmentExpression',
	program([
		expressionStatement(
			assignmentExpression(
				'=',
				identifier('foo'),
				literal(42)
			)
		)
	]),
	parse 'foo = 42;'

# BinaryExpression
test 'BinaryExpression',
	program([
		expressionStatement(
			binaryExpression(
				'+',
				literal(42),
				literal(69)
			)
		)
	]),
	parse '42 + 69;'

# CallExpression
test 'CallExpression',
	program([
		expressionStatement(
			callExpression(
				identifier('alert'),
				[
					literal('asdf')
				]
			)
		)
	]),
	parse 'alert("asdf");'

# EmptyStatement
test 'EmptyStatement',
	program([
		emptyStatement()
	]),
	parse ';'

# FunctionDeclaration
test 'FunctionDeclaration',
	program([
		functionDeclaration(
			identifier('bar'),
			[
				identifier('a'),
				identifier('b')
			],
			[],
			null,
			blockStatement([])
		)
	]),
	parse 'function bar(a, b){}'

# Literal
test 'Literal',
	program([
		expressionStatement(
			literal(42;)
		)
	]),
	parse '42;'

# Program
test 'Program',
	program([]),
	parse ''

# VariableDeclaration
test 'VariableDeclaration',
	program([
		variableDeclaration(
			'let',
			[
				variableDeclarator(
					identifier('foo'),
					literal(42)
				)
			]
		)
	]),
	parse 'let foo = 42;'
