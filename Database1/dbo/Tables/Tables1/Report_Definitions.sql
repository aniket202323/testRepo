CREATE TABLE [dbo].[Report_Definitions] (
    [Report_Id]         INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [AutoRefresh]       BIT            CONSTRAINT [DF_Report_Definitions_AutoRefresh] DEFAULT ((0)) NULL,
    [Class]             INT            NULL,
    [Description]       VARCHAR (1000) NULL,
    [File_Name]         VARCHAR (255)  NULL,
    [Image_Ext]         VARCHAR (20)   NULL,
    [Native_Ext]        VARCHAR (20)   NULL,
    [OwnerId]           INT            NULL,
    [Priority]          INT            CONSTRAINT [DF_Report_Definitions_Priority] DEFAULT ((1)) NULL,
    [Report_Name]       VARCHAR (255)  NULL,
    [Report_Type_Id]    INT            NOT NULL,
    [Security_Group_Id] INT            NULL,
    [TimeStamp]         DATETIME       NULL,
    [Xml_Data]          TEXT           NULL,
    [Xml_Version]       VARCHAR (10)   NULL,
    CONSTRAINT [ReportDefinitions_PK_ReportId] PRIMARY KEY NONCLUSTERED ([Report_Id] ASC),
    CONSTRAINT [FK_Report_Definitions_1__11] FOREIGN KEY ([Report_Type_Id]) REFERENCES [dbo].[Report_Types] ([Report_Type_Id]),
    CONSTRAINT [FK_Report_Definitions_Security_Groups] FOREIGN KEY ([Security_Group_Id]) REFERENCES [dbo].[Security_Groups] ([Group_Id]),
    CONSTRAINT [FK_Report_Definitions_Users] FOREIGN KEY ([OwnerId]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE CLUSTERED INDEX [ReportDefinitions_IDX_ReportTypeId]
    ON [dbo].[Report_Definitions]([Report_Type_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Report_Definitions_IX_Report_Name]
    ON [dbo].[Report_Definitions]([Report_Name] ASC);


GO
CREATE TRIGGER [dbo].[Report_Definitions_TableFieldValue_Del]
 ON  [dbo].[Report_Definitions]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Report_Id
 WHERE tfv.TableId = 32
