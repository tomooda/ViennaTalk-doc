Class {
	#name : #VDMValue2HtmlDiagram,
	#superclass : #Object,
	#instVars : [
		'parser'
	],
	#classInstVars : [
		'current'
	],
	#category : 'ViennaTalk-Html-Core'
}

{ #category : #'sole instance' }
VDMValue2HtmlDiagram class >> current [
	^ current
		ifNil: [current := self new]
]

{ #category : #'initialize-release' }
VDMValue2HtmlDiagram >> initialize [
	super initialize.
	parser := self vdmToHtmlParser
]

{ #category : #converting }
VDMValue2HtmlDiagram >> vdmToHtml: aString [
	^ '<div style="float: left; padding-left: 20px; font: 10pt normal sans-serif">'
		, (parser parse: aString onError: [ aString asHTMLString ]) , '</div><div style="clear: left"></div>'
]

{ #category : #private }
VDMValue2HtmlDiagram >> vdmToHtmlParser [
	| titleBlock expression setEnumeration sequenceEnumeration mapEnumeration apply identifier rawname name symbolicLiteral number string char |
	titleBlock := [ :stream :p | 
	| start html end expr |
	start := stream position.
	html := p value.
	html isPetit2Failure
		ifTrue: [ html ]
		ifFalse: [ end := stream position.
			stream position: start.
			expr := (stream next: end - start) trimmed.
			stream position: end.
			'<div title="' , (expr asHTMLString copyReplaceAll: '"' with: '&quot;')
				,
					'" draggable="true" ondragstart="event.dataTransfer.setData(''text'', event.target.title)">'
				, html , '</div>' ] ].
	expression := PP2UnresolvedNode new.
	setEnumeration := PP2UnresolvedNode new.
	sequenceEnumeration := PP2UnresolvedNode new.
	mapEnumeration := PP2UnresolvedNode new.
	apply := PP2UnresolvedNode new.
	identifier := (#letter asPParser / '_' asPParser
		, (#letter asPParser / #digit asPParser / '_' asPParser) starA) flatten.
	rawname := (identifier , ('`' asPParser trim , identifier) optional) flatten.
	name := rawname ==> [ :n | n asHTMLString ] >=> titleBlock.
	symbolicLiteral := ('<' asPParser , ('>' asPParser not , #any asPParser) plusA
		, '>' asPParser) trim
		==> [ :triple | 
			| symbol |
			symbol := String withAll: (triple second collect: [ :pair | pair second ]).
			'<div style="border-style: outset; border-width: 1px; border-color: silver; background-color: lightgrey; padding: 0px 5px; font: 10pt normal courier">'
				, symbol asHTMLString , '</div>' ] >=> titleBlock.
	number := ('-' asPParser optional , #digit asPParser plusA
		, ('.' asPParser optional , #digit asPParser plusA) optional
		,
			('e' asPParser / 'E' asPParser , '-' asPParser optional , #digit asPParser plusA) optional)
		trim flatten ==> [ :n | n asHTMLString ] >=> titleBlock.
	string := ('"' asPParser
		,
			((('\u' asPParser , #any asPParser , #any asPParser , #any asPParser , #any asPParser)
				==> [ :array | 
					Character
						codePoint:
							(Integer readFrom: (String withAll: (array copyFrom: 2 to: array size)) base: 16) ])
				/ ('\"' asPParser ==> [ :single | $" ])
				/ (('"' asPParser not , #any asPParser) ==> [ :pair | pair second ])) starA
		, '"' asPParser) trim
		==> [ :triple | ('"' , (String withAll: triple second) , '"') asHTMLString ]
		>=> titleBlock.
	char := ('''' asPParser
		,
			((('\u' asPParser , #any asPParser , #any asPParser , #any asPParser , #any asPParser)
				==> [ :array | 
					Character
						codePoint:
							(Integer readFrom: (String withAll: (array copyFrom: 2 to: array size)) base: 16) ])
				/ ('\''' asPParser ==> [ :single | $' ])
				/ (('''' asPParser not , #any asPParser) ==> [ :pair | pair second ])) plusA
		, '''' asPParser) trim
		==> [ :triple | ('''' , (String withAll: triple second) , '''') asHTMLString ]
		>=> titleBlock.
	expression
		def:
			setEnumeration / sequenceEnumeration / mapEnumeration / apply / name / symbolicLiteral
				/ number / string / char.
	setEnumeration
		def:
			('{' asPParser trim
				,
					(((expression , ((',' asPParser trim , expression) ==> [ :pair | pair second ]) starA)
						==> [ :pair | (Array with: pair first) , pair second ]) optional
						==> [ :opt | opt ifNil: [ Array new ] ]) , '}' asPParser trim)
				==> [ :triple | 
					| values n stream |
					values := triple second.
					n := values size sqrt ceiling.
					stream := String new writeStream.
					stream nextPutAll: '<table style="border: 4px solid silver; border-radius: 20px">'.
					0 to: n - 1 do: [ :row | 
						stream nextPutAll: '<tr>'.
						0 to: n - 1 do: [ :column | 
							stream nextPutAll: '<td'.
							row = 0
								ifTrue: [ ' style="border-top: 1px solid gray"' ].
							stream nextPutAll: '>'.
							row * n + column + 1 <= values size
								ifTrue: [ stream nextPutAll: (values at: row * n + column + 1) ].
							stream nextPutAll: '</td>' ].
						stream nextPutAll: '</tr>' ].
					values
						ifEmpty: [ stream nextPutAll: '<tr><td style="padding: 10px 10px"></td></tr>' ].
					stream nextPutAll: '</table>'.
					stream contents ] >=> titleBlock.
	sequenceEnumeration
		def:
			('[' asPParser trim
				,
					(((expression , ((',' asPParser trim , expression) ==> [ :pair | pair second ]) starA)
						==> [ :pair | (Array with: pair first) , pair second ]) optional
						==> [ :opt | opt ifNil: [ Array new ] ]) , ']' asPParser trim)
				==> [ :triple | 
					| values stream |
					values := triple second.
					stream := String new writeStream.
					stream
						nextPutAll: '<div><div style="float: left; border-bottom: 4px solid lightgrey">'.
					values
						do: [ :value | 
							stream nextPutAll: '<div style="float: left; border-style: none; padding: 0px 5px">'.
							stream nextPutAll: value.
							stream nextPutAll: '</div>' ].
					values
						ifEmpty: [ stream
								nextPutAll: '<div style="float: left; border-style: none; padding: 10px 10px">&nbsp</div>' ].
					stream
						nextPutAll: '<div style="clear: left"></div></div><div style="clear: left"></div></div>'.
					stream contents ] >=> titleBlock.
	mapEnumeration
		def:
			('{' asPParser trim
				,
					(('|->' asPParser trim ==> [ :empty | Array new ])
						/
							(((expression , '|->' asPParser trim , expression)
								==> [ :triple | Array with: 'maplet' with: triple first with: triple third ]
								,
									((',' asPParser trim , expression , '|->' asPParser trim , expression)
										==> [ :quatro | Array with: 'maplet' with: quatro second with: quatro fourth ])
										starA) ==> [ :pair | (Array with: pair first) , pair second ]))
				, '}' asPParser trim)
				==> [ :triple | 
					| values stream |
					values := triple second.
					stream := String new writeStream.
					stream
						nextPutAll:
							'<table style="border-style: hidden; border-collapse: collapse;"><tr style="vertical-align: bottom; border-bottom: solid 1px black">'.
					values
						do: [ :value | 
							stream nextPutAll: '<td>'.
							stream nextPutAll: value second.
							stream nextPutAll: '</td>' ].
					values ifEmpty: [ stream nextPutAll: '<td>&nbsp</td>' ].
					stream nextPutAll: '</tr><tr style="vertical-align: top">'.
					values
						do: [ :value | 
							stream nextPutAll: '<td>'.
							stream nextPutAll: value third.
							stream nextPutAll: '</td>' ].
					values ifEmpty: [ stream nextPutAll: '<td>&nbsp</td>' ].
					stream nextPutAll: '</table>'.
					stream contents ] >=> titleBlock.
	apply
		def:
			(rawname , '(' asPParser trim
				,
					(((expression , ((',' asPParser trim , expression) ==> [ :pair | pair second ]) starA)
						==> [ :pair | (Array with: pair first) , pair second ]) optional
						==> [ :opt | opt ifNil: [ Array new ] ]) , ')' asPParser trim)
				==> [ :quatro | 
					| kind args stream |
					kind := quatro first copyFrom: 4 to: quatro first size.
					args := quatro third.
					stream := String new writeStream.
					kind
						ifNotEmpty: [ stream nextPutAll: '<div style="border-style:none; padding: 2px 10px">'.
							stream
								nextPutAll: '<div style="font-style: bold">';
								nextPutAll: kind;
								nextPutAll: '</div>' ].
					kind = 'token'
						ifTrue: [ stream
								nextPutAll:
									'<div style="border-style: outset; border-width: 1px; border-color: silver; background-color: lightgrey; padding: 0px 5px; font: 10pt normal courier">' ]
						ifFalse: [ stream
								nextPutAll:
									'<div style="border: solid 2px grey; box-shadow: 5px 5px 3px lightgrey; padding: 2px 10px">' ].
					args
						do: [ :arg | 
							stream
								nextPutAll: '<div>';
								nextPutAll: arg;
								nextPutAll: '</div>' ].
					stream nextPutAll: '</div>'.
					kind ifNotEmpty: [ stream nextPutAll: '</div>' ].
					stream contents ] >=> titleBlock.
	^ expression
]
