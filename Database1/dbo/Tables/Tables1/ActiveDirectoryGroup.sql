CREATE TABLE [dbo].[ActiveDirectoryGroup] (
    [AdGroupId] UNIQUEIDENTIFIER NOT NULL,
    [Name]      NVARCHAR (255)   NULL,
    [Sid]       NVARCHAR (255)   NULL,
    [Version]   BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([AdGroupId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ActiveDirectoryGroup_Name]
    ON [dbo].[ActiveDirectoryGroup]([Name] ASC);

