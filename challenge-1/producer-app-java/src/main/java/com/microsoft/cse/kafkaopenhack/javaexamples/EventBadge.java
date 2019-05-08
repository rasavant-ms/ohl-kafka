package com.microsoft.cse.kafkaopenhack.javaexamples;


import java.io.Serializable;

public class EventBadge implements Serializable {

    private String id;
    private String name;
    private String userId;
    private String displayName;
    private String reputation;
    private int upVotes;
    private int downVotes;

    public EventBadge() {}

    public EventBadge(String id, String name, String userId, String displayName, String reputation, int upVotes, int downVotes) {
        this.id = id;
        this.name = name;
        this.userId = userId;
        this.displayName = displayName;
        this.reputation = reputation;
        this.upVotes = upVotes;
        this.downVotes = downVotes;
    }

    public String getId() {
        return id;
    }

    public void setId(String value) {
        this.id = value;
    }

    public String getName() {
        return name;
    }

    public void setName(String value) {
        this.name = value;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String value) { this.userId = value; }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String value) {
        this.displayName = value;
    }

    public String getReputation() {
        return reputation;
    }

    public void setReputation(String value) {
        this.reputation = value;
    }

    public int getUpVotes() {
        return upVotes;
    }

    public void setUpVotes(int value) {
        this.upVotes = value;
    }

    public int getDownVotes() {
        return downVotes;
    }

    public void setDownVotes(int value) {
        this.downVotes = value;
    }

}
