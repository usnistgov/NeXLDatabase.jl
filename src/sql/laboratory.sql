CREATE TABLE LABORATORY (
    PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
    NAME TEXT NOT NULL,
    CONTACT INT NOT NULL,
    FOREIGN KEY(CONTACT) REFERENCES PERSON(PKEY)
);

CREATE INDEX NAME_INDEX ON LABORATORY(NAME);

INSERT INTO LABORATORY ( NAME, CONTACT ) VALUES ( "NIST MML MMSD", 1 );
