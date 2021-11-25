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

import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.LogManager;

public class WaitOnMySQLService {
    private static final Logger logger = LogManager.getLogger(WaitOnMySQLService.class);
    private static final int ACCESS_DENIED_ERROR_CODE = 1045;
    private static final ExecutorService executor = Executors.newFixedThreadPool(5);
    private static final int DELAY = 1;
    private final String hostname;
    private final String username;
    private final String password;
    private final String database;
    private final String port;
    private final boolean useSsl;
    private final String trustStore;
    private final String trustStorePassword;

    private WaitOnMySQLService(String hostname, String username, String password, String database, String port,
            boolean useSsl, String trustStore, String trustStorePassword) {
        this.hostname = hostname;
        this.username = username;
        this.password = password;
        this.database = database;
        this.port = port;
        this.useSsl = useSsl;
        this.trustStore = trustStore;
        this.trustStorePassword = trustStorePassword;
    }

    private Future<Boolean> waitForConnection() {
        Callable<Boolean> task = () -> {
            try {
                for (;;) {
                    try {
                        try {
                            `Connection connection = DriverManager.getConnection(getConnectionUrl());
                            connection.close();
                            return true;
                        } catch (SQLException e) {
                            if (e.getErrorCode() == ACCESS_DENIED_ERROR_CODE) {
                                throw new WrongCredentialsException();
                            } else {
                                logger.debug("Connection check failed: " + e.getMessage());
                            }
                        }

                        logger.info("Waiting for connection to " + hostname);
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

    private String getConnectionUrl() {
        final StringBuilder sb = new StringBuilder("jdbc:mysql://");
        sb.append(hostname);
        sb.append(":");
        sb.append(port);
        sb.append("/");
        sb.append(database);
        sb.append("?user=");
        sb.append(username);
        sb.append("&password=");
        sb.append(password);
        sb.append("&useSSL=");
        sb.append(useSsl);

        if (trustStore != null) {
            sb.append("&trustCertificateKeyStoreUrl=file://");
            sb.append(trustStore);
            sb.append("&trustCertificateKeyStorePassword=");
            sb.append(trustStorePassword);
        }

        logger.debug("Connection URL: " + sb.toString());
        return sb.toString();
    }

    public static void waitForAllConnections() {
        DriverManager.setLoginTimeout(10);
        final String json = System.getenv("DATASOURCES");

        if (json == null || json.equals("")) {
            return;
        }

        final JsonObject jsonObject = JsonParser.parseString(json).getAsJsonObject();
        final JsonArray datasources = jsonObject.get("datasources").getAsJsonArray();
        StreamSupport.stream(datasources.spliterator(), false).map(JsonElement::getAsJsonObject).map(datasource -> {
            final String host = getStringWithDefault(datasource, "host", "");
            final String username = getStringWithDefault(datasource, "username", "root");
            final String password = getStringWithDefault(datasource, "password", "");
            final String database = getStringWithDefault(datasource, "database", "mysql");
            final String port = getStringWithDefault(datasource, "port", "3306");
            final boolean useSsl = getBooleanWithDefault(datasource, "useSsl", false);
            final String trustStore = getStringWithDefault(datasource, "trustStore", null, false);
            final String trustStorePassword = getStringWithDefault(datasource, "trustStorePassword", "changeit");
            return new WaitOnMySQLService(host, username, password, database, port, useSsl, trustStore,
                    trustStorePassword);
        }).map(WaitOnMySQLService::waitForConnection).forEach(future -> {
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

    private static String getStringWithDefault(JsonObject object, String property, String defaultValue) {
        return getStringWithDefault(object, property, defaultValue, true);
    }

    private static String getStringWithDefault(JsonObject object, String property, String defaultValue,
            boolean urlEncode) {
        if (object.has(property)) {
            final String value = object.get(property).getAsString();

            if (urlEncode) {
                return URLEncoder.encode(value, StandardCharsets.UTF_8);
            } else {
                return value;
            }
        }

        return defaultValue;
    }

    private static boolean getBooleanWithDefault(JsonObject object, String property, boolean defaultValue) {
        if (object.has(property)) {
            return object.get(property).getAsBoolean();
        }

        return defaultValue;
    }

}
