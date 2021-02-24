-- A spectrum to be used as a reference for a set of elements.  Element-by-element details of the ROIs for which
-- this spectrum is suitable is specified in REFERENCEROI
CREATE TABLE REFERENCESPECTRUM (
   PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
   CAMPAIGN INTEGER NOT NULL,
   SPECTRUM INTEGER NOT NULL,
   ELEMENTS TEXT NOT NULL, -- Elements in the material (see below for format)
   FOREIGN KEY(CAMPAIGN) REFERENCES CAMPAIGN(PKEY),
   FOREIGN KEY(SPECTRUM) REFERENCES SPECTRUM(PKEY)
);
-- NOTE: It is common by not necessary to know the composition of the reference spectrum.

CREATE INDEX REFSPEC_IDX ON REFERENCESPECTRUM(CAMPAIGN, SPECTRUM);