CREATE TABLE [dbo].[Product_Definition_Property_History] (
    [Product_Definition_Property_History_Id] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Data_Type_Id]                           INT            NULL,
    [Entry_On]                               DATETIME       NULL,
    [Product_Definition_Property_Desc]       NVARCHAR (300) NULL,
    [User_Id]                                INT            NULL,
    [Spec_Id]                                INT            NULL,
    [Product_Definition_Property_Id]         INT            NULL,
    [Modified_On]                            DATETIME       NULL,
    [DBTT_Id]                                TINYINT        NULL,
    [Column_Updated_BitMask]                 VARCHAR (15)   NULL,
    CONSTRAINT [Product_Definition_Property_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Product_Definition_Property_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProductDefinitionPropertyHistory_IX_ProductDefinitionPropertyIdModifiedOn]
    ON [dbo].[Product_Definition_Property_History]([Product_Definition_Property_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Product_Definition_Property_History_UpdDel]
 ON  [dbo].[Product_Definition_Property_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
