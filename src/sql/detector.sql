CREATE TABLE DETECTOR (
    PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
    INSTRUMENT INTEGER NOT NULL,
    VENDOR TEXT NOT NULL,
    MODEL TEXT NOT NULL,
    DESCRIPTION TEXT,
    FOREIGN KEY(INSTRUMENT) REFERENCES INSTRUMENT(PKEY)
);

INSERT INTO DETECTOR ( INSTRUMENT, VENDOR, MODEL, DESCRIPTION ) VALUES ( 1, "Bruker", "Quantax 6|30", "30 mm² SDD with polymer thin window" );
INSERT INTO DETECTOR ( INSTRUMENT, VENDOR, MODEL, DESCRIPTION ) VALUES ( 2, "Pulsetor", "Torrent", "30 mm² SDD - 1 of 4" );
INSERT INTO DETECTOR ( INSTRUMENT, VENDOR, MODEL, DESCRIPTION ) VALUES ( 2, "Pulsetor", "Torrent", "30 mm² SDD - 2 of 4" );
INSERT INTO DETECTOR ( INSTRUMENT, VENDOR, MODEL, DESCRIPTION ) VALUES ( 2, "Pulsetor", "Torrent", "30 mm² SDD - 3 of 4" );
INSERT INTO DETECTOR ( INSTRUMENT, VENDOR, MODEL, DESCRIPTION ) VALUES ( 2, "Pulsetor", "Torrent", "30 mm² SDD - 4 of 4" );
INSERT INTO DETECTOR ( INSTRUMENT, VENDOR, MODEL, DESCRIPTION ) VALUES ( 2, "Pulsetor", "Torrent", "30 mm² SDD - sum" );