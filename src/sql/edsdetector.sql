CREATE TABLE EDSDETECTOR (
    pkey INTEGER PRIMAY KEY NOT NULL,
    instrument INTEGER NOT NULL,
    vendor TEXT NOT NULL,
    model TEXT NOT NULL,
    window TEXT,
    description TEXT,
    FOREIGN KEY(instrument) REFERENCES instrument(pkey)
);
