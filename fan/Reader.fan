** Indicates that there was an error while parsing the tables file.
const class TablesReadingErr : Err
{
	new make(Str msg := "", Err? cause := null) : super(msg) {}
}

enum class EType
{
	Empty('E'),
	Byte('b'),
	Boolean('B'),
	Integer('I'),
	String('S')

	private new make(Int ind) { indicator = ind; }
	const Int indicator
}

class Entry
{

	EType type := EType.Empty
	
	Obj? data
}

class Record
{
	Int numOfEntries

	Entry[] entries := [,]
}

** A clas for reading the tables.
class Reader
{
	InStream GTF

	Log log := Pod.of(this).log

	Record currRec := Record()

	Bool hasMoreRec := true
	
	new make(Uri filePath)
	{
		GTF = filePath.toFile.in
		init
	}

	new makeFromStream(InStream in)
	{
		GTF = in
		init
	}

	private Void init()
	{
		GTF.endian = Endian.little
		Str header := readStr
		log.debug("Version string is: $header")
		if (header != "GOLD Parser Tables/v5.0")
			throw TablesReadingErr("File is of unsupported type.")
	}

	public Void nextRec()
	{
		if (GTF.peek == null)
		{
			hasMoreRec = false
			return
		}
		currRec = Record()
		GTF.readS1 //should be 77
		currRec.numOfEntries = GTF.readU2
		log.debug("num of entries in rec: $currRec.numOfEntries")
		currRec.numOfEntries.times
		{
			ind := GTF.readS1
			log.debug("found entry ind: $ind ($ind.toChar)")
			type := EType.vals.find { it.indicator == ind }
			en := Entry()
			en.type = type
			switch (type)
			{
			case EType.Empty:
				en.data = null
			case EType.Byte:
				en.data = GTF.readU1
			case EType.Boolean:
				en.data = GTF.readU1 != 0
			case EType.Integer:
				en.data = GTF.readS2
			case EType.String:
				en.data = readStr
			default:
				throw TablesReadingErr("unknown entry type: $ind ($ind.toChar)")
			}
			log.debug("found data: $en.data")
			currRec.entries.add(en)
		}
	}

	public Void eachRec(|Record| f)
	{
		nextRec
		while (hasMoreRec)
		{
			f(currRec)
			nextRec
		}
	}

	** Returns a null-terminated string read from GTF
	private Str readStr()
	{
		Int[] ret := [,]
		tmp := GTF.readU2
		while (tmp != 0)
		{
			ret.add(tmp)
			tmp = GTF.readU2
		}

		return Str.fromChars(ret)
	}
}
