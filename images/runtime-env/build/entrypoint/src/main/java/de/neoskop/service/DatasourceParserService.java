package de.neoskop.service;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import de.neoskop.model.Datasource;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.stream.StreamSupport;

class DatasourceParserService {
    public static List<Datasource> getDatasources() {
        final String json = System.getenv("DATASOURCES");

        if (json == null || json.equals("")) {
            return null;
        }

        final JsonObject jsonObject = JsonParser.parseString(json).getAsJsonObject();
        final JsonArray datasources = jsonObject.get("datasources").getAsJsonArray();

        return StreamSupport.stream(datasources.spliterator(), false).map(JsonElement::getAsJsonObject)
                .map(datasource -> {
                    final String name = getStringWithDefault(datasource, "name", "");
                    final String host = getStringWithDefault(datasource, "host", "");
                    final String username = getStringWithDefault(datasource, "username", "root");
                    final String password = getStringWithDefault(datasource, "password", "");
                    final String database = getStringWithDefault(datasource, "database", "mysql");
                    final String port = getStringWithDefault(datasource, "port", "3306");
                    final boolean useSsl = getBooleanWithDefault(datasource, "useSsl", false);
                    final String trustStore = getStringWithDefault(datasource, "trustStore", null, false);
                    final String trustStorePassword = getStringWithDefault(datasource, "trustStorePassword",
                            "changeit");
                    final String enabledTLSProtocols = getStringWithDefault(datasource, "enabledTLSProtocols", null);
                    return new Datasource(name, host, username, password, database, port, useSsl, trustStore,
                            trustStorePassword, enabledTLSProtocols);
                }).toList();
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