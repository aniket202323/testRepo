CREATE TABLE [dbo].[Segment_Parameter_History] (
    [Segment_Parameter_History_Id] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Data_Type_Id]                 INT            NULL,
    [Entry_On]                     DATETIME       NULL,
    [Parameter_Code]               NVARCHAR (50)  NULL,
    [User_Id]                      INT            NULL,
    [Parameter_Desc]               NVARCHAR (300) NULL,
    [Parameter_Name]               NVARCHAR (50)  NULL,
    [Eng_Unit_Id]                  INT            NULL,
    [L_Entry]                      NVARCHAR (50)  NULL,
    [L_Reject]                     NVARCHAR (50)  NULL,
    [L_User]                       NVARCHAR (50)  NULL,
    [L_Warning]                    NVARCHAR (50)  NULL,
    [Mask]                         NVARCHAR (50)  NULL,
    [Segment_Default]              NVARCHAR (50)  NULL,
    [U_Entry]                      NVARCHAR (50)  NULL,
    [U_Reject]                     NVARCHAR (50)  NULL,
    [U_User]                       NVARCHAR (50)  NULL,
    [U_Warning]                    NVARCHAR (50)  NULL,
    [Parameter_Id]                 INT            NULL,
    [Modified_On]                  DATETIME       NULL,
    [DBTT_Id]                      TINYINT        NULL,
    [Column_Updated_BitMask]       VARCHAR (15)   NULL,
    CONSTRAINT [Segment_Parameter_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Segment_Parameter_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [SegmentParameterHistory_IX_ParameterIdModifiedOn]
    ON [dbo].[Segment_Parameter_History]([Parameter_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Segment_Parameter_History_UpdDel]
 ON  [dbo].[Segment_Parameter_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
