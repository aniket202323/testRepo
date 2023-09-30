CREATE TABLE [dbo].[Report_Types] (
    [Report_Type_Id]       INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Class_Name]           VARCHAR (255) NOT NULL,
    [Date_Saved]           DATETIME      NULL,
    [Date_Tested_Locally]  DATETIME      NULL,
    [Date_Tested_Remotely] DATETIME      NULL,
    [Description]          VARCHAR (255) NOT NULL,
    [Detail_Desc]          VARCHAR (255) NULL,
    [ForceRunMode]         TINYINT       NULL,
    [Image_Ext]            VARCHAR (20)  NULL,
    [Is_Addin]             BIT           NULL,
    [MinVersion]           VARCHAR (10)  NULL,
    [Native_Ext]           VARCHAR (20)  NULL,
    [OwnerId]              INT           NULL,
    [Security_Group_Id]    INT           NULL,
    [Send_Parameters]      TINYINT       CONSTRAINT [ReportTypes_DF_SendParameters] DEFAULT ((0)) NULL,
    [SPName]               VARCHAR (255) NULL,
    [Template_File]        IMAGE         NULL,
    [Template_File_Name]   VARCHAR (255) NULL,
    [Template_Path]        VARCHAR (255) NOT NULL,
    [Version]              INT           NULL,
    CONSTRAINT [PK___4__27] PRIMARY KEY CLUSTERED ([Report_Type_Id] ASC),
    CONSTRAINT [FK_Report_Types_Security_Groups] FOREIGN KEY ([Security_Group_Id]) REFERENCES [dbo].[Security_Groups] ([Group_Id]),
    CONSTRAINT [FK_Report_Types_Users] FOREIGN KEY ([OwnerId]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [IX_Report_Types] UNIQUE NONCLUSTERED ([Description] ASC)
);


GO
CREATE TRIGGER [dbo].[Report_Types_TableFieldValue_Del]
 ON  [dbo].[Report_Types]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Report_Type_Id
 WHERE tfv.TableId = 31
