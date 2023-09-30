CREATE TABLE [dbo].[Specification_History] (
    [Specification_History_Id] BIGINT                    IDENTITY (1, 1) NOT NULL,
    [Data_Type_Id]             INT                       NULL,
    [Prop_Id]                  INT                       NULL,
    [Spec_Desc]                [dbo].[Varchar_Desc]      NULL,
    [Array_Size]               INT                       NULL,
    [Comment_Id]               INT                       NULL,
    [Eng_Units]                VARCHAR (50)              NULL,
    [Extended_Info]            VARCHAR (255)             NULL,
    [External_Link]            [dbo].[Varchar_Ext_Link]  NULL,
    [Group_Id]                 INT                       NULL,
    [Parent_Id]                INT                       NULL,
    [Retention_Limit]          INT                       NULL,
    [Spec_Order]               INT                       NULL,
    [Spec_Precision]           [dbo].[Tinyint_Precision] NULL,
    [Specification_Type_Id]    INT                       NULL,
    [Tag]                      VARCHAR (50)              NULL,
    [Unit_Conversion]          REAL                      NULL,
    [Var_Id]                   INT                       NULL,
    [Spec_Id]                  INT                       NULL,
    [Modified_On]              DATETIME                  NULL,
    [DBTT_Id]                  TINYINT                   NULL,
    [Column_Updated_BitMask]   VARCHAR (15)              NULL,
    CONSTRAINT [Specification_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Specification_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [SpecificationHistory_IX_SpecIdModifiedOn]
    ON [dbo].[Specification_History]([Spec_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Specification_History_UpdDel]
 ON  [dbo].[Specification_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
