CREATE TABLE groups (
    id          INTEGER UNIQUE NOT NULL PRIMARY KEY,
    code        VARCHAR UNIQUE NOT NULL, /* e.g., 'flo' */
    name        VARCHAR NOT NULL,
    shortname   VARCHAR,
    domain      VARCHAR
);

CREATE TABLE projects (
    id          INTEGER UNIQUE NOT NULL PRIMARY KEY,
    code        VARCHAR UNIQUE NOT NULL, /* e.g., 'upress' */
    pcode       VARCHAR UNIQUE,          /* e.g., 'p4874b89dc' */
    status      VARCHAR NOT NULL DEFAULT 'idle',
    created     INTEGER NOT NULL,
    description VARCHAR NOT NULL,
    ongoing     INTEGER NOT NULL DEFAULT 1,
    frequency   VARCHAR NOT NULL DEFAULT 'unknown',
    group_id    INTEGER NOT NULL REFERENCES groups(id)
);

CREATE TABLE files (
    id          INTEGER UNIQUE NOT NULL PRIMARY KEY,
    path        VARCHAR NOT NULL,
    num_records INTEGER NOT NULL,
    md5sum      VARCHAR NOT NULL,
    purpose     VARCHAR NOT NULL DEFAULT 'add'
);

CREATE TABLE records (
    id          INTEGER UNIQUE NOT NULL PRIMARY KEY,
    file_id     INTEGER NOT NULL REFERENCES files(id),
    record_num  INTEGER NOT NULL,
    oclc_num    INTEGER NULL
);

CREATE TABLE updates (
    id          INTEGER UNIQUE NOT NULL PRIMARY KEY,
    code        VARCHAR NOT NULL,       /* e.g., '2018-03' */
    status      VARCHAR NOT NULL DEFAULT 'new',
    created     INTEGER NOT NULL,       /* seconds since UNIX epoch */
    description VARCHAR NULL,
    purpose     VARCHAR NOT NULL DEFAULT 'add',   /* add | delete | replace */
    project_id  INTEGER NOT NULL REFERENCES projects(id),
    file_id     INTEGER NOT NULL REFERENCES files(id)
);

CREATE TABLE jobs (
    id          INTEGER UNIQUE NOT NULL PRIMARY KEY,
    jcode       VARCHAR NOT NULL,
    status      VARCHAR NOT NULL DEFAULT 'new',
    first       INTEGER NOT NULL,  /* range within */
    last        INTEGER NOT NULL,  /*  the update */
    update_id   INTEGER NOT NULL REFERENCES updates(id)
);

CREATE TABLE load_results (
    job_id      INTEGER NOT NULL REFERENCES jobs(id),
    record_id   INTEGER NOT NULL REFERENCES records(id),
    action      VARCHAR NULL,
    ils_num     INTEGER NULL
);

/*
CREATE TABLE batches (
    id          INTEGER UNIQUE NOT NULL PRIMARY KEY,
    first       INTEGER NOT NULL,
    last        INTEGER NOT NULL,
    status      VARCHAR NOT NULL DEFAULT 'new',
    created     INTEGER NOT NULL,
    update_id   INTEGER NOT NULL REFERENCES updates(id)
);
*/
