CREATE TABLE [dbo].[Stored_Proc_Parm_Types] (
    [SP_Parm_Type_Id]   INT                  IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [SP_Parm_Type_Desc] [dbo].[Varchar_Desc] NOT NULL,
    CONSTRAINT [SPParmTypes_PK_SPParamTypeId] PRIMARY KEY NONCLUSTERED ([SP_Parm_Type_Id] ASC)
);

