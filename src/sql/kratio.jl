CREATE TABLE KRATIO (
    PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
    ELEMENT INTEGER NOT NULL, -- Element
    INNER INT NOT NULL,       -- Inner shell of primary line K->1, L1->2, ..., M1->5, ..., N1->10, etc
    OUTER INT NOT NULL,       -- Outer shell of primary line K->1, L1->2, ..., M1->5, ..., N1->10, etc
    MODE CHAR NOT NULL,       -- 'E' or 'W'
    UNKNOWN INTEGER NOT NULL, -- Unknown material pkey
    UNKE0 REAL NOT NULL,      -- Unknown beam energy
    UNKTOA REAL NOT NULL,     -- Unknown take-off angle
    REFERENCE INTEGER NOT NULL, -- Unknown material pkey
    REFE0 REAL NOT NULL,      -- Reference beam energy
    REFTOA REAL NOT NULL,     -- Reference take-off angle
    PRIMARY TEXT NOT NULL,    -- Primary measured x-ray e.g. "Si K-L3"
    LINES TEXT NOT NULL,      -- List of all lines in fit e.g. "Si K-L3, Si K-L2, Si K-M2"
    FOREIGN KEY(UNKNOWN) REFERENCES MATERIAL(PKEY),
    FOREIGN KEY(REFERENCE) REFERENCES MATERIAL(PKEY)
);
