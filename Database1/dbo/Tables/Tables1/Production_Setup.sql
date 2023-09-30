CREATE TABLE [dbo].[Production_Setup] (
    [PP_Setup_Id]                  INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Actual_Bad_Items]             INT           NULL,
    [Actual_Bad_Quantity]          FLOAT (53)    NULL,
    [Actual_Down_Time]             FLOAT (53)    NULL,
    [Actual_End_Time]              DATETIME      NULL,
    [Actual_Good_Items]            INT           NULL,
    [Actual_Good_Quantity]         FLOAT (53)    NULL,
    [Actual_Repetitions]           INT           NULL,
    [Actual_Running_Time]          FLOAT (53)    NULL,
    [Actual_Start_Time]            DATETIME      NULL,
    [Alarm_Count]                  INT           NULL,
    [Base_Dimension_A]             REAL          NULL,
    [Base_Dimension_X]             REAL          NULL,
    [Base_Dimension_Y]             REAL          NULL,
    [Base_Dimension_Z]             REAL          NULL,
    [Base_General_1]               REAL          NULL,
    [Base_General_2]               REAL          NULL,
    [Base_General_3]               REAL          NULL,
    [Base_General_4]               REAL          NULL,
    [Comment_Id]                   INT           NULL,
    [Entry_On]                     DATETIME      NULL,
    [Extended_Info]                VARCHAR (255) NULL,
    [Forecast_Quantity]            FLOAT (53)    NULL,
    [Implied_Sequence]             INT           NULL,
    [Late_Items]                   INT           NULL,
    [Parent_PP_Setup_Id]           INT           NULL,
    [Pattern_Code]                 VARCHAR (25)  NULL,
    [Pattern_Repititions]          INT           NULL,
    [PP_Id]                        INT           NOT NULL,
    [PP_Status_Id]                 INT           NOT NULL,
    [Predicted_Remaining_Duration] FLOAT (53)    NULL,
    [Predicted_Remaining_Quantity] FLOAT (53)    NULL,
    [Predicted_Total_Duration]     FLOAT (53)    NULL,
    [Shrinkage]                    REAL          NULL,
    [User_General_1]               VARCHAR (255) NULL,
    [User_General_2]               VARCHAR (255) NULL,
    [User_General_3]               VARCHAR (255) NULL,
    [User_Id]                      INT           NULL,
    CONSTRAINT [Production_Setup_PK_PPSetupId] PRIMARY KEY CLUSTERED ([PP_Setup_Id] ASC),
    CONSTRAINT [FK_ProductionSetup_PPStatus] FOREIGN KEY ([PP_Status_Id]) REFERENCES [dbo].[Production_Plan_Statuses] ([PP_Status_Id]),
    CONSTRAINT [Production_Setup_FK_PPId] FOREIGN KEY ([PP_Id]) REFERENCES [dbo].[Production_Plan] ([PP_Id]),
    CONSTRAINT [Production_Setup_UC_PPIdPatternCode] UNIQUE NONCLUSTERED ([PP_Id] ASC, [Pattern_Code] ASC)
);


GO
CREATE NONCLUSTERED INDEX [productionsetup_IX_PPIdImpliedSequence]
    ON [dbo].[Production_Setup]([PP_Id] ASC, [Implied_Sequence] ASC);


GO
CREATE NONCLUSTERED INDEX [ProductionSetup_IDX_PPId]
    ON [dbo].[Production_Setup]([PP_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [ProductionSetup_IDX_ParentPPSetupId]
    ON [dbo].[Production_Setup]([Parent_PP_Setup_Id] ASC);


GO
CREATE TRIGGER [dbo].[Production_Setup_History_Upd]
 ON  [dbo].[Production_Setup]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 419
 If (@Populate_History = 1) and ( Update(Base_Dimension_A) or Update(Base_Dimension_X) or Update(Base_Dimension_Y) or Update(Base_Dimension_Z) or Update(Base_General_1) or Update(Base_General_2) or Update(Base_General_3) or Update(Base_General_4) or Update(Comment_Id) or Update(Entry_On) or Update(Extended_Info) or Update(Forecast_Quantity) or Update(Parent_PP_Setup_Id) or Update(Pattern_Code) or Update(Pattern_Repititions) or Update(PP_Id) or Update(PP_Setup_Id) or Update(PP_Status_Id) or Update(Shrinkage) or Update(User_General_1) or Update(User_General_2) or Update(User_General_3) or Update(User_Id)) 
   Begin
 	  	   Insert Into Production_Setup_History
 	  	   (Base_Dimension_A,Base_Dimension_X,Base_Dimension_Y,Base_Dimension_Z,Base_General_1,Base_General_2,Base_General_3,Base_General_4,Comment_Id,Entry_On,Extended_Info,Forecast_Quantity,Parent_PP_Setup_Id,Pattern_Code,Pattern_Repititions,PP_Id,PP_Setup_Id,PP_Status_Id,Shrinkage,User_General_1,User_General_2,User_General_3,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Base_Dimension_A,a.Base_Dimension_X,a.Base_Dimension_Y,a.Base_Dimension_Z,a.Base_General_1,a.Base_General_2,a.Base_General_3,a.Base_General_4,a.Comment_Id,a.Entry_On,a.Extended_Info,a.Forecast_Quantity,a.Parent_PP_Setup_Id,a.Pattern_Code,a.Pattern_Repititions,a.PP_Id,a.PP_Setup_Id,a.PP_Status_Id,a.Shrinkage,a.User_General_1,a.User_General_2,a.User_General_3,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.Production_Setup_Del
  ON dbo.Production_Setup
  FOR DELETE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare @@Id int,
 	 @Comment_Id int
Declare Production_Setup_Del_Cursor INSENSITIVE CURSOR
  For (Select PP_Setup_Id, Comment_Id From DELETED)
  For Read Only
  Open Production_Setup_Del_Cursor  
Fetch_Loop:
  Fetch Next From Production_Setup_Del_Cursor Into @@Id, @Comment_Id 
  If (@@Fetch_Status = 0)
    Begin
      If @Comment_Id is NOT NULL 
        BEGIN
          Delete From Comments Where TopOfChain_Id = @Comment_Id 
          Delete From Comments Where Comment_Id = @Comment_Id   
        END
      Execute spServer_CmnRemoveScheduledTask @@Id,8
      Goto Fetch_Loop
    End
Close Production_Setup_Del_Cursor
Deallocate Production_Setup_Del_Cursor

GO
CREATE TRIGGER dbo.Production_Setup_Ins
  ON dbo.Production_Setup
  FOR INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare  @@Id int
Declare Production_Setup_Ins_Cursor INSENSITIVE CURSOR
  For (Select PP_Setup_Id From INSERTED)
  For Read Only
  Open Production_Setup_Ins_Cursor  
Fetch_Loop:
  Fetch Next From Production_Setup_Ins_Cursor Into @@Id
  If (@@Fetch_Status = 0)
    Begin
      Execute spServer_CmnAddScheduledTask @@Id,8
      Goto Fetch_Loop
    End
Close Production_Setup_Ins_Cursor
Deallocate Production_Setup_Ins_Cursor

GO
CREATE TRIGGER [dbo].[Production_Setup_TableFieldValue_Del]
 ON  [dbo].[Production_Setup]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.PP_Setup_Id
 WHERE tfv.TableId = 8

GO
CREATE TRIGGER dbo.Production_Setup_Upd
  ON dbo.Production_Setup
  FOR UPDATE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare @@Id int
Declare Production_Setup_Upd_Cursor INSENSITIVE CURSOR
  For (Select PP_Setup_Id From INSERTED)
  For Read Only
  Open Production_Setup_Upd_Cursor  
Fetch_Loop:
  Fetch Next From Production_Setup_Upd_Cursor Into @@Id
  If (@@Fetch_Status = 0)
    Begin
      Execute spServer_CmnAddScheduledTask @@Id,8
      Goto Fetch_Loop
    End
Close Production_Setup_Upd_Cursor
Deallocate Production_Setup_Upd_Cursor

GO
CREATE TRIGGER [dbo].[Production_Setup_History_Del]
 ON  [dbo].[Production_Setup]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 419
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Production_Setup_History
 	  	   (Base_Dimension_A,Base_Dimension_X,Base_Dimension_Y,Base_Dimension_Z,Base_General_1,Base_General_2,Base_General_3,Base_General_4,Comment_Id,Entry_On,Extended_Info,Forecast_Quantity,Parent_PP_Setup_Id,Pattern_Code,Pattern_Repititions,PP_Id,PP_Setup_Id,PP_Status_Id,Shrinkage,User_General_1,User_General_2,User_General_3,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Base_Dimension_A,a.Base_Dimension_X,a.Base_Dimension_Y,a.Base_Dimension_Z,a.Base_General_1,a.Base_General_2,a.Base_General_3,a.Base_General_4,a.Comment_Id,a.Entry_On,a.Extended_Info,a.Forecast_Quantity,a.Parent_PP_Setup_Id,a.Pattern_Code,a.Pattern_Repititions,a.PP_Id,a.PP_Setup_Id,a.PP_Status_Id,a.Shrinkage,a.User_General_1,a.User_General_2,a.User_General_3,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[Production_Setup_History_Ins]
 ON  [dbo].[Production_Setup]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 419
 If (@Populate_History = 1 or @Populate_History = 3)  and ( Update(Base_Dimension_A) or Update(Base_Dimension_X) or Update(Base_Dimension_Y) or Update(Base_Dimension_Z) or Update(Base_General_1) or Update(Base_General_2) or Update(Base_General_3) or Update(Base_General_4) or Update(Comment_Id) or Update(Entry_On) or Update(Extended_Info) or Update(Forecast_Quantity) or Update(Parent_PP_Setup_Id) or Update(Pattern_Code) or Update(Pattern_Repititions) or Update(PP_Id) or Update(PP_Setup_Id) or Update(PP_Status_Id) or Update(Shrinkage) or Update(User_General_1) or Update(User_General_2) or Update(User_General_3) or Update(User_Id)) 
   Begin
 	  	   Insert Into Production_Setup_History
 	  	   (Base_Dimension_A,Base_Dimension_X,Base_Dimension_Y,Base_Dimension_Z,Base_General_1,Base_General_2,Base_General_3,Base_General_4,Comment_Id,Entry_On,Extended_Info,Forecast_Quantity,Parent_PP_Setup_Id,Pattern_Code,Pattern_Repititions,PP_Id,PP_Setup_Id,PP_Status_Id,Shrinkage,User_General_1,User_General_2,User_General_3,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Base_Dimension_A,a.Base_Dimension_X,a.Base_Dimension_Y,a.Base_Dimension_Z,a.Base_General_1,a.Base_General_2,a.Base_General_3,a.Base_General_4,a.Comment_Id,a.Entry_On,a.Extended_Info,a.Forecast_Quantity,a.Parent_PP_Setup_Id,a.Pattern_Code,a.Pattern_Repititions,a.PP_Id,a.PP_Setup_Id,a.PP_Status_Id,a.Shrinkage,a.User_General_1,a.User_General_2,a.User_General_3,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE	TRIGGER [dbo].[Local_TgrProductionSetupIns] ON [dbo].[Production_Setup]
FOR INSERT
AS
-------------------------------------------------------------------------------
-- Date         Version Build Author  
-- 12-Apr-2005  001     001   AJudkowicz Initial Coding
-- 12-May-2005  001     004   AJ Add Product Code
-- 08-Apr-2010	DWFH - Get Production Rule From BOM_Desc
-------------------------------------------------------------------------------
DECLARE	@PreviousIdentity 	INT
-------------------------------------------------------------------------------
-- Save the current value for @@identity 
-------------------------------------------------------------------------------
SELECT	@PreviousIdentity = @@Identity 
-------------------------------------------------------------------------------
-- Add a record in the local table for each PS record 
-- being added
-------------------------------------------------------------------------------
INSERT	Local_Production_Plan_Transactions	
	(Transaction_Type,
	Process_Order,
	Path_Code,
	Forecast_Start_Date,
	Forecast_End_Date,
	BOM_Formulation_Desc,
	Product_Production_Rule_Id,
	Pattern_Code,
	Forecast_Quantity,
	PPS_PP_Status_Desc,
	PP_PP_Status_Desc,
	Product_Code,
	Source_Trigger,
	Transaction_TimeStamp,
	Processed_TimeStamp,
	Error_Code,
	Message)
	SELECT	'I',
		PP.Process_Order,
		PA.Path_Code,
		PP.Forecast_Start_Date,
		PP.Forecast_End_Date,
		BOFMF.Bom_Formulation_Desc,
		BOM.BOM_Desc,
--		CASE 
--			WHEN	CharIndex(':', BOFMF.Bom_Formulation_Desc)>0	THEN 
--				LEFT(BOFMF.Bom_Formulation_Desc, CharIndex(':', BOFMF.Bom_Formulation_Desc) -1)
--			WHEN	CharIndex(':', BOFMF.Bom_Formulation_Desc)=0 	THEN
--				Null
--		END,
		I.Pattern_Code,
		Coalesce(I.Forecast_Quantity,PP.Forecast_Quantity),
		S2.PP_Status_Desc,
		S.PP_Status_Desc,
		P.Prod_Code,
		'Local_TgrProductionSetupIns',
		GetDate(),
		Null,
		0,
		Null
	FROM	Inserted I
	JOIN	Production_Plan PP
	ON	I.PP_Id		= PP.PP_Id
	LEFT
	JOIN	PrdExec_Paths PA
	ON	PP.Path_Id		= PA.Path_Id
	LEFT
	JOIN	Bill_Of_Material_Formulation BOFMF
	ON	PP.Bom_Formulation_Id 	= BOFMF.Bom_Formulation_Id
	---------------------------------------------------------------------
	-- added to get Production Rule from BOM_Desc
	---------------------------------------------------------------------
	LEFT
	JOIN	Bill_Of_Material BOM
	ON	BOFMF.BOM_Id 	= BOM.BOM_Id
	---------------------------------------------------------------------
	LEFT
	JOIN	Production_Plan_Statuses S
	ON	PP.PP_Status_Id		= S.PP_Status_Id
	LEFT
	JOIN	Production_Plan_Statuses S2
	ON	I.PP_Status_Id		= S2.PP_Status_Id
	LEFT
	JOIN	Products P
	ON	P.Prod_Id		= PP.Prod_Id


GO
CREATE	TRIGGER [dbo].[Local_TgrProductionSetupUpd] ON [dbo].[Production_Setup]
FOR UPDATE
AS
-------------------------------------------------------------------------------
-- Date         Version Build Author  
-- 12-Apr-2005  001     001   AJudkowicz Initial Coding
-- 13-Apr-2005  001     002   AJ Change Column name
-- 14-Apr-2005  001     003   AJ Filter out irrelevant columns
-- 12-May-2005  001     004   AJ Add Product Code
-- 08-Apr-2010	DWFH - Get Production Rule From BOM_Desc
-------------------------------------------------------------------------------
DECLARE	@PreviousIdentity 	INT
-------------------------------------------------------------------------------
-- Save the current value for @@identity 
-------------------------------------------------------------------------------
SELECT	@PreviousIdentity = @@Identity 
-------------------------------------------------------------------------------
-- Go ahead only if one of these columns have been changed
-------------------------------------------------------------------------------
IF	UPDATE(Pattern_Code)
	OR	UPDATE(Forecast_Quantity)
	OR	UPDATE(PP_Status_Id)
BEGIN	
	-------------------------------------------------------------------------------
	-- Add a record in the local table for each PS record
	-- being updated
	-------------------------------------------------------------------------------
	INSERT	Local_Production_Plan_Transactions	
		(Transaction_Type,
		Process_Order,
		Path_Code,
		Forecast_Start_Date,
		Forecast_End_Date,
		BOM_Formulation_Desc,
		Product_Production_Rule_Id,
		Pattern_Code,
		Forecast_Quantity,
		PPS_PP_Status_Desc,
		PP_PP_Status_Desc,
		Product_Code,
		Source_Trigger,
		Transaction_TimeStamp,
		Processed_TimeStamp,
		Error_Code,
		Message)
		SELECT	'D',
			PP.Process_Order,
			PA.Path_Code,
			PP.Forecast_Start_Date,
			PP.Forecast_End_Date,
			BOFMF.Bom_Formulation_Desc,
			BOM.BOM_Desc,
--			CASE 
--				WHEN	CharIndex(':', BOFMF.Bom_Formulation_Desc)>0	THEN 
--					LEFT(BOFMF.Bom_Formulation_Desc, CharIndex(':', BOFMF.Bom_Formulation_Desc) -1)
--				WHEN	CharIndex(':', BOFMF.Bom_Formulation_Desc)=0 	THEN
--					Null
--			END,
			I.Pattern_Code,
			Coalesce(I.Forecast_Quantity,PP.Forecast_Quantity),
			S2.PP_Status_Desc,
			S.PP_Status_Desc,
			P.Prod_Code,
			'Local_TgrProductionSetupUpd',
			GetDate(),
			Null,
			0,
			Null
		FROM	Deleted I
		JOIN	Production_Plan PP
		ON	I.PP_Id		= PP.PP_Id
		LEFT
		JOIN	PrdExec_Paths PA
		ON	PP.Path_Id		= PA.Path_Id
		LEFT
		JOIN	Bill_Of_Material_Formulation BOFMF
		ON	PP.Bom_Formulation_Id 	= BOFMF.Bom_Formulation_Id
		---------------------------------------------------------------------
		-- added to get Production Rule from BOM_Desc
		---------------------------------------------------------------------
		LEFT
		JOIN	Bill_Of_Material BOM
		ON	BOFMF.BOM_Id 	= BOM.BOM_Id
		---------------------------------------------------------------------
		LEFT
		JOIN	Production_Plan_Statuses S
		ON	PP.PP_Status_Id		= S.PP_Status_Id
		LEFT
		JOIN	Production_Plan_Statuses S2
		ON	I.PP_Status_Id		= S2.PP_Status_Id
		LEFT
		JOIN	Products P
		ON	P.Prod_Id		= PP.Prod_Id
	
	INSERT	Local_Production_Plan_Transactions	
		(Transaction_Type,
		Process_Order,
		Path_Code,
		Forecast_Start_Date,
		Forecast_End_Date,
		BOM_Formulation_Desc,
		Product_Production_Rule_Id,
		Pattern_Code,
		Forecast_Quantity,
		PPS_PP_Status_Desc,
		PP_PP_Status_Desc,
		Product_Code,
		Source_Trigger,
		Transaction_TimeStamp,
		Processed_TimeStamp,
		Error_Code,
		Message)
		SELECT	'I',
			PP.Process_Order,
			PA.Path_Code,
			PP.Forecast_Start_Date,
			PP.Forecast_End_Date,
			BOFMF.Bom_Formulation_Desc,
			BOM.BOM_Desc,
--			CASE 
--				WHEN	CharIndex(':', BOFMF.Bom_Formulation_Desc)>0	THEN 
--					LEFT(BOFMF.Bom_Formulation_Desc, CharIndex(':', BOFMF.Bom_Formulation_Desc) -1)
--				WHEN	CharIndex(':', BOFMF.Bom_Formulation_Desc)=0 	THEN
--					Null
--			END,
			I.Pattern_Code,
			Coalesce(I.Forecast_Quantity,PP.Forecast_Quantity),
			S2.PP_Status_Desc,
			S.PP_Status_Desc,
			P.Prod_Code,
			'Local_TgrProductionSetupUpd',
			GetDate(),
			Null,
			0,
			Null
		FROM	Inserted I
		JOIN	Production_Plan PP
		ON	I.PP_Id		= PP.PP_Id
		LEFT
		JOIN	PrdExec_Paths PA
		ON	PP.Path_Id		= PA.Path_Id
		LEFT
		JOIN	Bill_Of_Material_Formulation BOFMF
		ON	PP.Bom_Formulation_Id 	= BOFMF.Bom_Formulation_Id
		---------------------------------------------------------------------
		-- added to get Production Rule from BOM_Desc
		---------------------------------------------------------------------
		LEFT
		JOIN	Bill_Of_Material BOM
		ON	BOFMF.BOM_Id 	= BOM.BOM_Id
		---------------------------------------------------------------------
		LEFT
		JOIN	Production_Plan_Statuses S
		ON	PP.PP_Status_Id		= S.PP_Status_Id
		LEFT
		JOIN	Production_Plan_Statuses S2
		ON	I.PP_Status_Id		= S2.PP_Status_Id
		LEFT
		JOIN	Products P
		ON	P.Prod_Id		= PP.Prod_Id
END

GO
CREATE	TRIGGER [dbo].[Local_TgrProductionSetupDel] ON [dbo].[Production_Setup]
FOR DELETE
AS
-------------------------------------------------------------------------------
-- Date         Version Build Author  
-- 12-Apr-2005  001     001   AJudkowicz Initial Coding
-- 13-Apr-2005  001     001   AJ Change Column name
-- 12-May-2005  001     004   AJ Add Product Code
-- 08-Apr-2010	DWFH - Get Production Rule From BOM_Desc
-------------------------------------------------------------------------------
DECLARE	@PreviousIdentity 	INT
-------------------------------------------------------------------------------
-- Save the current value for @@identity 
-------------------------------------------------------------------------------
SELECT	@PreviousIdentity = @@Identity 
-------------------------------------------------------------------------------
-- Add a record in the local table for each PS record
--  being deleted
-------------------------------------------------------------------------------
INSERT	Local_Production_Plan_Transactions	
	(Transaction_Type,
	Process_Order,
	Path_Code,
	Forecast_Start_Date,
	Forecast_End_Date,
	BOM_Formulation_Desc,
	Product_Production_Rule_Id,
	Pattern_Code,
	Forecast_Quantity,
	PPS_PP_Status_Desc,
	PP_PP_Status_Desc,
	Product_Code,
	Source_Trigger,
	Transaction_TimeStamp,
	Processed_TimeStamp,
	Error_Code,
	Message)
	SELECT	'D',
		PP.Process_Order,
		PA.Path_Code,
		PP.Forecast_Start_Date,
		PP.Forecast_End_Date,
		BOFMF.Bom_Formulation_Desc,
		BOM.BOM_Desc,
--		CASE 
--			WHEN	CharIndex(':', BOFMF.Bom_Formulation_Desc)>0	THEN 
--				LEFT(BOFMF.Bom_Formulation_Desc, CharIndex(':', BOFMF.Bom_Formulation_Desc) -1)
--			WHEN	CharIndex(':', BOFMF.Bom_Formulation_Desc)=0 	THEN
--				Null
--		END,
		I.Pattern_Code,
		Coalesce(I.Forecast_Quantity,PP.Forecast_Quantity),
		S2.PP_Status_Desc,
		S.PP_Status_Desc,
		P.Prod_Code,
		'Local_TgrProductionSetupDel',
		GetDate(),
		Null,
		0,
		Null
	FROM	Deleted I
	JOIN	Production_Plan PP
	ON	I.PP_Id		= PP.PP_Id
	LEFT
	JOIN	PrdExec_Paths PA
	ON	PP.Path_Id		= PA.Path_Id
	LEFT
	JOIN	Bill_Of_Material_Formulation BOFMF
	ON	PP.Bom_Formulation_Id 	= BOFMF.Bom_Formulation_Id
	---------------------------------------------------------------------
	-- added to get Production Rule from BOM_Desc
	---------------------------------------------------------------------
	LEFT
	JOIN	Bill_Of_Material BOM
	ON	BOFMF.BOM_Id 	= BOM.BOM_Id
	---------------------------------------------------------------------
	LEFT
	JOIN	Production_Plan_Statuses S
	ON	PP.PP_Status_Id		= S.PP_Status_Id
	LEFT
	JOIN	Production_Plan_Statuses S2
	ON	I.PP_Status_Id		= S2.PP_Status_Id
	LEFT
	JOIN	Products P
	ON	P.Prod_Id		= PP.Prod_Id
