CREATE TABLE [dbo].[Language_Data] (
    [Language_Data_Id] INT             IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Language_Id]      INT             NOT NULL,
    [Prompt_Number]    INT             NOT NULL,
    [Prompt_String]    NVARCHAR (4000) NULL,
    CONSTRAINT [LangData_PK_LangDataId] PRIMARY KEY NONCLUSTERED ([Language_Data_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [LangData_IDX_LangIdPromptNum]
    ON [dbo].[Language_Data]([Language_Id] ASC, [Prompt_Number] ASC);

