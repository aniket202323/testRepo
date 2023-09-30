CREATE TABLE [dbo].[Security_Groups] (
    [Group_Id]      INT                      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]    INT                      NULL,
    [External_Link] [dbo].[Varchar_Ext_Link] NULL,
    [Group_Desc]    [dbo].[Varchar_Desc]     NOT NULL,
    CONSTRAINT [Security_Groups_PK_GroupId] PRIMARY KEY CLUSTERED ([Group_Id] ASC),
    CONSTRAINT [Security_Groups_UC_GroupDesc] UNIQUE NONCLUSTERED ([Group_Desc] ASC)
);


GO
CREATE TRIGGER dbo.Security_Groups_Del ON dbo.Security_Groups
  FOR DELETE 
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE Security_Groups_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN Security_Groups_Del_Cursor 
--
--
Fetch_Security_Groups_Del:
FETCH NEXT FROM Security_Groups_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
    Delete From Comments Where TopOfChain_Id = @Comment_Id 
    Delete From Comments Where Comment_Id = @Comment_Id 
    GOTO Fetch_Security_Groups_Del
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in Security_Groups_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE Security_Groups_Del_Cursor 
