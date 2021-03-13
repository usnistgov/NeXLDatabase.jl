-- Header for fitting multiple spectra with a set of reference spectra.
CREATE TABLE CAMPAIGN (
   PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
   PROJECT INTEGER NOT NULL,
   DETECTOR INTEGER NOT NULL,
   ELEMENTS TEXT NOT NULL, -- The elements to fit (see below for format)
   MATKEY INTEGER, -- Helpful to reference a MATERIAL when the composition is known
   DISPOSITION TEXT, -- "OK" or "Reason not to include"
   FOREIGN KEY(DETECTOR) REFERENCES DETECTOR(PKEY),
   FOREIGN KEY(PROJECT) REFERENCES PROJECT(PKEY)
);

CREATE INDEX CAMPAIGN_PROJECT_IDX ON CAMPAIGN(PROJECT);

-- NOTE: ELEMENTS and REFFOR are stored as a string of element symbols separated by commas i.e. "Fe,Cr,Ni"
-- This is much more transparent than creating a special set of tables
