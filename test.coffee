include = (module) -> global[k] = v for k, v of require module

{ generate } = require 'escodegen'
include './builder'

ast = program([
	expressionStatement(
		callExpression(
			functionExpression(null, [ identifier('$') ], [], null,
				blockStatement([
					functionDeclaration(
						identifier('foo'),
						[ identifier('bar') ],
						[],
						null,
						blockStatement([
							expressionStatement(
								callExpression(
									memberExpression(
										identifier('console'),
										identifier('log'),
										false
									),
									[ identifier('bar') ]
								)
							),
							returnStatement(
								identifier('bar')
							)
						])
					),
					expressionStatement(
						callExpression(
							identifier('foo'),
							[ literal(42) ]
						)
					),
					variableDeclaration(
						'var', [
							variableDeclarator(
								identifier('answer'),
								binaryExpression('*',
									literal(6),
									callExpression(
										identifier('foo'),
										[ literal(7) ]
									)
								)
							)
						]
					)
				])
			),
			[ identifier('jQuery') ]
		)
	)
])

#console.log JSON.stringify ast
console.log generate ast
