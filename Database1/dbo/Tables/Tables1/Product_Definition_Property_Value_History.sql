CREATE TABLE [dbo].[Product_Definition_Property_Value_History] (
    [Product_Definition_Property_Value_History_Id] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Entry_On]                                     DATETIME      NULL,
    [Product_Definition_Id]                        INT           NULL,
    [Product_Definition_Property_Id]               INT           NULL,
    [User_Id]                                      INT           NULL,
    [Value]                                        NVARCHAR (50) NULL,
    [PDP_Value_Id]                                 INT           NULL,
    [Modified_On]                                  DATETIME      NULL,
    [DBTT_Id]                                      TINYINT       NULL,
    [Column_Updated_BitMask]                       VARCHAR (15)  NULL,
    CONSTRAINT [Product_Definition_Property_Value_History_PK_Id] PRIMARY KEY NONCLUSTERED ([Product_Definition_Property_Value_History_Id] ASC)
);


GO
CREATE CLUSTERED INDEX [ProductDefinitionPropertyValueHistory_IX_PDPValueIdModifiedOn]
    ON [dbo].[Product_Definition_Property_Value_History]([PDP_Value_Id] ASC, [Modified_On] ASC);


GO
CREATE TRIGGER [dbo].[Product_Definition_Property_Value_History_UpdDel]
 ON  [dbo].[Product_Definition_Property_Value_History]
  INSTEAD OF UPDATE,DELETE
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
