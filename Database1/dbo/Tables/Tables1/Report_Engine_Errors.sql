CREATE TABLE [dbo].[Report_Engine_Errors] (
    [Error_Id]    INT NOT NULL,
    [Response_Id] INT NOT NULL,
    CONSTRAINT [PK_Report_Engine_Errors] PRIMARY KEY NONCLUSTERED ([Error_Id] ASC)
);

