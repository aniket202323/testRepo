CREATE TABLE [dbo].[Language_Data_Client] (
    [Language_Data_Client_Id] INT             IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [App_Id]                  INT             NOT NULL,
    [Language_Id]             INT             NOT NULL,
    [Prompt_Number]           INT             NOT NULL,
    [Prompt_String]           NVARCHAR (4000) NULL,
    CONSTRAINT [LangData_PK_LangDataClientId] PRIMARY KEY NONCLUSTERED ([Language_Data_Client_Id] ASC),
    CONSTRAINT [LanguageDataClient_FK_AppVersions] FOREIGN KEY ([App_Id]) REFERENCES [dbo].[AppVersions] ([App_Id])
);

