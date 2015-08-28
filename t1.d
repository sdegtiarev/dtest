import std.traits;
import std.stdio;



struct A(T) if(!hasIndirections!T)
{
	private T val;

	@property ref T Ref() { return val; }
	@property T Ref() const { return val; }
	alias Ref this;
}

struct A(T) if(isDynamicArray!T)
{
	private T val;
	this(size_t l) { val.length=l; }
	

	@property ref T Ref() { return val; }
	@property T Ref() const { return val; }
	alias Ref this;
}




void main()
{
	A!int x;
	x=1;
	writeln("x=", x);

	A!string s;
	s="ABCD";
	writeln("s=", s);
	s~="..XYZ";
	writeln("s=", s);

	auto t=A!string(8);
	writeln(t.length, ": t=", t);

	A!(char[32]) ch;
	ch[]='_';
	ch[2..5]="xyz";
	writeln("ch=", ch);
}




	
