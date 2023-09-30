CREATE TABLE [dbo].[Characteristic_Groups] (
    [Characteristic_Grp_Id]          INT                      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Comment_Id]                     INT                      NULL,
    [External_Link]                  [dbo].[Varchar_Ext_Link] NULL,
    [Prop_Id]                        INT                      NOT NULL,
    [Characteristic_Grp_Desc_Global] [dbo].[Varchar_Desc]     NULL,
    [Characteristic_Grp_Desc_Local]  [dbo].[Varchar_Desc]     NOT NULL,
    [Characteristic_Grp_Desc]        AS                       (case when (@@options&(512))=(0) then isnull([Characteristic_Grp_Desc_Global],[Characteristic_Grp_Desc_Local]) else [Characteristic_Grp_Desc_Local] end),
    CONSTRAINT [CharGroups_PK_CharGrpId] PRIMARY KEY CLUSTERED ([Characteristic_Grp_Id] ASC),
    CONSTRAINT [CharGroups_FK_PropId] FOREIGN KEY ([Prop_Id]) REFERENCES [dbo].[Product_Properties] ([Prop_Id]),
    CONSTRAINT [CharGroups_UC_GrpDescPropIdLocal] UNIQUE NONCLUSTERED ([Characteristic_Grp_Desc_Local] ASC, [Prop_Id] ASC)
);


GO
CREATE TRIGGER dbo.Characteristic_Groups_Del ON dbo.Characteristic_Groups 
FOR DELETE 
AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
Declare 
 	 @Comment_Id int
DECLARE Characteristic_Groups_Del_Cursor CURSOR
  FOR SELECT Comment_Id FROM DELETED WHERE Comment_Id IS NOT NULL 
  FOR READ ONLY
OPEN Characteristic_Groups_Del_Cursor 
--
--
Fetch_Next_Characteristic_Groups:
FETCH NEXT FROM Characteristic_Groups_Del_Cursor INTO @Comment_Id
IF @@FETCH_STATUS = 0
  BEGIN
    Delete From Comments Where TopOfChain_Id = @Comment_Id 
    Delete From Comments Where Comment_Id = @Comment_Id 
 	   GOTO Fetch_Next_Characteristic_Groups
  END
ELSE IF @@FETCH_STATUS <> -1
  BEGIN
    RAISERROR('Fetch error in Characteristic_Groups_Del (@@FETCH_STATUS = %d).', 11,
      -1, @@FETCH_STATUS)
  END
DEALLOCATE Characteristic_Groups_Del_Cursor 
