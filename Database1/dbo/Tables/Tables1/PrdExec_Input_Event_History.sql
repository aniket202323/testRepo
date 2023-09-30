CREATE TABLE [dbo].[PrdExec_Input_Event_History] (
    [Input_Event_History_Id]     INT      IDENTITY (1, 1) NOT NULL,
    [Comment_Id]                 INT      NULL,
    [DBTT_Id]                    TINYINT  NULL,
    [Dimension_A]                REAL     NULL,
    [Dimension_A_Updated]        BIT      NULL,
    [Dimension_X]                REAL     NULL,
    [Dimension_X_Updated]        BIT      NULL,
    [Dimension_Y]                REAL     NULL,
    [Dimension_Y_Updated]        BIT      NULL,
    [Dimension_Z]                REAL     NULL,
    [Dimension_Z_Updated]        BIT      NULL,
    [Entry_On]                   DATETIME NOT NULL,
    [Event_Id]                   INT      NULL,
    [Event_Id_Updated]           BIT      NULL,
    [History_EntryOn]            DATETIME NULL,
    [Input_Event_Id]             INT      NULL,
    [PEI_Id]                     INT      NOT NULL,
    [PEI_Id_Updated]             BIT      NULL,
    [PEIP_Id]                    INT      NOT NULL,
    [PEIP_Id_Updated]            BIT      NULL,
    [Signature_Id]               INT      NULL,
    [Start_Coordinate_A]         REAL     NULL,
    [Start_Coordinate_A_Updated] BIT      NULL,
    [Start_Coordinate_X]         REAL     NULL,
    [Start_Coordinate_X_Updated] BIT      NULL,
    [Start_Coordinate_Y]         REAL     NULL,
    [Start_Coordinate_Y_Updated] BIT      NULL,
    [Start_Coordinate_Z]         REAL     NULL,
    [Start_Coordinate_Z_Updated] BIT      NULL,
    [Timestamp]                  DATETIME NOT NULL,
    [Timestamp_Updated]          BIT      NULL,
    [Unloaded]                   TINYINT  CONSTRAINT [PrdExecInputEventsHist_DF_Unloaded] DEFAULT ((0)) NOT NULL,
    [Unloaded_Updated]           BIT      NULL,
    [User_Id]                    INT      NOT NULL,
    CONSTRAINT [PrdExec_Input_Event_History_PK_ID] PRIMARY KEY NONCLUSTERED ([Input_Event_History_Id] ASC),
    CONSTRAINT [PrdExecInputEventHistory_FK_SignatureID] FOREIGN KEY ([Signature_Id]) REFERENCES [dbo].[ESignature] ([Signature_Id]),
    CONSTRAINT [PrdExecInputsHist_FK_Users] FOREIGN KEY ([User_Id]) REFERENCES [dbo].[Users_Base] ([User_Id])
);


GO
CREATE CLUSTERED INDEX [PrdExec_Input_Event_History_IX_PEI_PEIP_TS]
    ON [dbo].[PrdExec_Input_Event_History]([PEI_Id] ASC, [PEIP_Id] ASC, [Timestamp] ASC);


GO
CREATE NONCLUSTERED INDEX [PrdExecInputEventHistory_IDX_SignatureId]
    ON [dbo].[PrdExec_Input_Event_History]([Signature_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [PrdExec_Input_Event_History_IX_EventId]
    ON [dbo].[PrdExec_Input_Event_History]([Event_Id] ASC);


GO
CREATE TRIGGER dbo.PrdExec_Input_Event_History_InsUpd
  ON dbo.PrdExec_Input_Event_History
  FOR INSERT, UPDATE
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare
  @@Id int
Declare Trigger_Cursor INSENSITIVE CURSOR
  For (Select Input_Event_History_Id From INSERTED)
  For Read Only
  Open Trigger_Cursor  
Fetch_Loop:
  Fetch Next From Trigger_Cursor Into @@Id
  If (@@Fetch_Status = 0)
    Begin
      Execute spServer_CmnAddScheduledTask @@Id,6
      Goto Fetch_Loop
    End
Close Trigger_Cursor
Deallocate Trigger_Cursor
