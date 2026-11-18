import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/*
 * Runs a steady allocation workload for a given number of seconds so that a real JVM writes real garbage
 * collection log lines. It keeps a fixed number of MiB of 64 KiB blocks alive, replaces them slowly and
 * allocates short-lived blocks continuously. Arguments: duration in seconds, retained size in MiB.
 */
public class Alloc {
    private static final int BLOCK_BYTES = 64 * 1024;
    private static final int BLOCKS_PER_MIB = 16;
    private static final int REPLACE_ODDS = 2048;

    public static void main(String[] args) {
        long seconds = Long.parseLong(args[0]);
        int retainedMib = Integer.parseInt(args[1]);
        List<byte[]> retained = new ArrayList<>();
        Random random = new Random(1);
        long end = System.nanoTime() + seconds * 1_000_000_000L;
        long allocated = 0;
        while (System.nanoTime() < end) {
            byte[] block = new byte[BLOCK_BYTES];
            block[0] = (byte) random.nextInt();
            allocated += block.length;
            if (retained.size() < retainedMib * BLOCKS_PER_MIB) {
                retained.add(block);
            } else if (random.nextInt(REPLACE_ODDS) == 0) {
                retained.set(random.nextInt(retained.size()), block);
            }
        }
        System.out.println(allocated + " " + retained.size());
    }
}
