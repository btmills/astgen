isArray = Array.isArray or (obj) ->
	toString.call obj == '[object Array]'

isObject = (obj) ->
	obj == Object obj

compare = module.exports = (a, b) ->
	if not isArray(a) and not isArray(b) and not isObject(a) and not isObject(b)
		log "basic compare #{a} === #{b}"
		return a == b

	unless (isArray(a) and isArray(b)) or (isObject(a) and isObject(b))
		log 'a and b are not same type'
		log "a is #{typeof a}"
		log "b is #{typeof b}"
		return false

	if isArray a
		unless a.length == b.length
			log 'a.length != b.length'
			return false
		for i in [0...a.length]
			unless compare a[i], b[i]
				log "#{a[i]} != #{b[i]}"
				return false
		return true

	for k, v of a when a.hasOwnProperty k
		#console.log k
		unless b.hasOwnProperty k
			log "b is missing property #{k}"
			return false
		unless compare v, b[k]
			log "#{v} != #{b[k]}"
			return false
	for k, v of b when b.hasOwnProperty k
		#console.log k
		unless a.hasOwnProperty k
			log "a is missing property #{k}"
			return false
		unless compare a[k], v
			log "#{a[k]} != #{v}"
			return false

	return true

log = (msg) ->
	console.log msg if false

# log compare 42, 42
# log compare { a: 42 }, { a: 42 }
# log compare { a: 42, b: 69 }, { a: 42 }
# log compare { a: 42, b: null }, { a: 42 }
# log compare { a: 42, b: null }, { a: 42, b: null }
# log compare { a: [1, 2] }, { a: [1, 2] }
# log compare { 'body': [{ 'type': 'EmptyStatement' }], 'type': 'Program' }, { 'type': 'Program', 'body': [{ 'type': 'EmptyStatement' }] }
