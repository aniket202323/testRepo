CREATE TABLE [dbo].[Test_Status] (
    [Testing_Status]      INT                  NOT NULL,
    [Testing_Status_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [TestStatus_PK_TestingStatus] PRIMARY KEY CLUSTERED ([Testing_Status] ASC)
);

