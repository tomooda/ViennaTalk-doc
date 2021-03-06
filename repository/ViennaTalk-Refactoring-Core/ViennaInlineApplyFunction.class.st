Class {
	#name : #ViennaInlineApplyFunction,
	#superclass : #ViennaInline,
	#instVars : [
		'callerNode',
		'definitionNode'
	],
	#category : #'ViennaTalk-Refactoring-Core'
}

{ #category : #accessing }
ViennaInlineApplyFunction >> callerNode [
	^ callerNode ifNil: [ callerNode := self findCallerNode ]
]

{ #category : #accessing }
ViennaInlineApplyFunction >> callerNode: aViennaNode [
	callerNode := aViennaNode
]

{ #category : #operations }
ViennaInlineApplyFunction >> check [
	ast ifNil: [ ^ false ].
	self callerNode ifNil: [ ^ false ].
	self definitionNode ifNil: [ ^ false ].
	^ true
]

{ #category : #accessing }
ViennaInlineApplyFunction >> definitionNode [
	^ definitionNode ifNil: [ definitionNode := self findDefinitionNode ]
]

{ #category : #accessing }
ViennaInlineApplyFunction >> definitionNode: aViennaNode [
	definitionNode := aViennaNode
]

{ #category : #operations }
ViennaInlineApplyFunction >> execute [
	self definitionNode ifNil: [ ^ nil ].
	self
		replaceNode: self callerNode
		with:
			(ViennaNode
				label: 'LetExpression'
				with:
					(ViennaNode
						label: 'LocalDefinitionList'
						withAll:
							((1 to: self callerNode second size)
								collect: [ :index | 
									| param type arg |
									param := (self definitionNode fifth first at: index)
										copyFragment.
									type := self callerNode second size = 1
										ifTrue: [ self definitionNode third first ]
										ifFalse: [ self definitionNode third first label = 'ProductType'
												ifTrue: [ self definitionNode third first at: index ]
												ifFalse: [ nil ] ].
									arg := (self callerNode second at: index) copyFragment.
									ViennaNode
										label: 'LocalDefinition'
										with:
											(ViennaNode
												label: 'ValueDefinition'
												with: param
												with: type
												with: arg) ]))
				with: self definitionNode sixth)
]

{ #category : #accessing }
ViennaInlineApplyFunction >> findCallerNode [
	| node |
	node := ast.
	node ifNil: [ ^ nil ].
	node label = 'LocalName'
		ifTrue: [ node := node parent ].
	node label = 'GlobalName'
		ifTrue: [ node := node parent ].
	node label = 'FunctionTypeInstantiation'
		ifTrue: [ node := node parent ].
	node label = 'Apply'
		ifTrue: [ ^ node ].
	^ nil
]

{ #category : #accessing }
ViennaInlineApplyFunction >> findDefinitionNode [
	self callerNode ifNil: [ ^ nil ].
	self callerNode first
		ifNotNil: [ :nameNode | 
			nameNode label = 'LocalName'
				ifTrue: [ ^ (nameNode resolveLocalName: nameNode first)
						ifNotNil: [ :defNode | 
							defNode label = 'ExplicitFunctionDefinition'
								ifTrue: [ defNode ]
								ifFalse: [ nil ] ] ].
			nameNode label = 'GlobalName'
				ifTrue: [ ^ (nameNode moduleNamed: nameNode first)
						ifNotNil: [ :moduleNode | 
							(moduleNode resolveLocalName: nameNode second)
								ifNotNil: [ :defNode | 
									defNode label = 'ExplicitFunctionDefinition'
										ifTrue: [ defNode ]
										ifFalse: [ nil ] ] ] ] ].
	^ nil
]

{ #category : #accessing }
ViennaInlineApplyFunction >> sortingOrder [
	^ 2.14
]
