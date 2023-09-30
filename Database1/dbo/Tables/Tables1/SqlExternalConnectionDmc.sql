CREATE TABLE [dbo].[SqlExternalConnectionDmc] (
    [ConnectionName]   NVARCHAR (255)  NOT NULL,
    [ConnectionString] NVARCHAR (4000) NULL,
    [Description]      NVARCHAR (255)  NULL,
    [ConnectionType]   NVARCHAR (255)  NULL,
    [Version]          BIGINT          NULL,
    PRIMARY KEY CLUSTERED ([ConnectionName] ASC)
);

