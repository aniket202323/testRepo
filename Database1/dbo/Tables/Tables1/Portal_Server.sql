CREATE TABLE [dbo].[Portal_Server] (
    [Id]                  UNIQUEIDENTIFIER NOT NULL,
    [Name]                NVARCHAR (255)   NOT NULL,
    [Port]                BIGINT           NULL,
    [Description]         NVARCHAR (255)   NULL,
    [DefaultUser]         NVARCHAR (255)   NULL,
    [DefaultUserPassword] NVARCHAR (255)   NULL,
    [DefaultUserDomain]   NVARCHAR (255)   NULL,
    [Url]                 NVARCHAR (255)   NULL,
    [Version]             BIGINT           NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Portal_Server_Name]
    ON [dbo].[Portal_Server]([Name] ASC);

