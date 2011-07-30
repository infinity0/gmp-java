import gnu.java.math.BigInteger;

import junit.framework.TestCase;

public class Test extends TestCase {

	public void testNativeDebug() {
		assertTrue("please re-run this with -Dgnu.native.debug=true",
		  Boolean.getBoolean("gnu.native.debug"));
		assertTrue("can't load native code", BigInteger.usingNative());
	}

	public void testSimpleAdd() {
		BigInteger a = new BigInteger("999999999999999999999999999999999999999999999999999999999999999999");
		BigInteger b = new BigInteger("999999999999999999999999999999999999999999999999999999999999999998");
		BigInteger c = new BigInteger("1999999999999999999999999999999999999999999999999999999999999999997");
		assertEquals(a.add(b), c);
	}

}
