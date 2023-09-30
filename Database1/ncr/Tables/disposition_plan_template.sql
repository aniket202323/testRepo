CREATE TABLE [ncr].[disposition_plan_template] (
    [id]               BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]       VARCHAR (255) NULL,
    [created_on]       DATETIME2 (7) NULL,
    [last_modified_by] VARCHAR (255) NULL,
    [last_modified_on] DATETIME2 (7) NULL,
    [version]          INT           NULL,
    [template_id]      VARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

