CREATE TABLE [dbo].[Language_Application_Data] (
    [App_Id]           INT NOT NULL,
    [Prompt_Number]    INT NOT NULL,
    [Lang_App_Data_Id] INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    CONSTRAINT [LangAppData_PK_AppIdPromptNum] PRIMARY KEY NONCLUSTERED ([App_Id] ASC, [Prompt_Number] ASC)
);

