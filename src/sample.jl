

CREATE TABLE SAMPLE (
    PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
    OWNER INTEGER NOT NULL,
    NAME TEXT NOT NULL, -- Ex: "Block C"
    DESCRIPTION TEXT,
    UUID TEXT, -- Unique ID for sample
    FOREIGN KEY(OWNER) REFERENCES PERSON(PKEY)
);

struct Sample
    pkey::Int
    owner::Int
    name::String
    description::String
    uuid::UUID
end
