import std.traits;
import std.stdio;



struct A(T) if(!hasIndirections!T)
{
	private T val;
	this(Args...)(Args args) { val=T(args); }

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
	auto x=A!int(1);
	writeln("x=", x);
	assert(x == 1);
	assert(x > 0);
	assert(x <= 1);

	A!string s;
	s="ABCD";
	writeln("s=", s);
	s~="..XYZ";
	writeln("s=", s);
	assert(s == "ABCD..XYZ");

	auto t=A!string(8);
	writeln(t.length, ": t=", t);
	assert(t.length == 8);

	A!(char[32]) ch;
	ch[]='_';
	ch[2..5]="xyz";
	writeln("ch=", ch);
	assert(ch[0..6] == "__xyz_");
}




	
