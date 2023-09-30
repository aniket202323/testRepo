CREATE TABLE [dbo].[Event_Configuration] (
    [EC_Id]                 INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]            INT           NULL,
    [Debug]                 BIT           CONSTRAINT [DF__event_con__Debug__7CA54796] DEFAULT ((0)) NULL,
    [EC_Desc]               VARCHAR (50)  NULL,
    [ED_Model_Id]           INT           NULL,
    [ESignature_Level]      INT           NULL,
    [ET_Id]                 TINYINT       NULL,
    [Event_Subtype_Id]      INT           NULL,
    [Exclusions]            VARCHAR (255) NULL,
    [Extended_Info]         VARCHAR (255) NULL,
    [External_Time_Zone]    VARCHAR (100) NULL,
    [Is_Active]             TINYINT       CONSTRAINT [EventCfg_DF_IsActive] DEFAULT ((0)) NOT NULL,
    [Is_Calculation_Active] TINYINT       NULL,
    [Max_Run_Time]          INT           NULL,
    [Model_Group]           INT           NULL,
    [PEI_Id]                INT           NULL,
    [Priority]              INT           NULL,
    [PU_Id]                 INT           NOT NULL,
    [Retention_Limit]       INT           NULL,
    [Move_EndTime_Interval] INT           NULL,
    CONSTRAINT [EventCfg_PK_ECId] PRIMARY KEY NONCLUSTERED ([EC_Id] ASC),
    CONSTRAINT [EventCfg_FK_ETId] FOREIGN KEY ([ET_Id]) REFERENCES [dbo].[Event_Types] ([ET_Id]),
    CONSTRAINT [EventCfg_FK_ModelId] FOREIGN KEY ([ED_Model_Id]) REFERENCES [dbo].[ED_Models] ([ED_Model_Id]),
    CONSTRAINT [EventCfg_FK_PEIId] FOREIGN KEY ([PEI_Id]) REFERENCES [dbo].[PrdExec_Inputs] ([PEI_Id]),
    CONSTRAINT [EventCfg_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [EventCfg_FK_SubtypeId] FOREIGN KEY ([Event_Subtype_Id]) REFERENCES [dbo].[Event_Subtypes] ([Event_Subtype_Id])
);


GO
CREATE CLUSTERED INDEX [EventCfg_IX_PUIDETID]
    ON [dbo].[Event_Configuration]([PU_Id] ASC, [ET_Id] ASC);


GO
CREATE TRIGGER [dbo].[Event_Configuration_History_Ins]
 ON  [dbo].[Event_Configuration]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 430
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Event_Configuration_History
 	  	   (Comment_Id,Debug,EC_Desc,EC_Id,ED_Model_Id,ESignature_Level,ET_Id,Event_Subtype_Id,Exclusions,Extended_Info,External_Time_Zone,Is_Active,Is_Calculation_Active,Max_Run_Time,Model_Group,Move_EndTime_Interval,PEI_Id,Priority,PU_Id,Retention_Limit,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Debug,a.EC_Desc,a.EC_Id,a.ED_Model_Id,a.ESignature_Level,a.ET_Id,a.Event_Subtype_Id,a.Exclusions,a.Extended_Info,a.External_Time_Zone,a.Is_Active,a.Is_Calculation_Active,a.Max_Run_Time,a.Model_Group,a.Move_EndTime_Interval,a.PEI_Id,a.Priority,a.PU_Id,a.Retention_Limit,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[fnBF_ApiFindAvailableUnitsAndEventTypes_EVENT_Configuration_Sync]
  	  ON [dbo].[EVENT_Configuration]
  	  FOR INSERT, UPDATE, DELETE
AS  	  
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
UPDATE SITE_Parameters SET [Value] = 1 where parm_Id = 700 and [Value]=0;

GO
CREATE TRIGGER [dbo].[Event_Configuration_History_Del]
 ON  [dbo].[Event_Configuration]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 430
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Event_Configuration_History
 	  	   (Comment_Id,Debug,EC_Desc,EC_Id,ED_Model_Id,ESignature_Level,ET_Id,Event_Subtype_Id,Exclusions,Extended_Info,External_Time_Zone,Is_Active,Is_Calculation_Active,Max_Run_Time,Model_Group,Move_EndTime_Interval,PEI_Id,Priority,PU_Id,Retention_Limit,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Debug,a.EC_Desc,a.EC_Id,a.ED_Model_Id,a.ESignature_Level,a.ET_Id,a.Event_Subtype_Id,a.Exclusions,a.Extended_Info,a.External_Time_Zone,a.Is_Active,a.Is_Calculation_Active,a.Max_Run_Time,a.Model_Group,a.Move_EndTime_Interval,a.PEI_Id,a.Priority,a.PU_Id,a.Retention_Limit,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER dbo.Event_Configuration_Del ON dbo.Event_Configuration
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE Event_Configuration_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN Event_Configuration_Del_Cursor 
--
--
Fetch_Next_Event_Configuration:
FETCH NEXT FROM Event_Configuration_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
    Delete From Comments Where TopOfChain_Id = @Comment_Id 
    Delete From Comments Where Comment_Id = @Comment_Id 
    GOTO Fetch_Next_Event_Configuration
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in Event_Configuration_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE Event_Configuration_Del_Cursor 

GO
CREATE TRIGGER [dbo].[Event_Configuration_History_Upd]
 ON  [dbo].[Event_Configuration]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 430
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Event_Configuration_History
 	  	   (Comment_Id,Debug,EC_Desc,EC_Id,ED_Model_Id,ESignature_Level,ET_Id,Event_Subtype_Id,Exclusions,Extended_Info,External_Time_Zone,Is_Active,Is_Calculation_Active,Max_Run_Time,Model_Group,Move_EndTime_Interval,PEI_Id,Priority,PU_Id,Retention_Limit,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Comment_Id,a.Debug,a.EC_Desc,a.EC_Id,a.ED_Model_Id,a.ESignature_Level,a.ET_Id,a.Event_Subtype_Id,a.Exclusions,a.Extended_Info,a.External_Time_Zone,a.Is_Active,a.Is_Calculation_Active,a.Max_Run_Time,a.Model_Group,a.Move_EndTime_Interval,a.PEI_Id,a.Priority,a.PU_Id,a.Retention_Limit,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
