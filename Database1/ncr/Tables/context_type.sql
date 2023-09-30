CREATE TABLE [ncr].[context_type] (
    [id]               BIGINT        IDENTITY (1, 1) NOT NULL,
    [created_by]       VARCHAR (255) NULL,
    [created_on]       DATETIME2 (7) NULL,
    [last_modified_by] VARCHAR (255) NULL,
    [last_modified_on] DATETIME2 (7) NULL,
    [version]          INT           NULL,
    [deleted]          BIT           NULL,
    [display_name]     VARCHAR (255) NULL,
    [name]             VARCHAR (255) NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [U_CNTXTYP_DISPLAY_NAME] UNIQUE NONCLUSTERED ([display_name] ASC),
    CONSTRAINT [U_CNTXTYP_NAME] UNIQUE NONCLUSTERED ([name] ASC)
);

