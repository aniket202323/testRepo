CREATE TABLE [dbo].[Sheet_Groups] (
    [Sheet_Group_Id]          INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Group_Id]                INT                  NULL,
    [Sheet_Group_Desc_Global] [dbo].[Varchar_Desc] NULL,
    [Sheet_Group_Desc_Local]  [dbo].[Varchar_Desc] NOT NULL,
    [Sheet_Group_Desc]        AS                   (case when (@@options&(512))=(0) then isnull([Sheet_Group_Desc_Global],[Sheet_Group_Desc_Local]) else [Sheet_Group_Desc_Local] end),
    CONSTRAINT [SheetGrps_PK_ShtGrpId] PRIMARY KEY CLUSTERED ([Sheet_Group_Id] ASC),
    CONSTRAINT [SheetGroups_FK_GroupId] FOREIGN KEY ([Group_Id]) REFERENCES [dbo].[Security_Groups] ([Group_Id]),
    CONSTRAINT [SheetGrps_UC_ShtGrpDescLocal] UNIQUE NONCLUSTERED ([Sheet_Group_Desc_Local] ASC)
);


GO
CREATE TRIGGER [dbo].[fnBF_ApiFindAvailableUnitsAndEventTypes_Sheet_Groups_Sync]
  	  ON [dbo].[Sheet_Groups]
  	  FOR INSERT, UPDATE, DELETE
AS  	  
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
UPDATE SITE_Parameters SET [Value] = 1 where parm_Id = 700 and [Value]=0;
