CREATE TABLE [ncr].[non_conformance_property_value] (
    [id]                     BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]             VARCHAR (255) NULL,
    [created_on]             DATETIME2 (7) NULL,
    [last_modified_by]       VARCHAR (255) NULL,
    [last_modified_on]       DATETIME2 (7) NULL,
    [version]                INT           NULL,
    [property_definition_id] VARCHAR (255) NULL,
    [value]                  VARCHAR (255) NULL,
    [origin_id]              BIGINT        NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK__non_confo__origi__59063A47] FOREIGN KEY ([origin_id]) REFERENCES [ncr].[non_conformance] ([id])
);

