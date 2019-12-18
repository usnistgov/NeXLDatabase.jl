CREATE TABLE COATING (
    pkey INTEGER PRIMARY KEY NOT NULL,
    thickness REAL NOT NULL,
    material INTEGER NOT NULL,
    FOREIGN KEY(material) REFERENCES material(pkey)
);
