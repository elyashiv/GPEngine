class prog : Test
{
	Log l := Pod.of(this).log

	public Symbol checkS(InStream s, Grammer g)
	{
		st := g.DFAStates[g.DFAInitial]
		acc := false
		c := s.readChar
		flag := true

		if (c == null)
		{
			l.debug("fond: EOF")
			return g.SymbolTable.find { it.type == SymbolType.EOF }
		}

		while (flag)
		{
			l.debug("Processing symbol: ${c?.toChar}")
			ind := g.CharSets.find { it.contains(c) }?.index
			acc = st.isAccept

			nextHup := st.edge[ind ?: -1]

			if (nextHup == null)
				flag = false
			else
			{
				st = g.DFAStates[st.edge[ind]]
				c = s.readChar
			}
		}
		l.debug("fond: ${g.SymbolTable[st.to].name}")
		return g.SymbolTable[st.to]
	}

	public Symbol parse(InStream s, Grammer g)
	{
		st := g.LALRStates[g.LALRInitial]
		SymbolStack := Symbol[,]
		StateStack := [g.LALRInitial,]
		acc := false
		currS := checkS(s,g)
		tmp := currS
		try {
			while (!acc)
			{
				currAction := st.actions[currS.index]
				switch (currAction.at)
				{
				case ActionType.Shift:
					SymbolStack.push(currS)
					StateStack.push(st.index)
					currS = checkS(s,g)
					st = g.LALRStates[currAction.target]

				case ActionType.Reduce:
					rule := g.Rules[currAction.target]
					rule.from.size.times
					{ 
						SymbolStack.pop
						StateStack.pop
					}
					SymbolStack.push(rule.derived)
					tmp = currS
					currS = rule.derived
					st = g.LALRStates[StateStack.peek]

				case ActionType.Goto:
					st = g.LALRStates[currAction.target]
					StateStack.push(st.index)
					currS = tmp

				case ActionType.accept:
					acc = true
					
				}
			}
		}
		catch (Err e)
		{
			m := |Symbol symbol -> Str| { symbol.name }
			Env.cur.err.writeChars("st.actions = $st.actions\nSymbolStack = ${SymbolStack.map(m)}\nStateStack = $StateStack")
			Env.cur.err.writeChars(e.msg)
			e.trace(Env.cur.err)
		}

		return SymbolStack[0]
	}

	public Void testHexEgt()
	{
		gr := GrammerReader(Pod.of(this).file(`/res/test-grammers/Hex.egt`).in)
		g := gr.getGrammer
		PrintData(g)
		
		s := "0x54321".in                          
		verifyEq(checkS(s, g).name, "CHexLiteral", "Apperantly, not a CHexliteral")
		verifyNull(s.peekChar, "Apperantly, didn't read to the end")

		s = "&H54321".in
		verifyEq(checkS(s, g).name, "VBHexLiteral", "Apperantly, not a VBHexliteral")
		verifyNull(s.peekChar, "Apperantly, didn't read to the end")

		verifyEq(parse("0x5432".in, g).name, "Hex")
	}

	public Void testId()
	{
		gr := GrammerReader(Pod.of(this).file(`/res/test-grammers/grammar-example-identifiers.egt`).in)
		g := gr.getGrammer
		PrintData(g)
		
		s := "h123".in
		verifyEq(checkS(s,g).name, "Identifier") 
		verifyNull(s.peekChar)

		verifyEq(parse("j3424".in, g).name, "Value")
	}

	public Void PrintData(Grammer g)
	{
		l.debug("*************************")
		g.properties.each |V,K|
		{
			l.debug("$K: $V")
		}
		l.debug("*************************")
		l.debug("num of symbols: $g.SymbolCount")
		l.debug("num of Character sets: $g.CharacterSetCount")
		l.debug("num of rules: $g.RulesCount")
		l.debug("num of DFA states: $g.DFAStatesCount")
		l.debug("num of LALR states: $g.LALRStatesCount")
		l.debug("num of lexical groups: $g.LGroupCount")
		l.debug("*************************")
		l.debug("DFA initial state: $g.DFAInitial")
		l.debug("LALR initial state: $g.LALRInitial")
		l.debug("*************************")
		l.debug("Char sets:")
		g.CharSets.each
		{
			s := ""
			it.ranges.each { it.each { s += it.toChar } }
			l.debug(s)
		}
		l.debug("*************************")
		g.SymbolTable.each 
		{
			l.debug("Symbol Name: $it.name, symbol type: $it.type")
		}
		l.debug("*************************")
		l.debug("Rules:")
		g.Rules.each 
		{
			s := "$it.derived.name ::= "
			it.from.each
			{
				s += "$it.name "
			}
			l.debug(s)
		}
	}
}
