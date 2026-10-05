package org.apache.catalina.startup;

/** A live JVM that carries the Tomcat Bootstrap identity for launcher process checks. */
public final class Bootstrap {
    public static void main(String[] args) throws Exception {
        System.out.println("ready");
        System.out.flush();
        Thread.sleep(60000);
    }
}
