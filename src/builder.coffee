isA = (obj, type) ->
	if typeof type == 'string'
		unless typeof obj == type
			throw new TypeError "Expecting #{type} but was #{typeof obj}"
	else
		unless obj instanceof type
			throw new TypeError "Expecting #{type?.name} but was #{obj?.constructor?.name}"
	return true

isOneOf = (obj, types) ->
	one = false
	for type in types
		try
			isA obj, type
			return true
		catch
	throw new TypeError "Expecting one of #{types} but was #{typeof obj} #{obj?.constructor?.name}"


isNullOr = (obj, type) ->
	unless obj is null
		try
			if Array.isArray type then isOneOf obj, type else isA obj, type
			return true
		catch
			throw new TypeError "Expecting null or #{type?.name} but was #{obj?.constructor?.name}"
	return true

isArrayOf = (arr, type) ->
	unless Array.isArray arr
		throw new TypeError "Expecting Array but was #{typeof arr}"
	isA el, type for el in arr
	return true

isLiterally = (obj, literals) ->
	literals = [ literals ] unless Array.isArray literals
	for literal in literals
		return true if obj == literal
	throw new TypeError "Expecting one of #{literals} but was #{typeof obj} #{obj?.constructor?.name}"




# Base classes

class Node
	constructor: (@type, loc) ->
		#console.log "Constructing a #{@type}"
		isA @type, 'string'
		#isNullOr @loc, SourceLocation
		if loc?
			@loc = loc
			isNullOr @loc, SourceLocation

class SourceLocation
	constructor: (@start, @end, @source = null) ->
		isA @start, Position
		isA @end, Position
		isNullOr @source, 'string'

class Position
	constructor: (@line, @column) ->
		isA @line, 'number'
		throw new RangeError "Expecting line >= 1 but was #{line}" unless @line >= 1
		isA @column, 'number'
		throw new RangeError "Expecting column >= 0 but was #{column}" unless @column >= 0

class Expression extends Node
	constructor: (type, loc) ->
		super type, loc

class Pattern extends Expression
	constructor: (type, loc) ->
		super type, loc

class Function extends Node
	constructor: (type, @id, @params, @defaults, @rest, @body, loc) ->
		super type, loc
		isNullOr @id, Identifier
		isArrayOf @params, Pattern
		isArrayOf @defaults, Expression
		isNullOr @rest, Identifier
		isOneOf @body, [ BlockStatement, Expression ]

class Statement extends Node
	constructor: (type, loc) ->
		super type, loc

class Declaration extends Statement
	constructor: (type, loc) ->
		super type, loc

# Enums

AssignmentOperator = [
	'=', '+=', '-=', '*=', '/=', '%=',
	'<<=', '>>=', '>>>=',
	'|=', '^=', '&='
]

BinaryOperator = [
	'==', '!=', '===', '!==',
	'<', '<=', '>', '>=',
	'<<', '>>', '>>>',
	'+', '-', '*', '/', '%',
	'|', '^', 'in',
	'instanceof', '..'
]

LogicalOperator = [
	'||', '&&'
]

UnaryOperator = [
	'-', '+', '!', '~', 'typeof', 'void', 'delete'
]

UpdateOperator = [
	'++', '--'
]

# Syntax

class ArrayExpression extends Expression
	constructor: (elts, loc = null) ->
		super 'ArrayExpression', loc
		@elements = elts
		isArrayOf @elements, Expression

class ArrayPattern extends Pattern
	constructor: (@elements, loc = null) ->
		super 'ArrayPattern', loc
		isArrayOf @elements, Pattern

class ArrowExpression extends Expression
	constructor: (@params, @defaults, @rest, @body, isGenerator = false, isExpression = false, loc = null) ->
		super 'ArrowExpression', loc
		@generator = isGenerator
		@expression = isExpression
		isArrayOf @params, Pattern
		isArrayOf @defaults, Expression
		isNullOr @rest, Identifier
		isOneOf @body, [ BlockStatement, Expression ]
		isA @generator, 'boolean'
		isA @expression, 'boolean'

class AssignmentExpression extends Expression
	constructor: (@operator, @left, @right, loc = null) ->
		super 'AssignmentExpression', loc
		isLiterally @operator, AssignmentOperator
		isA @left, Expression
		isA @right, Expression

class BinaryExpression extends Expression
	constructor: (@operator, @left, @right, loc = null) ->
		super 'BinaryExpression', loc
		isLiterally @operator, BinaryOperator
		isA @left, Expression
		isA @right, Expression

class BlockStatement extends Statement
	constructor: (@body, loc = null) ->
		super 'BlockStatement', loc
		isArrayOf @body, Statement

class BreakStatement extends Statement
	constructor: (@label, loc = null) ->
		super 'BreakStatement', loc
		isNullOr @label, Identifier

class CallExpression extends Expression
	constructor: (@callee, @arguments = [], loc = null) ->
		super 'CallExpression', loc
		isA @callee, Expression
		isArrayOf @arguments, Expression

class CatchClause extends Node
	constructor: (arg, @guard, @body, loc = null) ->
		super 'CatchClause', loc
		@param = arg
		isA @param, Pattern
		isNullOr @guard, Expression
		isA @body, Statement

class ComprehensionBlock extends Node
	constructor: (@left, @right, isForEach, loc = null) ->
		super 'ComprehensionBlock', loc
		@each = isForEach
		isA @left, Pattern
		isA @right, Expression
		isA @each, 'boolean'

class ComprehensionExpression extends Expression
	constructor: (@body, @blocks, @filter, loc = null) ->
		super 'ComprehensionExpression', loc
		isA @body, Expression
		isArrayOf @blocks, ComprehensionBlock
		isNullOr @filter, Expression

class ConditionalExpression extends Expression
	constructor: (@test, @consequent, @alternate, loc = null) ->
		super 'ConditionalExpression', loc
		isA @test, Expression
		isA @consequent, Expression
		isA @alternate, Expression

class ContinueStatement extends Statement
	constructor: (@label, loc = null) ->
		super 'ContinueStatement', loc
		isNullOr @label, Identifier

class DebuggerStatement extends Statement
	constructor: (loc = null) ->
		super 'DebuggerStatement', loc

class DoWhileStatement extends Statement
	constructor: (@body, @test, loc = null) ->
		super 'DoWhileStatement', loc
		isA @body, Statement
		isA @test, Expression

class EmptyStatement extends Statement
	constructor: (loc = null) ->
		super 'EmptyStatement', loc

class ExpressionStatement extends Statement
	constructor: (@expression, loc = null) ->
		super 'ExpressionStatement', loc
		isA @expression, Expression

class ForStatement extends Statement
	constructor: (@init, @test, @update, @body, loc = null) ->
		super 'ForStatement', loc
		isNullOr @init, [ VariableDeclaration, Expression ]
		isNullOr @test, Expression
		isNullOr @update, Expression
		isA @body, Statement

class ForInStatement extends Statement
	constructor: (@left, @right, @body, isForEach = false, loc = null) ->
		super 'ForInStatement', loc
		@each = isForEach
		isOneOf @left, [ VariableDeclaration, Expression ]
		isA @right, Expression
		isA @body, Statement
		isA @each, 'boolean'

class ForOfStatement extends Statement
	constructor: (@left, @right, @body, loc = null) ->
		super 'ForOfStatement', loc
		isOneOf @left, [ VariableDeclaration, Expression ]
		isA @right, Expression
		isA @body, Statement

class FunctionDeclaration extends Declaration #, Function
	constructor: (@id, @params = [], @defaults = [], @rest = null, @body, isGenerator = false, isExpression = false, loc = null) ->
		super 'FunctionDeclaration', loc
		@generator = isGenerator
		@expression = isExpression
		isA @id, Identifier
		isArrayOf @params, Pattern
		isArrayOf @defaults, Expression
		isNullOr @rest, Identifier
		isOneOf @body, [ BlockStatement, Expression ]
		isA @generator, 'boolean'
		isA @expression, 'boolean'

class FunctionExpression extends Expression #, Function
	constructor: (@id = null, @params = [], @defaults = [], @rest = null, @body, isGenerator = false, isExpression = false, loc = null) ->
		super 'FunctionExpression', loc
		@generator = isGenerator
		@expression = isExpression
		isNullOr @id, Identifier
		isArrayOf @params, Pattern
		isArrayOf @defaults, Expression
		isNullOr @rest, Identifier
		isOneOf @body, [ BlockStatement, Expression ]
		isA @generator, 'boolean'
		isA @expression, 'boolean'

class GeneratorExpression extends Expression
	constructor: (@body, @blocks, @filter, loc = null) ->
		super 'GeneratorExpression', loc
		isA @body, Expression
		isArrayOf @blocks, ComprehensionBlock
		isNullOr @filter, Expression

class Identifier extends Pattern #, Expression, Node
	constructor: (@name, loc = null) ->
		super 'Identifier', loc
		isA @name, 'string'

class IfStatement extends Statement
	constructor: (@test, @consequent, @alternate = null, loc = null) ->
		super 'IfStatement', loc
		isA @test, Expression
		isA @consequent, Statement
		isNullOr @alternate, Statement

class LabeledStatement extends Statement
	constructor: (@label, @body, loc = null) ->
		super 'LabeledStatement', loc
		isA @label, Identifier
		isA @body, Statement

###
# LetExpressions are currently exclusive to SpiderMonkey
class LetExpression extends Expression
	constructor: (@head, @body, loc = null) ->
		super 'LetExpression', loc
		isArrayOf @head, Declarator
		isA @body, Expression
###

###
# LetStatements are currently exclusive to SpiderMonkey
class LetStatement extends Statement
	constructor: (@head, @body, loc = null) ->
		super 'LetStatement', loc
		isArrayOf @head, Declarator
		isA @body, Statement
###

class Literal extends Expression #, Node
	constructor: (@value, loc = null) ->
		super 'Literal', loc
		isNullOr @value, [ 'string', 'boolean', 'number', RegExp ]

class LogicalExpression extends Expression
	constructor: (@operator, @left, @right, loc = null) ->
		super 'LogicalExpression', loc
		isLiterally @operator, LogicalOperator
		isA @left, Expression
		isA @right, Expression

class MemberExpression extends Expression
	constructor: (@object, @property, isComputed = false, loc = null) ->
		super 'MemberExpression', loc
		@computed = isComputed
		isA @object, Expression
		isOneOf @property, [ Identifier, Expression ]
		isA @computed, 'boolean'

class NewExpression extends Expression
	constructor: (@callee, @arguments = [], loc = null) ->
		super 'NewExpression', loc
		isA @callee, Expression
		isArrayOf @arguments, Expression

class ObjectExpression extends Expression
	constructor: (@properties = [], loc = null) ->
		super 'ObjectExpression', loc
		isArrayOf @properties, Property

class ObjectPattern extends Pattern
	constructor: (@properties = [], loc = null) ->
		super 'ObjectPattern', loc
		isArrayOf @properties, PropertyPattern

class Program extends Node
	constructor: (@body = [], loc = null) ->
		super 'Program', loc
		isArrayOf @body, Statement

class Property extends Node
	constructor: (@key, @value, @kind, loc = null) ->
		super 'Property', loc
		isOneOf @key, [ Literal, Identifier ]
		isA @value, Expression
		isLiterally @kind, [ 'init', 'get', 'set' ]

class PropertyPattern extends Node
	constructor: (@key, @value, loc = null) ->
		super 'PropertyPattern', loc
		isOneOf @key, [ Literal, Identifier ]
		isA @value, Pattern

class ReturnStatement extends Statement
	constructor: (@argument, loc = null) ->
		super 'ReturnStatement', loc
		isNullOr @argument, Expression

class SequenceExpression extends Expression
	constructor: (@expressions, loc = null) ->
		super 'SequenceExpression', loc
		isArrayOf @expressions, Expression

class SpreadExpression extends Expression
	constructor: (@argument, loc = null) ->
		super 'SpreadExpression', loc
		isA @argument, Expression

class SwitchCase extends Node
	constructor: (@test, @consequent = [], loc = null) ->
		super 'SwitchCase', loc
		isNullOr @test, Expression
		isArrayOf @consequent, Statement

class SwitchStatement extends Statement
	constructor: (@discriminant, @cases, isLexical, loc = null) ->
		super 'SwitchStatement', loc
		@lexical = isLexical
		isA @discriminant, Expression
		isArrayOf @cases, SwitchCase
		isA @lexical, 'boolean'

class ThisExpression extends Expression
	constructor: (loc = null) ->
		super 'ThisExpression', loc

class ThrowStatement extends Statement
	constructor: (@argument, loc = null) ->
		super 'ThrowStatement', loc
		isA @argument, Expression

class TryStatement extends Statement
	constructor: (@body, @handler, @finalizer, loc = null) ->
		super 'TryStatement', loc
		isA @body, Statement
		isNullOr @handler, CatchClause
		isNullOr @finalizer, Statement

class UnaryExpression extends Expression
	constructor: (@operator, @argument, isPrefix, loc = null) ->
		super 'UnaryExpression', loc
		@prefix = isPrefix
		isLiterally @operator, UnaryOperator
		isA @argument, Expression
		isA @prefix, 'boolean'

class UpdateExpression extends Expression
	constructor: (@operator, @argument, isPrefix, loc = null) ->
		super 'UpdateExpression', loc
		@prefix = isPrefix
		isLiterally @operator, UpdateOperator
		isA @argument, Expression
		isA @prefix, 'boolean'

class VariableDeclaration extends Declaration
	constructor: (@kind, @declarations, loc = null) ->
		super 'VariableDeclaration', loc
		isA @kind, 'string'
		isArrayOf @declarations, VariableDeclarator

class VariableDeclarator extends Node
	constructor: (@id, @init = null, loc = null) ->
		super 'VariableDeclarator', loc
		isA @id, Pattern
		isNullOr @init, Expression

class WhileStatement extends Statement
	constructor: (@test, @body, loc = null) ->
		super 'WhileStatement', loc
		isA @test, Expression
		isA @body, Statement

class WithStatement extends Statement
	constructor: (obj, @body, loc = null) ->
		super 'WithStatement', loc
		@object = obj
		isA @object, Expression
		isA @body, Statement

class YieldExpression extends Expression
	constructor: (@argument, loc = null) ->
		super 'YieldExpression', loc
		isNullOr @argument, Expression

Properties =
	ArrayExpression: ['elements', 'loc']
	ArrayPattern: ['elements', 'loc']
	ArrowExpression: ['params', 'defaults', 'rest', 'body', 'generator', 'expression', 'loc']
	AssignmentExpression: ['operator', 'left', 'right', 'loc']
	BinaryExpression: ['operator', 'left', 'right', 'loc']
	BlockStatement: ['body', 'loc']
	BreakStatement: ['label', 'loc']
	CallExpression: ['callee', 'arguments', 'loc']
	CatchClause: ['param', 'guard', 'body', 'loc']
	ComprehensionBlock: ['left', 'right', 'each', 'loc']
	ComprehensionExpression: ['body', 'blocks', 'filter', 'loc']
	ConditionalExpression: ['test', 'consequent', 'alternate', 'loc']
	ContinueStatement: ['label', 'loc']
	DebuggerStatement: ['loc']
	DoWhileStatement: ['body', 'test', 'loc']
	EmptyStatement: ['loc']
	ExpressionStatement: ['expression', 'loc']
	ForStatement: ['init', 'test', 'update', 'body', 'loc']
	ForInStatement: ['left', 'right', 'body', 'each', 'loc']
	ForOfStatement: ['left', 'right', 'body', 'loc']
	FunctionDeclaration: ['id', 'params', 'defaults', 'rest', 'body', 'generator', 'expression', 'loc']
	FunctionExpression: ['id', 'params', 'defaults', 'rest', 'body', 'generator', 'expression', 'loc']
	GeneratorExpression: ['body', 'blocks', 'filter', 'loc']
	Identifier: ['name', 'loc']
	IfStatement: ['test', 'consequent', 'alternate', 'loc']
	LabeledStatement: ['label', 'body', 'loc']
	LetExpression: ['head', 'body', 'loc']
	LetStatement: ['head', 'body', 'loc']
	Literal: ['value', 'loc']
	LogicalExpression: ['operator', 'left', 'right', 'loc']
	MemberExpression: ['object', 'property', 'computed', 'loc']
	NewExpression: ['callee', 'arguments', 'loc']
	ObjectExpression: ['properties', 'loc']
	ObjectPattern: ['properties', 'loc']
	Program: ['body', 'loc']
	Property: ['key', 'value', 'kind', 'loc']
	PropertyPattern: ['key', 'value', 'loc']
	ReturnStatement: ['argument', 'loc']
	SequenceExpression: ['expressions', 'loc']
	SpreadExpression: ['argument', 'loc']
	SwitchCase: ['test', 'consequent', 'loc']
	SwitchStatement: ['discriminant', 'cases', 'lexical', 'loc']
	ThisExpression: ['loc']
	ThrowStatement: ['argument', 'loc']
	TryStatement: ['block', 'handler', 'finalizer', 'loc']
	UnaryExpression: ['operator', 'argument', 'prefix', 'loc']
	UpdateExpression: ['operator', 'argument', 'prefix', 'loc']
	VariableDeclaration: ['kind', 'declarations', 'loc']
	VariableDeclarator: ['id', 'init', 'loc']
	WhileStatement: ['test', 'body', 'loc']
	WithStatement: ['object', 'body', 'loc']
	YieldExpression: ['argument', 'loc']

Types =
	arrayExpression: ArrayExpression
	arrayPattern: ArrayPattern
	arrowExpression: ArrowExpression
	assignmentExpression: AssignmentExpression
	binaryExpression: BinaryExpression
	blockStatement: BlockStatement
	breakStatement: BreakStatement
	callExpression: CallExpression
	catchClause: CatchClause
	comprehensionBlock: ComprehensionBlock
	comprehensionExpression: ComprehensionExpression
	conditionalExpression: ConditionalExpression
	continueStatement: ContinueStatement
	debuggerStatement: DebuggerStatement
	doWhileStatement: DoWhileStatement
	emptyStatement: EmptyStatement
	expressionStatement: ExpressionStatement
	forStatement: ForStatement
	forInStatement: ForInStatement
	forOfStatement: ForOfStatement
	functionDeclaration: FunctionDeclaration
	functionExpression: FunctionExpression
	generatorExpression: GeneratorExpression
	identifier: Identifier
	ifStatement: IfStatement
	labeledStatement: LabeledStatement
	#letExpression: LetExpression
	#letStatement: LetStatement
	literal: Literal
	logicalExpression: LogicalExpression
	memberExpression: MemberExpression
	newExpression: NewExpression
	objectExpression: ObjectExpression
	objectPattern: ObjectPattern
	position: Position
	program: Program
	property: Property
	propertyPattern: PropertyPattern
	returnStatement: ReturnStatement
	sequenceExpression: SequenceExpression
	spreadExpression: SpreadExpression
	sourceLocation: SourceLocation
	switchCase: SwitchCase
	switchStatement: SwitchStatement
	thisExpression: ThisExpression
	throwStatement: ThrowStatement
	tryStatement: TryStatement
	unaryExpression: UnaryExpression
	updateExpression: UpdateExpression
	variableDeclaration: VariableDeclaration
	variableDeclarator: VariableDeclarator
	whileStatement: WhileStatement
	withStatement: WithStatement
	yieldExpression: YieldExpression

builders = module.exports = {}

# To avoid having to call builders with new, wrap constructors
for key, value of Types
	builders[key] = do (ctor = value) -> # Closure within loop
		# Return a function that constructs a new instance of the type
		-> do (ctor, args = Array.prototype.slice.call arguments) ->
			return new (ctor.bind.apply ctor, [null].concat args)()

# Optionally move type builders into the global scope
globalize = module.exports.globalize = ->
	global[type] = builders[type] for type of Types

validate = module.exports.validate = (tree) ->
	args = []
	for prop in Properties[tree.type]
		if !tree[prop]?
			args.push null
		else if Array.isArray tree[prop]
			# Property nodes don't always have a type property
			if tree.type == 'ObjectExpression' && prop == 'properties'
				args.push tree[prop].map (el) ->
					validate {
						type: 'Property'
						key: tree[prop].key
						value: tree[prop].value
						kind: tree[prop].kind
						loc: tree[prop].loc
					}
			else
				args.push tree[prop].map (el) -> validate el
		else if typeof tree[prop] == 'object' && tree[prop].type?
			args.push validate tree[prop]
		else
			args.push tree[prop]
	builders[tree.type[0].toLowerCase() + tree.type[1...]].apply(null, args)

