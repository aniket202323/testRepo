CREATE TABLE [dbo].[Containers] (
    [Container_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Container_Code] VARCHAR (50)         NOT NULL,
    [Container_Desc] [dbo].[Varchar_Desc] NOT NULL,
    [Dimension_X]    REAL                 NULL,
    [Dimension_Y]    REAL                 NULL,
    [Dimension_Z]    REAL                 NULL,
    [Is_Active]      BIT                  CONSTRAINT [Containers_DF_IsActive] DEFAULT ((0)) NOT NULL,
    [Dimension_A]    FLOAT (53)           NULL,
    CONSTRAINT [Cont_PK_ContId] PRIMARY KEY NONCLUSTERED ([Container_Id] ASC),
    CONSTRAINT [Cont_UC_ContCode] UNIQUE NONCLUSTERED ([Container_Code] ASC),
    CONSTRAINT [Cont_UC_ContDesc] UNIQUE NONCLUSTERED ([Container_Desc] ASC)
);


GO
CREATE TRIGGER [dbo].[Containers_TableFieldValue_Del]
 ON  [dbo].[Containers]
  FOR DELETE
  AS
 DELETE Table_Fields_Values
 FROM Table_Fields_Values tfv
 JOIN  Deleted d on tfv.KeyId = d.Container_Id
 WHERE tfv.TableId = 60
