package de.neoskop.service;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import de.neoskop.exception.WrongCredentialsException;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.concurrent.*;
import java.util.stream.StreamSupport;

public class WaitOnMySQLService {
    private static final int ACCESS_DENIED_ERROR_CODE = 1045;
    private static ExecutorService EXECUTOR = Executors.newFixedThreadPool(5);
    private static final int DELAY = 1;
    private final String hostname;
    private final String username;
    private final String password;
    private final String database;
    private final String port;

    private WaitOnMySQLService(String hostname, String username, String password, String database, String port) {
        this.hostname = hostname;
        this.username = username;
        this.password = password;
        this.database = database;
        this.port = port;
    }

    private Future<Boolean> waitForConnection() {
        Callable<Boolean> task = () -> {
            try {
                for (;;) {
                    try {
                        try {
                            Connection connection = DriverManager.getConnection(getConnectionUrl());
                            connection.close();
                            return true;
                        } catch (SQLException e) {
                            if (e.getErrorCode() == ACCESS_DENIED_ERROR_CODE) {
                                throw new WrongCredentialsException();
                            }
                        }

                        System.out.println("Waiting for connection to " + hostname);
                        TimeUnit.SECONDS.sleep(DELAY);
                    } catch (InterruptedException e) {
                        return false;
                    }
                }
            } catch (WrongCredentialsException e) {
                return false;
            }
        };

        return EXECUTOR.submit(task);
    }

    private String getConnectionUrl() {
        return "jdbc:mysql://" + hostname + ":" + port + "/" + database + "?user=" + username + "&password=" + password
                + "&useSSL=false";
    }

    public static void waitForAllConnections() {
        DriverManager.setLoginTimeout(10);
        final String json = System.getenv("DATASOURCES");

        if (json == null || json.equals("")) {
            return;
        }

        final JsonObject jsonObject = new JsonParser().parse(json).getAsJsonObject();
        final JsonArray datasources = jsonObject.get("datasources").getAsJsonArray();
        StreamSupport.stream(datasources.spliterator(), false).map(JsonElement::getAsJsonObject).map(datasource -> {
            final String host = getWithDefault(datasource, "host", "");
            final String username = getWithDefault(datasource, "username", "root");
            final String password = getWithDefault(datasource, "password", "");
            final String database = getWithDefault(datasource, "database", "mysql");
            final String port = getWithDefault(datasource, "port", "3306");
            return new WaitOnMySQLService(host, username, password, database, port);
        }).map(WaitOnMySQLService::waitForConnection).forEach(future -> {
            boolean credentialsCorrect;

            try {
                credentialsCorrect = future.get();
            } catch (InterruptedException | ExecutionException e) {
                System.out.println("Connection test failed: " + e.getMessage());
                return;
            }

            if (!credentialsCorrect) {
                System.out.println("Credentials are incorrect. Exiting.");
                System.exit(1);
            }
        });

        EXECUTOR.shutdown();
    }

    private static String getWithDefault(JsonObject object, String property, String defaultValue) {
        if (object.has(property)) {
            return URLEncoder.encode(object.get(property).getAsString(), StandardCharsets.UTF_8);
        }

        return defaultValue;
    }

}
