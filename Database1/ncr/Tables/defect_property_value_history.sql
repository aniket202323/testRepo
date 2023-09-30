CREATE TABLE [ncr].[defect_property_value_history] (
    [id]                       BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]               VARCHAR (255) NULL,
    [created_on]               DATETIME2 (7) NULL,
    [last_modified_by]         VARCHAR (255) NULL,
    [last_modified_on]         DATETIME2 (7) NULL,
    [version]                  INT           NULL,
    [property_definition_id]   VARCHAR (255) NULL,
    [value]                    VARCHAR (255) NULL,
    [column_updated_bitmask]   VARCHAR (15)  NULL,
    [dbtt_id]                  INT           NULL,
    [defect_property_value_id] BIGINT        NULL,
    [modified_on]              DATETIME2 (7) NULL,
    [origin_id]                BIGINT        NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK__defect_pr__defec__4F7CD00D] FOREIGN KEY ([defect_property_value_id]) REFERENCES [ncr].[defect_property_value] ([id])
);

