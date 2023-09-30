CREATE TABLE [dbo].[DataModelInfo] (
    [DataModel]   NVARCHAR (255) NOT NULL,
    [Description] NVARCHAR (255) NULL,
    [Version]     BIGINT         NOT NULL,
    PRIMARY KEY CLUSTERED ([DataModel] ASC)
);

