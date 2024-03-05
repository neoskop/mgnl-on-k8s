package de.neoskop.service;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import de.neoskop.model.Datasource;

public class ContextSetupService {
    private static final Logger LOGGER = LogManager.getLogger(ContextSetupService.class);
    private static final String CATALINA_HOME = System.getenv("CATALINA_HOME");
    private static final String MAGNOLIA_CONFIG = System.getenv("MAGNOLIA_CONFIG");

    public static void setupContext() {
        File contextFile = new File(CATALINA_HOME + "/conf/Catalina/localhost/ROOT.xml");
        try (PrintWriter writer = new PrintWriter(new FileWriter(contextFile))) {
            writer.println("<?xml version='1.0' encoding='utf-8'?>");
            writer.println("<Context>");

            writer.println("  <Manager pathname=\"\" />");
            writer.println("  <WatchedResource>WEB-INF/web.xml</WatchedResource>");
            writer.println("  <Resources cachingAllowed=\"true\" cacheMaxSize=\"100000\" />");
            writer.println("  <CookieProcessor sameSiteCookies=\"strict\" />");
            writer.println("  <JarScanner scanClassPath=\"false\" />");

            if (MAGNOLIA_CONFIG != null) {
                writer.printf(
                        "  <Parameter name=\"magnolia.initialization.file\" value=\"WEB-INF/config/%s/magnolia.properties,WEB-INF/config/default/magnolia.properties,WEB-INF/config/magnolia.properties\" override=\"false\" />\n",
                        MAGNOLIA_CONFIG);
            }

            final List<Datasource> datasources = DatasourceParserService.getDatasources();

            if (datasources != null) {
                datasources.stream().forEach(datasource -> {
                    writer.printf(
                            "  <Resource name=\"jdbc/%s\" auth=\"Container\" type=\"javax.sql.DataSource\" maxTotal=\"100\" maxIdle=\"30\" maxWaitMillis=\"10000\" url=\"%s",
                            datasource.name, datasource.getConnectionUrl());
                    writer.println(
                            "\" driverClassName=\"com.mysql.cj.jdbc.Driver\" validationQuery=\"SELECT 1\" testOnBorrow=\"true\" />");
                });
            }

            writer.println("</Context>");
        } catch (IOException e) {
            LOGGER.error(e.getMessage());
        }
    }
}