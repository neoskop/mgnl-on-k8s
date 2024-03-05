package de.neoskop.service;

import de.neoskop.exception.WrongCredentialsException;
import de.neoskop.model.Datasource;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.List;
import java.util.concurrent.*;

import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.LogManager;

public class WaitOnMySQLService {
    private static final Logger logger = LogManager.getLogger(WaitOnMySQLService.class);
    private static final int ACCESS_DENIED_ERROR_CODE = 1045;
    private static final ExecutorService executor = Executors.newFixedThreadPool(5);
    private static final int DELAY = 1;
    private final Datasource datasource;

    private WaitOnMySQLService(Datasource datasource) {
        this.datasource = datasource;
    }

    private Future<Boolean> waitForConnection() {
        Callable<Boolean> task = () -> {
            try {
                for (;;) {
                    try {
                        try {
                            Connection connection = DriverManager.getConnection(datasource.getConnectionUrl());
                            connection.close();
                            return true;
                        } catch (SQLException e) {
                            if (e.getErrorCode() == ACCESS_DENIED_ERROR_CODE) {
                                throw new WrongCredentialsException();
                            } else {
                                logger.debug("Connection check failed: " + e.getMessage());
                            }
                        }

                        logger.info("Waiting for connection to " + datasource.host);
                        TimeUnit.SECONDS.sleep(DELAY);
                    } catch (InterruptedException e) {
                        return false;
                    }
                }
            } catch (WrongCredentialsException e) {
                return false;
            }
        };

        return executor.submit(task);
    }

    public static void waitForAllConnections() {
        DriverManager.setLoginTimeout(10);

        final List<Datasource> datasources = DatasourceParserService.getDatasources();

        if (datasources == null) {
            return;
        }

        datasources.stream().map(datasource -> new WaitOnMySQLService(datasource))
                .map(WaitOnMySQLService::waitForConnection).forEach(future -> {
                    boolean credentialsCorrect;

                    try {
                        credentialsCorrect = future.get();
                    } catch (InterruptedException | ExecutionException e) {
                        logger.error("Connection test failed: " + e.getMessage());
                        return;
                    }

                    if (!credentialsCorrect) {
                        logger.error("Credentials are incorrect. Exiting.");
                        System.exit(1);
                    }
                });

        executor.shutdown();
    }

}
