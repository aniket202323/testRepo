CREATE TABLE [dbo].[Report_Runs] (
    [Run_Id]      INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [End_Time]    DATETIME      NULL,
    [Engine_Id]   INT           NULL,
    [Error_Id]    INT           CONSTRAINT [DF_Report_Runs_Error_Id] DEFAULT ((0)) NULL,
    [File_Name]   VARCHAR (255) NULL,
    [Last_Result] INT           CONSTRAINT [DF_Report_Runs_Last_Result] DEFAULT ((0)) NULL,
    [Report_Id]   INT           NOT NULL,
    [Schedule_Id] INT           NULL,
    [Start_Time]  DATETIME      NULL,
    [Status]      INT           CONSTRAINT [DF_Report_Runs_Status] DEFAULT ((3)) NULL,
    [User_Id]     INT           NULL,
    CONSTRAINT [PK___1__11] PRIMARY KEY CLUSTERED ([Run_Id] ASC),
    CONSTRAINT [FK_Report_Runs_Report_Engines] FOREIGN KEY ([Engine_Id]) REFERENCES [dbo].[Report_Engines] ([Engine_Id]),
    CONSTRAINT [ReportRuns_FK_ReportId] FOREIGN KEY ([Report_Id]) REFERENCES [dbo].[Report_Definitions] ([Report_Id])
);


GO
CREATE TRIGGER [dbo].[Report_Runs_TableFieldValue_Del]
 ON  [dbo].[Report_Runs]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Run_Id
 WHERE tfv.TableId = 33
