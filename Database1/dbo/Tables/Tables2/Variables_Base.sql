CREATE TABLE [dbo].[Variables_Base] (
    [Var_Id]                       INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ArrayStatOnly]                TINYINT                   CONSTRAINT [Variables_DF_ArrayStatOnly] DEFAULT ((0)) NULL,
    [Calculation_Id]               INT                       NULL,
    [Comment_Id]                   INT                       NULL,
    [Comparison_Operator_Id]       INT                       NULL,
    [Comparison_Value]             VARCHAR (50)              NULL,
    [CPK_SubGroup_Size]            INT                       NULL,
    [Data_Type_Id]                 INT                       NOT NULL,
    [Debug]                        BIT                       CONSTRAINT [Variables_DF_Debug] DEFAULT ((0)) NULL,
    [DQ_Tag]                       VARCHAR (255)             NULL,
    [DS_Id]                        INT                       NOT NULL,
    [Eng_Units]                    [dbo].[Varchar_Eng_Units] NULL,
    [Esignature_Level]             INT                       NULL,
    [Event_Dimension]              TINYINT                   NULL,
    [Event_Subtype_Id]             INT                       NULL,
    [Event_Type]                   TINYINT                   CONSTRAINT [Variables_DF_EventType] DEFAULT ((0)) NOT NULL,
    [Extended_Info]                VARCHAR (255)             NULL,
    [Extended_Test_Freq]           INT                       CONSTRAINT [Variables_DF_ExtTestFreq] DEFAULT ((1)) NULL,
    [External_Link]                [dbo].[Varchar_Ext_Link]  NULL,
    [Force_Sign_Entry]             TINYINT                   CONSTRAINT [Variables_DF_FSEntry] DEFAULT ((0)) NULL,
    [Group_Id]                     INT                       NULL,
    [Input_Tag]                    VARCHAR (255)             NULL,
    [Input_Tag2]                   VARCHAR (255)             NULL,
    [Is_Active]                    BIT                       CONSTRAINT [Variables_DF_IsActive] DEFAULT ((1)) NULL,
    [Is_Conformance_Variable]      BIT                       CONSTRAINT [Variables_DF_ConformanceVariable] DEFAULT ((1)) NOT NULL,
    [LEL_Tag]                      VARCHAR (255)             NULL,
    [LRL_Tag]                      VARCHAR (255)             NULL,
    [LUL_Tag]                      VARCHAR (255)             NULL,
    [LWL_Tag]                      VARCHAR (255)             NULL,
    [Max_RPM]                      FLOAT (53)                NULL,
    [Output_DS_Id]                 INT                       NULL,
    [Output_Tag]                   VARCHAR (255)             NULL,
    [PEI_Id]                       INT                       NULL,
    [Perform_Event_Lookup]         TINYINT                   CONSTRAINT [Variables_DF_EventLookup] DEFAULT ((1)) NULL,
    [ProdCalc_Type]                TINYINT                   NULL,
    [PU_Id]                        INT                       NOT NULL,
    [PUG_Id]                       INT                       NOT NULL,
    [PUG_Order]                    INT                       CONSTRAINT [Variables_DF_PUGOrder] DEFAULT ((1)) NOT NULL,
    [PVar_Id]                      INT                       NULL,
    [Rank]                         [dbo].[Smallint_Pct]      CONSTRAINT [Variables_DF_Rank] DEFAULT ((0)) NOT NULL,
    [ReadLagTime]                  INT                       NULL,
    [Reload_Flag]                  TINYINT                   NULL,
    [Repeat_Backtime]              INT                       NULL,
    [Repeating]                    TINYINT                   NULL,
    [Reset_Value]                  FLOAT (53)                NULL,
    [Retention_Limit]              INT                       NULL,
    [SA_Id]                        TINYINT                   CONSTRAINT [Variables_DF_SAId] DEFAULT ((1)) NOT NULL,
    [Sampling_Interval]            [dbo].[Smallint_Offset]   NULL,
    [Sampling_Offset]              [dbo].[Smallint_Offset]   NULL,
    [Sampling_Reference_Var_Id]    INT                       NULL,
    [Sampling_Type]                TINYINT                   NULL,
    [Sampling_Window]              INT                       NULL,
    [ShouldArchive]                TINYINT                   CONSTRAINT [Variables_DF_ShouldArchive] DEFAULT ((1)) NULL,
    [SPC_Calculation_Type_Id]      INT                       NULL,
    [SPC_Group_Variable_Type_Id]   INT                       NULL,
    [Spec_Id]                      INT                       NULL,
    [String_Specification_Setting] TINYINT                   NULL,
    [System]                       TINYINT                   NULL,
    [Tag]                          VARCHAR (50)              NULL,
    [Target_Tag]                   VARCHAR (255)             NULL,
    [Test_Name]                    VARCHAR (50)              NULL,
    [TF_Reset]                     TINYINT                   CONSTRAINT [Variables_DF_TFReset] DEFAULT ((0)) NULL,
    [Tot_Factor]                   REAL                      CONSTRAINT [Variables_DF_TotFactor] DEFAULT ((1.0)) NULL,
    [UEL_Tag]                      VARCHAR (255)             NULL,
    [Unit_Reject]                  BIT                       CONSTRAINT [Variables_DF_UnitReject] DEFAULT ((0)) NOT NULL,
    [Unit_Summarize]               BIT                       CONSTRAINT [Variables_DF_UnitSummarize] DEFAULT ((0)) NOT NULL,
    [URL_Tag]                      VARCHAR (255)             NULL,
    [User_Defined1]                VARCHAR (255)             NULL,
    [User_Defined2]                VARCHAR (255)             NULL,
    [User_Defined3]                VARCHAR (255)             NULL,
    [UUL_Tag]                      VARCHAR (255)             NULL,
    [UWL_Tag]                      VARCHAR (255)             NULL,
    [Var_Desc]                     [dbo].[Varchar_Desc]      NOT NULL,
    [Var_Desc_Global]              VARCHAR (50)              NULL,
    [Var_Precision]                [dbo].[Tinyint_Precision] NULL,
    [Var_Reject]                   BIT                       CONSTRAINT [Variables_DF_VarReject] DEFAULT ((0)) NOT NULL,
    [Write_Group_DS_Id]            INT                       NULL,
    [Ignore_Event_Status]          TINYINT                   NULL,
    CONSTRAINT [PK___3__12] PRIMARY KEY NONCLUSTERED ([Var_Id] ASC),
    CONSTRAINT [Variables_CC_Tags] CHECK ([PVar_Id] IS NULL OR [UEL_Tag] IS NULL AND [URL_Tag] IS NULL AND [UWL_Tag] IS NULL AND [UUL_Tag] IS NULL AND [Target_TAG] IS NULL AND [UUL_Tag] IS NULL AND [UWL_Tag] IS NULL AND [URL_Tag] IS NULL AND [UEL_Tag] IS NULL),
    CONSTRAINT [FK_Variables_OutputDSId] FOREIGN KEY ([Output_DS_Id]) REFERENCES [dbo].[Data_Source] ([DS_Id]),
    CONSTRAINT [FK_Variables_SamplingReferenceVar_Id] FOREIGN KEY ([Sampling_Reference_Var_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id]),
    CONSTRAINT [Variables_FK_DataTypeId] FOREIGN KEY ([Data_Type_Id]) REFERENCES [dbo].[Data_Type] ([Data_Type_Id]),
    CONSTRAINT [Variables_FK_DSId] FOREIGN KEY ([DS_Id]) REFERENCES [dbo].[Data_Source] ([DS_Id]),
    CONSTRAINT [Variables_FK_DSWriteGroup] FOREIGN KEY ([Write_Group_DS_Id]) REFERENCES [dbo].[Data_Source] ([DS_Id]),
    CONSTRAINT [Variables_FK_EventSubTypeId] FOREIGN KEY ([Event_Subtype_Id]) REFERENCES [dbo].[Event_Subtypes] ([Event_Subtype_Id]),
    CONSTRAINT [Variables_FK_EventType] FOREIGN KEY ([Event_Type]) REFERENCES [dbo].[Event_Types] ([ET_Id]),
    CONSTRAINT [Variables_FK_GroupId] FOREIGN KEY ([Group_Id]) REFERENCES [dbo].[Security_Groups] ([Group_Id]),
    CONSTRAINT [Variables_FK_PEIId] FOREIGN KEY ([PEI_Id]) REFERENCES [dbo].[PrdExec_Inputs] ([PEI_Id]),
    CONSTRAINT [Variables_FK_PUGId] FOREIGN KEY ([PUG_Id]) REFERENCES [dbo].[PU_Groups] ([PUG_Id]),
    CONSTRAINT [Variables_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [Variables_FK_PVarId] FOREIGN KEY ([PVar_Id]) REFERENCES [dbo].[Variables_Base] ([Var_Id]),
    CONSTRAINT [Variables_FK_SamplingType] FOREIGN KEY ([Sampling_Type]) REFERENCES [dbo].[Sampling_Type] ([ST_Id]),
    CONSTRAINT [Variables_FK_SPCCalculationTypeId] FOREIGN KEY ([SPC_Calculation_Type_Id]) REFERENCES [dbo].[SPC_Calculation_Types] ([SPC_Calculation_Type_Id]),
    CONSTRAINT [Variables_FK_SPCGroupVariableTypeId] FOREIGN KEY ([SPC_Group_Variable_Type_Id]) REFERENCES [dbo].[SPC_Group_Variable_Types] ([SPC_Group_Variable_Type_Id]),
    CONSTRAINT [Variables_FK_SpecId] FOREIGN KEY ([Spec_Id]) REFERENCES [dbo].[Specifications] ([Spec_Id]),
    CONSTRAINT [Variables_UC_PUIdVarDesc] UNIQUE NONCLUSTERED ([PU_Id] ASC, [Var_Desc] ASC)
);


GO
CREATE CLUSTERED INDEX [Variables_IX_PUIdDTIdVarDesc]
    ON [dbo].[Variables_Base]([PU_Id] ASC, [Data_Type_Id] ASC, [Var_Desc] ASC);


GO
CREATE NONCLUSTERED INDEX [Variables_IDX_PUIdTestName]
    ON [dbo].[Variables_Base]([Test_Name] ASC, [PU_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Variables_IX_PUIdInputTag]
    ON [dbo].[Variables_Base]([PU_Id] ASC, [Input_Tag] ASC);


GO
CREATE NONCLUSTERED INDEX [Variables_IDX_PUGId]
    ON [dbo].[Variables_Base]([PUG_Id] ASC, [Var_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Var_By_Desc]
    ON [dbo].[Variables_Base]([Var_Desc] ASC);


GO
CREATE NONCLUSTERED INDEX [Variables_IX_VarIdSAIDEsigDTId]
    ON [dbo].[Variables_Base]([Var_Id] ASC, [SA_Id] ASC, [Data_Type_Id] ASC, [Esignature_Level] ASC);


GO
CREATE NONCLUSTERED INDEX [Variables_IDX_DataTypeId]
    ON [dbo].[Variables_Base]([Data_Type_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Variables_IDX_SpecId]
    ON [dbo].[Variables_Base]([Spec_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Variables_IDX_ExtendedInfo]
    ON [dbo].[Variables_Base]([Extended_Info] ASC);


GO
CREATE NONCLUSTERED INDEX [Variables_IDX_PVarId]
    ON [dbo].[Variables_Base]([PVar_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Variables_IDX_VarIdPrecEU]
    ON [dbo].[Variables_Base]([Var_Id] ASC, [Var_Precision] ASC, [Eng_Units] ASC);


GO
CREATE TRIGGER [dbo].[Variables_History_Ins]
 ON  [dbo].[Variables_Base]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 421
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into Variable_History
 	  	   (ArrayStatOnly,Calculation_Id,Comment_Id,Comparison_Operator_Id,Comparison_Value,CPK_SubGroup_Size,Data_Type_Id,Debug,DQ_Tag,DS_Id,Eng_Units,Esignature_Level,Event_Dimension,Event_Subtype_Id,Event_Type,Extended_Info,Extended_Test_Freq,External_Link,Force_Sign_Entry,Group_Id,Ignore_Event_Status,Input_Tag,Input_Tag2,Is_Active,Is_Conformance_Variable,LEL_Tag,LRL_Tag,LUL_Tag,LWL_Tag,Max_RPM,Output_DS_Id,Output_Tag,PEI_Id,Perform_Event_Lookup,ProdCalc_Type,PU_Id,PUG_Id,PUG_Order,PVar_Id,Rank,ReadLagTime,Reload_Flag,Repeat_Backtime,Repeating,Reset_Value,Retention_Limit,SA_Id,Sampling_Interval,Sampling_Offset,Sampling_Reference_Var_Id,Sampling_Type,Sampling_Window,ShouldArchive,SPC_Calculation_Type_Id,SPC_Group_Variable_Type_Id,Spec_Id,String_Specification_Setting,System,Tag,Target_Tag,Test_Name,TF_Reset,Tot_Factor,UEL_Tag,Unit_Reject,Unit_Summarize,URL_Tag,User_Defined1,User_Defined2,User_Defined3,UUL_Tag,UWL_Tag,Var_Desc,Var_Id,Var_Precision,Var_Reject,Write_Group_DS_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.ArrayStatOnly,a.Calculation_Id,a.Comment_Id,a.Comparison_Operator_Id,a.Comparison_Value,a.CPK_SubGroup_Size,a.Data_Type_Id,a.Debug,a.DQ_Tag,a.DS_Id,a.Eng_Units,a.Esignature_Level,a.Event_Dimension,a.Event_Subtype_Id,a.Event_Type,a.Extended_Info,a.Extended_Test_Freq,a.External_Link,a.Force_Sign_Entry,a.Group_Id,a.Ignore_Event_Status,a.Input_Tag,a.Input_Tag2,a.Is_Active,a.Is_Conformance_Variable,a.LEL_Tag,a.LRL_Tag,a.LUL_Tag,a.LWL_Tag,a.Max_RPM,a.Output_DS_Id,a.Output_Tag,a.PEI_Id,a.Perform_Event_Lookup,a.ProdCalc_Type,a.PU_Id,a.PUG_Id,a.PUG_Order,a.PVar_Id,a.Rank,a.ReadLagTime,a.Reload_Flag,a.Repeat_Backtime,a.Repeating,a.Reset_Value,a.Retention_Limit,a.SA_Id,a.Sampling_Interval,a.Sampling_Offset,a.Sampling_Reference_Var_Id,a.Sampling_Type,a.Sampling_Window,a.ShouldArchive,a.SPC_Calculation_Type_Id,a.SPC_Group_Variable_Type_Id,a.Spec_Id,a.String_Specification_Setting,a.System,a.Tag,a.Target_Tag,a.Test_Name,a.TF_Reset,a.Tot_Factor,a.UEL_Tag,a.Unit_Reject,a.Unit_Summarize,a.URL_Tag,a.User_Defined1,a.User_Defined2,a.User_Defined3,a.UUL_Tag,a.UWL_Tag,a.Var_Desc,a.Var_Id,a.Var_Precision,a.Var_Reject,a.Write_Group_DS_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
Create  TRIGGER dbo.Variables_Reload_InsUpdDel
 	 ON dbo.Variables_Base
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
Update cxs_service set Should_Reload_Timestamp = DateAdd(minute,5,dbo.fnServer_CmnGetDate(getUTCdate())) where Service_Id in (4,5,6,7,8,17,19)

GO
Create  TRIGGER dbo.Variables_UpdDescription
 	 ON dbo.Variables_Base
 	 For  UPDATE
 	 AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
DECLARE @VarId Int
DECLARE @NewVarDesc VarChar(100)
DECLARE @g1  uniqueidentifier
DECLARE @g1VarChar  nvarchar(400)
DECLARE @g2  uniqueidentifier
DECLARE @g3  uniqueidentifier
DECLARE @Origin1Name varchar(100)
DECLARE @VariablesToUpdate TABLE(Id Int Identity(1,1),NewVarDesc VarChar(100), VarId Int,PK1 uniqueidentifier,PK2 uniqueidentifier)
DECLARE @Start INt
DECLARE @End INt
SET @Start = 1
INSERT INTO @VariablesToUpdate(VarId,NewVarDesc) 
 	 SELECT Distinct a.var_Id,Var_Desc  
 	  	 FROM Inserted a
 	  	 JOIN  	 Variables_Aspect_EquipmentProperty b ON a.Var_Id = b.Var_Id 
SET @End = @@ROWCOUNT
WHILE @Start <= @End
BEGIN
 	 SELECT  @VarId  =  VarId,@NewVarDesc = NewVarDesc 
 	  	  FROM @VariablesToUpdate 
 	  	  WHERE Id = @Start
 	 SELECT @Origin1Name = a.Origin1Name,@g1 = Origin1EquipmentId
 	  	  FROM Variables_Aspect_EquipmentProperty a where a.Var_Id = @VarId
 	 SET @g1VarChar = Convert(nvarchar(400),@g1)
 	 IF @Origin1Name Is Not Null
 	 BEGIN
 	  	 IF @NewVarDesc != @Origin1Name
 	  	 BEGIN
 	  	  	 UPDATE StructuredTypeProperty SET  Name = @NewVarDesc,LastBuiltName = @NewVarDesc  Where  TypeOwnerName = @g1VarChar and TypeOwnerNamespace = N'Equipment'and Name = @Origin1Name
 	  	  	 UPDATE Property_EquipmentClass set PropertyName = @NewVarDesc WHERE EquipmentClassName  = @g1 and PropertyName = @Origin1Name
 	  	  	 UPDATE Property_Equipment_EquipmentClass SET Name = @NewVarDesc WHERE EquipmentId = @g1 and Name = @Origin1Name
 	  	  	 UPDATE Variables_Aspect_EquipmentProperty SET Origin1Name = @NewVarDesc Where Var_Id = @VarId
 	  	  	 UPDATE Variables_Aspect_EquipmentProperty SET Origin2PropertyName  = @NewVarDesc Where Var_Id is Null and  Origin2PropertyName  = @Origin1Name and Origin2EquipmentClassName  = @g1VarChar
 	  	 END
 	 END
 	 SET @Start = @Start + 1
END

GO
CREATE TRIGGER dbo.Variables_Del ON dbo.Variables_Base
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE Variables_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN Variables_Del_Cursor 
--
--
Fetch_Variables_Del:
FETCH NEXT FROM Variables_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
    Delete From Comments Where TopOfChain_Id = @Comment_Id 
    Delete From Comments Where Comment_Id = @Comment_Id 
    GOTO Fetch_Variables_Del
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in Variables_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE Variables_Del_Cursor 

GO
CREATE TRIGGER [dbo].[Variables_TableFieldValue_Del]
 ON  [dbo].[Variables_Base]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Var_Id
 WHERE tfv.TableId = 20

GO
CREATE TRIGGER [dbo].[Variables_History_Upd]
 ON  [dbo].[Variables_Base]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 421
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into Variable_History
 	  	   (ArrayStatOnly,Calculation_Id,Comment_Id,Comparison_Operator_Id,Comparison_Value,CPK_SubGroup_Size,Data_Type_Id,Debug,DQ_Tag,DS_Id,Eng_Units,Esignature_Level,Event_Dimension,Event_Subtype_Id,Event_Type,Extended_Info,Extended_Test_Freq,External_Link,Force_Sign_Entry,Group_Id,Ignore_Event_Status,Input_Tag,Input_Tag2,Is_Active,Is_Conformance_Variable,LEL_Tag,LRL_Tag,LUL_Tag,LWL_Tag,Max_RPM,Output_DS_Id,Output_Tag,PEI_Id,Perform_Event_Lookup,ProdCalc_Type,PU_Id,PUG_Id,PUG_Order,PVar_Id,Rank,ReadLagTime,Reload_Flag,Repeat_Backtime,Repeating,Reset_Value,Retention_Limit,SA_Id,Sampling_Interval,Sampling_Offset,Sampling_Reference_Var_Id,Sampling_Type,Sampling_Window,ShouldArchive,SPC_Calculation_Type_Id,SPC_Group_Variable_Type_Id,Spec_Id,String_Specification_Setting,System,Tag,Target_Tag,Test_Name,TF_Reset,Tot_Factor,UEL_Tag,Unit_Reject,Unit_Summarize,URL_Tag,User_Defined1,User_Defined2,User_Defined3,UUL_Tag,UWL_Tag,Var_Desc,Var_Id,Var_Precision,Var_Reject,Write_Group_DS_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.ArrayStatOnly,a.Calculation_Id,a.Comment_Id,a.Comparison_Operator_Id,a.Comparison_Value,a.CPK_SubGroup_Size,a.Data_Type_Id,a.Debug,a.DQ_Tag,a.DS_Id,a.Eng_Units,a.Esignature_Level,a.Event_Dimension,a.Event_Subtype_Id,a.Event_Type,a.Extended_Info,a.Extended_Test_Freq,a.External_Link,a.Force_Sign_Entry,a.Group_Id,a.Ignore_Event_Status,a.Input_Tag,a.Input_Tag2,a.Is_Active,a.Is_Conformance_Variable,a.LEL_Tag,a.LRL_Tag,a.LUL_Tag,a.LWL_Tag,a.Max_RPM,a.Output_DS_Id,a.Output_Tag,a.PEI_Id,a.Perform_Event_Lookup,a.ProdCalc_Type,a.PU_Id,a.PUG_Id,a.PUG_Order,a.PVar_Id,a.Rank,a.ReadLagTime,a.Reload_Flag,a.Repeat_Backtime,a.Repeating,a.Reset_Value,a.Retention_Limit,a.SA_Id,a.Sampling_Interval,a.Sampling_Offset,a.Sampling_Reference_Var_Id,a.Sampling_Type,a.Sampling_Window,a.ShouldArchive,a.SPC_Calculation_Type_Id,a.SPC_Group_Variable_Type_Id,a.Spec_Id,a.String_Specification_Setting,a.System,a.Tag,a.Target_Tag,a.Test_Name,a.TF_Reset,a.Tot_Factor,a.UEL_Tag,a.Unit_Reject,a.Unit_Summarize,a.URL_Tag,a.User_Defined1,a.User_Defined2,a.User_Defined3,a.UUL_Tag,a.UWL_Tag,a.Var_Desc,a.Var_Id,a.Var_Precision,a.Var_Reject,a.Write_Group_DS_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[Variables_History_Del]
 ON  [dbo].[Variables_Base]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 421
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into Variable_History
 	  	   (ArrayStatOnly,Calculation_Id,Comment_Id,Comparison_Operator_Id,Comparison_Value,CPK_SubGroup_Size,Data_Type_Id,Debug,DQ_Tag,DS_Id,Eng_Units,Esignature_Level,Event_Dimension,Event_Subtype_Id,Event_Type,Extended_Info,Extended_Test_Freq,External_Link,Force_Sign_Entry,Group_Id,Ignore_Event_Status,Input_Tag,Input_Tag2,Is_Active,Is_Conformance_Variable,LEL_Tag,LRL_Tag,LUL_Tag,LWL_Tag,Max_RPM,Output_DS_Id,Output_Tag,PEI_Id,Perform_Event_Lookup,ProdCalc_Type,PU_Id,PUG_Id,PUG_Order,PVar_Id,Rank,ReadLagTime,Reload_Flag,Repeat_Backtime,Repeating,Reset_Value,Retention_Limit,SA_Id,Sampling_Interval,Sampling_Offset,Sampling_Reference_Var_Id,Sampling_Type,Sampling_Window,ShouldArchive,SPC_Calculation_Type_Id,SPC_Group_Variable_Type_Id,Spec_Id,String_Specification_Setting,System,Tag,Target_Tag,Test_Name,TF_Reset,Tot_Factor,UEL_Tag,Unit_Reject,Unit_Summarize,URL_Tag,User_Defined1,User_Defined2,User_Defined3,UUL_Tag,UWL_Tag,Var_Desc,Var_Id,Var_Precision,Var_Reject,Write_Group_DS_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.ArrayStatOnly,a.Calculation_Id,a.Comment_Id,a.Comparison_Operator_Id,a.Comparison_Value,a.CPK_SubGroup_Size,a.Data_Type_Id,a.Debug,a.DQ_Tag,a.DS_Id,a.Eng_Units,a.Esignature_Level,a.Event_Dimension,a.Event_Subtype_Id,a.Event_Type,a.Extended_Info,a.Extended_Test_Freq,a.External_Link,a.Force_Sign_Entry,a.Group_Id,a.Ignore_Event_Status,a.Input_Tag,a.Input_Tag2,a.Is_Active,a.Is_Conformance_Variable,a.LEL_Tag,a.LRL_Tag,a.LUL_Tag,a.LWL_Tag,a.Max_RPM,a.Output_DS_Id,a.Output_Tag,a.PEI_Id,a.Perform_Event_Lookup,a.ProdCalc_Type,a.PU_Id,a.PUG_Id,a.PUG_Order,a.PVar_Id,a.Rank,a.ReadLagTime,a.Reload_Flag,a.Repeat_Backtime,a.Repeating,a.Reset_Value,a.Retention_Limit,a.SA_Id,a.Sampling_Interval,a.Sampling_Offset,a.Sampling_Reference_Var_Id,a.Sampling_Type,a.Sampling_Window,a.ShouldArchive,a.SPC_Calculation_Type_Id,a.SPC_Group_Variable_Type_Id,a.Spec_Id,a.String_Specification_Setting,a.System,a.Tag,a.Target_Tag,a.Test_Name,a.TF_Reset,a.Tot_Factor,a.UEL_Tag,a.Unit_Reject,a.Unit_Summarize,a.URL_Tag,a.User_Defined1,a.User_Defined2,a.User_Defined3,a.UUL_Tag,a.UWL_Tag,a.Var_Desc,a.Var_Id,a.Var_Precision,a.Var_Reject,a.Write_Group_DS_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End
