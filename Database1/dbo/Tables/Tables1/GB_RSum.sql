CREATE TABLE [dbo].[GB_RSum] (
    [RSum_Id]    INT                   IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id] INT                   NULL,
    [Conf_Index] [dbo].[Float_Pct]     NOT NULL,
    [Duration]   [dbo].[Float_Natural] NOT NULL,
    [End_Time]   DATETIME              NOT NULL,
    [In_Limit]   [dbo].[Float_Pct]     NOT NULL,
    [In_Warning] [dbo].[Float_Pct]     NOT NULL,
    [Prod_Id]    INT                   NOT NULL,
    [PU_Id]      INT                   NOT NULL,
    [Start_Time] DATETIME              NOT NULL,
    CONSTRAINT [GB_RSum_PK_RSumId] PRIMARY KEY CLUSTERED ([RSum_Id] ASC),
    CONSTRAINT [GB_RSum_FK_ProdId] FOREIGN KEY ([Prod_Id]) REFERENCES [dbo].[Products_Base] ([Prod_Id]),
    CONSTRAINT [GB_RSum_FK_PUId] FOREIGN KEY ([PU_Id]) REFERENCES [dbo].[Prod_Units_Base] ([PU_Id])
);


GO
CREATE NONCLUSTERED INDEX [Rsum_By_Product]
    ON [dbo].[GB_RSum]([PU_Id] ASC, [Start_Time] ASC, [Prod_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [Rsum_By_PU]
    ON [dbo].[GB_RSum]([PU_Id] ASC, [Start_Time] ASC);


GO
CREATE TRIGGER dbo.GBRSum_Del ON dbo.GB_RSum 
FOR DELETE 
AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE GBRSum_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN GBRSum_Del_Cursor 
--
--
Fetch_Next_GBRSum_Del:
FETCH NEXT FROM GBRSum_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
    Delete From Comments Where TopOfChain_Id = @Comment_Id 
    Delete From Comments Where Comment_Id = @Comment_Id 
    GOTO Fetch_Next_GBRSum_Del
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in GBRSum_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE GBRSum_Del_Cursor 
