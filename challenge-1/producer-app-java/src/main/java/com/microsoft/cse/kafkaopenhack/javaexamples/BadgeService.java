package com.microsoft.cse.kafkaopenhack.javaexamples;

import java.sql.Connection;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.DriverManager;
import java.util.ArrayList;

public class BadgeService {


    private static Connection connection = null;

    public static ArrayList<EventBadge> GetBadges() {
        ArrayList<EventBadge> badgeEvents = new ArrayList<EventBadge>();
        try (Statement statement = connection.createStatement()) {
            ResultSet resultSet = statement.executeQuery("Challenge1.GetBadge");
            while (resultSet.next())
            {
                final EventBadge badge = new EventBadge();
                badge.setId(resultSet.getString(1));
                badge.setName(resultSet.getString(2));
                badge.setUserId(resultSet.getString(3));
                badge.setDisplayName(resultSet.getString(4));
                badge.setReputation(resultSet.getString(5));
                badge.setUpVotes(resultSet.getInt(6));
                badge.setDownVotes(resultSet.getInt(7));
                badgeEvents.add(badge);
            }
        }
        catch (Exception e) {
            e.printStackTrace();
            return null;
        }
        finally {
            return badgeEvents;
        }
    }

    public static void OpenConnection() {
        // Connect to database
        String hostName = "your_server.database.windows.net"; // update me
        String dbName = "your_database"; // update me
        String user = "your_username"; // update me
        String password = "your_password"; // update me
        String url = String.format("jdbc:sqlserver://%s:1433;database=%s;user=%s;password=%s;encrypt=true;"
                + "hostNameInCertificate=*.database.windows.net;loginTimeout=30;", hostName, dbName, user, password);
        try {
            connection = DriverManager.getConnection(url);
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void CloseConnection() {
        try {
            connection.close();
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
}