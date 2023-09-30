CREATE TABLE [ncr].[defect_template] (
    [id]               BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]       VARCHAR (255) NULL,
    [created_on]       DATETIME2 (7) NULL,
    [last_modified_by] VARCHAR (255) NULL,
    [last_modified_on] DATETIME2 (7) NULL,
    [version]          INT           NULL,
    [template_id]      VARCHAR (255) NULL,
    [defect_type_id]   BIGINT        NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK__defect_te__defec__5070F446] FOREIGN KEY ([defect_type_id]) REFERENCES [ncr].[defect_type] ([id])
);

