import java.security.SecureRandom;

import junit.framework.TestCase;

import java.util.logging.Logger;
import java.util.logging.Formatter;
import java.util.logging.ConsoleHandler;
import java.util.logging.LogRecord;

import java.util.Arrays;

public class Benchmark extends TestCase {

	private static final Logger log = Logger.getLogger(Benchmark.class.getCanonicalName());

	static {
		log.setUseParentHandlers(false);
		ConsoleHandler hd = new ConsoleHandler();
		hd.setFormatter(new Formatter() {
			@Override
			public synchronized String format(LogRecord record) {
				return new StringBuilder()
				  .append(record.getMillis()/1000)
				  .append('.')
				  .append(String.format("%03d", record.getMillis()%1000))
				  .append(" | ")
				  .append(record.getLevel().getLocalizedName())
				  .append(" | ")
				  .append(formatMessage(record))
				  .append('\n')
				  .toString();
			}
		});
		log.addHandler(hd);
	}

	/** number of runs to warm up the JIT for */
	private static int warmRuns = 100;
	/** number of runs for the actual benchmark */
	private static int testRuns = 400;

	private int runsProcessed;

	/*
	 * the sample numbers are elG generator/prime so we can test with reasonable
	 * numbers
	 */
	private final static byte[] _sampleGenerator = new java.math.BigInteger("2").toByteArray();
	private final static byte[] _samplePrime = new java.math.BigInteger(
	  "FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD1" +
	  "29024E088A67CC74020BBEA63B139B22514A08798E3404DD" +
	  "EF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245" +
	  "E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7ED" +
	  "EE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3D" +
	  "C2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5F" +
	  "83655D23DCA3AD961C62F356208552BB9ED529077096966D" +
	  "670C354E4ABC9804F1746C08CA18217C32905E462E36CE3B" +
	  "E39E772C180E86039B2783A2EC07A28FB5C55DF06F4C52C9" +
	  "DE2BCBF6955817183995497CEA956AE515D2261898FA0510" +
	  "15728E5A8AACAA68FFFFFFFFFFFFFFFF", 16).toByteArray();

	private SecureRandom rand;

	TestJV6 jv6Test;
	TestGNU gnuTest;

	protected void setUp() throws Exception {
		assertTrue("can't load native code", gnu.java.math.BigInteger.usingNative());

		rand = new SecureRandom();
		rand.nextBoolean();
		rand.nextBoolean();
		rand.nextBoolean();
		log.info("Random number generator warmed up");

		byte[] randbytes = (new java.math.BigInteger(2048, rand)).toByteArray();

		jv6Test = new TestJV6(
		  "jv6",
		  new java.math.BigInteger(1, _sampleGenerator),
		  new java.math.BigInteger(1, _samplePrime),
		  new java.math.BigInteger(1, randbytes)
		);

		gnuTest = new TestGNU(
		  "gnu",
		  new gnu.java.math.BigInteger(1, _sampleGenerator),
		  new gnu.java.math.BigInteger(1, _samplePrime),
		  new gnu.java.math.BigInteger(1, randbytes)
		);

	}

	protected void tearDown() throws Exception {
		if (testRuns == runsProcessed)
			log.info(runsProcessed + " runs complete without any errors");
		else
			log.severe(runsProcessed + " runs until we got an error");

		log.info(jv6Test.getReport());
		log.info(gnuTest.getReport());
		log.info("  = " + (gnuTest.getTime() * 100.0 / jv6Test.getTime()) + "% of pure java");
	}

	public void testModPow() {
		for (int warmup = 0; warmup < warmRuns; warmup++) {
			byte[] jv6Val = jv6Test.testModPow(false);
			byte[] gnuVal = gnuTest.testModPow(false);
			assertTrue(Arrays.equals(jv6Val, gnuVal));
		}
		for (runsProcessed = 0; runsProcessed < testRuns; runsProcessed++) {
			byte[] jv6Val = jv6Test.testModPow(true);
			byte[] gnuVal = gnuTest.testModPow(true);
			assertTrue(Arrays.equals(jv6Val, gnuVal));
		}
	}

	public void testDoubleValue() {
		for (int warmup = 0; warmup < warmRuns; warmup++) {
			double jv6Val = jv6Test.testDoubleValue(false);
			double gnuVal = gnuTest.testDoubleValue(false);
			assertEquals(jv6Val, gnuVal);
		}
		for (runsProcessed = 0; runsProcessed < testRuns; runsProcessed++) {
			double jv6Val = jv6Test.testDoubleValue(true);
			double gnuVal = gnuTest.testDoubleValue(true);
			assertEquals(jv6Val, gnuVal);
		}
	}

	static abstract class TestTimer {

		final String name;

		protected long time;
		protected int runs;

		final static int DOUBLE_VAL_TEST_RUNS = 0x10000; // Run the doubleValue() calls within a loop since they are pretty fast..

		public TestTimer(String name) {
			this.name = name;
		}

		public long getTime() {
			return time;
		}

		public String getReport() {
			return name + " run time: " + String.format("%8d", time)
			  + "ms (" + String.format("%3d", (time/runs)) + "ms each)";
		}

		public byte[] testModPow(boolean count) {
			long start = System.currentTimeMillis();
			byte[] r = modPow();
			if (count) {
				time += System.currentTimeMillis() - start;
				++runs;
			}
			return r;
		}

		public double testDoubleValue(boolean count) {
			long start = System.currentTimeMillis();
			double r = 0.0;
			for (int i=0; i < DOUBLE_VAL_TEST_RUNS; ++i) {
				r = doubleValue();
			}
			if (count) {
				++runs;
				time += System.currentTimeMillis() - start;
			}
			return r;
		}

		abstract protected byte[] modPow();

		abstract protected double doubleValue();
	}

	static class TestJV6 extends TestTimer {

		final java.math.BigInteger g;
		final java.math.BigInteger p;
		final java.math.BigInteger k;

		public TestJV6(String name,
		  java.math.BigInteger g,
		  java.math.BigInteger p,
		  java.math.BigInteger k) {
			super(name);
			this.g = g;
			this.p = p;
			this.k = k;
		}

		protected final byte[] modPow() {
			return g.modPow(p, k).toByteArray();
		}

		protected final double doubleValue() {
			return g.doubleValue();
		}

	}

	static class TestGNU extends TestTimer {

		final gnu.java.math.BigInteger g;
		final gnu.java.math.BigInteger p;
		final gnu.java.math.BigInteger k;

		public TestGNU(String name,
		  gnu.java.math.BigInteger g,
		  gnu.java.math.BigInteger p,
		  gnu.java.math.BigInteger k) {
			super(name);
			this.g = g;
			this.p = p;
			this.k = k;
		}

		protected final byte[] modPow() {
			return g.modPow(p, k).toByteArray();
		}

		protected final double doubleValue() {
			return g.doubleValue();
		}

	}

}
