create table doc_parsed
(
    id             integer                             not null
        constraint doc_parsed_pk
            primary key,
    doc_id         integer                             not null,
    full_text      text                                not null,
    structure_info jsonb                               not null,
    parse_time     timestamp default CURRENT_TIMESTAMP not null,
    status         varchar(32)                         not null,
    error_info     text
);

alter table doc_parsed
    owner to postgres;

create table file_metadata
(
    id            integer                             not null
        constraint file_metadata_pk
            primary key,
    file_id       integer                             not null,
    source        varchar(64)                         not null,
    title         varchar(256)                        not null,
    authors       varchar(255),
    institutions  varchar(255),
    publish_year  timestamp,
    publish_venue varchar(64)                         not null,
    keywords      jsonb     default '[]'::jsonb,
    abstract      text,
    language      varchar(32),
    created_time  timestamp default CURRENT_TIMESTAMP not null,
    update_time   timestamp                           not null
);

alter table file_metadata
    owner to postgres;

create table file_resource
(
    id           integer                             not null
        constraint file_resource_pk
            primary key,
    path         varchar(256)                        not null,
    name         varchar(128)                        not null,
    type         varchar(16),
    source       varchar(64)                         not null,
    created_time timestamp default CURRENT_TIMESTAMP not null
);

alter table file_resource
    owner to postgres;

create table labels
(
    id        bigint generated always as identity
        constraint labels_pk
            primary key,
    top_label varchar(128)              not null,
    sub_label jsonb default '[]'::jsonb not null
);

comment on column labels.top_label is '主标签';

comment on column labels.sub_label is '子标签';

alter table labels
    owner to postgres;

