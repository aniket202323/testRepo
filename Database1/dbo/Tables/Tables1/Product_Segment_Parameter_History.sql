CREATE TABLE [dbo].[Product_Segment_Parameter_History] (
    [Product_Segment_Parameter_History_Id] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Entry_On]                             DATETIME      NULL,
    [Parameter_Id]                         INT           NULL,
    [Product_Segment_Id]                   INT           NULL,
    [User_id]                              INT           NULL,
    [Overridden]                           BIT           NULL,
    [Sequence]                             INT           NULL,
    [L_Entry]                              NVARCHAR (50) NULL,
    [L_Reject]                             NVARCHAR (50) NULL,
    [L_User]                               NVARCHAR (50) NULL,
    [L_Warning]                            NVARCHAR (50) NULL,
    [Precision]                            TINYINT       NULL,
    [Spec_Id]                              INT           NULL,
    [U_Entry]                              NVARCHAR (50) NULL,
    [U_Reject]                             NVARCHAR (50) NULL,
    [U_User]                               NVARCHAR (50) NULL,
    [U_Warning]                            NVARCHAR (50) NULL,
    [Value]                                NVARCHAR (50) NULL,
    [Product_Segment_Parameter_Id]         INT           NULL,
    [Modified_On]                          DATETIME      NULL,
    [DBTT_Id]                              TINYINT       NULL,
    [Column_Updated_BitMask]               VARCHAR (15)  NULL,
    CONSTRAINT [Product_Segment_Parameter_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Product_Segment_Parameter_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProductSegmentParameterHistory_IX_ProductSegmentParameterIdModifiedOn]
    ON [dbo].[Product_Segment_Parameter_History]([Product_Segment_Parameter_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Product_Segment_Parameter_History_UpdDel]
 ON  [dbo].[Product_Segment_Parameter_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
