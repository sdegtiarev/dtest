module std.perpetual;
import std.stdio;

private import std.mmfile;
private import std.file;
private import core.stdc.stdio;
private import std.traits;
private import std.string;
private import std.conv;
private import std.exception;
version (Windows) {
private import core.sys.windows.windows;
private import std.utf;
private import std.windows.syserror;
} else version (Posix) {
private import core.sys.posix.fcntl;
private import core.sys.posix.unistd;
private import core.sys.posix.sys.mman;
private import core.sys.posix.sys.stat;
} else {
	static assert(0);
}



/**
 * Persistently maps value type object to file
 */
struct perpetual(T)
{
	private MmFile _heap;
	private enum _tag="perpetual!("~T.stringof~")";

	static if(is(T == Element[],Element)) {
	// dynamic array 
		private Element[] _value;
		enum bool dynamic=true;
		static assert(!hasIndirections!Element, Element.stringof~" is reference type");
		@property Element[] Ref() { return _value; }
		string toString() { return to!string(_value); }

	} else {
	// value type
		private T *_value;
		enum bool dynamic=false;
		static assert(!hasIndirections!T, T.stringof~" is reference type");
		@property ref T Ref() {	return *_value; }
		/**
		 * Return string representation for wrapped object instead of self.
		 */
		//string toString() const { return to!string(Ref); }
		string toString() { return to!string(*_value); }
	}

/**
 * Get reference to wrapped object.
 */
	alias Ref this;

	private bool _owner=true;
	@property auto master() { return _owner; }




/**
 * Open file and assosiate object with it.
 * The file is extended if smaller than requred. Initialized
 *   with T.init if created or extended.
 */
	this(string path) {
		static if(dynamic) {
			enforce(exists(path), _tag~": dynamic array of zero length");
			size_t size=0;
		} else {
			size_t size=T.sizeof;
		}
		_heap=new MmFile(path, MmFile.Mode.readWrite, size, null, 0);

		void[] p=_heap[0.._heap.length];
		static if(dynamic) {
			_value=cast(Element[]) p;
		} else if(master) {
			_value=cast(T*) p.ptr;
		}
 	}
}


///
import std.stdio;
import std.conv;
import std.string;
import std.getopt;
import std.perpetual;

struct A { int x; };
class B {};
enum Color { black, red, green, blue, white };


// Usage: test
// Output:
// perpetual!int                   : 0
// perpetual!double                : nan
// perpetual!(A)                   : A(0)
// perpetual!(int[5])              : [0, 0, 0, 0, 0]
// perpetual!(immutable(short[]))  : [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
// perpetual!(Color)               : black
// perpetual!(char[])              : ________________________________
// perpetual!string                : ________________________________
// perpetual!(char[3][5])          : ["one", "...", "two", "...", "..."]
// perpetual!(const(char[]))       : one...two......
// perpetual!(char[3][])           : ["one", "...", "two", "...", "..."]
//
// Usage: test --int=3 --real=3.14159 --struct=11 --array=1,3,5,7 --color=green --string=ABCDE 
// Output:
// perpetual!int                   : 3
// perpetual!double                : 3.14159
// perpetual!(A)                   : A(11)
// perpetual!(int[5])              : [1, 3, 5, 7, 0]
// perpetual!(immutable(short[]))  : [1, 0, 3, 0, 5, 0, 7, 0, 0, 0]
// perpetual!(Color)               : green
// perpetual!(char[])              : ABCDE___________________________
// perpetual!string                : ABCDE___________________________
// perpetual!(char[3][5])          : ["one", "...", "two", "...", "..."]
// perpetual!(const(char[]))       : one...two......
// perpetual!(char[3][])           : ["one", "...", "two", "...", "..."]


void main(string[] arg)
{

	// simple built-in values
	auto p0=perpetual!int("Q1");
	auto p1=perpetual!double("Q2");

	// struct
	auto p2=perpetual!A("Q3");
	// static array of integers

	auto p3=perpetual!(int[5])("Q4");
	// view only, map above as array of shorts
	auto p4=perpetual!(immutable(short[]))("Q4");

	// enum
	auto p5=perpetual!Color("Q5");

	// character string, reinitialize if new file created
	auto p6=perpetual!(char[32])("Q6");
	// view only variant of above
	auto p7=perpetual!string("Q6");

	// double static array with initailization
	auto p8=perpetual!(char[3][5])("Q7");
	if(p8.master) { foreach(ref x; p8) x="..."; p8[0]="one"; p8[2]="two"; }
	// map of above as plain array
	auto p9=perpetual!(const(char[]))("Q7");
	// map again as dynamic array
	auto pA=perpetual!(char[3][])("Q7");

	//auto pX=perpetual!(char*)("Q?"); //ERROR: "char* is reference type"
	//auto pX=perpetual!B("Q?"); //ERROR: "B is reference type"
	//auto pX=perpetual!(char*[])("Q?"); //ERROR: "char* is reference type"
	//auto pX=perpetual!(char*[12])("Q?"); //ERROR: "char*[12] is reference type"
	//auto pX=perpetual!(char[string])("Q?"); //ERROR: "char[string] is reference type"
	//auto pX=perpetual!(char[][])("Q?"); //ERROR: "char[] is reference type"
	//auto pX=perpetual!(char[][3])("Q?"); //ERROR: "char[][3] is reference type"


	auto opt=getopt(arg
		, "int", delegate(string key, string val){ p0=to!int(val); }
		, "real", delegate(string key, string val){ p1=to!double(val); }
		, "struct", delegate(string key, string val){ p2.x=to!int(val); }
		, "array", delegate(string key, string val){
		 	auto lst=split(val,",");
			p3[0..lst.length]=to!(int[])(lst);
		}
		, "color", delegate(string key, string val){ p5=to!Color(val); }
		, "string", delegate(string key, string val){ p6[0..val.length]=val; }
		);
	if(opt.helpWanted) {
		defaultGetoptPrinter("Syntax:", opt.options);
		return;
	}


	writefln("%-32s: %s", typeof(p0).stringof, p0);
	writefln("%-32s: %s", typeof(p1).stringof, p1);
	writefln("%-32s: %s", typeof(p2).stringof, p2);
	writefln("%-32s: %s", typeof(p3).stringof, p3);
	writefln("%-32s: %s", typeof(p4).stringof, p4);
	writefln("%-32s: %s", typeof(p5).stringof, p5);
	writefln("%-32s: %s", typeof(p6).stringof, p6);
	writefln("%-32s: %s", typeof(p7).stringof, p7);
	writefln("%-32s: %s", typeof(p8).stringof, p8);
	writefln("%-32s: %s", typeof(p9).stringof, p9);
	writefln("%-32s: %s", typeof(pA).stringof, pA);
}


