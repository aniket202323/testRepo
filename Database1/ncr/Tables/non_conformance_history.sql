CREATE TABLE [ncr].[non_conformance_history] (
    [id]                      BIGINT         IDENTITY (1, 1) NOT NULL,
    [created_by]              VARCHAR (255)  NULL,
    [created_on]              DATETIME2 (7)  NULL,
    [last_modified_by]        VARCHAR (255)  NULL,
    [last_modified_on]        DATETIME2 (7)  NULL,
    [version]                 INT            NULL,
    [column_updated_bitmask]  VARCHAR (15)   NULL,
    [dbtt_id]                 INT            NULL,
    [modified_on]             DATETIME2 (7)  NULL,
    [description]             VARCHAR (1000) NULL,
    [name]                    VARCHAR (255)  NULL,
    [non_conformance_type_id] BIGINT         NULL,
    [source]                  VARCHAR (255)  NULL,
    [non_conformance_id]      BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK__non_confo__non_c__5812160E] FOREIGN KEY ([non_conformance_id]) REFERENCES [ncr].[non_conformance] ([id])
);

