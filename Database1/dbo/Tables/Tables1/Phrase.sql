CREATE TABLE [dbo].[Phrase] (
    [Phrase_Id]        INT                      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Active]           BIT                      CONSTRAINT [DF__Phrase__Active__0446695E] DEFAULT ((1)) NOT NULL,
    [Changed_Date]     DATETIME                 NULL,
    [Comment_Required] BIT                      CONSTRAINT [Phrase_DF_CommentRequired] DEFAULT ((0)) NOT NULL,
    [Data_Type_Id]     INT                      NOT NULL,
    [Old_Phrase]       [dbo].[Varchar_Value]    NULL,
    [Phrase_Order]     [dbo].[Smallint_Natural] NOT NULL,
    [Phrase_Value]     [dbo].[Varchar_Value]    NOT NULL,
    CONSTRAINT [Phrase_PK_PhraseId] PRIMARY KEY NONCLUSTERED ([Phrase_Id] ASC),
    CONSTRAINT [Phrase_CC_DataTypeId] CHECK ([Data_Type_Id]>(6)),
    CONSTRAINT [Prase_CC_Value] CHECK (len([Phrase_Value])>(0)),
    CONSTRAINT [Phrase_FK_DataTypeId] FOREIGN KEY ([Data_Type_Id]) REFERENCES [dbo].[Data_Type] ([Data_Type_Id]),
    CONSTRAINT [Phrase_UC_DataTypeIdOrder] UNIQUE CLUSTERED ([Data_Type_Id] ASC, [Phrase_Order] ASC),
    CONSTRAINT [Phrase_UC_DataTypeIdValue] UNIQUE NONCLUSTERED ([Data_Type_Id] ASC, [Phrase_Value] ASC)
);


GO
CREATE TRIGGER [dbo].[Phrase_TableFieldValue_Del]
 ON  [dbo].[Phrase]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Phrase_Id
 WHERE tfv.TableId = 44

GO
CREATE TRIGGER [dbo].[DataType_Phrase_Upd]
 ON  [dbo].[Phrase]
  FOR INSERT 
  AS
 IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
 insert into Sheet_Display_Options_Changed
 Select i.Phrase_Id,i.active,--i.value 
 case  	 
 	 when i.Phrase_Id > 0 then 'activities-app-service'
 End
 from inserted i 
 Where  i.Phrase_Id > 0
 and not exists (select 1 from deleted)
