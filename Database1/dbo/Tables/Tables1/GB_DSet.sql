CREATE TABLE [dbo].[GB_DSet] (
    [DSet_Id]    INT                      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id] INT                      NULL,
    [Operator]   [dbo].[Varchar_Operator] NULL,
    [Prod_Id]    INT                      NOT NULL,
    [PU_Id]      INT                      NOT NULL,
    [Timestamp]  DATETIME                 NOT NULL,
    CONSTRAINT [GB_DSet_PK_DSetId] PRIMARY KEY CLUSTERED ([DSet_Id] ASC),
    CONSTRAINT [GB_DSet_FK_ProdId] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [GB_DSet_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id])
);


GO
CREATE NONCLUSTERED INDEX [Dset_By_PU]
    ON [dbo].[GB_DSet]([PU_Id] ASC, [Timestamp] ASC);


GO
CREATE TRIGGER dbo.GB_DSet_Del ON dbo.GB_DSet 
FOR DELETE 
AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE GB_DSet_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN GB_DSet_Del_Cursor 
--
--
Fetch_Next_GB_DSet:
FETCH NEXT FROM GB_DSet_Del_Cursor INTO @Comment_Id 
IF @@FETCH_STATUS = 0
  BEGIN
 	  	 Delete From Comments Where TopOfChain_Id = @Comment_Id 
 	  	 Delete From Comments Where Comment_Id = @Comment_Id 
    GOTO Fetch_Next_GB_DSet
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in GB_DSet_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE GB_DSet_Del_Cursor 
