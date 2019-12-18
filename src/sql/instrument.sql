CREATE TABLE INSTRUMENT (
    pkey INTEGER PRIMAY KEY,
    labkey INTEGER NOT NULL,
    vendor TEXT NOT NULL,
    model TEXT NOT NULL,
    description TEXT,
    FOREIGN KEY(labkey) REFERENCES laboratory(pkey)
);
