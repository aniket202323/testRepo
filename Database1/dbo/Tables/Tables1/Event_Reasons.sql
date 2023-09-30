CREATE TABLE [dbo].[Event_Reasons] (
    [Event_Reason_Id]          INT                      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]               INT                      NULL,
    [Comment_Required]         TINYINT                  CONSTRAINT [Evt_Rsns_DF_CmntReq] DEFAULT ((0)) NOT NULL,
    [Event_Reason_Code]        VARCHAR (10)             NULL,
    [Event_Reason_Order]       INT                      NULL,
    [External_Link]            [dbo].[Varchar_Ext_Link] NULL,
    [Group_Id]                 INT                      NULL,
    [Event_Reason_Name_Global] VARCHAR (100)            NULL,
    [Event_Reason_Name_Local]  VARCHAR (100)            NOT NULL,
    [Event_Reason_Name]        AS                       (case when (@@options&(512))=(0) then isnull([Event_Reason_Name_Global],[Event_Reason_Name_Local]) else [Event_Reason_Name_Local] end),
    CONSTRAINT [Evt_Rsns_PK_EventReasonId] PRIMARY KEY CLUSTERED ([Event_Reason_Id] ASC),
    CONSTRAINT [Event_Reasons_UC_NameLocal] UNIQUE NONCLUSTERED ([Event_Reason_Name_Local] ASC)
);


GO
CREATE TRIGGER [dbo].[Event_Reasons_TableFieldValue_Del]
 ON  [dbo].[Event_Reasons]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Event_Reason_Id
 WHERE tfv.TableId = 24
