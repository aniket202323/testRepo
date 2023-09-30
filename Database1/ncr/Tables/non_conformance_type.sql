CREATE TABLE [ncr].[non_conformance_type] (
    [id]                         BIGINT         IDENTITY (1, 1) NOT NULL,
    [created_by]                 VARCHAR (255)  NULL,
    [created_on]                 DATETIME2 (7)  NULL,
    [last_modified_by]           VARCHAR (255)  NULL,
    [last_modified_on]           DATETIME2 (7)  NULL,
    [version]                    INT            NULL,
    [deleted]                    BIT            NULL,
    [defect_cause_tree_id]       VARCHAR (255)  NULL,
    [description]                VARCHAR (1000) NULL,
    [display_name]               VARCHAR (255)  NULL,
    [disposition_action_tree_id] VARCHAR (255)  NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [U_NN_CTYP_DISPLAY_NAME] UNIQUE NONCLUSTERED ([display_name] ASC)
);

