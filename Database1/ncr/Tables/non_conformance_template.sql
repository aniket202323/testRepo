CREATE TABLE [ncr].[non_conformance_template] (
    [id]                      BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]              VARCHAR (255) NULL,
    [created_on]              DATETIME2 (7) NULL,
    [last_modified_by]        VARCHAR (255) NULL,
    [last_modified_on]        DATETIME2 (7) NULL,
    [version]                 INT           NULL,
    [template_id]             VARCHAR (255) NULL,
    [non_conformance_type_id] BIGINT        NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK__non_confo__non_c__59FA5E80] FOREIGN KEY ([non_conformance_type_id]) REFERENCES [ncr].[non_conformance_type] ([id])
);

