CREATE TABLE [dbo].[Local_SSI_ErrorSeverityLevel] (
    [Severity_Level_Id]   INT          IDENTITY (1, 1) NOT NULL,
    [Severity_Level_Desc] VARCHAR (25) NULL,
    [EG_Id]               INT          NULL,
    [Report_Frequency]    INT          NULL,
    [Last_Report_Time]    DATETIME     NULL,
    CONSTRAINT [LocalSSIErrorSeverityLevel_PK_SeverityLevelId] PRIMARY KEY CLUSTERED ([Severity_Level_Id] ASC)
);

