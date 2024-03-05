package de.neoskop.model;

import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.LogManager;

public class Datasource {
    private static final Logger logger = LogManager.getLogger(Datasource.class);

    public final String name;
    public final String host;
    public final String username;
    public final String password;
    public final String database;
    public final String port;
    public final boolean useSsl;
    public final String trustStore;
    public final String trustStorePassword;
    public final String enabledTLSProtocols;

    public Datasource(String name, String host, String username, String password, String database, String port,
            boolean useSsl,
            String trustStore, String trustStorePassword, String enabledTLSProtocols) {
        this.name = name;
        this.host = host;
        this.username = username;
        this.password = password;
        this.database = database;
        this.port = port;
        this.useSsl = useSsl;
        this.trustStore = trustStore;
        this.trustStorePassword = trustStorePassword;
        this.enabledTLSProtocols = enabledTLSProtocols;
    }

    public String getConnectionUrl() {
        final StringBuilder sb = new StringBuilder("jdbc:mysql://");
        sb.append(host);
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

        if (enabledTLSProtocols != null) {
            sb.append("&enabledTLSProtocols=");
            sb.append(enabledTLSProtocols);
        }

        logger.debug("Connection URL: " + sb.toString());
        return sb.toString();
    }
}