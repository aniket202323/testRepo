CREATE TABLE [dbo].[Production_Plan] (
    [PP_Id]                        INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Actual_Bad_Items]             INT           NULL,
    [Actual_Bad_Quantity]          FLOAT (53)    NULL,
    [Actual_Down_Time]             FLOAT (53)    NULL,
    [Actual_End_Time]              DATETIME      NULL,
    [Actual_Good_Items]            INT           NULL,
    [Actual_Good_Quantity]         FLOAT (53)    NULL,
    [Actual_Repetitions]           INT           NULL,
    [Actual_Running_Time]          FLOAT (53)    NULL,
    [Actual_Start_Time]            DATETIME      NULL,
    [Adjusted_Quantity]            FLOAT (53)    NULL,
    [Alarm_Count]                  INT           NULL,
    [Block_Number]                 VARCHAR (50)  NULL,
    [BOM_Formulation_Id]           BIGINT        NULL,
    [Comment_Id]                   INT           NULL,
    [Control_Type]                 TINYINT       CONSTRAINT [ProductionPlan_DF_ControlType] DEFAULT ((2)) NULL,
    [Entry_On]                     DATETIME      NOT NULL,
    [Extended_Info]                VARCHAR (255) NULL,
    [Forecast_End_Date]            DATETIME      NULL,
    [Forecast_Quantity]            FLOAT (53)    NULL,
    [Forecast_Start_Date]          DATETIME      NULL,
    [Implied_Sequence]             INT           NULL,
    [Late_Items]                   INT           NULL,
    [Parent_PP_Id]                 INT           NULL,
    [Path_Id]                      INT           NULL,
    [PP_Status_Id]                 INT           CONSTRAINT [Production_Plan_PP_DF_StatusId] DEFAULT ((1)) NULL,
    [PP_Type_Id]                   INT           CONSTRAINT [DF_Production_Plan_PP_Type_Id] DEFAULT ((1)) NOT NULL,
    [Predicted_Remaining_Duration] FLOAT (53)    NULL,
    [Predicted_Remaining_Quantity] FLOAT (53)    NULL,
    [Predicted_Total_Duration]     FLOAT (53)    NULL,
    [Process_Order]                VARCHAR (50)  NULL,
    [Prod_Id]                      INT           NOT NULL,
    [Production_Rate]              FLOAT (53)    NULL,
    [Source_PP_Id]                 INT           NULL,
    [User_General_1]               VARCHAR (255) NULL,
    [User_General_2]               VARCHAR (255) NULL,
    [User_General_3]               VARCHAR (255) NULL,
    [User_Id]                      INT           NOT NULL,
    [Implied_Sequence_Offset]      INT           NULL,
    CONSTRAINT [Production_Plan_PK_PPId] PRIMARY KEY CLUSTERED ([PP_Id] ASC),
    CONSTRAINT [Production_Plan_FK_PathId] FOREIGN KEY ([Path_Id]) REFERENCES [dbo].[Prdexec_Paths] ([Path_Id]),
    CONSTRAINT [Production_Plan_FK_PPStatusId] FOREIGN KEY ([PP_Status_Id]) REFERENCES [dbo].[Production_Plan_Statuses] ([PP_Status_Id]),
    CONSTRAINT [Production_Plan_FK_ProdId] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [Production_Plan_FK_UserId] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id]),
    CONSTRAINT [ProductionPlan_FK_BOMFormulationId] FOREIGN KEY ([BOM_Formulation_Id]) REFERENCES [dbo].[Bill_Of_Material_Formulation] ([BOM_Formulation_Id]),
    CONSTRAINT [ProductionPlan_FK_ControlType] FOREIGN KEY ([Control_Type]) REFERENCES [dbo].[Control_Type] ([Control_Type_Id]),
    CONSTRAINT [ProductionPlan_FK_PPTypeId] FOREIGN KEY ([PP_Type_Id]) REFERENCES [dbo].[Production_Plan_Types] ([PP_Type_Id]),
    CONSTRAINT [Production_Plan_UC_PathIdProcessOrder] UNIQUE NONCLUSTERED ([Path_Id] ASC, [Process_Order] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ProductionPlan_IDX_BOMFormulationId]
    ON [dbo].[Production_Plan]([BOM_Formulation_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [ProductionPlan_Idx_ParentPPIdProcessOrder]
    ON [dbo].[Production_Plan]([Parent_PP_Id] ASC, [Process_Order] ASC);


GO
CREATE NONCLUSTERED INDEX [productionplan_IX_PathIdImpliedSequence]
    ON [dbo].[Production_Plan]([Path_Id] ASC, [Implied_Sequence] ASC);


GO
CREATE NONCLUSTERED INDEX [ProductionPlan_IDX_PathIdStatusId]
    ON [dbo].[Production_Plan]([Path_Id] ASC, [PP_Status_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [ProductionPlan_IDX_SourcePPId]
    ON [dbo].[Production_Plan]([Source_PP_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PRODUCTIONPLAN_STATUSID_PATHID_PRODID_BOMFORMID_ORDER]
    ON [dbo].[Production_Plan]([Path_Id] ASC, [PP_Status_Id] ASC)
    INCLUDE([Actual_Bad_Items], [Actual_Bad_Quantity], [Actual_Down_Time], [Actual_End_Time], [Actual_Good_Items], [Actual_Good_Quantity], [Actual_Running_Time], [Actual_Start_Time], [Adjusted_Quantity], [Alarm_Count], [Block_Number], [Comment_Id], [Control_Type], [Entry_On], [Extended_Info], [Forecast_End_Date], [Forecast_Quantity], [Forecast_Start_Date], [Implied_Sequence], [Implied_Sequence_Offset], [PP_Type_Id], [Predicted_Remaining_Duration], [Predicted_Remaining_Quantity], [Predicted_Total_Duration], [Process_Order], [Production_Rate], [User_General_1], [User_General_2], [User_General_3], [User_Id], [BOM_Formulation_Id], [PP_Id], [Prod_Id]);


GO
CREATE TRIGGER [dbo].[Production_Plan_TableFieldValue_Del]
 ON  [dbo].[Production_Plan]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.PP_Id
 WHERE tfv.TableId = 7

GO
CREATE TRIGGER [dbo].[Production_Plan_History_Ins]
 ON  [dbo].[Production_Plan]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 402
 If (@Populate_History = 1 or @Populate_History = 3)  and ( Update(Adjusted_Quantity) or Update(Block_Number) or Update(BOM_Formulation_Id) or Update(Comment_Id) or Update(Control_Type) or Update(Entry_On) or Update(Extended_Info) or Update(Forecast_End_Date) or Update(Forecast_Quantity) or Update(Forecast_Start_Date) or Update(Parent_PP_Id) or Update(Path_Id) or Update(PP_Id) or Update(PP_Status_Id) or Update(PP_Type_Id) or Update(Process_Order) or Update(Prod_Id) or Update(Production_Rate) or Update(Source_PP_Id) or Update(User_General_1) or Update(User_General_2) or Update(User_General_3) or Update(User_Id)) 
   Begin
 	  	   Insert Into Production_Plan_History
 	  	   (Adjusted_Quantity,Block_Number,BOM_Formulation_Id,Comment_Id,Control_Type,Entry_On,Extended_Info,Forecast_End_Date,Forecast_Quantity,Forecast_Start_Date,Parent_PP_Id,Path_Id,PP_Id,PP_Status_Id,PP_Type_Id,Process_Order,Prod_Id,Production_Rate,Source_PP_Id,User_General_1,User_General_2,User_General_3,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Adjusted_Quantity,a.Block_Number,a.BOM_Formulation_Id,a.Comment_Id,a.Control_Type,a.Entry_On,a.Extended_Info,a.Forecast_End_Date,a.Forecast_Quantity,a.Forecast_Start_Date,a.Parent_PP_Id,a.Path_Id,a.PP_Id,a.PP_Status_Id,a.PP_Type_Id,a.Process_Order,a.Prod_Id,a.Production_Rate,a.Source_PP_Id,a.User_General_1,a.User_General_2,a.User_General_3,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER dbo.Production_Plan_Del
  ON dbo.Production_Plan
  FOR DELETE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare @@Id int,
 	 @Comment_Id int
Declare Production_Plan_Del_Cursor INSENSITIVE CURSOR
  For (Select PP_Id, Comment_Id From DELETED)
  For Read Only
  Open Production_Plan_Del_Cursor  
Fetch_Loop:
  Fetch Next From Production_Plan_Del_Cursor Into @@Id, @Comment_Id 
  If (@@Fetch_Status = 0)
    Begin
      If @Comment_Id is NOT NULL 
        BEGIN
          Delete From Comments Where TopOfChain_Id = @Comment_Id 
          Delete From Comments Where Comment_Id = @Comment_Id   
        END
      Execute spServer_CmnRemoveScheduledTask @@Id,7
      Goto Fetch_Loop
    End
Close Production_Plan_Del_Cursor
Deallocate Production_Plan_Del_Cursor

GO
CREATE	TRIGGER [dbo].[Local_TgrProductionPlanIns] ON [dbo].[Production_Plan]
FOR INSERT
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
-- Add a record in the local table for each PP record being added
-- no need to join to PS, because it can not have a PS
-- without PP
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
		I.Process_Order,
		PA.Path_Code,
		I.Forecast_Start_Date,
		I.Forecast_End_Date,
		BOFMF.Bom_Formulation_Desc,
		BOM.BOM_Desc,
--		CASE 
--			WHEN	CharIndex(':', BOFMF.Bom_Formulation_Desc)>0	THEN 
--				LEFT(BOFMF.Bom_Formulation_Desc, CharIndex(':', BOFMF.Bom_Formulation_Desc) -1)
--			WHEN	CharIndex(':', BOFMF.Bom_Formulation_Desc)=0 	THEN
--				Null
--		END,
		Null,
		I.Forecast_Quantity,
		Null,
		S.PP_Status_Desc,
		P.Prod_Code,
		'Local_TgrProductionPlanIns',
		GetDate(),
		Null,
		0,
		Null
	FROM	Inserted I
	LEFT
	JOIN	PrdExec_Paths PA
	ON	I.Path_Id		= PA.Path_Id
	LEFT
	JOIN	Bill_Of_Material_Formulation BOFMF
	ON	I.Bom_Formulation_Id 	= BOFMF.Bom_Formulation_Id
	---------------------------------------------------------------------
	-- added to get Production Rule from BOM_Desc
	---------------------------------------------------------------------
	LEFT
	JOIN	Bill_Of_Material BOM
	ON	BOFMF.BOM_Id 	= BOM.BOM_Id
	---------------------------------------------------------------------
	LEFT
	JOIN	Production_Plan_Statuses S
	ON	I.PP_Status_Id		= S.PP_Status_Id
	LEFT
	JOIN	Products P
	ON	P.Prod_Id		= I.Prod_Id

GO
CREATE	TRIGGER [dbo].[Local_TgrProductionPlanDel] ON [dbo].[Production_Plan]
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
-- Add a record in the local table for each PP record
-- being deleted
-- It does not have to join PS, because a PP can
-- not be deleted if there is still a PS record
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
		I.Process_Order,
		PA.Path_Code,
		I.Forecast_Start_Date,
		I.Forecast_End_Date,
		BOFMF.Bom_Formulation_Desc,
		BOM.BOM_Desc,
--		CASE 
--			WHEN	CharIndex(':', BOFMF.Bom_Formulation_Desc)>0	THEN 
--				LEFT(BOFMF.Bom_Formulation_Desc, CharIndex(':', BOFMF.Bom_Formulation_Desc) -1)
--			WHEN	CharIndex(':', BOFMF.Bom_Formulation_Desc)=0 	THEN
--				Null
--		END,
		Null,
		I.Forecast_Quantity,
		Null,
		S.PP_Status_Desc,
		P.Prod_Code,
		'Local_TgrProductionPlanDel',
		GetDate(),
		Null,
		0,
		Null
	FROM	Deleted I
	LEFT
	JOIN	PrdExec_Paths PA
	ON	I.Path_Id		= PA.Path_Id
	LEFT
	JOIN	Bill_Of_Material_Formulation BOFMF
	ON	I.Bom_Formulation_Id 	= BOFMF.Bom_Formulation_Id
	---------------------------------------------------------------------
	-- added to get Production Rule from BOM_Desc
	---------------------------------------------------------------------
	LEFT
	JOIN	Bill_Of_Material BOM
	ON	BOFMF.BOM_Id 	= BOM.BOM_Id
	---------------------------------------------------------------------
	LEFT
	JOIN	Production_Plan_Statuses S
	ON	I.PP_Status_Id		= S.PP_Status_Id
	LEFT
	JOIN	Products P
	ON	P.Prod_Id		= I.Prod_Id


GO
CREATE TRIGGER dbo.Production_Plan_Upd
  ON dbo.Production_Plan
  FOR UPDATE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare @@Id int
Declare Production_Plan_Upd_Cursor INSENSITIVE CURSOR
  For (Select PP_Id From INSERTED)
  For Read Only
  Open Production_Plan_Upd_Cursor  
Fetch_Loop:
  Fetch Next From Production_Plan_Upd_Cursor Into @@Id
  If (@@Fetch_Status = 0)
    Begin
 	  	 If (Update(Block_Number) or Update(Control_Type)  or Update(Forecast_End_Date) or Update(Forecast_Quantity) or Update(Forecast_Start_Date) or Update(Implied_Sequence) or Update(Parent_PP_Id) or Update(Path_Id) or Update(PP_Status_Id) or Update(PP_Type_Id) or Update(Process_Order) or Update(Prod_Id) or Update(Source_PP_Id))
       	 Execute spServer_CmnAddScheduledTask @@Id,7
      Goto Fetch_Loop
    End
Close Production_Plan_Upd_Cursor
Deallocate Production_Plan_Upd_Cursor

GO
CREATE	TRIGGER [dbo].[Local_TgrProductionPlanUpd] ON [dbo].[Production_Plan]
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
IF	UPDATE(Process_Order)
	OR	UPDATE(Path_Id)
	OR	UPDATE(Forecast_Start_Date)
	OR	UPDATE(Forecast_End_Date)
	OR	UPDATE(BOM_Formulation_Id)
	OR	UPDATE(PP_Status_Id)
	OR	UPDATE(Forecast_Quantity)
	OR	UPDATE(Prod_Id)
BEGIN	
	-------------------------------------------------------------------------------
	-- Add a record in the local table for each PS record
	-- linked to each PP record being updated
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
			I.Process_Order,
			PA.Path_Code,
			I.Forecast_Start_Date,
			I.Forecast_End_Date,
			BOFMF.Bom_Formulation_Desc,
			BOM.BOM_Desc,
--			CASE 
--				WHEN	CharIndex(':', BOFMF.Bom_Formulation_Desc)>0	THEN 
--					LEFT(BOFMF.Bom_Formulation_Desc, CharIndex(':', BOFMF.Bom_Formulation_Desc) -1)
--				WHEN	CharIndex(':', BOFMF.Bom_Formulation_Desc)=0 	THEN
--					Null
--			END,
			PS.Pattern_Code,
			Coalesce(PS.Forecast_Quantity, I.Forecast_Quantity),
			S2.PP_Status_Desc,
			S.PP_Status_Desc,
			P.Prod_Code,
			'Local_TgrProductionPlanUpd',
			GetDate(),
			Null,
			0,
			Null
		FROM	Deleted I
		LEFT
		JOIN	PrdExec_Paths PA
		ON	I.Path_Id		= PA.Path_Id
		LEFT
		JOIN	Bill_Of_Material_Formulation BOFMF
		ON	I.Bom_Formulation_Id 	= BOFMF.Bom_Formulation_Id
		---------------------------------------------------------------------
		-- added to get Production Rule from BOM_Desc
		---------------------------------------------------------------------
		LEFT
		JOIN	Bill_Of_Material BOM
		ON	BOFMF.BOM_Id 	= BOM.BOM_Id
		---------------------------------------------------------------------
		LEFT
		JOIN	Production_Plan_Statuses S
		ON	I.PP_Status_Id		= S.PP_Status_Id
		LEFT
		JOIN	Production_Setup PS
		ON	I.PP_Id			= PS.PP_Id
		LEFT
		JOIN	Production_Plan_Statuses S2
		ON	PS.PP_Status_Id		= S2.PP_Status_Id
		LEFT
		JOIN	Products P
		ON	P.Prod_Id		= I.Prod_Id
	
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
			I.Process_Order,
			PA.Path_Code,
			I.Forecast_Start_Date,
			I.Forecast_End_Date,
			BOFMF.Bom_Formulation_Desc,
			BOM.BOM_Desc,
--			CASE 
--				WHEN	CharIndex(':', BOFMF.Bom_Formulation_Desc)>0	THEN 
--					LEFT(BOFMF.Bom_Formulation_Desc, CharIndex(':', BOFMF.Bom_Formulation_Desc) -1)
--				WHEN	CharIndex(':', BOFMF.Bom_Formulation_Desc)=0 	THEN
--					Null
--			END,
			PS.Pattern_Code,
			Coalesce(PS.Forecast_Quantity, I.Forecast_Quantity),
			S2.PP_Status_Desc,
			S.PP_Status_Desc,
			P.Prod_Code,
			'Local_TgrProductionPlanUpd',
			GetDate(),
			Null,
			0,
			Null
		FROM	Inserted I
		LEFT
		JOIN	PrdExec_Paths PA
		ON	I.Path_Id		= PA.Path_Id
		LEFT
		JOIN	Bill_Of_Material_Formulation BOFMF
		ON	I.Bom_Formulation_Id 	= BOFMF.Bom_Formulation_Id
		---------------------------------------------------------------------
		-- added to get Production Rule from BOM_Desc
		---------------------------------------------------------------------
		LEFT
		JOIN	Bill_Of_Material BOM
		ON	BOFMF.BOM_Id 	= BOM.BOM_Id
		---------------------------------------------------------------------
		LEFT
		JOIN	Production_Plan_Statuses S
		ON	I.PP_Status_Id		= S.PP_Status_Id
		LEFT
		JOIN	Production_Setup PS
		ON	I.PP_Id			= PS.PP_Id
		LEFT
		JOIN	Production_Plan_Statuses S2
		ON	PS.PP_Status_Id		= S2.PP_Status_Id
		LEFT
		JOIN	Products P
		ON	P.Prod_Id		= I.Prod_Id
END

GO
CREATE TRIGGER [dbo].[Production_Plan_History_Upd]
 ON  [dbo].[Production_Plan]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 402
 If (@Populate_History = 1) and ( Update(Adjusted_Quantity) or Update(Block_Number) or Update(BOM_Formulation_Id) or Update(Comment_Id) or Update(Control_Type) or Update(Entry_On) or Update(Extended_Info) or Update(Forecast_End_Date) or Update(Forecast_Quantity) or Update(Forecast_Start_Date) or Update(Parent_PP_Id) or Update(Path_Id) or Update(PP_Id) or Update(PP_Status_Id) or Update(PP_Type_Id) or Update(Process_Order) or Update(Prod_Id) or Update(Production_Rate) or Update(Source_PP_Id) or Update(User_General_1) or Update(User_General_2) or Update(User_General_3) or Update(User_Id)) 
   Begin
 	  	   Insert Into Production_Plan_History
 	  	   (Adjusted_Quantity,Block_Number,BOM_Formulation_Id,Comment_Id,Control_Type,Entry_On,Extended_Info,Forecast_End_Date,Forecast_Quantity,Forecast_Start_Date,Parent_PP_Id,Path_Id,PP_Id,PP_Status_Id,PP_Type_Id,Process_Order,Prod_Id,Production_Rate,Source_PP_Id,User_General_1,User_General_2,User_General_3,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Adjusted_Quantity,a.Block_Number,a.BOM_Formulation_Id,a.Comment_Id,a.Control_Type,a.Entry_On,a.Extended_Info,a.Forecast_End_Date,a.Forecast_Quantity,a.Forecast_Start_Date,a.Parent_PP_Id,a.Path_Id,a.PP_Id,a.PP_Status_Id,a.PP_Type_Id,a.Process_Order,a.Prod_Id,a.Production_Rate,a.Source_PP_Id,a.User_General_1,a.User_General_2,a.User_General_3,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Production_Plan_History_Del]
 ON  [dbo].[Production_Plan]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 402
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Production_Plan_History
 	  	   (Adjusted_Quantity,Block_Number,BOM_Formulation_Id,Comment_Id,Control_Type,Entry_On,Extended_Info,Forecast_End_Date,Forecast_Quantity,Forecast_Start_Date,Parent_PP_Id,Path_Id,PP_Id,PP_Status_Id,PP_Type_Id,Process_Order,Prod_Id,Production_Rate,Source_PP_Id,User_General_1,User_General_2,User_General_3,User_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Adjusted_Quantity,a.Block_Number,a.BOM_Formulation_Id,a.Comment_Id,a.Control_Type,a.Entry_On,a.Extended_Info,a.Forecast_End_Date,a.Forecast_Quantity,a.Forecast_Start_Date,a.Parent_PP_Id,a.Path_Id,a.PP_Id,a.PP_Status_Id,a.PP_Type_Id,a.Process_Order,a.Prod_Id,a.Production_Rate,a.Source_PP_Id,a.User_General_1,a.User_General_2,a.User_General_3,a.User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER dbo.Production_Plan_Ins
  ON dbo.Production_Plan
  FOR INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare @@Id int
Declare Production_Plan_Ins_Cursor INSENSITIVE CURSOR
  For (Select PP_Id From INSERTED)
  For Read Only
  Open Production_Plan_Ins_Cursor  
Fetch_Loop:
  Fetch Next From Production_Plan_Ins_Cursor Into @@Id
  If (@@Fetch_Status = 0)
 	 Begin
      Execute spServer_CmnAddScheduledTask @@Id,7
      Goto Fetch_Loop
    End
Close Production_Plan_Ins_Cursor
Deallocate Production_Plan_Ins_Cursor

GO
CREATE TRIGGER dbo.Production_Plan_InsUpd_StatTrans
ON dbo.Production_Plan
FOR INSERT, UPDATE
AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
DECLARE @intNewPPId 	  	 INT,
 	  	 @intNewStatus 	 INT,
 	  	 @dtmNewEntryOn 	 DATETIME,
 	  	 @intCounter 	  	 INT,
 	  	 @intMaxCount 	 INT,
 	  	 @intOldStatus 	 INT,
 	  	 @intPPTId 	  	 INT,
 	  	 @Now 	  	  	 DATETIME
SELECT @Now = dbo.fnServer_CmnGetDate(getUTCdate())
DECLARE @tblInserted TABLE (Id 	  	  	 INT PRIMARY KEY IDENTITY(1,1),
 	  	  	  	  	  	  	 PPId 	  	 INT,
 	  	  	  	  	  	  	 PPStatusId 	 INT,
 	  	  	  	  	  	  	 EntryOn 	  	 DATETIME)
INSERT @tblInserted (PPId, PPStatusId, EntryOn)
 	 SELECT PP_Id, PP_Status_Id, Entry_On
 	 FROM INSERTED
SELECT @intCounter = MIN(Id),@intMaxCount = MAX(Id)
 	 FROM @tblInserted
WHILE @intCounter <= @intMaxCount
BEGIN
 	 SELECT 	 @intNewPPId = PPId,
 	  	  	 @intNewStatus = PPStatusId,
 	  	  	 @dtmNewEntryOn = COALESCE(EntryOn,@Now)
 	 FROM @tblInserted
 	 WHERE Id = @intCounter
 	 SELECT 	 @intOldStatus = PP_Status_Id
 	 FROM DELETED
 	 WHERE PP_Id = @intNewPPId
 	 IF @intNewStatus <> @intOldStatus OR @intOldStatus IS NULL
 	 BEGIN
 	  	 SELECT @intPPTId = NULL
 	  	 SELECT @intPPTId = PPT_Id
 	  	  	 FROM dbo.Production_Plan_Transitions
 	  	  	 WHERE PP_Id = @intNewPPId AND End_Time IS NULL
 	  	 IF @intPPTId IS NOT NULL
 	  	 BEGIN
 	  	  	 UPDATE dbo.Production_Plan_Transitions
 	  	  	 SET End_Time = @dtmNewEntryOn
 	  	  	 WHERE PPT_Id = @intPPTId
 	  	 END
 	  	 INSERT dbo.Production_Plan_Transitions (PP_Id, PPStatus_Id, Start_Time)
 	  	  	 VALUES (@intNewPPId, @intNewStatus, @dtmNewEntryOn)
 	 END
 	 SELECT @intCounter = @intCounter + 1
END
