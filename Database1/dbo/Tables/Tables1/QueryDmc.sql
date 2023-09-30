CREATE TABLE [dbo].[QueryDmc] (
    [Id]                  NVARCHAR (255) NOT NULL,
    [DisplayName]         NVARCHAR (255) NULL,
    [QueryClassification] NVARCHAR (255) NULL,
    [InclusionClause]     NVARCHAR (MAX) NULL,
    [ExclusionClause]     NVARCHAR (MAX) NULL,
    [Description]         NVARCHAR (255) NULL,
    [Version]             BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

