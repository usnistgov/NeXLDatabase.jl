-- Header for fitting multiple spectra with a set of reference spectra.
CREATE TABLE FITSPECTRA (
   PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
   PROJECT INTEGER NOT NULL,
   DETECTOR INTEGER NOT NULL,
   ELEMENTS TEXT NOT NULL, -- The elements to fit (see below for format)
   MATKEY INTEGER, -- Helpful to reference a MATERIAL when the composition is known
   DISPOSITION TEXT, -- "OK" or "Reason not to include"
   FOREIGN KEY(DETECTOR) REFERENCES DETECTOR(PKEY),
   FOREIGN KEY(PROJECT) REFERENCES PROJECT(PKEY)
);

CREATE INDEX FITSPEC_PROJECT_IDX ON FITSPECTRA(PROJECT);

-- A spectrum to be fit
CREATE TABLE FITSPECTRUM (
   FITSPECTRA INT NOT NULL,  -- FITSPECTRA(PKEY)
   SPECTRUM INT NOT NULL,  -- SPECTRUM(PKEY)
   FOREIGN KEY(FITSPECTRA) REFERENCES FITSPECTRA(PKEY),
   FOREIGN KEY(SPECTRUM) REFERENCES SPECTRUM(PKEY),
   PRIMARY KEY(FITSPECTRA, SPECTRUM)
);

-- A spectrum to be used as a reference for a set of elements.  Element-by-element details of the ROIs for which
-- this spectrum is suitable is specified in REFERENCEROI
CREATE TABLE REFERENCESPECTRUM (
   PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
   FITSPECTRA INTEGER NOT NULL,
   SPECTRUM INTEGER NOT NULL,
   ELEMENTS TEXT NOT NULL, -- Elements in the material (see below for format)
   FOREIGN KEY(FITSPECTRA) REFERENCES FITSPECTRA(PKEY),
   FOREIGN KEY(SPECTRUM) REFERENCES SPECTRUM(PKEY)
);
-- NOTE: It is common by not necessary to know the composition of the reference spectrum.

CREATE INDEX REFSPEC_IDX ON REFERENCESPECTRUM(FITSPECTRA, SPECTRUM);

-- NOTE: ELEMENTS and REFFOR are stored as a string of element symbols separated by commas i.e. "Fe,Cr,Ni"
-- This is much more transparent than creating a special set of tables

-- "SELECT * FROM FITSPECTRUM WHERE FITSPECTRA=?;"
-- "SELECT * FROM REFERENCESPECTRUM WHERE FITSPECTRA=?;"
-- "INSERT INTO ELEMENT ( ELMSET, ATOMICNUMBER) VALUES (?, ?);"
