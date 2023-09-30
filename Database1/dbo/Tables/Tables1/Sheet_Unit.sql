CREATE TABLE [dbo].[Sheet_Unit] (
    [PU_Id]    INT            NOT NULL,
    [Sheet_Id] INT            NOT NULL,
    [value]    VARCHAR (7000) NULL,
    CONSTRAINT [SheetUnit_PK_SheetIdPUId] PRIMARY KEY NONCLUSTERED ([Sheet_Id] ASC, [PU_Id] ASC),
    CONSTRAINT [SheetUnit_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id]),
    CONSTRAINT [SheetUnit_FK_SheetId] FOREIGN KEY ([Sheet_Id]) REFERENCES [dbo].[Sheets] ([Sheet_Id])
);


GO
CREATE TRIGGER [dbo].[fnBF_ApiFindAvailableUnitsAndEventTypes_Sheet_Unit_Sync]
  	  ON [dbo].[Sheet_Unit]
  	  FOR INSERT, UPDATE, DELETE
AS  	  
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
UPDATE SITE_Parameters SET [Value] = 1 where parm_Id = 700 and [Value]=0;
