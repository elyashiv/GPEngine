class CharSet
{
	Int index

	Range[] ranges := [,]

	@Operator
	public This add(Range r) { ranges.add(r); return this }

	public Bool contains(Int? c)
	{
		if (c == null)
			return false
		return ranges.any { it.contains(c) }
	}
}

** Represents the types of symbols.
** http://goldparser.org/doc/egt/record-symbol.htm
enum class SymbolType
{
	Nonterminal,
	Terminal,
	Noise,
	EOF,
	GroupStart,
	GroupEnd,
	DEP, //not used in egt
	Error
}

class Symbol
{
	Int index
	Str name
	SymbolType type

	new make(Int ind, Str name, SymbolType type) { this.index = ind; this.name = name; this.type = type }
}

//http://goldparser.org/doc/egt/index.htm
class Rule
{
	Symbol derived 
	Symbol[] from 

	new make(Symbol d, Symbol[] f) { derived = d; from = f }
}

class DFAState
{
	Bool isAccept
	Int to
	[Int:Int] edge := [:]
}

** http://goldparser.org/doc/egt/record-lalr-state.htm
enum class ActionType
{
	Shift,
	Reduce,
	Goto,
	accept
}

class Action
{
	ActionType at := ActionType.Shift
	Int target
}

class LALRState
{
	Int index
	[Int:Action] actions := [:]
}

class Grammer
{

	** The properties of the grammer, stored by key:value pairs.
	** http://goldparser.org/doc/egt/record-property.htm
	[Str:Str] properties := [:]

	//http://goldparser.org/doc/egt/record-table-counts.htm
	** The number of Symbols in the language
	Int SymbolCount
	** The number of character sets used by the DFA
	Int CharacterSetCount
	** The nummber of rules in the grammer
	Int RulesCount
	** The number of states in the DFA
	Int DFAStatesCount
	** The number of LALR states
	Int LALRStatesCount
	** The number of lexical groups
	Int LGroupCount


	//http://goldparser.org/doc/egt/record-initial-states.htm
	** The DFA initial state
	Int DFAInitial
	** The LALR initial state
	Int LALRInitial

	** Characters sets.
	** http://goldparser.org/doc/egt/record-char-set.htm
	CharSet[] CharSets := [,]

	** Symbol table.
	** http://goldparser.org/doc/egt/record-symbol.htm
	[Int:Symbol] SymbolTable := [:]

	** The rules in this grammer
	** http://goldparser.org/doc/egt/index.htm
	[Int:Rule] Rules := [:]

	[Int:DFAState] DFAStates := [:]

	[Int:LALRState] LALRStates := [:]
}

class GrammerReader
{
	private Reader re
	new make(Uri gf) { re = Reader(gf) }
	new makeFromStream(InStream ins) { re = Reader(ins) }

	public Grammer getGrammer()
	{
		g := Grammer()
		re.eachRec
		{
			switch (it.entries[0].data)
			{
			case 'p': //property
				g.properties[it.entries[2].data] = it.entries[3].data

			case 't': //tables count
				g.SymbolCount = it.entries[1].data
				g.CharacterSetCount = it.entries[2].data
				g.RulesCount = it.entries[3].data
				g.DFAStatesCount = it.entries[4].data
				g.LALRStatesCount = it.entries[5].data
				g.LGroupCount = it.entries[6].data

			case 'I': //initial states
				g.DFAInitial = it.entries[1].data
				g.LALRInitial = it.entries[2].data

			case 'c': //characters sets
				c := CharSet()
				c.index = it.entries[1].data
				Int count := it.entries[3].data
				Int[] ranges := it.entries[5..-1].map { it.data }
				for (Int i := 0; i < count; i++)
				{
					c.add(ranges[i * 2]..ranges[i * 2 + 1])
				}
				g.CharSets.add(c)

			case 'S': //symbol
				s := Symbol((Int) it.entries[1].data,(Str)it.entries[2].data, SymbolType.vals[(Int)it.entries[3].data])
				g.SymbolTable[(Int) it.entries[1].data] = s 

			case 'R': //rule
				derived := g.SymbolTable[(Int) it.entries[2].data]
				from := it.entries[4..-1].map |Entry v -> Symbol| { return g.SymbolTable[(Int) v.data] }
				r := Rule(derived, from)
				g.Rules[(Int) it.entries[1].data] = r

			case 'D': //DFA state
				ds := DFAState()
				ds.isAccept = it.entries[2].data
				ds.to = it.entries[3].data
				edges := it.entries[5..-1].map { it.data }.exclude { it == null }.map {(Int) it }
				for (Int i := 0; i < edges.size / 2; i++)
				{
					ds.edge[edges[i * 2]] = edges[i * 2 + 1]
				}
				g.DFAStates[(Int) it.entries[1].data] = ds
			
			case 'L': // LALR state
				ls := LALRState()
				ls.index = it.entries[1].data
				Int[] actions := it.entries[3..-1].map { it.data }.exclude { it == null }.map {(Int) it }

				for (Int i := 0; i < actions.size / 3; i++)
				{
					a := Action()
					a.at = ActionType.vals[actions[i * 3 + 1] - 1]
					a.target = actions[i * 3 + 2]
					ls.actions[actions[i * 3]] = a
				}
				g.LALRStates[ls.index] = ls
			}
		}
		return g
	}
}
