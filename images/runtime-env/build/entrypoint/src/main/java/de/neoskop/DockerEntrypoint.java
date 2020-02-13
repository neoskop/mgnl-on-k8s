package de.neoskop;

import de.neoskop.service.WaitOnMySQLService;

public class DockerEntrypoint {
    public static void main(String[] args) {
        WaitOnMySQLService.waitForAllConnections();
    }
}
