CREATE TABLE [dbo].[Language_Substitutions] (
    [Language_Data_Id]       INT          NULL,
    [Prompt_Substitution_1]  VARCHAR (50) NULL,
    [Prompt_Substitution_10] VARCHAR (50) NULL,
    [Prompt_Substitution_2]  VARCHAR (50) NULL,
    [Prompt_Substitution_3]  VARCHAR (50) NULL,
    [Prompt_Substitution_4]  VARCHAR (50) NULL,
    [Prompt_Substitution_5]  VARCHAR (50) NULL,
    [Prompt_Substitution_6]  VARCHAR (50) NULL,
    [Prompt_Substitution_7]  VARCHAR (50) NULL,
    [Prompt_Substitution_8]  VARCHAR (50) NULL,
    [Prompt_Substitution_9]  VARCHAR (50) NULL,
    CONSTRAINT [LangSubs_FK_LangDataId] FOREIGN KEY ([Language_Data_Id]) REFERENCES [dbo].[Language_Data] ([Language_Data_Id])
);

