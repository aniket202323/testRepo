CREATE TABLE [dbo].[Local_SSI_ErrorCodeMapping] (
    [ECM_Id]      INT           IDENTITY (1, 1) NOT NULL,
    [App_Name]    VARCHAR (100) NOT NULL,
    [Object_Name] VARCHAR (256) NOT NULL,
    [Error_Code]  INT           NOT NULL,
    [Prompt_Id]   INT           NOT NULL,
    CONSTRAINT [LocalSSIErrorCodeMapping_PK_ECMId] PRIMARY KEY CLUSTERED ([ECM_Id] ASC)
);

