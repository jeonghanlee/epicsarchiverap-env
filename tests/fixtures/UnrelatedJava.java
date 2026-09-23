/** An unrelated live JVM used only for negative process-identity checks. */
public final class UnrelatedJava {
    public static void main(String[] args) throws Exception {
        System.out.println("ready");
        System.out.flush();
        Thread.sleep(60000);
    }
}
