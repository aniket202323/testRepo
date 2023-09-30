CREATE TABLE [dbo].[ActiveDirectoryChildGroup] (
    [AdChildGroupId] UNIQUEIDENTIFIER NOT NULL,
    [Name]           NVARCHAR (255)   NULL,
    [Sid]            NVARCHAR (255)   NULL,
    [Version]        BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([AdChildGroupId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_ActiveDirectoryChildGroup_Name]
    ON [dbo].[ActiveDirectoryChildGroup]([Name] ASC);

