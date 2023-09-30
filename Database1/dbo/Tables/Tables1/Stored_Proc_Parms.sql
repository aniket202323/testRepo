CREATE TABLE [dbo].[Stored_Proc_Parms] (
    [SP_Parm_Id]        INT                       IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Constant_Value]    [dbo].[Varchar_Value]     NULL,
    [DT_Id]             INT                       NOT NULL,
    [SP_Id]             INT                       NOT NULL,
    [SP_Parm_Desc]      [dbo].[Varchar_Desc]      NOT NULL,
    [SP_Parm_Long_Desc] [dbo].[Varchar_Long_Desc] NULL,
    [SP_Parm_Order]     TINYINT                   NOT NULL,
    [SP_Parm_Type_Id]   INT                       NOT NULL,
    CONSTRAINT [SPParms_PK_SPParamId] PRIMARY KEY NONCLUSTERED ([SP_Parm_Id] ASC),
    CONSTRAINT [SPParms_UC_SPIdSPParmDesc] UNIQUE NONCLUSTERED ([SP_Id] ASC, [SP_Parm_Desc] ASC),
    CONSTRAINT [SPParms_UC_SPIdSPParmOrder] UNIQUE NONCLUSTERED ([SP_Id] ASC, [SP_Parm_Order] ASC)
);

