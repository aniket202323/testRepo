CREATE TABLE [dbo].[Sheets] (
    [Sheet_Id]            INT                          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Auto_Label_Status]   INT                          NULL,
    [Column_Headers]      BIT                          CONSTRAINT [Sheets_DF_ColumnHeaders] DEFAULT ((0)) NOT NULL,
    [Column_Numbering]    TINYINT                      CONSTRAINT [Sheets_DF_ColumnNumbering] DEFAULT ((0)) NOT NULL,
    [Comment_Id]          INT                          NULL,
    [Display_Comment_Win] TINYINT                      CONSTRAINT [Sheets_DF_DisplayCommentWin] DEFAULT ((0)) NULL,
    [Display_Data_Source] BIT                          CONSTRAINT [Sheets_DF_DisplayDataSource] DEFAULT ((0)) NOT NULL,
    [Display_Data_Type]   BIT                          CONSTRAINT [Sheets_DF_DisplayDataType] DEFAULT ((0)) NOT NULL,
    [Display_Date]        BIT                          CONSTRAINT [Sheets_DF_DisplayDate] DEFAULT ((1)) NOT NULL,
    [Display_Description] BIT                          CONSTRAINT [Sheets_DF_DisplayDesc] DEFAULT ((1)) NOT NULL,
    [Display_EngU]        BIT                          CONSTRAINT [Sheets_DF_DisplayEngUnits] DEFAULT ((0)) NOT NULL,
    [Display_Event]       BIT                          CONSTRAINT [Sheets_DF_DisplayEvent] DEFAULT ((1)) NOT NULL,
    [Display_Grade]       BIT                          CONSTRAINT [Sheets_DF_DisplayGrade] DEFAULT ((1)) NOT NULL,
    [Display_Prod_Line]   BIT                          CONSTRAINT [Sheets_DF_DisplayProdLine] DEFAULT ((0)) NOT NULL,
    [Display_Prod_Unit]   BIT                          CONSTRAINT [Sheets_DF_DisplayProdUnit] DEFAULT ((0)) NOT NULL,
    [Display_Spec]        BIT                          CONSTRAINT [Sheets_DF_DisplaySpec] DEFAULT ((0)) NOT NULL,
    [Display_Spec_Column] TINYINT                      NULL,
    [Display_Spec_Win]    TINYINT                      CONSTRAINT [Sheets_DF_DisplaySpecWin] DEFAULT ((0)) NULL,
    [Display_Time]        BIT                          CONSTRAINT [Sheets_DF_DisplayTime] DEFAULT ((1)) NOT NULL,
    [Display_Var_Order]   BIT                          CONSTRAINT [Sheets_DF_DisplayOrder] DEFAULT ((0)) NOT NULL,
    [Dynamic_Rows]        TINYINT                      CONSTRAINT [Sheets_DF_Dynamic_Rows] DEFAULT ((0)) NULL,
    [Event_Prompt]        [dbo].[Varchar_Event_Prompt] NULL,
    [Event_Subtype_Id]    INT                          NULL,
    [Event_Type]          TINYINT                      NOT NULL,
    [External_Link]       [dbo].[Varchar_Ext_Link]     NULL,
    [Group_Id]            INT                          NULL,
    [Initial_Count]       [dbo].[Int_Natural]          CONSTRAINT [Sheets_DF_InitialCount] DEFAULT ((24)) NOT NULL,
    [Interval]            [dbo].[Smallint_Offset]      CONSTRAINT [Sheets_DF_Interval] DEFAULT ((0)) NOT NULL,
    [Is_Active]           BIT                          CONSTRAINT [Sheets_DF_IsActive] DEFAULT ((0)) NOT NULL,
    [Master_Unit]         INT                          NULL,
    [Max_Edit_Hours]      INT                          NULL,
    [Max_Inventory_Days]  INT                          CONSTRAINT [Sheets_DF_MaxInvDays] DEFAULT ((0)) NULL,
    [Maximum_Count]       [dbo].[Int_Natural]          CONSTRAINT [Sheets_DF_MaximumCount] DEFAULT ((24)) NOT NULL,
    [Offset]              [dbo].[Smallint_Offset]      CONSTRAINT [Sheets_DF_Offset] DEFAULT ((0)) NOT NULL,
    [PEI_Id]              INT                          NULL,
    [PL_Id]               INT                          NULL,
    [Row_Headers]         BIT                          CONSTRAINT [Sheets_DF_RowHeaders] DEFAULT ((0)) NOT NULL,
    [Row_Numbering]       TINYINT                      CONSTRAINT [Sheets_DF_RowNumbering] DEFAULT ((0)) NOT NULL,
    [Sheet_Desc_Global]   [dbo].[Varchar_Desc]         NULL,
    [Sheet_Desc_Local]    [dbo].[Varchar_Desc]         NOT NULL,
    [Sheet_Group_Id]      INT                          CONSTRAINT [Sheets_DF_SheetGrpId] DEFAULT ((1)) NULL,
    [Sheet_Type]          TINYINT                      NULL,
    [Wrap_Product]        TINYINT                      NULL,
    [Sheet_Desc]          AS                           (case when (@@options&(512))=(0) then isnull([Sheet_Desc_Global],[Sheet_Desc_Local]) else [Sheet_Desc_Local] end),
    CONSTRAINT [Sheets_PK_ShtId] PRIMARY KEY CLUSTERED ([Sheet_Id] ASC),
    CONSTRAINT [Sheets_CC_IntervalOffset] CHECK ([Interval]>(0) OR [Offset]=(0)),
    CONSTRAINT [Sheets_FK_EventSubTypeId] FOREIGN KEY ([Event_Subtype_Id]) REFERENCES [dbo].[Event_Subtypes] ([Event_Subtype_Id]),
    CONSTRAINT [Sheets_FK_MasterUnit] FOREIGN KEY ([Master_Unit]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [Sheets_FK_PEIId] FOREIGN KEY ([PEI_Id]) REFERENCES [dbo].[PrdExec_Inputs] ([PEI_Id]),
    CONSTRAINT [Sheets_FK_PLId] FOREIGN KEY ([PL_Id]) REFERENCES [dbo].[Prod_Lines_Base] ([PL_Id]),
    CONSTRAINT [Sheets_FK_SheetGrpId] FOREIGN KEY ([Sheet_Group_Id]) REFERENCES [dbo].[Sheet_Groups] ([Sheet_Group_Id]),
    CONSTRAINT [Sheets_UC_SheetDescLocal] UNIQUE NONCLUSTERED ([Sheet_Desc_Local] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Ix_Sheets_Acitive_Type_sheetId_PUID]
    ON [dbo].[Sheets]([Is_Active] ASC, [Sheet_Type] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Sheets_By_DescriptionLocal]
    ON [dbo].[Sheets]([Sheet_Desc_Local] ASC);


GO
CREATE TRIGGER [dbo].[fnBF_ApiFindAvailableUnitsAndEventTypes_Sheets_Sync]
  	  ON [dbo].[Sheets]
  	  FOR INSERT, UPDATE, DELETE
AS  	  
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
UPDATE SITE_Parameters SET [Value] = 1 where parm_Id = 700 and [Value]=0;

GO
CREATE TRIGGER dbo.Sheets_Del ON dbo.Sheets 
FOR DELETE 
AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE Sheets_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN Sheets_Del_Cursor 
--
--
Fetch_Sheets_Del:
FETCH NEXT FROM Sheets_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
    Delete From Comments Where TopOfChain_Id = @Comment_Id 
    Delete From Comments Where Comment_Id = @Comment_Id 
    GOTO Fetch_Sheets_Del
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in Sheets_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE Sheets_Del_Cursor 

GO
Create  TRIGGER dbo.Sheets_Reload_InsUpdDel
 	 ON dbo.Sheets
 	 FOR INSERT, UPDATE, DELETE
 	 AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 	 Declare @ShouldReload Int
 	 Select @ShouldReload = sp.Value 
 	  	 From Parameters p
 	  	 Join Site_Parameters sp on p.Parm_Id = sp.Parm_Id
 	  	 Where Parm_Name = 'Perform automatic service reloads'
 	 If @ShouldReload is null or @ShouldReload = 0 
 	  	 Return
/*
2  -Database Mgr
4  -Event Mgr
5  -Reader
6  -Writer
7  -Summary Mgr
8  -Stubber
9  -Message Bus
14 -Gateway
16 -Email Engine
17 -Alarm Manager
18 -FTP Engine
19 -Calculation Manager
20 -Print Server
22 -Schedule Mgr
*/
Update cxs_service set Should_Reload_Timestamp = DateAdd(minute,5,dbo.fnServer_CmnGetDate(getUTCdate())) where Service_Id in (8)
