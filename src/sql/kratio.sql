CREATE TABLE KRATIO (
    PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
    FITSPEC INTEGER NOT NULL, -- Key into FITSPECTRA
    ELEMENT INTEGER NOT NULL, -- Element
    INNER INT NOT NULL,       -- Inner shell of primary line K->1, L1->2, ..., M1->5, ..., N1->10, etc
    OUTER INT NOT NULL,       -- Outer shell of primary line K->1, L1->2, ..., M1->5, ..., N1->10, etc
    MODE TEXT NOT NULL,       -- 'EDX' or 'WDS'
    MEASURED INTEGER NOT NULL, -- Measured material pkey
    MEASNAME TEXT NOT NULL,     -- Human friendly name of measured
    MEASE0 REAL NOT NULL,      -- Standard beam energy
    MEASTOA REAL NOT NULL,     -- Standard take-off angle
    REFERENCE INTEGER NOT NULL, -- Reference material pkey
    REFNAME TEXT NOT NULL,
    REFE0 REAL NOT NULL,      -- Reference beam energy
    REFTOA REAL NOT NULL,     -- Reference take-off angle
    PRINCIPAL TEXT NOT NULL,  -- Same as ELEMENT INNER-OUTER
    LINES TEXT NOT NULL,      -- List of all lines in fit e.g. "Si K-L3, Si K-L2, Si K-M2"
    KRATIO REAL NOT NULL,     -- The k-ratio
    DKRATIO REAL NOT NULL,    -- The 1-sigma standard uncertainty
    FOREIGN KEY(MEASURED) REFERENCES MATERIAL(PKEY),
    FOREIGN KEY(REFERENCE) REFERENCES MATERIAL(PKEY),
    FOREIGN KEY(FITSPEC) REFERENCES FITSPECTRA(PKEY)
);

CREATE INDEX KRATIO_INDEX ON KRATIO(ELEMENT, INNER, OUTER);
CREATE INDEX FITSPEC_KR_INDEX ON KRATIO(FITSPEC);
CREATE INDEX ELMREF_INDEX ON KRATIO(ELEMENT, REFERENCE);
