CREATE TABLE MATERIAL (
    PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
    MATNAME TEXT NOT NULL, -- Make material name unique
    MATDESCRIPTION TEXT,
    MATDENSITY REAL
);

INSERT INTO MATERIAL ( MATNAME, MATDESCRIPTION, MATDENSITY ) VALUE ( "Unknown", "Unknown material", 0.0 );