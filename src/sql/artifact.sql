-- For storing file-type objects in the database
CREATE TABLE ARTIFACT (
    PKEY INT PRIMARY KEY AUTOINCREMENT,
    TYPE TEXT NOT NULL, -- SPECTRUM, IMAGE, ...
    FORMAT TEXT NOT NULL, -- EMSA, TIFF, PNG etc
    FILENAME TEXT NOT NULL, -- Source filename
    DATA BLOB NOT NULL,
);
