package de.neoskop.service;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import de.neoskop.model.Datasource;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.StreamSupport;

class DatasourceParserService {
    private static final Pattern ENV_VAR_PATTERN = Pattern.compile("\\$\\{([A-Za-z_][A-Za-z0-9_]*)\\}");

    public static List<Datasource> getDatasources() {
        String json = System.getenv("DATASOURCES");

        if (json == null || json.equals("")) {
            return null;
        }

        // Perform environment variable substitution (replace ${VAR} with env value)
        json = substituteEnvVars(json);

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

    /**
     * Substitutes environment variable references in the input string.
     * Replaces ${VAR_NAME} patterns with the corresponding environment variable value.
     * If an environment variable is not set, the placeholder is replaced with an empty string.
     *
     * @param input the string containing ${VAR} placeholders
     * @return the string with placeholders replaced by environment variable values
     */
    private static String substituteEnvVars(String input) {
        if (input == null) {
            return null;
        }

        Matcher matcher = ENV_VAR_PATTERN.matcher(input);
        StringBuilder result = new StringBuilder();

        while (matcher.find()) {
            String varName = matcher.group(1);
            String envValue = System.getenv(varName);
            // Replace with env value, or empty string if not set
            matcher.appendReplacement(result, Matcher.quoteReplacement(envValue != null ? envValue : ""));
        }
        matcher.appendTail(result);

        return result.toString();
    }
}