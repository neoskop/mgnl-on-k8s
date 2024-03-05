package de.neoskop;

import de.neoskop.service.ContextSetupService;
import de.neoskop.service.WaitOnMySQLService;

public class DockerEntrypoint {
    public static void main(String[] args) {
        ContextSetupService.setupContext();
        WaitOnMySQLService.waitForAllConnections();
    }
}
