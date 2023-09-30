CREATE TABLE [dbo].[Container_Classes] (
    [Container_Class_Id]      INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Container_Class_Desc]    [dbo].[Varchar_Desc] NOT NULL,
    [Default_X]               REAL                 NULL,
    [Default_Y]               REAL                 NULL,
    [Default_Z]               REAL                 NULL,
    [Dimension_X_Desc]        [dbo].[Varchar_Desc] NULL,
    [Dimension_Y_Desc]        [dbo].[Varchar_Desc] NULL,
    [Dimension_Z_Desc]        [dbo].[Varchar_Desc] NULL,
    [Default_A]               FLOAT (53)           NULL,
    [Dimension_A_Desc]        VARCHAR (50)         NULL,
    [Dimension_A_Eng_Unit_Id] INT                  NULL,
    [Dimension_X_Eng_Unit_Id] INT                  NULL,
    [Dimension_Y_Eng_Unit_Id] INT                  NULL,
    [Dimension_Z_Eng_Unit_Id] INT                  NULL,
    CONSTRAINT [ContC_PK_ContCId] PRIMARY KEY NONCLUSTERED ([Container_Class_Id] ASC),
    CONSTRAINT [ContC_UC_ContCDesc] UNIQUE NONCLUSTERED ([Container_Class_Desc] ASC)
);


GO
CREATE TRIGGER [dbo].[Container_Classes_TableFieldValue_Del]
 ON  [dbo].[Container_Classes]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Container_Class_Id
 WHERE tfv.TableId = 61
