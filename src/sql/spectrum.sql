-- DEFINES A SPECTRUM FROM MATERIAL COLLECTED ON A DETECTOR
CREATE TABLE SPECTRUM (
    pkey INTEGER PRIMARY KEY NOT NULL,
    detector INTEGER NOT NULL,
    beamenergy REAL NOT NULL, -- IN EV
    collectedby INTEGER,
    name TEXT,
    sample INTEGER NOT NULL,
    coating INTEGER,
    data BLOB,
    FOREIGN KEY(detector) REFERENCES edsdetector(pkey)
    FOREIGN KEY(collectedby) REFERENCES person(pkey)
    FOREIGN KEY(sample) REFERENCES sample(pkey)
);
