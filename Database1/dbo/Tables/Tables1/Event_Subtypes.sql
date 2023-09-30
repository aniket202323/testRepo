CREATE TABLE [dbo].[Event_Subtypes] (
    [Event_Subtype_Id]          INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Ack_Required]              BIT                       CONSTRAINT [EventST_DF_AckReq] DEFAULT ((0)) NOT NULL,
    [Action_Required]           BIT                       CONSTRAINT [EventST_DF_ActionReq] DEFAULT ((0)) NOT NULL,
    [Action_Tree_Id]            INT                       NULL,
    [Cause_Required]            BIT                       CONSTRAINT [EventST_DF_CauseReq] DEFAULT ((0)) NOT NULL,
    [Cause_Tree_Id]             INT                       NULL,
    [Comment_Id]                INT                       NULL,
    [Default_Action1]           INT                       NULL,
    [Default_Action2]           INT                       NULL,
    [Default_Action3]           INT                       NULL,
    [Default_Action4]           INT                       NULL,
    [Default_Cause1]            INT                       NULL,
    [Default_Cause2]            INT                       NULL,
    [Default_Cause3]            INT                       NULL,
    [Default_Cause4]            INT                       NULL,
    [Dimension_A_Enabled]       TINYINT                   NULL,
    [Dimension_A_Eng_Unit_Id]   INT                       NULL,
    [Dimension_A_Eng_Units]     [dbo].[Varchar_Eng_Units] NULL,
    [Dimension_A_Name]          [dbo].[Varchar_Desc]      NULL,
    [Dimension_X_Eng_Unit_Id]   INT                       NULL,
    [Dimension_X_Eng_Units]     [dbo].[Varchar_Eng_Units] NULL,
    [Dimension_X_Name]          [dbo].[Varchar_Desc]      NULL,
    [Dimension_Y_Enabled]       TINYINT                   NULL,
    [Dimension_Y_Eng_Unit_Id]   INT                       NULL,
    [Dimension_Y_Eng_Units]     [dbo].[Varchar_Eng_Units] NULL,
    [Dimension_Y_Name]          [dbo].[Varchar_Desc]      NULL,
    [Dimension_Z_Enabled]       TINYINT                   NULL,
    [Dimension_Z_Eng_Unit_Id]   INT                       NULL,
    [Dimension_Z_Eng_Units]     [dbo].[Varchar_Eng_Units] NULL,
    [Dimension_Z_Name]          [dbo].[Varchar_Desc]      NULL,
    [Duration_Required]         BIT                       CONSTRAINT [EventST_DF_DurationReq] DEFAULT ((0)) NOT NULL,
    [Eng_Units]                 [dbo].[Varchar_Eng_Units] NULL,
    [ESignature_Level]          INT                       NULL,
    [ET_Id]                     TINYINT                   NOT NULL,
    [Event_Controlled_Product]  BIT                       CONSTRAINT [EventST_DF_EventControlledProduct] DEFAULT ((0)) NOT NULL,
    [Event_Mask]                VARCHAR (30)              NULL,
    [Event_Reason_Tree_Data_Id] INT                       NULL,
    [Event_Subtype_Desc]        [dbo].[Varchar_Desc]      NOT NULL,
    [Extended_Info]             VARCHAR (255)             NULL,
    [Icon_Id]                   INT                       NULL,
    [Default_Event_Status]      INT                       NULL,
    CONSTRAINT [EvtSubType_PK_EvtSubTypeId] PRIMARY KEY NONCLUSTERED ([Event_Subtype_Id] ASC),
    CONSTRAINT [EventST_FK_ETId] FOREIGN KEY ([ET_Id]) REFERENCES [dbo].[Event_Types] ([ET_Id]),
    CONSTRAINT [EventST_FK_EventReasonTreeData] FOREIGN KEY ([Event_Reason_Tree_Data_Id]) REFERENCES [dbo].[Event_Reason_Tree_Data] ([Event_Reason_Tree_Data_Id]),
    CONSTRAINT [EventSubtypesEngUnitA_FK_EngUnitId] FOREIGN KEY ([Dimension_A_Eng_Unit_Id]) REFERENCES [dbo].[Engineering_Unit] ([Eng_Unit_Id]),
    CONSTRAINT [EventSubtypesEngUnitX_FK_EngUnitId] FOREIGN KEY ([Dimension_X_Eng_Unit_Id]) REFERENCES [dbo].[Engineering_Unit] ([Eng_Unit_Id]),
    CONSTRAINT [EventSubtypesEngUnitY_FK_EngUnitId] FOREIGN KEY ([Dimension_Y_Eng_Unit_Id]) REFERENCES [dbo].[Engineering_Unit] ([Eng_Unit_Id]),
    CONSTRAINT [EventSubtypesEngUnitZ_FK_EngUnitId] FOREIGN KEY ([Dimension_Z_Eng_Unit_Id]) REFERENCES [dbo].[Engineering_Unit] ([Eng_Unit_Id]),
    CONSTRAINT [EvtSubType_UC_EvtSubTypeDesc] UNIQUE NONCLUSTERED ([Event_Subtype_Desc] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_Event_Subtypes]
    ON [dbo].[Event_Subtypes]([Dimension_X_Eng_Unit_Id] ASC);


GO
CREATE TRIGGER [dbo].[Event_Subtypes_TableFieldValue_Del]
 ON  [dbo].[Event_Subtypes]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Event_Subtype_Id
 WHERE tfv.TableId = 51

GO
Create TRIGGER [dbo].[Event_Subtypes_InsUpd]
 ON  [dbo].[Event_Subtypes]
  FOR UPDATE,INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
DECLARE @Event_Subtype_Id Int,@X_Eng_Unit_Id Int, @Y_Eng_Unit_Id Int, @Z_Eng_Unit_Id Int, @A_Eng_Unit_Id Int
DECLARE @Deleted_X_Eng_Unit_Id Int, @Deleted_Y_Eng_Unit_Id Int, @Deleted_Z_Eng_Unit_Id Int, @Deleted_A_Eng_Unit_Id Int
Declare @New_X VarChar(15),@New_Y VarChar(15),@New_Z VarChar(15),@New_A VarChar(15)
DECLARE Event_Subtypes_Upd_Cursor CURSOR
  FOR SELECT Event_Subtype_Id,Dimension_X_Eng_Unit_Id, Dimension_Y_Eng_Unit_Id, Dimension_Z_Eng_Unit_Id, Dimension_A_Eng_Unit_Id FROM INSERTED
  FOR READ ONLY
OPEN Event_Subtypes_Upd_Cursor
  Fetch_Next_EventSubType:
  FETCH NEXT FROM Event_Subtypes_Upd_Cursor INTO @Event_Subtype_Id,@X_Eng_Unit_Id, @Y_Eng_Unit_Id, @Z_Eng_Unit_Id, @A_Eng_Unit_Id
  IF @@FETCH_STATUS = 0
    BEGIN
 	 Select @Deleted_X_Eng_Unit_Id = Null, @Deleted_Y_Eng_Unit_Id = Null,
            @Deleted_Z_Eng_Unit_Id = Null, @Deleted_A_Eng_Unit_Id = Null
      Select @Deleted_X_Eng_Unit_Id = Dimension_X_Eng_Unit_Id,
             @Deleted_Y_Eng_Unit_Id = Dimension_Y_Eng_Unit_Id,
             @Deleted_Z_Eng_Unit_Id = Dimension_Z_Eng_Unit_Id,
             @Deleted_A_Eng_Unit_Id = Dimension_A_Eng_Unit_Id
        From DELETED
        Where (Event_Subtype_Id = @Event_Subtype_Id)
      If (@Deleted_X_Eng_Unit_Id Is Not NULL) Or (@X_Eng_Unit_Id Is Not NULL)
        Begin
          If @X_Eng_Unit_Id Is NULL
 	  	  	 Select @New_X = Null
 	  	 Else 
 	  	  	 Select @New_X = Eng_Unit_Code From Engineering_Unit Where Eng_Unit_Id = @X_Eng_Unit_Id
        End
      If (@Deleted_Y_Eng_Unit_Id Is Not NULL) Or (@Y_Eng_Unit_Id Is Not NULL)
        Begin
          If @Y_Eng_Unit_Id Is NULL
 	  	  	 Select @New_Y = Null
 	  	 Else 
 	  	  	 Select @New_Y = Eng_Unit_Code From Engineering_Unit Where Eng_Unit_Id = @Y_Eng_Unit_Id
        End
      If (@Deleted_Z_Eng_Unit_Id Is Not NULL) Or (@Z_Eng_Unit_Id Is Not NULL)
        Begin
          If @Z_Eng_Unit_Id Is NULL
 	  	  	 Select @New_Z = Null
 	  	 Else 
 	  	  	 Select @New_Z = Eng_Unit_Code From Engineering_Unit Where Eng_Unit_Id = @Z_Eng_Unit_Id
        End
      If (@Deleted_A_Eng_Unit_Id Is Not NULL) Or (@A_Eng_Unit_Id Is Not NULL)
        Begin
          If @A_Eng_Unit_Id Is NULL
 	  	  	 Select @New_A = Null
 	  	 Else 
 	  	  	 Select @New_A = Eng_Unit_Code From Engineering_Unit Where Eng_Unit_Id = @A_Eng_Unit_Id
        End
 	  Update Event_Subtypes set Dimension_X_Eng_Units = @New_X,
 	  	  	  	  	  	  Dimension_Y_Eng_Units = @New_Y,
 	  	  	  	  	  	  Dimension_Z_Eng_Units = @New_Z,
 	  	  	  	  	  	  Dimension_A_Eng_Units = @New_A
 	  	 Where Event_Subtype_Id = @Event_Subtype_Id
      GOTO Fetch_Next_EventSubType
    END
  DEALLOCATE Event_Subtypes_Upd_Cursor
