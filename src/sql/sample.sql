CREATE TABLE SAMPLE (
    pkey INTEGER PRIMAY KEY NOT NULL,
    parent INTEGER, -- Parent sample
    name TEXT NOT NULL, -- Ex: "Block C"
    material INTEGER, -- material(pkey)
    description TEXT
);
