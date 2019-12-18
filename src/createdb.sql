-- DEFINES THE TABLES IN THE NEXL K-RATIO DATABASE


-- DEFINES A SAMPLE WITH REPRESENTS A PARTICULAR ITEM IN YOUR LABORATORY
-- (BECAUSE NOT ALL INSTANCES OF A MATERIAL ARE EQUIVALENT)


-- DEFINES THE UNKNOWN IN AN EDS QUANTIFICATION
CREATE TABLE EDSUNKNOWN (
    pkey INTEGER PRIMARY KEY NOT NULL,
    unknown INTEGER NOT NULL,
    FOREIGN KEY(unknown) REFERENCES spectrum(pkey)
);

-- DEFINES A STANDARD IN AN EDS QUANTIFICATION
CREATE TABLE EDSSTANDARD (
    pkey INTEGER PRIMARY KEY NOT NULL,
    z INTEGER NOT NULL,
    spectrum INTEGER NOT NULL,
    FOREIGN KEY(spectrum) REFERENCES spectrum(pkey)
);

-- ASSIGNS STANDARDS TO AN UNKNOWN
CREATE TABLE QUANTEDS (
    unknown INTEGER NOT NULL,
    standard INTEGER NOT NULL,
    FOREIGN KEY(unknown) REFERENCES edsunknown(pkey)
    FOREIGN KEY(standard) REFERENCES edsstandard(pkey)
);


INSERT INTO PERSON VALUES ( 1, "Nicholas W. M. Ritchie", "nicholas.ritchie@nist.gov");
INSERT INTO PERSON VALUES ( 2, "Dale E. Newbury", "dale.newbury@nist.gov");
INSERT INTO PERSON VALUES ( 3, "Kent Rhodes", "kent.rhodes@mccrone.com");

INSERT INTO LABORATORY VALUES ( 1, "NIST MMSD", "NIST, Building 217", "nicholas.ritchie@nist.gov" );
INSERT INTO LABORATORY VALUES ( 1, "McCrone Associates", "850 Pasquinelli Drive Westmont, IL, 60559", "kent.rhodes@mccrone.com" );

INSERT INTO INSTRUMENT VALUES ( 1, 1, "JEOL", "JXA-8500F", "4 spectrometer microprobe with Bruker EDS", "217 D113" );
INSERT INTO INSTRUMENT VALUES ( 2, 1, "TESCAN", "MIRA3", "Thermal field-emission SEM with 4 SDD", "217 F101" );
INSERT INTO INSTRUMENT VALUES ( 3, 1, "TESCAN", "MIRA3", "Thermal field-emission SEM with 3 SDD", "McCrone" );

INSERT INTO EDSDETECTOR VALUES ( 1, 1, "Bruker", "6030", "AP3.3", "30 mm² SDD" );
INSERT INTO EDSDETECTOR VALUES ( 2, 2, "Pulsetor", "Torrent", "AP3.3", "30 mm² SDD #1" );
INSERT INTO EDSDETECTOR VALUES ( 3, 2, "Pulsetor", "Torrent", "AP3.3", "30 mm² SDD #2" );
INSERT INTO EDSDETECTOR VALUES ( 4, 2, "Pulsetor", "Torrent", "AP3.3", "30 mm² SDD #3" );
INSERT INTO EDSDETECTOR VALUES ( 5, 2, "Pulsetor", "Torrent", "AP3.3", "30 mm² SDD #4" );
INSERT INTO EDSDETECTOR VALUES ( 6, 2, "Pulsetor", "Torrent", "AP3.3", "4 × 30 mm² SDD" );
INSERT INTO EDSDETECTOR VALUES ( 7, 3, "EDAX", "Octane", "AP3.3", "30 mm² SDD #1" );
INSERT INTO EDSDETECTOR VALUES ( 8, 3, "EDAX", "Octane", "AP3.3", "30 mm² SDD #2" );
INSERT INTO EDSDETECTOR VALUES ( 9, 3, "EDAX", "Octane", "AP3.3", "30 mm² SDD #3" );
INSERT INTO EDSDETECTOR VALUES ( 10, 3, "EDAX", "Octane", "AP3.3", "3 × 30 mm² SDD" );

-- Add a material
INSERT INTO MATERIAL VALUES ( 1, "K412", "SRM 470 K412 glass", null );
INSERT INTO COMPTABLE VALUES ( 1, 8, 0.42758, null, null);
INSERT INTO COMPTABLE VALUES ( 1, 12, 0.116567, null, null);
INSERT INTO COMPTABLE VALUES ( 1, 13, 0.0490615, null, null);
INSERT INTO COMPTABLE VALUES ( 1, 14, 0.211982, null, null);
INSERT INTO COMPTABLE VALUES ( 1, 20, 0.10899, null, null);
INSERT INTO COMPTABLE VALUES ( 1, 26, 0.0774196, null, null);

INSERT INTO MATERIAL VALUES ( 2, "ADM 6005a", "Doug's ADM glass", null );
INSERT INTO COMPTABLE VALUES ( 2, 8, 0.3398, null, null);
INSERT INTO COMPTABLE VALUES ( 2, 13, 0.0664, null, null);
INSERT INTO COMPTABLE VALUES ( 2, 14, 0.0405, null, null);
INSERT INTO COMPTABLE VALUES ( 2, 20, 0.0683, null, null);
INSERT INTO COMPTABLE VALUES ( 2, 22, 0.0713, null, null);
INSERT INTO COMPTABLE VALUES ( 2, 30, 0.1055, null, null);
INSERT INTO COMPTABLE VALUES ( 2, 32, 0.3037, null, null);

INSERT INTO MATERIAL VALUES ( 3, "Carbon", "Pure carbon", 1.9 );
INSERT INTO COMPTABLE VALUES (3, 6, 1.0, 0.0, null );
