CREATE TABLE [dbo].[PrdExec_Inputs] (
    [PEI_Id]                  INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Alternate_Spec_Id]       INT                  NULL,
    [Def_Event_Comp_Sheet_Id] INT                  NULL,
    [Event_Subtype_Id]        INT                  NOT NULL,
    [Input_Name]              [dbo].[Varchar_Desc] NOT NULL,
    [Input_Order]             INT                  NOT NULL,
    [Lock_Inprogress_Input]   BIT                  CONSTRAINT [PrdExec_Inputs_DF_Lock_InProgress_Input] DEFAULT ((1)) NOT NULL,
    [Primary_Spec_Id]         INT                  NULL,
    [PU_Id]                   INT                  NOT NULL,
    CONSTRAINT [PrdExecInputs_PK_PEIId] PRIMARY KEY NONCLUSTERED ([PEI_Id] ASC),
    CONSTRAINT [PrdExecInputs_FK_AltSpecId] FOREIGN KEY ([Alternate_Spec_Id]) REFERENCES [dbo].[Specifications] ([Spec_Id]),
    CONSTRAINT [PrdExecInputs_FK_PrimSpecId] FOREIGN KEY ([Primary_Spec_Id]) REFERENCES [dbo].[Specifications] ([Spec_Id]),
    CONSTRAINT [PrdExecInputs_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id])
);


GO
CREATE UNIQUE CLUSTERED INDEX [PrdExecInputs_IDX_INamePUId]
    ON [dbo].[PrdExec_Inputs]([PU_Id] ASC, [Input_Name] ASC);


GO
CREATE TRIGGER [dbo].[PrdExec_Inputs_History_Del]
 ON  [dbo].[PrdExec_Inputs]
  FOR DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 453
 If (@Populate_History = 1 or @Populate_History = 3)
   Begin
 	  	 Insert Into PrdExec_Input_History
 	  	   (Alternate_Spec_Id,Def_Event_Comp_Sheet_Id,Event_Subtype_Id,Input_Name,Input_Order,Lock_Inprogress_Input,PEI_Id,Primary_Spec_Id,PU_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alternate_Spec_Id,a.Def_Event_Comp_Sheet_Id,a.Event_Subtype_Id,a.Input_Name,a.Input_Order,a.Lock_Inprogress_Input,a.PEI_Id,a.Primary_Spec_Id,a.PU_Id,dbo.fnServer_CmnGetDate(getUTCdate()),4,COLUMNS_UPDATED() 
 	  	   From Deleted a
   End

GO
CREATE TRIGGER [dbo].[PrdExec_Inputs_TableFieldValue_Del]
 ON  [dbo].[PrdExec_Inputs]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.PEI_Id
 WHERE tfv.TableId = 35

GO
CREATE TRIGGER [dbo].[PrdExec_Inputs_History_Ins]
 ON  [dbo].[PrdExec_Inputs]
  FOR INSERT
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 453
 If (@Populate_History = 1 or @Populate_History = 3) 
   Begin
 	  	   Insert Into PrdExec_Input_History
 	  	   (Alternate_Spec_Id,Def_Event_Comp_Sheet_Id,Event_Subtype_Id,Input_Name,Input_Order,Lock_Inprogress_Input,PEI_Id,Primary_Spec_Id,PU_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alternate_Spec_Id,a.Def_Event_Comp_Sheet_Id,a.Event_Subtype_Id,a.Input_Name,a.Input_Order,a.Lock_Inprogress_Input,a.PEI_Id,a.Primary_Spec_Id,a.PU_Id,dbo.fnServer_CmnGetDate(getUTCdate()),2,COLUMNS_UPDATED()
 	  	   From Inserted a
   End

GO
CREATE TRIGGER [dbo].[PrdExec_Inputs_History_Upd]
 ON  [dbo].[PrdExec_Inputs]
  FOR UPDATE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 Declare  @Populate_History TinyInt
 Select @Populate_History = Value From Site_Parameters Where Parm_Id = 453
 If (@Populate_History = 1)
   Begin
 	  	   Insert Into PrdExec_Input_History
 	  	   (Alternate_Spec_Id,Def_Event_Comp_Sheet_Id,Event_Subtype_Id,Input_Name,Input_Order,Lock_Inprogress_Input,PEI_Id,Primary_Spec_Id,PU_Id,Modified_On,DBTT_Id,Column_Updated_BitMask)
 	  	   Select  a.Alternate_Spec_Id,a.Def_Event_Comp_Sheet_Id,a.Event_Subtype_Id,a.Input_Name,a.Input_Order,a.Lock_Inprogress_Input,a.PEI_Id,a.Primary_Spec_Id,a.PU_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,COLUMNS_UPDATED()
 	  	   From Inserted a
   End
