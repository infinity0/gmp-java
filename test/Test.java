import gnu.java.math.BigInteger;

public class Test {
	public static void main(String[] args) {
		Boolean debug = Boolean.getBoolean("gnu.native.debug");
		if (!debug) {
			System.err.println("please re-run this with -Dgnu.native.debug=true");
		} else {
			System.out.println("if you don't see \"using pure java implementation\", all is well");
		}
		BigInteger a = new BigInteger("999999999999999999999999999999999999999999999999999999999999999999");
		BigInteger b = new BigInteger("999999999999999999999999999999999999999999999999999999999999999998");
		System.out.println("   " + a);
		System.out.println("+  " + b);
		System.out.println("= 1999999999999999999999999999999999999999999999999999999999999999997 expected");
		System.out.println("? " + a.add(b) + " actual");
		System.out.println("test passed");
	}
}
