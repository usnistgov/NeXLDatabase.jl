-- Header for fitting multiple spectra with a set of reference spectra.
CREATE TABLE FITSPECTRA (
   PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
   NAME TEXT,
   PROJECT INTEGER NOT NULL,
   ELEMENTS TEXT NOT NULL, -- The elements to fit (see below for format)
   FOREIGN KEY(ELEMENTS) REFERENCES ELEMENTSET(PKEY)
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
   SAMPLE INTEGER NOT NULL,
   ELEMENTS TEXT NOT NULL, -- Elements in the material (see below for format)
   FOREIGN KEY(FITSPECTRA) REFERENCES FITSPECTRA(PKEY),
   FOREIGN KEY(SPECTRUM) REFERENCES SPECTRUM(PKEY),
   FOREIGN KEY(SAMPLE) REFERENCES SAMPLE(PKEY)
);
-- NOTE: It is common by not necessary to know the composition of the reference spectrum.

CREATE INDEX REFSPEC_IDX ON REFERENCESPECTRUM(FITSPECTRA, SPECTRUM);

-- An ROI detailing the range of energies over which the REFERENCESPECTRUM is suitable to be used as a
-- reference for the specified element.  The ROI should be as broad (expansive) as possible.
CREATE TABLE REFERENCEROI
   PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
   REFKEY INTEGER NOT NULL,  -- REFERENCE(PKEY)
   ATOMICNUMBER INTEGER NOT NULL, -- 1 to 100ish
   LOW REAL NOT NULL,
   HIGH REAL NOT NULL
END



CREATE INDEX REF_QUANT_IDX ON REFERENCESPECTRUM(FITSPECTRA);

-- NOTE: ELEMENTS and REFFOR are stored as a string of element symbols separated by commas i.e. "Fe,Cr,Ni"
-- This is much more transparent than creating a special set of tables

-- "SELECT * FROM FITSPECTRUM WHERE FITSPECTRA=?;"
-- "SELECT * FROM REFERENCESPECTRUM WHERE FITSPECTRA=?;"
-- "INSERT INTO ELEMENT ( ELMSET, ATOMICNUMBER) VALUES (?, ?);"
