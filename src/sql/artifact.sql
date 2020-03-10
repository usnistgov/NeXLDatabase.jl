-- For storing file-type objects in the database
CREATE TABLE ARTIFACT (
    PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
    FORMAT TEXT NOT NULL, -- EMSA, ASPEXTIFF, PNG etc
    FILENAME TEXT NOT NULL, -- Source filename
    DATA BLOB NOT NULL
);
