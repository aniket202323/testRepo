CREATE TABLE [dbo].[Local_PG_SQLObjectsVersions] (
    [Object_Id]   INT             IDENTITY (1, 1) NOT NULL,
    [Object_Name] VARCHAR (255)   NOT NULL,
    [Version]     VARCHAR (50)    NOT NULL,
    [SVN_User]    VARCHAR (50)    NOT NULL,
    [Message]     NVARCHAR (4000) NOT NULL,
    [Last_Commit] DATETIME        NOT NULL,
    [App_Id]      INT             NULL,
    CONSTRAINT [LocalPGSQLObjectsVersions_PK_ObjectId] PRIMARY KEY CLUSTERED ([Object_Id] ASC)
);

