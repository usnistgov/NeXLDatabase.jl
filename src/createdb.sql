-- DEFINES THE TABLES IN THE NEXL K-RATIO DATABASE

-- IDENTIFIES A PERSON
CREATE TABLE PERSON (
    pkey INTEGER PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    email TEXT
);

-- IDENTIFIES A LABORATORY
CREATE TABLE LABORATORY (
    pkey INTEGER PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    address TEXT,
    contact TEXT
);

-- ASSIGNS PERSON TO LABORATORY
CREATE TABLE LABMEMBERS (
    labkey INTEGER NOT NULL,
    personkey INTEGER NOT NULL,
    FOREIGN KEY(labkey) REFERENCES laboratory(pkey),
    FOREIGN KEY(personkey) REFERENCES person(pkey),
    PRIMARY KEY(labkey, personkey)
);

-- DEFINES A HIGH LEVEL PROJECT
CREATE TABLE PROJECT (
    pkey INTEGER PRIMAY KEY NOT NULL,
    parent INTEGER,
    name TEXT NOT NULL,
    description TEXT
);

-- DEFINES A MATERIAL AND WITH COMPTABLE A COMPOSITION
CREATE TABLE MATERIAL (
    pkey INTEGER PRIMAY KEY NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    density REAL
);

-- RECORDS HOW MUCH OF ELEMENT Z IS PRESENT IN MATERIAL
CREATE TABLE COMPTABLE (
    material INTEGER NOT NULL,
    z INTEGER NOT NULL,
    c REAL NOT NULL,
    uc REAL,
    FOREIGN KEY(material) REFERENCES material(pkey),
    PRIMARY KEY(material, z)
);

-- DEFINES A SAMPLE WITH REPRESENTS A PARTICULAR ITEM IN YOUR LABORATORY
-- (BECAUSE NOT ALL INSTANCES OF A MATERIAL ARE EQUIVALENT)
CREATE TABLE SAMPLE (
    pkey INTEGER PRIMAY KEY NOT NULL,
    name TEXT NOT NULL, -- Ex: "K412 in Block C"
    material INTEGER, -- material(pkey)
    description TEXT
);

-- DEFINES AN INSTRUMENT IN A LAB
CREATE TABLE INSTRUMENT (
    pkey INTEGER PRIMAY KEY,
    labkey INTEGER NOT NULL,
    vendor TEXT NOT NULL,
    model TEXT NOT NULL,
    description TEXT,
    FOREIGN KEY(labkey) REFERENCES laboratory(pkey)
);

-- DEFINES AN EDSDETECTOR ON AN INSTRUMENT
CREATE TABLE EDSDETECTOR (
    pkey INTEGER PRIMAY KEY NOT NULL,
    instrument INTEGER NOT NULL,
    vendor TEXT NOT NULL,
    model TEXT NOT NULL,
    window TEXT,
    description TEXT,
    FOREIGN KEY(instrument) REFERENCES instrument(pkey)
);

-- DEFINES A SAMPLE CONDUCTIVE COATING
CREATE TABLE COATING (
    pkey INTEGER PRIMARY KEY NOT NULL,
    thickness REAL NOT NULL,
    material INTEGER NOT NULL,
    FOREIGN KEY(material) REFERENCES material(pkey)
);

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

INSERT INTO LABORATORY VALUES ( 1, "NIST MMSD", "NIST, Building 217", "nicholas.ritchie@nist.gov" );

INSERT INTO INSTRUMENT VALUES ( 1, 1, "JEOL", "JXA-8500F", "4 spectrometer microprobe with Bruker EDS" );
INSERT INTO INSTRUMENT VALUES ( 2, 1, "TESCAN", "MIRA3", "Thermal field-emission SEM with 4 SDD" );

INSERT INTO EDSDETECTOR VALUES ( 1, 1, "Bruker", "6030", "AP3.3", "30 mm2 SDD" );
INSERT INTO EDSDETECTOR VALUES ( 2, 2, "Pulsetor", "Torrent", "AP3.3", "30 mm2 SDD #1" );
INSERT INTO EDSDETECTOR VALUES ( 3, 2, "Pulsetor", "Torrent", "AP3.3", "30 mm2 SDD #2" );
INSERT INTO EDSDETECTOR VALUES ( 4, 2, "Pulsetor", "Torrent", "AP3.3", "30 mm2 SDD #3" );
INSERT INTO EDSDETECTOR VALUES ( 5, 2, "Pulsetor", "Torrent", "AP3.3", "30 mm2 SDD #4" );
INSERT INTO EDSDETECTOR VALUES ( 6, 2, "Pulsetor", "Torrent", "AP3.3", "30 mm2 SDD combined" );

-- Add a material
INSERT INTO MATERIAL VALUES ( 1, "K412", "SRM 470 K412 glass", null );
INSERT INTO COMPTABLE VALUES ( 1, 8, 0.42758, null);
INSERT INTO COMPTABLE VALUES ( 1, 12, 0.116567, null);
INSERT INTO COMPTABLE VALUES ( 1, 13, 0.0490615, null);
INSERT INTO COMPTABLE VALUES ( 1, 14, 0.211982, null);
INSERT INTO COMPTABLE VALUES ( 1, 20, 0.10899, null);
INSERT INTO COMPTABLE VALUES ( 1, 26, 0.0774196, null);
