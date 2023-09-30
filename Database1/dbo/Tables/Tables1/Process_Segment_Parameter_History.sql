CREATE TABLE [dbo].[Process_Segment_Parameter_History] (
    [Process_Segment_Parameter_History_Id] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Entry_On]                             DATETIME      NULL,
    [Parameter_Id]                         INT           NULL,
    [Process_Segment_Id]                   INT           NULL,
    [Sequence]                             INT           NULL,
    [User_Id]                              INT           NULL,
    [L_Entry]                              NVARCHAR (50) NULL,
    [L_Reject]                             NVARCHAR (50) NULL,
    [L_User]                               NVARCHAR (50) NULL,
    [L_Warning]                            NVARCHAR (50) NULL,
    [U_Entry]                              NVARCHAR (50) NULL,
    [U_Reject]                             NVARCHAR (50) NULL,
    [U_User]                               NVARCHAR (50) NULL,
    [U_Warning]                            NVARCHAR (50) NULL,
    [Value]                                NVARCHAR (50) NULL,
    [PS_Parameter_Id]                      INT           NULL,
    [Modified_On]                          DATETIME      NULL,
    [DBTT_Id]                              TINYINT       NULL,
    [Column_Updated_BitMask]               VARCHAR (15)  NULL,
    CONSTRAINT [Process_Segment_Parameter_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Process_Segment_Parameter_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProcessSegmentParameterHistory_IX_PSParameterIdModifiedOn]
    ON [dbo].[Process_Segment_Parameter_History]([PS_Parameter_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Process_Segment_Parameter_History_UpdDel]
 ON  [dbo].[Process_Segment_Parameter_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
