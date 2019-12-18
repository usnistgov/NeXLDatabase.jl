CREATE TABLE LABMEMBERS (
    labkey INTEGER NOT NULL,
    personkey INTEGER NOT NULL,
    FOREIGN KEY(labkey) REFERENCES laboratory(pkey),
    FOREIGN KEY(personkey) REFERENCES person(pkey),
    PRIMARY KEY(labkey, personkey)
);
