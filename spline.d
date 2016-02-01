module spline;
import std.math;
import std.stdio;


struct Spline(T)
{
private:
	immutable ulong N;
	T[] A,B,C,D;

	this(const(T)[] F)
	{
		N=F.length-1;
		A=F.dup;
		C.length=N+1;
		B.length=D.length=N;
		T[] p; p.length=N;
		foreach(i; 1..N) {
			C[i]=4;
			p[i]=3*(A[i-1]-2*A[i]+A[i+1]);
		}
		C[0]=C[N]=p[0]=0;
		
		foreach(i; 2..N) {
			C[i]-=1/C[i-1];
			p[i]-=p[i-1]/C[i-1];
		}
		
		foreach_reverse(i; 1..N-1) {
			C[i]-=1/C[i+1];
			p[i]-=p[i+1]/C[i+1];
		}
		foreach(i; 1..N) C[i]=p[i]/C[i];

		foreach_reverse(i; 0..N) {
			B[i]=F[i+1]-F[i]-(C[i+1]+2*C[i])/3;
			D[i]=(C[i+1]-C[i])/3;
		}
	}


	@property ulong length() { return N; }

	T opCall(T x) {
		ulong n;
		if(x < 0) {
			n=0;
		} else if(x >= N) {
			n=N-1;
			x-=n;
		} else {
			n=cast(long) x;
			x-=n;
		}
		return A[n]+x*(B[n]+x*(C[n]+x*D[n]));
		//return 2*(C[n]+x*3*D[n]);
	}
}


Spline!T spline(T)(T[] f) { return Spline!T(f); }



struct Spline1(T)
{
private:
	immutable ulong N;
	T[] A,B,C,D;

	this(const(T)[] F)
	{
		N=F.length-1;
		A=F.dup;
		C.length=N+1;
		B.length=D.length=N;
		T[] p; p.length=N;
		foreach(i; 1..N) {
			C[i]=4;
			p[i]=3*(A[i-1]-2*A[i]+A[i+1]);
		}
		C[0]=C[N]=p[0]=0;
		C[1]-=.5;   p[1]-=3*(A[1]-A[0])/2;
		C[N-1]-=.5; p[N-1]+=3*(A[N]-A[N-1])/2;
		
		foreach(i; 2..N) {
			C[i]-=1/C[i-1];
			p[i]-=p[i-1]/C[i-1];
		}
		
		foreach_reverse(i; 1..N-1) {
			C[i]-=1/C[i+1];
			p[i]-=p[i+1]/C[i+1];
		}
		foreach(i; 1..N) C[i]=p[i]/C[i];
		C[0]=3*(A[1]-A[0])/2-C[1]/2;
		C[N]=3*(A[N-1]-A[N])/2-C[N-1]/2;

		foreach_reverse(i; 0..N) {
			B[i]=F[i+1]-F[i]-(C[i+1]+2*C[i])/3;
			D[i]=(C[i+1]-C[i])/3;
		}
	}


	@property ulong length() { return N; }

	T opCall(T x) {
		ulong n;
		if(x < 0) {
			n=0;
		} else if(x >= N) {
			n=N-1;
			x-=n;
		} else {
			n=cast(long) x;
			x-=n;
		}
		return A[n]+x*(B[n]+x*(C[n]+x*D[n]));
		//return B[n]+x*(2*C[n]+3*x*D[n]);
		//return 2*(C[n]+x*3*D[n]);
	}
}


Spline1!T spline1(T)(T[] f) { return Spline1!T(f); }






void main(string[] arg)
{
	import std.conv;

	double[17] sn, cs;
	foreach(i; 0..sn.length) {
		sn[i]=sin(i*PI/16);
		cs[i]=cos(i*PI/16);
	}

	auto s=spline(sn);
	writeln("sin");
	for(double x=0; x <= 16; x+=.1)
			//writeln(x," ", s(x));
			writeln(x," ", s(x)-sin(x*PI/16));
	auto c=spline(cs);
	writeln("cos");
	for(double x=0; x <= 16; x+=.1)
			//writeln(x," ", c(x));
			writeln(x," ", c(x)-cos(x*PI/16));

	auto s1=spline1(sn);
	//writeln("sin1");
	//for(double x=0; x <= 16; x+=.1)
	//		//writeln(x," ", s1(x));
	//		writeln(x," ", s1(x)-sin(x*PI/16));
	auto c1=spline1(cs);
	writeln("cos1");
	for(double x=0; x <= 16; x+=.1)
			//writeln(x," ", c1(x));
			writeln(x," ", c1(x)-cos(x*PI/16));
}